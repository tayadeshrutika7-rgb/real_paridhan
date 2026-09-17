# PARIDHAN — "Wear Local. Support Local."
### Hyperlocal Fashion Marketplace with Bargaining & AI
**Engineering README for build agents** — this document is the single source of truth for tech stack, architecture, pages, fields, and API contracts. Read fully before writing code.

---

## 1. Product Summary

Paridhan connects local clothing sellers with nearby buyers. Differentiators: real-time price bargaining, AI shopping assistant, hyperlocal shop discovery, and a delivery-partner logistics layer. Four user roles: **Consumer, Seller, Delivery Partner, Admin** — plus a shared AI Help Desk layer.

---

## 2. Final Tech Stack (lightweight-first, minimal heavy lifting)

| Layer | Choice | Why |
|---|---|---|
| Consumer / Seller / Delivery apps (mobile + web) | **Flutter** (one codebase, 3 build "flavors") | One codebase → iOS, Android, Web. No separate native builds. |
| Admin dashboard | **Next.js 14 (App Router) + TypeScript** (web only) | Admin is desktop/internal-only — no need to force it into Flutter/mobile. |
| Database + Auth + Storage + Realtime | **Supabase** (Postgres) with **PostGIS extension enabled** | One managed platform replaces Firebase Auth + Firestore + S3 + a custom backend DB. RLS handles role-based access natively. PostGIS is required (not optional) for radius/nearby-shop queries to perform well at scale — enable it in migration #1. |
| Custom business logic (bargaining rules, order lifecycle, payment webhooks, payouts) | **Supabase Edge Functions** (Deno/TypeScript) | Serverless, no server to manage. |
| Realtime bargaining/chat/notifications | **Supabase Realtime** | Covers both the bargain chat AND live in-app notification badges (see §8). |
| Push notifications (app closed/background) | **OneSignal** | Cross-platform SDK, no separate Firebase project needed just for push. |
| Email (SMTP/transactional) | **Resend** | Simple API, good deliverability. |
| WhatsApp (transactional) | **Gupshup WhatsApp Business API** (or Twilio fallback) | Standard for Indian WhatsApp Business messaging. |
| Payments (marketplace, multi-seller) | **Razorpay Route** (Razorpay's marketplace/split-payment product) — NOT plain Razorpay Payments | Plain Razorpay only moves money platform↔consumer. Since you have many sellers who need their own payout, you need Route, which auto-splits each payment into platform commission + seller settlement, and requires each seller to have a **linked account** (their own sub-merchant profile with bank + PAN/KYC). |
| Maps & Location | **Google Maps Platform** (Maps SDK, Places, Directions, Geocoding) | Industry standard, good Flutter plugin support. |
| Image storage/CDN | **Supabase Storage** | Compress/resize client-side before upload (see §11) to control storage cost. |
| AI Help Desk / NLP / Recommendations | **Anthropic Claude API** | Single API for NLP search, bargaining assistant, product Q&A, role-specific responses. |
| Search | **Postgres full-text search (tsvector)** on Supabase | Upgrade to Meilisearch/Algolia only if volume demands it. |
| Hosting — backend | **Supabase** (managed) | |
| Hosting — Flutter Web build | **Firebase Hosting** or **Vercel** (static hosting only — not using other Firebase services) | |
| Hosting — Next.js Admin | **Vercel** | |
| CI/CD | **GitHub Actions** | |
| Error monitoring | **Sentry** (Flutter + Next.js SDKs) | |
| Analytics | **PostHog** | |

---

## 3. Repository Structure

```
paridhan/
├── apps/
│   ├── mobile/                 # Flutter app (Consumer/Seller/Delivery — 3 flavors)
│   │   ├── lib/
│   │   │   ├── core/            # shared: theme, constants, utils, network client, deep_links
│   │   │   ├── features/
│   │   │   │   ├── auth/
│   │   │   │   ├── consumer/
│   │   │   │   ├── seller/
│   │   │   │   ├── delivery/
│   │   │   │   ├── ai_helpdesk/
│   │   │   │   ├── legal/        # T&C, Privacy Policy screens
│   │   │   │   └── shared_widgets/
│   │   │   └── main_consumer.dart / main_seller.dart / main_delivery.dart
│   │   └── flavors/ (android/iOS flavor configs)
│   └── admin/                   # Next.js admin dashboard
│       ├── app/
│       ├── components/
│       └── lib/
├── supabase/
│   ├── migrations/              # SQL migration files (schema below)
│   ├── functions/                # Edge Functions (bargaining, orders, payouts, ai-proxy, webhooks)
│   └── seed.sql
├── docs/
│   ├── api-contracts.md
│   ├── privacy-policy.md
│   └── terms-and-conditions.md
└── README.md
```

---

## 4. Database Schema (Supabase / Postgres)

Enable extensions first: `create extension if not exists postgis;` — use `geography(Point, 4326)` for all lat/lng storage going forward, with a GIST spatial index, instead of plain float columns. This makes "shops within X km" queries fast and correct.

### 4.1 `profiles`
| Field | Type | Notes |
|---|---|---|
| id | uuid (PK, = auth.users.id) | |
| role | enum('consumer','seller','delivery','admin') | |
| full_name | text | |
| phone | text | unique |
| email | text | unique |
| avatar_url | text | |
| skin_tone_pref | text, nullable | opt-in field, phase 2 |
| accepted_terms_at | timestamptz | must be set before first order/listing |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### 4.2 `push_subscriptions`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK → profiles.id | |
| onesignal_player_id | text | one row per device |
| platform | enum('ios','android','web') | |
| created_at | timestamptz | |

### 4.3 `shops`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| seller_id | uuid FK → profiles.id | |
| name | text | |
| description | text | |
| logo_url | text | |
| banner_url | text | |
| address | text | |
| location | geography(Point,4326) | PostGIS — replaces plain lat/lng |
| status | enum('pending','verified','rejected','suspended') | admin-controlled |
| category_ids | uuid[] | FK → categories |
| avg_rating | numeric | computed/cached |
| razorpay_linked_account_id | text, nullable | from Razorpay Route onboarding |
| kyc_status | enum('not_started','pending','verified','rejected') | required before payouts |
| commission_rate | numeric | platform commission %, defaults from `platform_config` |
| created_at | timestamptz | |

### 4.4 `categories` / `brands`
| Field | Type |
|---|---|
| id | uuid PK |
| name | text |
| parent_id | uuid, nullable |
| icon_url | text |

### 4.5 `products`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| shop_id | uuid FK | |
| category_id | uuid FK | |
| brand_id | uuid FK, nullable | |
| title | text | |
| description | text | |
| base_price | numeric | |
| min_bargain_price | numeric | floor for negotiation — enforced server-side, see §9 |
| bargain_enabled | boolean | |
| status | enum('active','draft','out_of_stock','removed') | |
| search_vector | tsvector | |
| created_at | timestamptz | |

### 4.6 `product_variants`
| Field | Type |
|---|---|
| id | uuid PK |
| product_id | uuid FK |
| size | text |
| color | text |
| stock_qty | int |
| price_override | numeric, nullable |
| sku | text |
| image_urls | text[] |

### 4.7 `bargains`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| product_id | uuid FK | |
| consumer_id | uuid FK | |
| seller_id | uuid FK | |
| status | enum('open','countered','accepted','rejected','expired') | |
| current_offer | numeric | |
| current_offer_by | enum('consumer','seller') | |
| expires_at | timestamptz | |
| created_at | timestamptz | |

### 4.8 `bargain_messages`
| Field | Type |
|---|---|
| id | uuid PK |
| bargain_id | uuid FK |
| sender_id | uuid FK |
| offer_amount | numeric, nullable |
| message_type | enum('offer','counter','accept','reject','text') |
| text | text, nullable |
| created_at | timestamptz |

### 4.9 `cart_items`
| Field | Type |
|---|---|
| id | uuid PK |
| consumer_id | uuid FK |
| variant_id | uuid FK |
| quantity | int |
| agreed_price | numeric |

### 4.10 `wishlists`
| Field | Type |
|---|---|
| id | uuid PK |
| consumer_id | uuid FK |
| product_id | uuid FK |
| created_at | timestamptz |

### 4.11 `orders`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| consumer_id | uuid FK | |
| shop_id | uuid FK | |
| delivery_partner_id | uuid FK, nullable | |
| status | enum('placed','confirmed','packed','out_for_delivery','delivered','cancelled','return_requested','returned') | |
| payment_method | enum('cod','razorpay') | |
| payment_status | enum('pending','paid','failed','refunded','partially_refunded') | |
| razorpay_order_id | text, nullable | |
| razorpay_transfer_id | text, nullable | Route transfer to seller's linked account |
| subtotal | numeric | |
| delivery_fee | numeric | |
| commission_amount | numeric | platform's cut, computed at order time |
| seller_payout_amount | numeric | subtotal − commission |
| total | numeric | |
| cod_collected | boolean, default false | |
| cod_collected_at | timestamptz, nullable | |
| delivery_address | jsonb | |
| cancel_reason | text, nullable | |
| created_at | timestamptz | |

### 4.12 `order_items`
| Field | Type |
|---|---|
| id | uuid PK |
| order_id | uuid FK |
| variant_id | uuid FK |
| quantity | int |
| unit_price | numeric |

### 4.13 `returns_refunds`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| order_id | uuid FK | |
| requested_by | uuid FK (consumer) | |
| reason | text | |
| photo_urls | text[], nullable | |
| status | enum('requested','approved','rejected','picked_up','refunded') | |
| refund_amount | numeric, nullable | |
| resolved_by | uuid FK (seller/admin), nullable | |
| created_at | timestamptz | |

### 4.14 `payouts`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| seller_id | uuid FK | |
| period_start / period_end | date | settlement window |
| gross_sales | numeric | |
| commission_deducted | numeric | |
| net_payout | numeric | |
| status | enum('pending','processing','paid','failed') | |
| razorpay_payout_id | text, nullable | |
| created_at | timestamptz | |

### 4.15 `cod_remittance`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK | |
| delivery_partner_id | uuid FK | |
| order_id | uuid FK | |
| amount | numeric | |
| status | enum('pending','remitted') | cash handed back to platform/seller |
| remitted_at | timestamptz, nullable | |

### 4.16 `reviews`
| Field | Type |
|---|---|
| id | uuid PK |
| order_id | uuid FK |
| product_id | uuid FK, nullable |
| shop_id | uuid FK, nullable |
| reviewer_id | uuid FK |
| rating | int (1-5) |
| comment | text |
| created_at | timestamptz |

### 4.17 `addresses`
| Field | Type |
|---|---|
| id | uuid PK |
| consumer_id | uuid FK |
| label | text |
| line1, line2, city, state, pincode | text |
| location | geography(Point,4326) |
| is_default | boolean |

### 4.18 `delivery_partner_profile`
| Field | Type | Notes |
|---|---|---|
| id | uuid PK (= profiles.id) | |
| vehicle_type | text | |
| vehicle_number | text | |
| license_url | text | |
| is_available | boolean | |
| current_location | geography(Point,4326) | |
| verification_status | enum('pending','verified','rejected') | Admin queue, see §6.4 |
| bank_account_details | jsonb | for payout |

### 4.19 `notifications`
| Field | Type |
|---|---|
| id | uuid PK |
| user_id | uuid FK |
| title | text |
| body | text |
| type | enum('order','bargain','system','promo','return') |
| deep_link | text, nullable | e.g. `paridhan://order/{id}` |
| read | boolean |
| created_at | timestamptz |

### 4.20 `ai_interactions`
| Field | Type |
|---|---|
| id | uuid PK |
| user_id | uuid FK |
| role_context | text |
| query | text |
| response | text |
| created_at | timestamptz |

### 4.21 `reports_complaints`
| Field | Type |
|---|---|
| id | uuid PK |
| reporter_id | uuid FK |
| target_type | enum('shop','product','user','order') |
| target_id | uuid |
| reason | text |
| status | enum('open','reviewing','resolved','dismissed') |

### 4.22 `platform_config`
| Field | Type |
|---|---|
| key | text PK |
| value | jsonb |

**RLS pattern:** every table's policies check `auth.uid() = owner_id` for own-data access, and a `role = 'admin'` check (via an `is_admin()` SQL function) for full access.

---

## 5. Auth & Roles

- Supabase Auth: **Google OAuth** + **Phone OTP** + **Email/Password**.
- **Forgot Password** flow for email/password users via Supabase's built-in reset-password email (needs its own screen in each Flutter app).
- On first login, a Postgres trigger auto-creates a `profiles` row with `role` set from signup metadata (`consumer` by default; `seller`/`delivery` selected at signup; `admin` assigned manually in DB — never self-service).
- Flutter app reads `role` after login and routes to the correct flavor's home screen.
- Admin dashboard requires `role = 'admin'` — enforced both in Next.js middleware and RLS.
- Rate-limit OTP requests and signup attempts (Supabase has basic built-in throttling; add an Edge Function check for repeated failed attempts per phone/IP if abuse becomes an issue).
- **Guest browsing:** allow unauthenticated users to browse Home/Search/Product Detail; require login only at "Add to Cart," "Bargain," or "Checkout." Improves conversion — build this in from the start rather than retrofitting.

---

## 6. App Pages & Required Fields

### 6.1 Consumer App

| # | Screen | Key Fields / Components | Backend calls |
|---|---|---|---|
| 1 | Splash/Onboarding | — | check session |
| 2 | Login/Signup | email, phone, Google button, OTP input | `supabase.auth.signInWithOtp`, `signInWithOAuth` |
| 2b | Forgot Password | email input, reset link flow | Supabase Auth reset |
| 3 | Home/Discover (guest-accessible) | location permission, nearby shops carousel, category grid, banners | `shops` (PostGIS radius query), `categories` |
| 4 | Search & Filters (guest-accessible) | search bar, price range, size, color, category, sort | `products` full-text + filters |
| 5 | Shop Profile (guest-accessible) | shop name, logo, rating, address, product grid, "message/bargain" CTA | `shops`, `products` by shop_id |
| 6 | Product Listing (guest-accessible) | grid/list toggle, product card | `products` + `product_variants` |
| 7 | Product Detail (guest-accessible) | image gallery, variant selector, price, stock, "Bargain" button, "Add to Cart", reviews list | `products`, `product_variants`, `reviews` |
| 8 | Bargain Screen | offer input, counter-offer thread, accept/reject buttons, timer | `bargains`, `bargain_messages` via Realtime channel |
| 9 | Wishlist | grid of saved products, remove button | `wishlists` |
| 10 | Cart | line items, quantity stepper, agreed price shown, subtotal | `cart_items` |
| 11 | Checkout | address selector/new address form, payment method toggle (COD/Razorpay), order summary, "Accept Terms" checkbox | `addresses`, `orders`, Razorpay SDK |
| 12 | Order Tracking | status timeline, delivery partner live map | `orders`, `delivery_partner_profile` |
| 13 | Order History | list with status chips, reorder, **Cancel Order** button (pre-shipping only) | `orders` |
| 14 | Order Detail → Request Return | reason dropdown, photo upload, submit | `returns_refunds` |
| 15 | Write Review | star rating, comment box, photo upload (optional) | `reviews` |
| 16 | AI Help Desk | chat interface, quick-reply chips | Edge Function → Claude API |
| 17 | For You / Recommendations | horizontal product carousels | `ai_interactions` + `products` |
| 18 | Profile & Addresses | name, phone, email, avatar upload, address list (CRUD) | `profiles`, `addresses` |
| 19 | Notifications | list, mark-as-read, tapping opens deep-linked screen | `notifications` (Realtime + push) |
| 20 | Settings | logout, delete account, language, theme, notification prefs | — |
| 21 | Terms & Conditions / Privacy Policy | static content, "Accept" on first login | `profiles.accepted_terms_at` |

### 6.2 Seller App

| # | Screen | Key Fields | Backend calls |
|---|---|---|---|
| 1 | Signup + Shop Registration | shop name, address (map picker), category, GST/PAN upload | `shops` insert (status=pending, kyc_status=pending) |
| 2 | Razorpay Route Onboarding | bank account, PAN, business type — creates linked account | Edge Function → Razorpay Route API |
| 3 | Seller Dashboard | today's sales, pending orders count, pending bargains count, pending payout | aggregated queries |
| 4 | Shop Profile Management | name, logo, banner, description, hours | `shops` update |
| 5 | Product List | search/filter own products, status toggle | `products` by shop_id |
| 6 | Add/Edit Product | title, description, category, brand, base price, min bargain price, bargain toggle, variants (size/color/stock/price/images, compressed client-side) | `products`, `product_variants` |
| 7 | Inventory Management | stock table, bulk stock update | `product_variants` |
| 8 | Bargaining Settings | min price per product, auto-accept threshold | `products.min_bargain_price` |
| 9 | Bargain Inbox | list of open bargains, chat thread, accept/counter/reject | `bargains`, `bargain_messages` (Realtime) |
| 10 | Order Management | order list, status update buttons | `orders` update |
| 11 | Returns Inbox | list of return requests, approve/reject, refund trigger | `returns_refunds` |
| 12 | Sales & Analytics | revenue chart, top products, date range filter | aggregated |
| 13 | Payouts | settlement history, next payout date, commission breakdown | `payouts` |
| 14 | Reviews | list, reply (optional) | `reviews` |
| 15 | AI Assistant | chat (seller-context) | Edge Function → Claude API |
| 16 | Profile & Bank Settings | bank details, Razorpay linked account status | `profiles`, `shops` |
| 17 | Notifications | — | `notifications` |
| 18 | Terms & Conditions / Privacy Policy | — | `profiles.accepted_terms_at` |

### 6.3 Delivery Partner App

| # | Screen | Key Fields | Backend calls |
|---|---|---|---|
| 1 | Signup + Verification | name, phone, vehicle type, vehicle number, license upload | `delivery_partner_profile` insert (verification_status=pending) |
| 2 | Verification Pending Screen | status message while Admin reviews | `delivery_partner_profile.verification_status` |
| 3 | Dashboard | today's earnings, active assignment card | aggregated |
| 4 | Assignment List | pickup shop, drop address, distance, accept/decline | `orders` unassigned & nearby (PostGIS query) |
| 5 | Delivery Detail | pickup address, customer name/phone (masked), items, COD amount if applicable | `orders`, `order_items` |
| 6 | Live Navigation | embedded map, turn-by-turn | Google Directions API |
| 7 | Status Update | picked up → out for delivery → delivered (+ OTP confirmation), **COD collected toggle** | `orders.status`, `orders.cod_collected` |
| 8 | Delivery History | list with earnings per delivery | `orders` |
| 9 | Availability Toggle | online/offline switch | `delivery_partner_profile.is_available` |
| 10 | Earnings & History + Withdraw | totals, "Withdraw to Bank" button, COD remittance status | aggregated, `cod_remittance` |
| 11 | AI Assistant | chat (delivery-context) | Edge Function → Claude API |
| 12 | Profile & Vehicle Details | edit vehicle info, documents, bank account | `delivery_partner_profile` |
| 13 | Notifications | — | `notifications` |
| 14 | Terms & Conditions / Privacy Policy | — | `profiles.accepted_terms_at` |

### 6.4 Admin Dashboard (Next.js, web only)

| # | Screen | Key Fields | Backend calls |
|---|---|---|---|
| 1 | Login (+ 2FA) | email/password | Supabase Auth, admin role check |
| 2 | Overview Dashboard | GMV, active users, order volume, commission earned | aggregated |
| 3 | User Management | table of all profiles, role filter, suspend/activate | `profiles` |
| 4 | Shop Verification Queue | pending shops, KYC docs, approve/reject with reason | `shops.status`, `shops.kyc_status` |
| 5 | **Delivery Partner Verification Queue** | pending partners, license/vehicle docs, approve/reject | `delivery_partner_profile.verification_status` |
| 6 | Product Moderation Queue | flagged/new products, approve/remove | `products.status` |
| 7 | Order Monitoring | all orders, filters by status/date/shop | `orders` |
| 8 | Returns/Refunds Queue | escalated return requests, force-refund | `returns_refunds` |
| 9 | Delivery Management | delivery partner list, assignment overrides | `delivery_partner_profile`, `orders` |
| 10 | Bargaining Monitoring | flagged/abnormal bargains | `bargains` |
| 11 | Review Moderation | flagged reviews, remove/approve | `reviews` |
| 12 | Reports & Complaints | ticket list, status update, resolution notes | `reports_complaints` |
| 13 | Categories/Brands Management | CRUD | `categories` |
| 14 | Payouts & Settlements | payout runs, per-seller ledger, retry failed payouts | `payouts`, `cod_remittance` |
| 15 | Platform Analytics | cohort/retention, top shops/products | aggregated |
| 16 | System Configuration | commission %, delivery fee rules, feature flags | `platform_config` |
| 17 | AI Assistant (admin) | chat (admin-context) | Edge Function → Claude API |

---

## 7. Bargaining State Machine

```
[Consumer sends offer] → status: open
   ↓
[Seller counters] → status: countered (current_offer_by: seller)
   ↓ (loop: consumer can counter back → status: countered, current_offer_by: consumer)
   ↓
[Either party accepts] → status: accepted → auto-create cart_item at agreed_price
[Either party rejects] → status: rejected → thread closed, consumer may reopen new bargain
[expires_at passed with no action] → status: expired (scheduled Edge Function checks periodically)
```

**Server-side enforcement (required, not optional):** write a Postgres trigger (`before insert/update on bargain_messages`) or an Edge Function gatekeeper that rejects any `offer_amount` below the linked product's `min_bargain_price` — never rely on the Flutter client to enforce this, since a modified client or direct API call could bypass UI-level checks.

Realtime channel naming convention: `bargain:{bargain_id}`.

---

## 8. Realtime & Notifications — How the Two Systems Work Together

Two separate mechanisms, both required:
1. **Supabase Realtime** — subscribed while the app is open. Powers: bargain chat updates, live in-app notification bell/badge (subscribe to `notifications` table filtered by `user_id`), delivery partner's live location on the tracking map.
2. **OneSignal push** — fires when the app is closed/backgrounded. Every time a row is inserted into `notifications`, an Edge Function trigger also calls OneSignal's API using the recipient's `onesignal_player_id` (from `push_subscriptions`).

**Deep linking:** every `notifications` row carries a `deep_link` (e.g. `paridhan://order/{id}`). Set up `app_links` (Android)/associated domains (iOS) in Flutter so tapping a push notification or WhatsApp/email link opens the exact screen — don't leave this as an afterthought, it's fiddly to retrofit.

---

## 9. Payments — Marketplace Split (Razorpay Route)

- Each seller completes KYC and gets a **Razorpay linked account** before their shop can go live (`shops.kyc_status = 'verified'` gates this).
- On order payment success, Razorpay Route auto-splits the payment: seller's share goes to their linked account (minus commission), platform's commission stays with the main account.
- For **COD orders**, there's no live split — the delivery partner collects cash, marks `cod_collected = true`, and that cash is tracked in `cod_remittance` until physically/digitally settled back. Seller's payout for COD orders happens via the normal `payouts` cycle once remittance is confirmed.
- `payouts` table is populated by a scheduled Edge Function (e.g. weekly) that sums each seller's `orders.seller_payout_amount` for the period and initiates a Razorpay payout to their linked account.

---

## 10. Legal / Compliance (do not skip — app store blocker)

- Draft **Privacy Policy** and **Terms & Conditions** (docs/ folder) before submission — Play Store/App Store will reject apps collecting location, payment, and identity data without these, and without an in-app link to them.
- Add a **Data Safety** section (Play Store) / **App Privacy** section (App Store) describing exactly what's collected: location, phone, payment info, and later skin-tone data (marked as sensitive/optional).
- Note **India's DPDP Act 2023**: since the app stores location, payment, and biometric-adjacent (skin-tone) data, plan for user consent capture (`profiles.accepted_terms_at`), a data-deletion request flow, and a designated grievance contact — flag this to whoever handles legal, it's not purely an engineering task but affects schema (consent timestamps, deletion cascade behavior).

---

## 11. Environment Variables (`.env` template)

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=       # server/Edge Functions only, never in client
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_ROUTE_ACCOUNT_ID=
GOOGLE_MAPS_API_KEY=
GOOGLE_OAUTH_CLIENT_ID=
ONESIGNAL_APP_ID=
ONESIGNAL_API_KEY=
RESEND_API_KEY=
GUPSHUP_API_KEY=
ANTHROPIC_API_KEY=
SENTRY_DSN=
POSTHOG_API_KEY=
```

---

## 12. Build Phases (recommended order for agents)

**Phase 1 — Foundation**
- Supabase project + enable PostGIS + full schema migration + RLS policies
- Auth flows (Google/OTP/email + forgot password) in Flutter + role-based routing + guest browsing
- Terms & Conditions / Privacy Policy screens + consent capture
- Basic profile CRUD + push token registration

**Phase 2 — Core Commerce**
- Shop/Product/Variant CRUD (seller side), with client-side image compression
- Discovery (PostGIS nearby query)/Search/Product Detail (consumer side, guest-accessible)
- Cart → Checkout (Razorpay Route split payment + COD) → Orders
- Order cancellation (pre-shipping)

**Phase 3 — Bargaining**
- Bargain state machine with server-side floor-price enforcement + Realtime chat UI (both apps)

**Phase 4 — Delivery & Logistics**
- Delivery partner signup + Admin verification queue
- Assignment logic, live tracking, status updates, COD collection toggle

**Phase 5 — Returns & Payouts**
- Return/refund request flow (consumer → seller → admin escalation)
- Seller KYC/Razorpay Route onboarding
- Payouts + COD remittance tracking

**Phase 6 — Admin**
- Next.js dashboard: all verification queues, monitoring, returns, payouts, config

**Phase 7 — AI Layer**
- AI Help Desk Edge Function + chat UI across all 4 apps
- Basic recommendations

**Phase 8 — Notifications & Polish**
- Realtime in-app notifications + OneSignal push + deep linking
- Reviews, analytics, WhatsApp/email transactional messages

**Phase 9 — Deferred / Phase 2 features**
- Skin-tone based recommendations (with explicit opt-in + DPDP-compliant consent)
- Advanced analytics/reporting
- Search upgrade (Meilisearch) if needed

---

## 13. Conventions for Coding Agents

- All dates/timestamps in UTC, converted client-side.
- All monetary values stored as `numeric`, displayed with 2 decimals, currency = INR (₹).
- Every table needs `created_at`; mutable tables need `updated_at` with an `on update` trigger.
- Never expose `SUPABASE_SERVICE_ROLE_KEY` client-side — only in Edge Functions.
- Compress/resize images client-side (target ≤ 500KB) before upload to Supabase Storage.
- Flutter: Riverpod for state management, `go_router` for navigation (with deep-link support configured from day one), one `ApiClient` wrapper around Supabase client per feature module.
- Next.js: Server Components for data fetching where possible, Server Actions for mutations, Supabase SSR client.
- Write RLS policies before writing any client query that touches a new table — never rely on client-side role checks alone.
- Any price/floor logic (bargaining minimums, commission calculation) must be enforced server-side (trigger or Edge Function), never trusted from client input.
