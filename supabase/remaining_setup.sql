-- ==============================================================================
-- PARIDHAN HYPERLOCAL FASHION MARKETPLACE — REMAINING POST-TABLE DATABASE SETUP
-- ==============================================================================
-- Instructions:
-- Paste and run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/faqtswmhgintutwvnkyy/sql/new
--
-- This script DOES NOT touch or drop any of the 22 existing application tables.
-- It applies: Indexes, Helper Functions, PostGIS RPCs, Auth Triggers,
-- Bargain Triggers, RLS Policies, PostgREST Grants, and Full Seed Data.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. REQUIRED INDEXES (GIST, GIN, B-TREE)
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_shops_location ON public.shops USING gist(location);
CREATE INDEX IF NOT EXISTS idx_shops_seller ON public.shops(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_shop ON public.products(shop_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_search ON public.products USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_variants_product ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_product ON public.product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_bargains_consumer ON public.bargains(consumer_id);
CREATE INDEX IF NOT EXISTS idx_bargains_seller ON public.bargains(seller_id);
CREATE INDEX IF NOT EXISTS idx_bargains_product ON public.bargains(product_id);
CREATE INDEX IF NOT EXISTS idx_bargain_messages_bargain ON public.bargain_messages(bargain_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_consumer ON public.cart_items(consumer_id);
CREATE INDEX IF NOT EXISTS idx_orders_consumer ON public.orders(consumer_id);
CREATE INDEX IF NOT EXISTS idx_orders_shop ON public.orders(shop_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_partner ON public.orders(delivery_partner_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_order ON public.deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_partner ON public.deliveries(delivery_partner_id);

-- ------------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- 3. POSTGIS NEARBY BOUTIQUES DISCOVERY RPC
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_nearby_shops(
  lat double precision,
  lng double precision,
  radius_km double precision DEFAULT 10.0
)
RETURNS TABLE (
  id uuid,
  seller_id uuid,
  name text,
  description text,
  logo_url text,
  banner_url text,
  address text,
  distance_meters double precision,
  avg_rating numeric,
  category_ids uuid[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.seller_id,
    s.name,
    s.description,
    s.logo_url,
    s.banner_url,
    s.address,
    st_distance(s.location, st_setsrid(st_makepoint(lng, lat), 4326)::geography) AS distance_meters,
    s.avg_rating,
    s.category_ids
  FROM public.shops s
  WHERE s.status = 'verified'
    AND st_dwithin(s.location, st_setsrid(st_makepoint(lng, lat), 4326)::geography, radius_km * 1000)
  ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 4. AUTH SIGNUP TRIGGER & PROFILE AUTO-PROVISIONING
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role user_role := 'consumer';
  v_meta_role text;
BEGIN
  v_meta_role := new.raw_user_meta_data->>'role';
  IF v_meta_role IN ('consumer', 'seller', 'delivery', 'admin') THEN
    v_role := v_meta_role::user_role;
  END IF;

  INSERT INTO public.profiles (
    id, role, full_name, phone, email, avatar_url, accepted_terms_at
  ) VALUES (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    new.phone,
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    phone = coalesce(EXCLUDED.phone, profiles.phone),
    full_name = coalesce(nullif(EXCLUDED.full_name, ''), profiles.full_name);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 5. AUTO-SYNC ACCEPTED BARGAIN DEALS INTO SHOPPING BAG
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auto_cart_on_bargain_accepted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'accepted' AND (OLD.status IS DISTINCT FROM 'accepted') THEN
    INSERT INTO public.cart_items (consumer_id, product_id, variant_id, bargain_id, quantity, agreed_price)
    VALUES (NEW.consumer_id, NEW.product_id, NEW.variant_id, NEW.id, 1, NEW.agreed_price)
    ON CONFLICT (consumer_id, variant_id)
    DO UPDATE SET
      quantity = 1,
      bargain_id = EXCLUDED.bargain_id,
      agreed_price = EXCLUDED.agreed_price;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_cart_on_bargain_accepted ON public.bargains;
CREATE TRIGGER trg_auto_cart_on_bargain_accepted
  AFTER UPDATE ON public.bargains
  FOR EACH ROW EXECUTE FUNCTION public.auto_cart_on_bargain_accepted();

-- ------------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY (RLS) & PERMISSIVE POLICIES ON ALL 22 TABLES
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bargains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bargain_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_partner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.returns_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cod_remittance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles viewable" ON public.profiles;
CREATE POLICY "Public profiles viewable" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Push subscriptions permissive" ON public.push_subscriptions;
CREATE POLICY "Push subscriptions permissive" ON public.push_subscriptions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Shops are viewable by everyone" ON public.shops;
CREATE POLICY "Shops are viewable by everyone" ON public.shops FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Products viewable by everyone" ON public.products;
CREATE POLICY "Products viewable by everyone" ON public.products FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Variants viewable by everyone" ON public.product_variants;
CREATE POLICY "Variants viewable by everyone" ON public.product_variants FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Product images viewable by everyone" ON public.product_images;
CREATE POLICY "Product images viewable by everyone" ON public.product_images FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Categories viewable by everyone" ON public.categories;
CREATE POLICY "Categories viewable by everyone" ON public.categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Brands viewable by everyone" ON public.brands;
CREATE POLICY "Brands viewable by everyone" ON public.brands FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Bargains permissive" ON public.bargains;
CREATE POLICY "Bargains permissive" ON public.bargains FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Bargain messages permissive" ON public.bargain_messages;
CREATE POLICY "Bargain messages permissive" ON public.bargain_messages FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Cart items permissive" ON public.cart_items;
CREATE POLICY "Cart items permissive" ON public.cart_items FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Wishlists permissive" ON public.wishlists;
CREATE POLICY "Wishlists permissive" ON public.wishlists FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Orders permissive" ON public.orders;
CREATE POLICY "Orders permissive" ON public.orders FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Order items permissive" ON public.order_items;
CREATE POLICY "Order items permissive" ON public.order_items FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Deliveries permissive" ON public.deliveries;
CREATE POLICY "Deliveries permissive" ON public.deliveries FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Delivery partner profiles permissive" ON public.delivery_partner_profiles;
CREATE POLICY "Delivery partner profiles permissive" ON public.delivery_partner_profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Returns refunds permissive" ON public.returns_refunds;
CREATE POLICY "Returns refunds permissive" ON public.returns_refunds FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Payouts permissive" ON public.payouts;
CREATE POLICY "Payouts permissive" ON public.payouts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "COD remittance permissive" ON public.cod_remittance;
CREATE POLICY "COD remittance permissive" ON public.cod_remittance FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Reviews permissive" ON public.reviews;
CREATE POLICY "Reviews permissive" ON public.reviews FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Notifications permissive" ON public.notifications;
CREATE POLICY "Notifications permissive" ON public.notifications FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Platform config permissive" ON public.platform_config;
CREATE POLICY "Platform config permissive" ON public.platform_config FOR ALL USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 7. POSTGREST SCHEMA & TABLE GRANTS
-- ------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

-- ------------------------------------------------------------------------------
-- 8. PLATFORM CONFIG SEED VALUES
-- ------------------------------------------------------------------------------
INSERT INTO public.platform_config (key, value) VALUES
  ('default_commission_rate', '{"rate": 10.0}'::jsonb),
  ('delivery_fee_rules', '{"base_fee": 30.0, "per_km_rate": 5.0, "free_above": 999.0}'::jsonb),
  ('feature_flags', '{"bargaining_enabled": true, "ai_helpdesk_enabled": true, "skin_tone_recommendations": false}'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ------------------------------------------------------------------------------
-- 9. AUTH TEST ACCOUNTS (Passwords matching email or 'password123')
-- ------------------------------------------------------------------------------
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES 
  -- Buyers
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'buyer1@gm.com', crypt('buyer1@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Priya Sharma","role":"consumer"}', now(), now()),
  ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'buyer2@gm.com', crypt('buyer2@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Ananya Sen","role":"consumer"}', now(), now()),
  -- Sellers
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller3@gm.com', crypt('seller3@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Johari Royal Heritage Boutique","role":"seller"}', now(), now()),
  ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller1@gm.com', crypt('seller1@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Gulab Niwas Sarees","role":"seller"}', now(), now()),
  ('00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller2@gm.com', crypt('seller2@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Pink City Handlooms","role":"seller"}', now(), now()),
  ('00000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller4@gm.com', crypt('seller4@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rajputana Royal Coutures","role":"seller"}', now(), now()),
  -- Delivery Riders
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'delivery1@gm.com', crypt('delivery1@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Vikram Singh (Johari Rider)","role":"delivery"}', now(), now()),
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'delivery2@gm.com', crypt('delivery2@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rahul Sharma (Pink City Rider)","role":"delivery"}', now(), now()),
  -- Admins
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Platform Super Admin","role":"admin"}', now(), now()),
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin1@gm.com', crypt('admin1@gm.com', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Jaipur City Ops Admin","role":"admin"}', now(), now())
ON CONFLICT (id) DO NOTHING;

-- Sanitize token columns for GoTrue scanner compatibility
UPDATE auth.users 
SET 
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  email_change = COALESCE(email_change, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, ''),
  reauthentication_token = COALESCE(reauthentication_token, ''),
  aud = 'authenticated',
  role = 'authenticated'
WHERE email IN (
  'buyer1@gm.com', 'buyer2@gm.com', 'seller3@gm.com', 'seller1@gm.com',
  'seller2@gm.com', 'seller4@gm.com', 'delivery1@gm.com', 'delivery2@gm.com',
  'admin@paridhan.com', 'admin1@gm.com'
);

-- ------------------------------------------------------------------------------
-- 10. PUBLIC PROFILES SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.profiles (id, role, full_name, phone, email, avatar_url, accepted_terms_at) VALUES
  ('00000000-0000-0000-0000-000000000001', 'consumer', 'Priya Sharma', '+91 98290 11111', 'buyer1@gm.com', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000011', 'consumer', 'Ananya Sen', '+91 98290 11112', 'buyer2@gm.com', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000002', 'seller', 'Johari Royal Heritage Boutique', '+91 98290 22222', 'seller3@gm.com', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000021', 'seller', 'Gulab Niwas Sarees', '+91 98290 22221', 'seller1@gm.com', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000022', 'seller', 'Pink City Handlooms', '+91 98290 22223', 'seller2@gm.com', 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000023', 'seller', 'Rajputana Royal Coutures', '+91 98290 22224', 'seller4@gm.com', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000003', 'delivery', 'Vikram Singh (Johari Rider)', '+91 98290 33333', 'delivery1@gm.com', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000031', 'delivery', 'Rahul Sharma (Pink City Rider)', '+91 98290 33334', 'delivery2@gm.com', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000004', 'admin', 'Platform Super Admin', '+91 98290 44444', 'admin@paridhan.com', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80', now()),
  ('00000000-0000-0000-0000-000000000041', 'admin', 'Jaipur City Ops Admin', '+91 98290 44445', 'admin1@gm.com', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80', now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email;

-- ------------------------------------------------------------------------------
-- 11. DELIVERY PARTNER PROFILES SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.delivery_partner_profiles (
  id, vehicle_type, vehicle_number, driving_license_url, is_online, current_location, verification_status
) VALUES 
  (
    '00000000-0000-0000-0000-000000000003',
    'Motorcycle (Hero Splendor Plus)',
    'RJ 14 JP 4421',
    'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
    true,
    ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
    'verified'
  ),
  (
    '00000000-0000-0000-0000-000000000031',
    'Scooter (Honda Activa 6G)',
    'RJ 14 PK 8892',
    'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
    true,
    ST_SetSRID(ST_MakePoint(75.8210, 26.9185), 4326),
    'verified'
  )
ON CONFLICT (id) DO UPDATE SET is_online = true, verification_status = 'verified';

-- ------------------------------------------------------------------------------
-- 12. CATEGORIES & BRANDS SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.categories (id, name, icon_url) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Women Ethnic Wear', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000002', 'Men Kurtas & Apparel', 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000003', 'Sarees & Lehengas', 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000004', 'Kids Traditional', 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000005', 'Jaipuri Footwear & Juttis', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=400&q=80')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, icon_url = EXCLUDED.icon_url;

INSERT INTO public.brands (id, name, logo_url) VALUES
  ('b0000001-0000-0000-0000-000000000001', 'Jaipur Handlooms', 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000002', 'Pink City Silks', 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000003', 'Royal Rajputana', 'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000004', 'Gulab Cotton Crafts', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=200&q=80')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, logo_url = EXCLUDED.logo_url;

-- ------------------------------------------------------------------------------
-- 13. SHOES / VERIFIED BOUTIQUES SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.shops (
  id, seller_id, name, description, address, location, kyc_status, status, is_verified, banner_url, avg_rating
) VALUES
  (
    'c0000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'Johari Royal Heritage Boutique',
    'Authentic Jaipur ethnic wear, handcrafted Bandhani sarees, royal Gota Patti lehengas, and block-print kurtas.',
    'Shop 24, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
    ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80',
    4.95
  ),
  (
    'c0000001-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000021',
    'Gulab Niwas Sarees & Lehengas',
    'Authentic Rajasthani bridal wear, Bandhani sarees, and Gota Patti lehengas crafted by master artisans.',
    'Shop 42, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
    ST_SetSRID(ST_MakePoint(75.8270, 26.9242), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80',
    4.90
  ),
  (
    'c0000001-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000022',
    'Pink City Handloom Emporium',
    'Premium block-printed cotton kurtis, dupattas, and handcrafted ethnic wear.',
    'Shop 15, Bapu Bazaar, Jaipur, Rajasthan 302003',
    ST_SetSRID(ST_MakePoint(75.8210, 26.9185), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
    4.80
  ),
  (
    'c0000001-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000023',
    'Rajputana Royal Coutures',
    'Designer Sherwanis, Modi Jackets, and Royal Indo-Western collection for men.',
    'G-4, MI Road, Opp. Raj Mandir, Jaipur, Rajasthan 302001',
    ST_SetSRID(ST_MakePoint(75.8115, 26.9160), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1509319117193-57bab727e09d?auto=format&fit=crop&w=800&q=80',
    4.75
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  location = EXCLUDED.location,
  status = 'verified',
  is_verified = true;

-- ------------------------------------------------------------------------------
-- 14. PRODUCTS SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.products (
  id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
) VALUES
  (
    'd0000001-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000003',
    'b0000001-0000-0000-0000-000000000002',
    'Pure Silk Bandhani Bridal Lehenga',
    'Exquisite crimson red bridal lehenga hand-dyed using traditional Jaipuri Bandhej techniques with heavy gold zari embroidery.',
    12499.00,
    9999.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000002',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000001',
    'b0000001-0000-0000-0000-000000000001',
    'Jaipuri Hand Block Print Anarkali Set',
    'Authentic Sanganeri handblock printed pure mulmul cotton Anarkali kurta set with kota doria dupatta.',
    2899.00,
    2299.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000003',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000002',
    'b0000001-0000-0000-0000-000000000003',
    'Royal Raw Silk Sherwani with Stole',
    'Ivory raw silk designer sherwani with subtle dabka and marodi embroidery for wedding celebrations.',
    8999.00,
    7499.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000004',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000005',
    'b0000001-0000-0000-0000-000000000001',
    'Handcrafted Mojari Leather Jutti',
    'Genuine camel leather traditional Rajasthani mojari with hand-stitched silk thread patterns and cushioned insole.',
    1499.00,
    1150.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000005',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000003',
    'b0000001-0000-0000-0000-000000000004',
    'Handwoven Chanderi Zari Saree',
    'Lightweight emerald green Chanderi silk saree with woven gold zari border and floral meenakari pallu.',
    4299.00,
    3499.00,
    true,
    'active'
  )
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  base_price = EXCLUDED.base_price,
  min_bargain_price = EXCLUDED.min_bargain_price,
  status = 'active';

-- ------------------------------------------------------------------------------
-- 15. PRODUCT VARIANTS SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.product_variants (
  id, product_id, size, color, stock_qty, price_override, sku, image_urls
) VALUES
  ('e0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'M (38)', 'Crimson Red', 5, NULL, 'JHR-BDL-M', ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000001', 'L (40)', 'Crimson Red', 4, NULL, 'JHR-BDL-L', ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000002', 'M (38)', 'Indigo Blue', 12, NULL, 'JHR-ARK-M', ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002', 'L (40)', 'Indigo Blue', 8, NULL, 'JHR-ARK-L', ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000003', 'L (40)', 'Ivory White', 3, NULL, 'JHR-SHW-L', ARRAY['https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000006', 'd0000001-0000-0000-0000-000000000004', 'UK 8', 'Tan Brown', 15, NULL, 'JHR-MJR-8', ARRAY['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000007', 'd0000001-0000-0000-0000-000000000004', 'UK 9', 'Tan Brown', 10, NULL, 'JHR-MJR-9', ARRAY['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80']),
  ('e0000001-0000-0000-0000-000000000008', 'd0000001-0000-0000-0000-000000000005', 'Free Size', 'Emerald Green', 7, NULL, 'JHR-SAR-F', ARRAY['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80'])
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 16. PRODUCT IMAGES SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.product_images (id, product_id, url, display_order, is_primary) VALUES
  (gen_random_uuid(), 'd0000001-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80', 1, true),
  (gen_random_uuid(), 'd0000001-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80', 1, true),
  (gen_random_uuid(), 'd0000001-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80', 1, true),
  (gen_random_uuid(), 'd0000001-0000-0000-0000-000000000004', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80', 1, true),
  (gen_random_uuid(), 'd0000001-0000-0000-0000-000000000005', 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80', 1, true)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 17. BARGAINS SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.bargains (
  id, product_id, variant_id, consumer_id, seller_id, status,
  consumer_offer, counter_offer, agreed_price, current_offer, current_offer_by
) VALUES
  (
    'bb000001-0000-0000-0000-000000000001',
    'd0000001-0000-0000-0000-000000000004',
    'e0000001-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'accepted',
    1200.00,
    1300.00,
    1200.00,
    1200.00,
    'seller'
  ),
  (
    'bb000001-0000-0000-0000-000000000002',
    'd0000001-0000-0000-0000-000000000002',
    'e0000001-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'countered',
    2300.00,
    2500.00,
    NULL,
    2500.00,
    'seller'
  ),
  (
    'bb000001-0000-0000-0000-000000000003',
    'd0000001-0000-0000-0000-000000000001',
    'e0000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000002',
    'open',
    10500.00,
    NULL,
    NULL,
    10500.00,
    'consumer'
  )
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 18. CART ITEMS SEED DATA
-- ------------------------------------------------------------------------------
INSERT INTO public.cart_items (
  id, consumer_id, product_id, variant_id, bargain_id, quantity, agreed_price
) VALUES 
  (
    'cc000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'd0000001-0000-0000-0000-000000000004',
    'e0000001-0000-0000-0000-000000000006',
    'bb000001-0000-0000-0000-000000000001',
    1,
    1200.00
  ),
  (
    'cc000001-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'd0000001-0000-0000-0000-000000000001',
    'e0000001-0000-0000-0000-000000000001',
    NULL,
    1,
    NULL
  )
ON CONFLICT (consumer_id, variant_id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 19. ORDERS & DELIVERIES SEED DATA
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_order_1 uuid := 'f0000001-0000-0000-0000-000000000001';
  v_order_2 uuid := 'f0000001-0000-0000-0000-000000000002';
BEGIN
  -- Order 1: Confirmed & ready for delivery pickup
  INSERT INTO public.orders (
    id, order_number, consumer_id, shop_id, delivery_partner_id, status, payment_method,
    payment_status, subtotal, delivery_fee, commission_amount, seller_payout_amount,
    platform_fee, total_amount, cod_collected, delivery_address, delivery_otp
  ) VALUES (
    v_order_1,
    'PRD-2026-9042',
    '00000000-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000003',
    'confirmed',
    'cod',
    'pending',
    4200.00,
    40.00,
    210.00,
    4030.00,
    10.00,
    4250.00,
    false,
    jsonb_build_object(
      'full_name', 'Priya Sharma',
      'phone', '+91 98290 11111',
      'address_line1', 'House 14, Johari Bazaar Lane',
      'address_line2', 'Near Hawa Mahal Road',
      'city', 'Jaipur',
      'state', 'Rajasthan',
      'pincode', '302003',
      'latitude', 26.9242,
      'longitude', 75.8270
    ),
    '4829'
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.order_items (id, order_id, product_id, variant_id, quantity, unit_price)
  VALUES (gen_random_uuid(), v_order_1, 'd0000001-0000-0000-0000-000000000002', 'e0000001-0000-0000-0000-000000000003', 1, 4200.00)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.deliveries (id, order_id, delivery_partner_id, status, pickup_otp, delivery_otp, delivery_payout, distance_km)
  VALUES (gen_random_uuid(), v_order_1, '00000000-0000-0000-0000-000000000003', 'pending', '1234', '4829', 85.00, 2.4)
  ON CONFLICT (id) DO NOTHING;

  -- Order 2: Out for delivery with live tracking
  INSERT INTO public.orders (
    id, order_number, consumer_id, shop_id, delivery_partner_id, status, payment_method,
    payment_status, subtotal, delivery_fee, commission_amount, seller_payout_amount,
    platform_fee, total_amount, cod_collected, delivery_address, delivery_otp
  ) VALUES (
    v_order_2,
    'PRD-2026-9043',
    '00000000-0000-0000-0000-000000000011',
    'c0000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000003',
    'out_for_delivery',
    'cod',
    'pending',
    1499.00,
    40.00,
    75.00,
    1464.00,
    10.00,
    1549.00,
    false,
    jsonb_build_object(
      'full_name', 'Ananya Sen',
      'phone', '+91 98290 11112',
      'address_line1', 'Tower 4, Malviya Nagar Enclave',
      'address_line2', 'Near Calgiri Hospital',
      'city', 'Jaipur',
      'state', 'Rajasthan',
      'pincode', '302017',
      'latitude', 26.8520,
      'longitude', 75.8150
    ),
    '7719'
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.order_items (id, order_id, product_id, variant_id, quantity, unit_price)
  VALUES (gen_random_uuid(), v_order_2, 'd0000001-0000-0000-0000-000000000004', 'e0000001-0000-0000-0000-000000000006', 1, 1499.00)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.deliveries (id, order_id, delivery_partner_id, status, pickup_otp, delivery_otp, delivery_payout, distance_km, picked_up_at)
  VALUES (gen_random_uuid(), v_order_2, '00000000-0000-0000-0000-000000000003', 'picked_up', '1234', '7719', 110.00, 4.8, now() - interval '15 minutes')
  ON CONFLICT (id) DO NOTHING;
END $$;

-- ------------------------------------------------------------------------------
-- SETUP COMPLETED SUCCESSFULLY
-- ------------------------------------------------------------------------------
SELECT 'PARIDHAN POST-TABLE SETUP COMPLETE! All indexes, PostGIS RPCs, triggers, and seed accounts are ready.' AS status;
