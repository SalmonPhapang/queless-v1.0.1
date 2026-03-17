import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "npm:google-auth-library@8.8.0"

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
const firebaseServiceAccountJson = Deno.env.get(
  "FIREBASE_SERVICE_ACCOUNT_JSON",
) ?? ""

const supabase = createClient(supabaseUrl, supabaseServiceKey)

let projectId = ""
let googleAuth: GoogleAuth | null = null

if (firebaseServiceAccountJson) {
  const credentials = JSON.parse(firebaseServiceAccountJson)
  projectId = credentials.project_id as string
  googleAuth = new GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  })
}

async function getAccessToken(): Promise<string> {
  if (!googleAuth) {
    throw new Error("GoogleAuth not configured")
  }

  const client = await googleAuth.getClient()
  const token = await client.getAccessToken()

  if (!token || !token.token) {
    throw new Error("Failed to obtain FCM access token")
  }

  return token.token
}

async function sendFcmMessage({
  accessToken,
  message,
}: {
  accessToken: string
  message: Record<string, unknown>
}): Promise<boolean> {
  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

  const res = await fetch(fcmUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ message }),
  })

  if (!res.ok) {
    const text = await res.text()
    console.error("FCM send error:", text)
    return false
  }

  return true
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 })
  }

  let body: any
  try {
    body = await req.json()
  } catch {
    return new Response("Invalid JSON body", { status: 400 })
  }

  const orderId = body.order_id as string | undefined
  const requestedStoreId = body.store_id?.toString?.() ?? ""
  const requestedStoreOwnerUserId = body.store_owner_user_id?.toString?.() ?? ""

  if (!orderId) {
    return new Response("Missing required fields", { status: 400 })
  }

  if (!supabaseUrl || !supabaseServiceKey || !firebaseServiceAccountJson ||
    !projectId) {
    return new Response("Server configuration error", { status: 500 })
  }

  let accessToken: string
  try {
    accessToken = await getAccessToken()
  } catch (err) {
    console.error("Error obtaining FCM access token:", err)
    return new Response("Failed to get FCM access token", { status: 500 })
  }

  const { data: order, error: orderError } = await supabase
    .from("orders")
    .select("*")
    .eq("id", orderId)
    .maybeSingle()

  if (orderError) {
    console.error("Error fetching order:", orderError)
    return new Response("Failed to fetch order", { status: 500 })
  }

  if (!order) {
    return new Response("Order not found", { status: 404 })
  }

  const paymentStatus = (order as any).payment_status?.toString() ?? ""
  if (paymentStatus.toLowerCase() !== "completed") {
    return new Response(
      JSON.stringify({ message: "Order not paid, skipping notifications" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    )
  }

  const storeId = requestedStoreId || (order as any).store_id?.toString() ?? ""

  const dataPayload: Record<string, string> = {
    type: "new_order",
    order_id: orderId,
  }
  if (storeId) dataPayload.store_id = storeId

  let storeOwnerSuccess = 0
  let storeOwnerTargets = 0

  const storeOwnerUserId = requestedStoreOwnerUserId
  if (storeOwnerUserId) {
    const { data: tokens, error } = await supabase
      .from("user_fcm_tokens")
      .select("token")
      .eq("user_id", storeOwnerUserId)

    if (error) {
      console.error("Error fetching store owner tokens:", error)
    } else if (tokens && tokens.length > 0) {
      storeOwnerTargets = tokens.length
      for (const row of tokens as Array<{ token: string }>) {
        const ok = await sendFcmMessage({
          accessToken,
          message: {
            token: row.token,
            notification: {
              title: "New order",
              body: "A new order has been placed.",
            },
            data: dataPayload,
          },
        })
        if (ok) storeOwnerSuccess += 1
      }
    }
  } else if (storeId) {
    const { data: store, error: storeError } = await supabase
      .from("stores")
      .select("*")
      .eq("id", storeId)
      .maybeSingle()

    if (storeError) {
      console.error("Error fetching store:", storeError)
    } else if (store) {
      const ownerId = (store as any).owner_id?.toString() ??
        (store as any).ownerid?.toString() ??
        (store as any).ownerId?.toString() ??
        ""

      if (ownerId) {
        const { data: tokens, error } = await supabase
          .from("user_fcm_tokens")
          .select("token")
          .eq("user_id", ownerId)

        if (error) {
          console.error("Error fetching store owner tokens:", error)
        } else if (tokens && tokens.length > 0) {
          storeOwnerTargets = tokens.length
          for (const row of tokens as Array<{ token: string }>) {
            const ok = await sendFcmMessage({
              accessToken,
              message: {
                token: row.token,
                notification: {
                  title: "New order",
                  body: "A new order has been placed.",
                },
                data: dataPayload,
              },
            })
            if (ok) storeOwnerSuccess += 1
          }
        }
      }
    }
  }

  const driverOk = await sendFcmMessage({
    accessToken,
    message: {
      topic: "NEW_ORDER",
      notification: {
        title: "New delivery request",
        body: "A new order is available.",
      },
      data: dataPayload,
    },
  })

  return new Response(
    JSON.stringify({
      message: "Notifications attempted",
      store_owner: {
        targets: storeOwnerTargets,
        success: storeOwnerSuccess,
      },
      drivers: {
        topic: "NEW_ORDER",
        success: driverOk,
      },
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  )
})
