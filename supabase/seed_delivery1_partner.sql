-- ==============================================================================
-- SEED DATA FOR delivery1@gm.com (Johari Bazaar Rider)
-- ==============================================================================

-- 1. Ensure required columns exist on orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_number text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS platform_fee numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount numeric(10,2) DEFAULT 0.00;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_address jsonb;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_otp text DEFAULT '4829';

-- 2. Ensure deliveries table and columns exist
CREATE TABLE IF NOT EXISTS public.deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_partner_id uuid REFERENCES public.profiles(id),
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivery_partner_id uuid REFERENCES public.profiles(id);
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending';
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS pickup_otp text DEFAULT '1234';
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivery_otp text DEFAULT '4829';
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivery_payout numeric(10,2) DEFAULT 85.00;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS distance_km numeric(6,2) DEFAULT 2.4;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS accepted_at timestamptz;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS picked_up_at timestamptz;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS delivered_at timestamptz;

-- 3. Upsert Profile for delivery1@gm.com
INSERT INTO public.profiles (
  id, role, full_name, email, phone, avatar_url, accepted_terms_at
)
SELECT 
  u.id,
  'delivery',
  'Vikram Singh (Johari Rider)',
  'delivery1@gm.com',
  '+91 98290 55443',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
  now()
FROM auth.users u
WHERE u.email = 'delivery1@gm.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'delivery',
  full_name = 'Vikram Singh (Johari Rider)',
  phone = '+91 98290 55443';

-- 4. Upsert Delivery Partner Profile (Johari Bazaar Coordinates: 26.9239, 75.8267)
INSERT INTO public.delivery_partner_profiles (
  id, vehicle_type, vehicle_number, driving_license_url, is_online, current_location, verification_status
)
SELECT 
  u.id,
  'Motorcycle (Hero Splendor Plus)',
  'RJ 14 JP 4421',
  'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
  true,
  ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
  'verified'
FROM auth.users u
WHERE u.email = 'delivery1@gm.com'
ON CONFLICT (id) DO UPDATE SET
  is_online = true,
  verification_status = 'verified',
  current_location = ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326);

-- 5. Seed active test order ready for pickup from Johari Royal Heritage Boutique
INSERT INTO public.orders (
  id, order_number, consumer_id, shop_id, status, payment_method, payment_status,
  subtotal, delivery_fee, platform_fee, total_amount, delivery_address, delivery_otp, created_at, updated_at
)
SELECT
  '00000000-0000-0000-0000-000000000091'::uuid,
  'PRD-2026-8812',
  buyer.id,
  shop.id,
  'confirmed',
  'cod',
  'pending',
  4200.00,
  40.00,
  10.00,
  4250.00,
  jsonb_build_object(
    'full_name', 'Buyer One (Johari)',
    'phone', '+91 98290 11111',
    'address_line1', 'House 14, Johari Bazaar Lane',
    'address_line2', 'Near Hawa Mahal Road',
    'city', 'Jaipur',
    'state', 'Rajasthan',
    'pincode', '302003',
    'latitude', 26.9242,
    'longitude', 75.8270
  ),
  '4829',
  now(),
  now()
FROM auth.users buyer
CROSS JOIN (SELECT id FROM public.shops LIMIT 1) shop
WHERE buyer.email = 'buyer1@gm.com'
ON CONFLICT (id) DO NOTHING;

-- 6. Seed order item with product_id & variant_id
INSERT INTO public.order_items (order_id, product_id, variant_id, quantity, unit_price)
SELECT 
  '00000000-0000-0000-0000-000000000091'::uuid,
  v.product_id,
  v.id,
  1,
  4200.00
FROM public.product_variants v
LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- 7. Seed Dispatch Request into deliveries table
INSERT INTO public.deliveries (
  id, order_id, delivery_partner_id, status, pickup_otp, delivery_otp, delivery_payout, distance_km, created_at, updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000092'::uuid,
  '00000000-0000-0000-0000-000000000091'::uuid,
  NULL,
  'pending',
  '1234',
  '4829',
  85.00,
  1.4,
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

-- 8. Verification query
SELECT 
  p.id,
  p.role,
  p.full_name,
  p.email,
  dpp.vehicle_type,
  dpp.is_online
FROM public.profiles p
LEFT JOIN public.delivery_partner_profiles dpp ON dpp.id = p.id
WHERE p.email = 'delivery1@gm.com';
