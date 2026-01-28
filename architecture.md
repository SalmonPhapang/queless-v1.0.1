# Queless - Alcohol & Beverage Delivery App Architecture

## Executive Summary
Queless is a South African on-demand alcohol and beverage delivery platform designed for legal compliance, fast service, and exceptional user experience. Built with Flutter for cross-platform deployment.

---

## 1. HIGH-LEVEL ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Auth    │  │   Home   │  │  Orders  │  │ Profile  │  │
│  │  Screens │  │  Browse  │  │ Tracking │  │ Settings │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   Auth   │  │ Product  │  │  Order   │  │ Location │  │
│  │ Service  │  │ Service  │  │ Service  │  │ Service  │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Shared  │  │  Models  │  │  Utils   │  │  Config  │  │
│  │   Prefs  │  │   Data   │  │ Helpers  │  │   Keys   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. CORE FEATURES & USER STORIES

### 2.1 Customer Features

**Authentication & Onboarding**
- As a customer, I want to sign up with email/phone so I can create an account
- As a customer, I want to verify my age (18+) so I can legally purchase alcohol
- As a customer, I want to upload my SA ID for verification

**Browse & Search**
- As a customer, I want to browse beverages by category (beer, wine, spirits, mixers)
- As a customer, I want to search for specific brands (Castle Lager, Amarula, etc.)
- As a customer, I want to filter by alcohol type, price, and local brands
- As a customer, I want to see personalized recommendations based on past orders

**Shopping & Cart**
- As a customer, I want to add items to my cart and adjust quantities
- As a customer, I want to see special deals and bundles (braai packs, rugby match specials)
- As a customer, I want to apply promo codes for discounts
- As a customer, I want to see delivery fees and estimated delivery time before checkout

**Checkout & Payment**
- As a customer, I want to pay with card, EFT, or cash on delivery
- As a customer, I want to save my delivery addresses for quick reordering
- As a customer, I want to schedule deliveries for future events

**Order Tracking**
- As a customer, I want to track my order in real-time with GPS
- As a customer, I want to receive notifications about order status
- As a customer, I want to contact support via in-app chat if there are issues

**Safety & Compliance**
- As a customer, I want to see responsible drinking warnings
- As a customer, I want to know trading hour restrictions in my province
- As a customer, I want an emergency button for safety concerns

### 2.2 Admin Features (Future Phase)
- Inventory management from centralized warehouses
- Driver assignment and tracking
- Order fulfillment workflow
- Analytics dashboard for sales/trends

---

## 3. DATA MODELS

### 3.1 Core Models

**User Model**
```dart
- id: String
- email: String
- phone: String
- full_name: String
- age_verified: bool
- id_document_url: String?
- addresses: List<Address>
- payment_methods: List<PaymentMethod>
- favorite_products: List<String>
- created_at: DateTime
- updated_at: DateTime
```

**Product Model**
```dart
- id: String
- name: String
- category: ProductCategory (enum: beer, wine, spirits, mixers, snacks)
- brand: String
- description: String
- price: double
- image_url: String
- alcohol_content: double?
- volume: String
- is_local_brand: bool
- tags: List<String>
- created_at: DateTime
- updated_at: DateTime
```

**Order Model**
```dart
- id: String
- user_id: String
- items: List<OrderItem>
- subtotal: double
- delivery_fee: double
- discount: double
- total: double
- status: OrderStatus (enum: pending, confirmed, preparing, out_for_delivery, delivered, cancelled)
- delivery_address: Address
- payment_method: String
- payment_status: PaymentStatus
- scheduled_delivery: DateTime?
- tracking_updates: List<TrackingUpdate>
- created_at: DateTime
- updated_at: DateTime
```

**Address Model**
```dart
- id: String
- user_id: String
- label: String (home, work, etc.)
- street_address: String
- city: String
- province: String
- postal_code: String
- latitude: double
- longitude: double
- is_default: bool
```

**Cart Model**
```dart
- user_id: String
- items: List<CartItem>
- promo_code: String?
- created_at: DateTime
- updated_at: DateTime
```

---

## 4. SERVICE CLASSES

### 4.1 AuthService
- Sign up, sign in, sign out
- Age verification workflow
- ID document upload
- Session management

### 4.2 ProductService
- Fetch products by category
- Search products
- Get personalized recommendations
- Filter and sort products
- Manage favorites

### 4.3 OrderService
- Create order from cart
- Get order history
- Track active orders
- Cancel orders
- Rate orders

### 4.4 CartService
- Add/remove items
- Update quantities
- Apply promo codes
- Calculate totals with fees
- Clear cart

### 4.5 AddressService
- Save addresses
- Get saved addresses
- Set default address
- Geocode addresses

### 4.6 NotificationService
- Push notifications for order updates
- In-app notifications

---

## 5. SCREEN STRUCTURE

### 5.1 Authentication Flow
1. **Splash Screen** - Branding and initial load
2. **Welcome Screen** - First-time user greeting
3. **Sign Up / Login Screen** - Email/phone auth
4. **Age Verification Screen** - ID upload and validation
5. **Onboarding Screens** - App features walkthrough

### 5.2 Main App Flow
1. **Home Screen** (Tab 1)
   - Banner promotions
   - Category quick access
   - Featured products
   - Local brand spotlight
   - Special deals section

2. **Browse Screen** (Tab 2)
   - Category filters
   - Search bar
   - Product grid with images
   - Sort and filter options

