# 🤖 AGENT HANDOVER & AUTONOMOUS BOOTSTRAP INSTRUCTIONS

> **Note for AI Agents & Developers**: This document contains complete instructions to autonomously bootstrap, configure, test, and run the **PARIDHAN** Hyperlocal Fashion Marketplace without manual intervention.

---

## 🎯 Project Overview & Architecture
- **App**: Flutter Web / Mobile (`apps/mobile`) with Riverpod state management & GoRouter.
- **Backend & Database**: Supabase PostgreSQL with PostGIS Geospatial extensions, Row-Level-Security (RLS), and Realtime.
- **AI Service**: Python FastAPI server (`backend/` or `paridhan-ai-lab/backend/`) with LangChain / Gemini models.

---

## 🚀 Autonomous 3-Step Setup

### Step 1: Database Initialization (Single Consolidated SQL File)
Run the single SQL script in Supabase SQL Editor:
📄 **[`supabase/complete_setup.sql`](./supabase/complete_setup.sql)**

This script sets up:
- Extensions: `uuid-ossp`, `pgcrypto`, `postgis`.
- All 22 relational tables with foreign keys and cascade deletes.
- PostGIS RPC: `get_nearby_shops(lat, lng, radius_km)`.
- Triggers: `on_auth_user_created` (auto profile creation) and `trg_auto_cart_on_bargain_accepted` (auto-sync accepted bargain prices to shopping bag).
- Permissive RLS security policies.
- **Rich Seed Data for All 4 Roles**: Buyers, Boutique Sellers, Delivery Riders, and Super Admins.

### Step 2: Configure Supabase Credentials
Update the constants in [`apps/mobile/lib/core/constants/app_constants.dart`](./apps/mobile/lib/core/constants/app_constants.dart):
```dart
class AppConstants {
  static const String defaultSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String defaultSupabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

### Step 3: Run Flutter App & Tests
```bash
# Navigate to mobile app directory
cd apps/mobile

# Install packages
flutter pub get

# Run test suite (23 unit & widget tests)
flutter test

# Launch Flutter Web app
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0
```

---

## 👥 Seed Test Accounts & Credentials

| Role | Email | Password | Pre-loaded Data & Workflows |
| :--- | :--- | :--- | :--- |
| 🛍️ **Buyer / Consumer** | `buyer1@gm.com` | `buyer1@gm.com` | **Priya Sharma** — Has saved address in Johari Bazaar, pre-loaded shopping bag, active bargain negotiation at ₹1,200, placed orders |
| 🛍️ **Buyer 2** | `buyer2@gm.com` | `buyer2@gm.com` | **Ananya Sen** — Malviya Nagar address, out-for-delivery order with tracking OTP `7719` |
| 🏪 **Featured Seller** | `seller3@gm.com` | `seller3@gm.com` | **Johari Royal Heritage Boutique** (Johari Bazaar, Jaipur) — 5 catalog products (Lehenga, Anarkali, Sherwani, Jutti, Saree), variants, stock, seller incoming orders |
| 🏪 **Boutique 2** | `seller1@gm.com` | `seller1@gm.com` | **Gulab Niwas Sarees & Lehengas** (Johari Bazaar) |
| 🏪 **Boutique 3** | `seller2@gm.com` | `seller2@gm.com` | **Pink City Handlooms** (Bapu Bazaar) |
| 🏪 **Boutique 4** | `seller4@gm.com` | `seller4@gm.com` | **Rajputana Royal Coutures** (MI Road) |
| 🛵 **Delivery Rider 1** | `delivery1@gm.com` | `delivery1@gm.com` | **Vikram Singh (Johari Rider)** — Motorcycle profile, Johari Bazaar GPS, active dispatch radar with pending pickup job (Pickup OTP: `1234`, Delivery OTP: `4829`) |
| 🛵 **Delivery Rider 2** | `delivery2@gm.com` | `delivery2@gm.com` | **Rahul Sharma (Pink City Rider)** — Scooter Activa, Bapu Bazaar GPS |
| 👑 **Super Admin** | `admin@paridhan.com` | `password123` | Platform KPIs, GMV & 10% commission analytics, boutique KYC approval queue, dispute resolution |
| 👑 **City Ops Admin** | `admin1@gm.com` | `admin1@gm.com` | Jaipur City Operations Management |

---

## 🧭 Key Routes & Navigation
- `/` — Consumer Discovery & PostGIS Nearby Boutiques Map
- `/product/:id` — Product Detail, Image Carousel & Live Bargain Initiation
- `/bargain/:id` — Real-Time Negotiation Chat with Counter-Offers & Deal Acceptance
- `/cart` — Shopping Bag with Quantity Stepper, Dynamic Bargain Price & Subtotals
- `/checkout` — Address Selection & Cash-on-Delivery (COD) Placement
- `/order/:id` — Real-time Order Tracking & OTP Handover Verification
- `/seller` — Seller Studio (Inventory, Stock Management, Incoming Orders, Bargain Requests)
- `/delivery` — Delivery Partner Dashboard (Dispatch Radar, Accept Deliveries, OTP Verification)
- `/admin` — Super Admin Portal (GMV Metrics, Zone Analytics, Boutique Verification, Disputes)

---

## 🛠️ Verification Commands for Agents
To verify all APIs and functions against Supabase live:
```bash
dart run scratch/system_audit.dart
```
Expected result: **13 / 13 integration tests PASS (100%)**.
