# 👗 PARIDHAN — Hyperlocal Fashion Marketplace

> **Wear Local. Support Local.**
> Hyperlocal Fashion Marketplace with Direct Bargaining, PostGIS Local Discovery & Instant Delivery Dispatch.

---

## 🚀 Quick Links
- 🤖 **[Autonomous Agent Bootstrap & Handover Instructions (AGENTS.md)](./AGENTS.md)**
- 📖 **[Complete Setup & Handover Guide (README_HANDOVER.md)](./README_HANDOVER.md)**
- 📄 **[1-Step Database Initialization SQL (supabase/complete_setup.sql)](./supabase/complete_setup.sql)**
- 📋 **[Supabase Setup & Dummy Data Guide (SUPABASE_SETUP_GUIDE.txt)](./SUPABASE_SETUP_GUIDE.txt)**

---

## ⚡ Quickstart in 3 Steps

### 1. Database Setup
Run the single consolidated SQL script in your Supabase SQL Editor:
👉 **[`supabase/complete_setup.sql`](./supabase/complete_setup.sql)**

### 2. Configure Supabase Credentials
Update [`apps/mobile/lib/core/constants/app_constants.dart`](./apps/mobile/lib/core/constants/app_constants.dart):
```dart
class AppConstants {
  static const String defaultSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String defaultSupabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

### 3. Run Flutter App
```bash
cd apps/mobile
flutter pub get
flutter run -d chrome
```

---

## 👥 Seed Test Accounts & Passwords

| Role | Email | Password | Pre-loaded Workflows |
| :--- | :--- | :--- | :--- |
| 🛍️ **Buyer 1** | `buyer1@gm.com` | `buyer1@gm.com` | Priya Sharma (Johari Bazaar) — Shopping bag, accepted bargain at ₹1,200, placed orders |
| 🛍️ **Buyer 2** | `buyer2@gm.com` | `buyer2@gm.com` | Ananya Sen (Malviya Nagar) — Out-for-delivery order with OTP `7719` |
| 🏪 **Boutique Seller** | `seller3@gm.com` | `seller3@gm.com` | Johari Royal Heritage Boutique (Shop 24, Johari Bazaar) — 5 catalog garments, stock, order management |
| 🛵 **Delivery Rider** | `delivery1@gm.com` | `delivery1@gm.com` | Vikram Singh — Motorcycle, Johari Bazaar dispatch radar with pending pickup (OTP: `1234`, Handover: `4829`) |
| 👑 **Super Admin** | `admin@paridhan.com` | `password123` | GMV Analytics, KYC approvals, dispute resolution |