3. **Cart Screen** (Tab 3)
   - Cart items list
   - Promo code input
   - Order summary (subtotal, fees, total)
   - Checkout button

4. **Orders Screen** (Tab 4)
   - Active orders with tracking
   - Order history
   - Reorder functionality

5. **Profile Screen** (Tab 5)
   - User info
   - Saved addresses
   - Payment methods
   - Order history
   - Settings and preferences
   - Support and help

### 5.3 Secondary Screens
- **Product Detail Screen** - Full product info, add to cart
- **Checkout Screen** - Address selection, payment method, schedule
- **Order Tracking Screen** - Real-time GPS map, delivery status
- **Search Results Screen** - Filtered product list
- **Category Screen** - Products within category
- **Promo Screen** - Active promotions and deals
- **Support Chat Screen** - In-app messaging

---

## 6. LEGAL COMPLIANCE FEATURES

### 6.1 Age Verification
- Mandatory 18+ age check during signup
- SA ID document upload
- Manual review or eKYC integration (future)

### 6.2 Trading Hours Enforcement
- Province-based restrictions (no sales after 9 PM in some provinces)
- No Sunday sales in certain provinces
- Real-time checks before checkout

### 6.3 Responsible Drinking
- Warning messages during checkout
- Limit on bulk purchases
- "Don't drink and drive" messaging
- Links to responsible drinking resources

### 6.4 License Management
- Display liquor license info in app
- Compliance disclaimers

---

## 7. SOUTH AFRICAN INTEGRATIONS

### 7.1 Payment Gateways
- PayFast integration (primary)
- Ozow support
- SnapScan support
- Cash on delivery with change handling

### 7.2 Location Services
- SA address autocomplete
- Major city support (Johannesburg, Cape Town, Durban, Pretoria)
- Delivery zone validation

### 7.3 SMS/OTP Services
- Clickatell integration for phone verification

---

## 8. UNIQUE FEATURES

### 8.1 Local Brand Promotion
- Spotlight section for SA brands (Castle Lager, Amarula, KWV, etc.)
- "Support Local" filter option

### 8.2 Event Bundles
- Braai pack deals
- Rugby match specials
- Holiday bundles

### 8.3 Eco-Friendly Options
- Reusable packaging opt-in
- Sustainability badges on products

### 8.4 Surge Pricing
- Dynamic pricing during peak times (weekends, holidays)
- Transparent communication of pricing

---

## 9. TECHNICAL CONSIDERATIONS

### 9.1 Offline Support
- Load-shedding resilience
- Cached product catalog
- Queue orders for sync when online

### 9.2 Performance
- Image caching and optimization
- Lazy loading for product lists
- Efficient local storage

### 9.3 Security
- Encrypted storage for sensitive data
- Secure payment handling
- Driver-customer anonymity

---

## 10. DEVELOPMENT PHASES

### Phase 1: MVP (✅ COMPLETED)
- ✅ Authentication with age verification
- ✅ Product browsing and search with category filters
- ✅ Cart management with promo codes
- ✅ Checkout with address selection and payment methods
- ✅ Order placement with compliance checks
- ✅ Local storage for all data (15 sample South African beverages)
- ✅ Order tracking UI with timeline
- ✅ Profile management with address CRUD
- ✅ South African compliance features (trading hours, age verification)
- ✅ Modern UI with vibrant orange/teal color scheme

### Phase 2: Backend Integration (Future)
- Firebase/Supabase integration
- Real-time order tracking
- Push notifications
- Payment gateway integration
- Admin panel

### Phase 3: Advanced Features (Future)
- Driver app
- Live chat support
- Advanced analytics
- Subscription service
- Social features (share deals)

---

## 11. MVP TIMELINE ESTIMATE

1. **Week 1-2**: Data models, services, authentication flow
2. **Week 3-4**: Product browsing, search, cart functionality
3. **Week 5**: Checkout flow, order placement
4. **Week 6**: Order tracking UI, profile management
5. **Week 7**: Compliance features, legal warnings
6. **Week 8**: Testing, bug fixes, polish

---

## 12. COST BREAKDOWN (MVP)

- **Development**: 8 weeks × R15,000/week = R120,000
- **Design**: R20,000 (UI/UX)
- **Testing**: R10,000
- **Deployment**: R5,000 (App Store, Play Store)
- **Total MVP**: ~R155,000

---

## 13. KEY CHALLENGES & SOLUTIONS

### Challenge 1: Age Verification
**Solution**: Two-tier approach - basic age input at signup, ID document upload for first purchase, manual review queue initially, automate with eKYC later

### Challenge 2: Trading Hours Compliance
**Solution**: Province detection via GPS, hard-coded trading hour rules per province, real-time validation before checkout

### Challenge 3: Load-Shedding Resilience
**Solution**: Offline-first architecture, local caching, queue sync when online, clear user messaging

### Challenge 4: Payment Integration
**Solution**: Start with PayFast (most popular in SA), add others incrementally, support cash on delivery for immediate launch

### Challenge 5: Real-Time Tracking
**Solution**: MVP uses simulated tracking, Phase 2 adds GPS integration with driver app

---

## 14. SUCCESS METRICS

- User acquisition rate
- Order completion rate
- Average order value
- Delivery time accuracy
- Customer satisfaction scores
- Repeat order percentage
- Compliance incident rate (zero tolerance)

---

**End of Architecture Document**
