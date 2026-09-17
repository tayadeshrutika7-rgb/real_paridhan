# PARIDHAN — "Wear Local. Support Local."
### Hyperlocal Fashion Marketplace with Bargaining & AI

Paridhan connects local clothing boutiques and artisans with nearby consumers through real-time bargaining, same-day delivery logistics, and AI assistance.

---

## Monorepo Layout

```
paridhan/
├── apps/
│   ├── mobile/                 # Flutter application (Consumer, Seller, Delivery flavors)
│   │   ├── lib/
│   │   │   ├── core/           # Constants, Theme, Routing, Network
│   │   │   ├── features/       # Auth, Legal, Consumer, Seller, Delivery
│   │   │   ├── main_consumer.dart
│   │   │   ├── main_seller.dart
│   │   │   └── main_delivery.dart
│   │   └── test/
│   └── admin/                  # Next.js 14 (App Router) + TypeScript portal
├── supabase/
│   ├── migrations/             # PostGIS, full 22-table schema, RLS policies, triggers
│   │   └── 20240101000000_initial_schema.sql
│   ├── functions/              # Edge Functions (Deno / TypeScript)
│   └── seed.sql                # Categories, brands, initial configuration
├── docs/                       # DPDP compliance, Terms of Service, Privacy Policy
│   ├── terms-and-conditions.md
│   └── privacy-policy.md
├── AGENT_README.md             # Master engineering specifications
└── .env.example                # Environment variables template
```

---

## Getting Started

### 1. Database (Supabase + PostGIS)
1. Ensure the PostGIS extension is active on your Supabase instance:
   ```sql
   create extension if not exists postgis;
   ```
2. Apply the migration file:
   ```bash
   supabase db push
   # or execute supabase/migrations/20240101000000_initial_schema.sql directly in SQL Editor
   ```
3. Load seed data:
   ```bash
   # execute supabase/seed.sql
   ```

### 2. Mobile App (Flutter)
The mobile app supports three distinct flavors within a single codebase:
- **Consumer App:**
  ```bash
  cd apps/mobile
  flutter run -t lib/main_consumer.dart
  ```
- **Seller Studio:**
  ```bash
  cd apps/mobile
  flutter run -t lib/main_seller.dart
  ```
- **Delivery Partner Fleet:**
  ```bash
  cd apps/mobile
  flutter run -t lib/main_delivery.dart
  ```

---

## Phase Status
- **Phase 1: Project Setup, Database Schema (PostGIS) & Auth Foundation** — Complete & Tested.
- **Phase 2: Seller Shop & Catalog Management** — Ready to begin.
