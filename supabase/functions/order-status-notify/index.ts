// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
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

  const userId = body.user_id as string | undefined
  const orderId = body.order_id as string | undefined
  const status = body.status as string | undefined
  const source = (body.source as string | undefined) ?? "orders"

  if (!userId || !orderId || !status) {
    return new Response("Missing required fields", { status: 400 })
  }

  if (!supabaseUrl || !supabaseServiceKey || !firebaseServiceAccountJson ||
    !projectId) {
    return new Response("Server configuration error", { status: 500 })
  }

  const { data: tokens, error } = await supabase
    .from("user_fcm_tokens")
    .select("token")
    .eq("user_id", userId)

  if (error) {
    console.error("Error fetching FCM tokens:", error)
    return new Response("Failed to fetch tokens", { status: 500 })
  }

  if (!tokens || tokens.length === 0) {
    return new Response(
      JSON.stringify({ message: "No tokens for user" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    )
  }

  const registrationTokens = tokens.map((t: { token: string }) => t.token)

  let accessToken: string

  try {
    accessToken = await getAccessToken()
  } catch (err) {
    console.error("Error obtaining FCM access token:", err)
    return new Response("Failed to get FCM access token", { status: 500 })
  }

  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

  let successCount = 0

  for (const token of registrationTokens) {
    const messagePayload = {
      message: {
        token,
        data: {
          order_id: orderId,
          status,
          source,
        },
      },
    }

    const fcmResponse = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(messagePayload),
    })

    if (!fcmResponse.ok) {
      const text = await fcmResponse.text()
      console.error("FCM error for token", token, text)
      continue
    }

    successCount += 1
  }

  return new Response(
    JSON.stringify({
      message: "Notification sent",
      tokens: registrationTokens.length,
      success: successCount,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  )
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/order-status-notify' \
    --header 'Authorization: Bearer eyJhbGciOiJFUzI1NiIsImtpZCI6ImI4MTI2OWYxLTIxZDgtNGYyZS1iNzE5LWMyMjQwYTg0MGQ5MCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjIwODQwMTY0Njd9.cPxfrf7htadf1pAgNlmevvphEcmbgrgJrpBniaeWyAk2YOT53Xi1SzFpizwPNk-0p0i6ybTjo55AJQ-Ur--BpA' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
