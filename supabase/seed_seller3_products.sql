-- ==============================================================================
-- ADD RICH PRODUCT CATALOG & SHOP FOR SELLER3@GM.COM
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/zuhwilxfukdrmnmhyibg/sql/new
-- ==============================================================================

-- 1. Ensure RLS Allows Public Read Access to Marketplace Catalog
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Shops are viewable by everyone" ON public.shops;
CREATE POLICY "Shops are viewable by everyone" ON public.shops FOR SELECT USING (true);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT USING (true);

ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Variants are viewable by everyone" ON public.product_variants;
CREATE POLICY "Variants are viewable by everyone" ON public.product_variants FOR SELECT USING (true);

ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Product images are viewable by everyone" ON public.product_images;
CREATE POLICY "Product images are viewable by everyone" ON public.product_images FOR SELECT USING (true);

-- 2. Seed Shop & Products for seller3@gm.com
DO $$
DECLARE
  v_seller_id uuid;
  v_buyer_id uuid;
  v_shop_id uuid;
  v_cat_ethnic uuid;
  v_cat_men uuid;
  v_cat_sarees uuid;
  v_cat_footwear uuid;
  v_brand_handloom uuid;
  v_brand_pinkcity uuid;
  
  v_p1 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_p3 uuid := gen_random_uuid();
  v_p4 uuid := gen_random_uuid();
  v_p5 uuid := gen_random_uuid();
