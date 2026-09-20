-- ==============================================================================
-- STEP 1: FIX SCHEMA & ENABLE RLS FOR DELIVERY
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/zuhwilxfukdrmnmhyibg/sql/new
-- ==============================================================================

-- 1. Add all missing columns on orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_number text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_partner_id uuid REFERENCES public.profiles(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_fee numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS commission_amount numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS seller_payout_amount numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS platform_fee numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cod_collected boolean DEFAULT false;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cod_collected_at timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_address jsonb;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_otp text DEFAULT '4829';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancel_reason text;

-- 2. Ensure delivery partner profiles table exists
CREATE TABLE IF NOT EXISTS public.delivery_partner_profiles (
  id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  vehicle_type text NOT NULL DEFAULT 'Motorcycle (Hero Splendor Plus)',
  vehicle_number text NOT NULL DEFAULT 'RJ 14 JP 4421',
  driving_license_url text DEFAULT 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
  is_online boolean NOT NULL DEFAULT true,
  current_location geography(Point, 4326),
  verification_status text NOT NULL DEFAULT 'verified',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Ensure deliveries dispatch table exists
CREATE TABLE IF NOT EXISTS public.deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_partner_id uuid REFERENCES public.profiles(id),
  status text NOT NULL DEFAULT 'pending',
  pickup_otp text DEFAULT '1234',
  delivery_otp text DEFAULT '4829',
  delivery_payout numeric(10,2) NOT NULL DEFAULT 85.00,
  distance_km numeric(6,2) NOT NULL DEFAULT 2.4,
  accepted_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Ensure cod_remittance table exists
CREATE TABLE IF NOT EXISTS public.cod_remittance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_partner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  amount numeric(10,2) NOT NULL CHECK (amount >= 0),
  status text NOT NULL DEFAULT 'pending',
  remitted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 5. Fix RLS on all tables so authenticated users can read/write
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all profiles" ON public.profiles;
CREATE POLICY "Allow all profiles" ON public.profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.delivery_partner_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all delivery_partner_profiles" ON public.delivery_partner_profiles;
CREATE POLICY "Allow all delivery_partner_profiles" ON public.delivery_partner_profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all orders" ON public.orders;
CREATE POLICY "Allow all orders" ON public.orders FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all order_items" ON public.order_items;
CREATE POLICY "Allow all order_items" ON public.order_items FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all deliveries" ON public.deliveries;
CREATE POLICY "Allow all deliveries" ON public.deliveries FOR ALL TO authenticated USING (true) WITH CHECK (true);

ALTER TABLE public.cod_remittance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all cod_remittance" ON public.cod_remittance;
CREATE POLICY "Allow all cod_remittance" ON public.cod_remittance FOR ALL TO authenticated USING (true) WITH CHECK (true);
