# 👗 PARIDHAN — Complete Setup & Handover Guide

> **Hyperlocal Fashion Marketplace with Direct Bargaining, PostGIS Local Discovery & Instant Delivery Dispatch.**

---

## ⚡ 1-Step Database Setup (Single Consolidated File)

Everything (Database Schema, Tables, PostGIS Radius Functions, Bargain-to-Cart Sync Triggers, RLS Security Policies, and Ready-to-Test Dummy Data for every role) is combined into **a single consolidated SQL file**:

📁 **[`supabase/complete_setup.sql`](./supabase/complete_setup.sql)**

### How to Initialize your Database:
1. Create a free project on **[Supabase](https://supabase.com)** (e.g. `paridhan-marketplace`, Region: *Mumbai / ap-south-1*).
2. Go to **SQL Editor** in your Supabase Dashboard -> click **New Query**.
3. Copy the entire content of [`supabase/complete_setup.sql`](./supabase/complete_setup.sql), paste it into the editor, and click **RUN**.
4. That's it! Your entire database is created with sample boutiques, products, variants, and test accounts.

---

## 🔑 Connect Your Own Supabase Keys

1. In your Supabase Dashboard, go to **Project Settings** -> **API**.
2. Copy your:
   - **Project URL** (e.g., `https://your-project-id.supabase.co`)
   - **anon / public key** (e.g., `sb_publishable_...` or JWT token)
3. Open [`apps/mobile/lib/core/constants/app_constants.dart`](./apps/mobile/lib/core/constants/app_constants.dart) and paste them:

```dart
class AppConstants {
  // Replace with your project credentials:
  static const String defaultSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String defaultSupabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

*(Optional: If using the AI Backend in `backend/.env`, set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` there as well).*

---

## 🚀 Run the Application

```bash
# Navigate to mobile app
cd apps/mobile

# Get dependencies
flutter pub get

# Run test suite
flutter test

# Run on Chrome / Web Server
flutter run -d chrome
# or
flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0
```

---

## 👥 Comprehensive Pre-seeded Dummy Data for Every Role

The database is pre-populated with dummy accounts, boutiques, catalogs, and orders ready for testing:

| Role | Email | Password | Pre-loaded Data & Features |
| :--- | :--- | :--- | :--- |
| 🛍️ **Buyer 1** | `buyer1@gm.com` | `buyer1@gm.com` | **Priya Sharma** (Johari Bazaar, Jaipur) — Pre-populated bag, accepted bargain deal (₹1,200), order history |
| 🛍️ **Buyer 2** | `buyer2@gm.com` | `buyer2@gm.com` | **Ananya Sen** (Malviya Nagar, Jaipur) — Active out-for-delivery order with tracking OTP `7719` |
| 🏪 **Seller (Featured)** | `seller3@gm.com` | `seller3@gm.com` | **Johari Royal Heritage Boutique** (Shop 24, Johari Bazaar, Jaipur) — 5 ethnic products (Lehenga, Anarkali, Sherwani, Jutti, Saree), variants & stock, seller order queue |
| 🏪 **Boutique 2** | `seller1@gm.com` | `seller1@gm.com` | **Gulab Niwas Sarees & Lehengas** (Shop 42, Johari Bazaar) |
| 🏪 **Boutique 3** | `seller2@gm.com` | `seller2@gm.com` | **Pink City Handloom Emporium** (Shop 15, Bapu Bazaar) |
| 🏪 **Boutique 4** | `seller4@gm.com` | `seller4@gm.com` | **Rajputana Royal Coutures** (G-4, MI Road) |
| 🛵 **Delivery Rider 1** | `delivery1@gm.com` | `delivery1@gm.com` | **Vikram Singh (Johari Rider)** — Motorbike, Johari Bazaar location, dispatch radar with pending pickup (Pickup OTP: `1234`, Delivery OTP: `4829`) |
| 🛵 **Delivery Rider 2** | `delivery2@gm.com` | `delivery2@gm.com` | **Rahul Sharma (Pink City Rider)** — Scooter Activa, Bapu Bazaar location |
| 👑 **Super Admin** | `admin@paridhan.com` | `password123` | Platform KPIs, GMV & 10% commission analytics, boutique KYC approval queue, dispute resolution |
| 👑 **City Ops Admin** | `admin1@gm.com` | `admin1@gm.com` | Jaipur City Operations Management |

---

## 🏗️ Architecture & Features

- **Hyperlocal PostGIS Discovery**: `get_nearby_shops(lat, lng, radius_km)` queries local boutiques within delivery radius.
- **Dynamic Live Bargaining**: Real-time counter-offers, floor price validation, and automatic shopping bag price sync on deal acceptance.
- **Smart Shopping Bag & Checkout**: Subtotal and agreed bargain price calculation, quantity management, and Cash-on-Delivery (COD) or Online payment support.
- **Delivery Dispatch Radar**: Automatic dispatch task creation on order checkout with OTP-secured pickup and handover.