BEGIN
  -- 1. Get or Create seller3 user ID
  SELECT id INTO v_seller_id FROM auth.users WHERE email = 'seller3@gm.com';
  
  IF v_seller_id IS NULL THEN
    v_seller_id := gen_random_uuid();
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      v_seller_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'seller3@gm.com', crypt('seller3@gm.com', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Johari Heritage Boutique","role":"seller"}',
      now(), now()
    );
  END IF;

  -- 2. Upsert Seller Profile
  INSERT INTO public.profiles (id, role, full_name, email, avatar_url, accepted_terms_at)
  VALUES (
    v_seller_id,
    'seller',
    'Johari Heritage Boutique Owner',
    'seller3@gm.com',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'seller',
    full_name = 'Johari Heritage Boutique Owner';

  -- 3. Get or Create Categories
  SELECT id INTO v_cat_ethnic FROM public.categories WHERE name ILIKE '%Women%' LIMIT 1;
  IF v_cat_ethnic IS NULL THEN
    v_cat_ethnic := 'a0000001-0000-0000-0000-000000000001';
    INSERT INTO public.categories (id, name, icon_url)
    VALUES (v_cat_ethnic, 'Women Ethnic Wear', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  SELECT id INTO v_cat_men FROM public.categories WHERE name ILIKE '%Men%' LIMIT 1;
  IF v_cat_men IS NULL THEN
    v_cat_men := 'a0000001-0000-0000-0000-000000000002';
    INSERT INTO public.categories (id, name, icon_url)
    VALUES (v_cat_men, 'Men Kurtas & Apparel', 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?w=400')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  SELECT id INTO v_cat_sarees FROM public.categories WHERE name ILIKE '%Saree%' LIMIT 1;
  IF v_cat_sarees IS NULL THEN
    v_cat_sarees := 'a0000001-0000-0000-0000-000000000003';
    INSERT INTO public.categories (id, name, icon_url)
    VALUES (v_cat_sarees, 'Sarees & Lehengas', 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  SELECT id INTO v_cat_footwear FROM public.categories WHERE name ILIKE '%Footwear%' OR name ILIKE '%Jutti%' LIMIT 1;
  IF v_cat_footwear IS NULL THEN
    v_cat_footwear := 'a0000001-0000-0000-0000-000000000005';
    INSERT INTO public.categories (id, name, icon_url)
    VALUES (v_cat_footwear, 'Jaipuri Footwear & Juttis', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- 4. Get Brands
  SELECT id INTO v_brand_handloom FROM public.brands LIMIT 1;
  SELECT id INTO v_brand_pinkcity FROM public.brands OFFSET 1 LIMIT 1;

  -- 5. Upsert Shop in Johari Bazaar (Jaipur Lat: 26.9239, Lng: 75.8267)
  SELECT id INTO v_shop_id FROM public.shops WHERE seller_id = v_seller_id;
  
  IF v_shop_id IS NULL THEN
    v_shop_id := gen_random_uuid();
    INSERT INTO public.shops (
      id, seller_id, name, description, address, location, status, is_verified, kyc_status, banner_url, avg_rating
    ) VALUES (
      v_shop_id,
      v_seller_id,
      'Johari Royal Heritage Boutique',
      'Authentic Jaipur ethnic wear, handcrafted Bandhani sarees, royal Gota Patti lehengas, and block-print kurtas.',
      'Shop 24, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
      ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
      'verified',
      true,
      'verified',
      'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80',
      4.95
    );
  ELSE
    UPDATE public.shops
    SET name = 'Johari Royal Heritage Boutique',
        description = 'Authentic Jaipur ethnic wear, handcrafted Bandhani sarees, royal Gota Patti lehengas, and block-print kurtas.',
        address = 'Shop 24, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
        location = ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
        status = 'verified',
        is_verified = true,
        kyc_status = 'verified',
        banner_url = 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80',
        avg_rating = 4.95
    WHERE id = v_shop_id;
  END IF;

  -- Clean old products for this shop to avoid duplication
  DELETE FROM public.products WHERE shop_id = v_shop_id;

  -- 6. Insert 5 Rich Products for this Seller Boutique
  
  -- Product 1: Pure Silk Bandhani Bridal Lehenga
  INSERT INTO public.products (
    id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
  ) VALUES (
    v_p1, v_shop_id, v_cat_sarees, v_brand_pinkcity,
    'Pure Silk Bandhani Bridal Lehenga',
    'Exquisite hand-tied Bandhani lehenga in royal crimson red with heavy real Gota Patti work. Direct from Johari Bazaar master weavers.',
    12499.00, 9999.00, true, 'active'
  );

  INSERT INTO public.product_variants (product_id, size, color, stock_qty, sku, image_urls)
  VALUES 
    (v_p1, 'M (38)', 'Crimson Red', 12, 'JOH-LEH-M', ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80']),
    (v_p1, 'L (40)', 'Crimson Red', 8, 'JOH-LEH-L', ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80']);

  INSERT INTO public.product_images (product_id, url, is_primary, display_order)
  VALUES (v_p1, 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80', true, 0);

  -- Product 2: Jaipuri Hand Block Print Anarkali Set
  INSERT INTO public.products (
    id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
  ) VALUES (
    v_p2, v_shop_id, v_cat_ethnic, v_brand_handloom,
    'Jaipuri Hand Block Print Anarkali Set',
    '100% Cambric 60-60 pure Cotton flared Anarkali kurta with matching pants and Kota Doria dupatta with authentic Bagru block prints.',
    2899.00, 2200.00, true, 'active'
  );

  INSERT INTO public.product_variants (product_id, size, color, stock_qty, sku, image_urls)
  VALUES 
    (v_p2, 'M (38)', 'Indigo Blue', 25, 'JOH-ANK-M', ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']),
    (v_p2, 'L (40)', 'Indigo Blue', 18, 'JOH-ANK-L', ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']);

  INSERT INTO public.product_images (product_id, url, is_primary, display_order)
  VALUES (v_p2, 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80', true, 0);

  -- Product 3: Royal Rajasthani Silk Kurta & Modi Jacket
  INSERT INTO public.products (
    id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
  ) VALUES (
    v_p3, v_shop_id, v_cat_men, v_brand_handloom,
    'Royal Rajasthani Silk Kurta & Modi Jacket Set',
    'Raw silk festive kurta pajama set paired with a contrast Jacquard Modi Nehru jacket with metallic embossed buttons.',
    4499.00, 3799.00, true, 'active'
  );

  INSERT INTO public.product_variants (product_id, size, color, stock_qty, sku, image_urls)
  VALUES 
    (v_p3, 'L (40)', 'Gold / Navy', 15, 'JOH-KUR-L', ARRAY['https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80']),
    (v_p3, 'XL (42)', 'Gold / Navy', 10, 'JOH-KUR-XL', ARRAY['https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80']);

  INSERT INTO public.product_images (product_id, url, is_primary, display_order)
  VALUES (v_p3, 'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80', true, 0);

  -- Product 4: Chanderi Silk Zari Border Saree
  INSERT INTO public.products (
    id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
  ) VALUES (
    v_p4, v_shop_id, v_cat_sarees, v_brand_pinkcity,
    'Chanderi Silk Zari Border Festive Saree',
    'Lightweight festive Chanderi saree woven with golden Zari motifs and delicate floral pallu with unstitched blouse piece.',
    3299.00, 2650.00, true, 'active'
  );

  INSERT INTO public.product_variants (product_id, size, color, stock_qty, sku, image_urls)
  VALUES 
    (v_p4, 'Free Size', 'Emerald Green', 30, 'JOH-SAR-EMR', ARRAY['https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80']);

  INSERT INTO public.product_images (product_id, url, is_primary, display_order)
  VALUES (v_p4, 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80', true, 0);

  -- Product 5: Handcrafted Mojari Leather Jutti
  INSERT INTO public.products (
    id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
  ) VALUES (
    v_p5, v_shop_id, v_cat_footwear, v_brand_handloom,
    'Handcrafted Mojari Leather Jutti',
    'Pure leather handcrafted Rajasthani Jutti with intricate thread embroidery and comfortable double cushioned insole.',
    1499.00, 1150.00, true, 'active'
  );

  INSERT INTO public.product_variants (product_id, size, color, stock_qty, sku, image_urls)
  VALUES 
    (v_p5, 'UK 8', 'Tan Brown', 20, 'JOH-JUT-UK8', ARRAY['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80']),
    (v_p5, 'UK 9', 'Tan Brown', 15, 'JOH-JUT-UK9', ARRAY['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80']);

  INSERT INTO public.product_images (product_id, url, is_primary, display_order)
  VALUES (v_p5, 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80', true, 0);

  -- 7. Ensure Buyer1 Account exists & Location is set to Johari Bazaar
  SELECT id INTO v_buyer_id FROM auth.users WHERE email = 'buyer1@gm.com';
  
  IF v_buyer_id IS NULL THEN
    v_buyer_id := gen_random_uuid();
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
      v_buyer_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'buyer1@gm.com', crypt('buyer1@gm.com', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Priya Sharma","role":"consumer"}',
      now(), now()
    );
  END IF;

  INSERT INTO public.profiles (id, role, full_name, email, avatar_url, accepted_terms_at)
  VALUES (
    v_buyer_id, 'consumer', 'Priya Sharma', 'buyer1@gm.com',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    now()
  )
  ON CONFLICT (id) DO UPDATE SET role = 'consumer';

  DELETE FROM public.delivery_addresses WHERE user_id = v_buyer_id;
  INSERT INTO public.delivery_addresses (
    user_id, full_name, phone, address_line1, city, state, pincode, is_default, latitude, longitude
  ) VALUES (
    v_buyer_id,
    'Priya Sharma',
    '+91 98290 11111',
    'House 12, Johari Bazaar Lane',
    'Jaipur',
    'Rajasthan',
    '302003',
    true,
    26.9235,
    75.8265
  );

  -- 8. Auto confirm all emails (only update email_confirmed_at)
  UPDATE auth.users
  SET email_confirmed_at = now()
  WHERE email IN ('seller3@gm.com', 'buyer1@gm.com');

END $$;
