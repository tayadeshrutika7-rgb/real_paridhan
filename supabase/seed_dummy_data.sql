-- ==============================================================================
-- PARIDHAN MARKETPLACE COMPREHENSIVE SEED DATA
-- Fully verified IDs & zero duplicate constraints
-- ==============================================================================

-- 1. AUTH USERS (password: 'password123')
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES 
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'consumer@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Priya Sharma"}', now(), now()),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rajesh Khandelwal"}', now(), now()),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'delivery@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Vikram Singh"}', now(), now()),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Super Admin"}', now(), now())
ON CONFLICT (id) DO NOTHING;

-- 2. PUBLIC PROFILES
INSERT INTO public.profiles (id, role, full_name, phone, email, avatar_url) VALUES
  ('00000000-0000-0000-0000-000000000001', 'consumer', 'Priya Sharma', '+91 98290 11111', 'consumer@paridhan.com', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80'),
  ('00000000-0000-0000-0000-000000000002', 'seller', 'Rajesh Khandelwal', '+91 98290 22222', 'seller@paridhan.com', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80'),
  ('00000000-0000-0000-0000-000000000003', 'delivery', 'Vikram Singh', '+91 98290 33333', 'delivery@paridhan.com', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80'),
  ('00000000-0000-0000-0000-000000000004', 'admin', 'Super Admin', '+91 98290 44444', 'admin@paridhan.com', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80')
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email;

-- 3. CATEGORIES
INSERT INTO public.categories (id, name, icon_url) VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Women Ethnic Wear', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000002', 'Men Kurtas & Apparel', 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000003', 'Sarees & Lehengas', 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000004', 'Kids Traditional', 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=400&q=80'),
  ('a0000001-0000-0000-0000-000000000005', 'Jaipuri Footwear & Juttis', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=400&q=80')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, icon_url = EXCLUDED.icon_url;

-- 4. BRANDS
INSERT INTO public.brands (id, name, logo_url) VALUES
  ('b0000001-0000-0000-0000-000000000001', 'Jaipur Handlooms', 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000002', 'Pink City Silks', 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000003', 'Royal Rajputana', 'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=200&q=80'),
  ('b0000001-0000-0000-0000-000000000004', 'Gulab Cotton Crafts', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=200&q=80')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, logo_url = EXCLUDED.logo_url;

-- 5. SHOPS / BOUTIQUES (Jaipur Local Coordinates)
INSERT INTO public.shops (
  id, seller_id, name, description, address, location, kyc_status, status, is_verified, banner_url, avg_rating
) VALUES
  (
    'c0000001-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'Gulab Niwas Sarees & Lehengas',
    'Authentic Rajasthani bridal wear, Bandhani sarees, and Gota Patti lehengas crafted by master artisans.',
    'Shop 42, Johari Bazaar, Pink City, Jaipur, Rajasthan 302003',
    ST_SetSRID(ST_MakePoint(75.8267, 26.9239), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80',
    4.90
  ),
  (
    'c0000001-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000002',
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
    'c0000001-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000002',
    'Rajputana Royal Coutures',
    'Designer Sherwanis, Modi Jackets, and Royal Indo-Western collection for men.',
    'G-4, MI Road, Opp. Raj Mandir, Jaipur, Rajasthan 302001',
    ST_SetSRID(ST_MakePoint(75.8115, 26.9150), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1509319117193-57bab727e09d?auto=format&fit=crop&w=800&q=80',
    4.70
  ),
  (
    'c0000001-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000002',
    'Raja Park Silk Boutique',
    'Exclusive Chanderi, Tussar, and Organza sarees with intricate hand embroidery.',
    'Lane 3, Raja Park, Jaipur, Rajasthan 302004',
    ST_SetSRID(ST_MakePoint(75.8350, 26.8920), 4326),
    'verified',
    'verified',
    true,
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    4.90
  )
ON CONFLICT (id) DO NOTHING;

-- 6. PRODUCTS
INSERT INTO public.products (
  id, shop_id, category_id, brand_id, title, description, base_price, min_bargain_price, bargain_enabled, status
) VALUES
  (
    'd0000001-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    'a0000001-0000-0000-0000-000000000003',
    'b0000001-0000-0000-0000-000000000002',
    'Pure Silk Bandhani Bridal Lehenga',
    'Exquisite hand-tied Bandhani lehenga in royal crimson red with heavy real Gota Patti work. Includes stitched blouse and organza dupatta.',
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
    '100% Cambric 60-60 Cotton flared Anarkali kurta with matching pants and Kota Doria dupatta with Bagru block prints.',
    2899.00,
    2200.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000003',
    'c0000001-0000-0000-0000-000000000002',
    'a0000001-0000-0000-0000-000000000002',
    'b0000001-0000-0000-0000-000000000003',
    'Royal Rajasthani Silk Kurta & Modi Jacket',
    'Raw silk festive kurta pajama set paired with a contrast Jacquard Modi Nehru jacket with metallic buttons.',
    4499.00,
    3799.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000004',
    'c0000001-0000-0000-0000-000000000004',
    'a0000001-0000-0000-0000-000000000003',
    'b0000001-0000-0000-0000-000000000002',
    'Chanderi Silk Zari Border Saree',
    'Lightweight festive Chanderi saree woven with golden Zari motifs and delicate floral pallu.',
    3299.00,
    2650.00,
    true,
    'active'
  ),
  (
    'd0000001-0000-0000-0000-000000000005',
    'c0000001-0000-0000-0000-000000000002',
    'a0000001-0000-0000-0000-000000000005',
    'b0000001-0000-0000-0000-000000000004',
    'Handcrafted Mojari Leather Jutti',
    'Pure leather handcrafted Rajasthani Jutti with intricate thread work and comfortable double cushioning.',
    1499.00,
    1150.00,
    true,
    'active'
  )
ON CONFLICT (id) DO NOTHING;

-- 7. PRODUCT VARIANTS
INSERT INTO public.product_variants (
  id, product_id, size, color, stock_qty, price_override, sku, image_urls
) VALUES
  (
    'e0000001-0000-0000-0000-000000000001',
    'd0000001-0000-0000-0000-000000000001',
    'M (38)',
    'Crimson Red',
    12,
    NULL,
    'LEH-RED-M',
    ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80', 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000002',
    'd0000001-0000-0000-0000-000000000001',
    'L (40)',
    'Crimson Red',
    8,
    NULL,
    'LEH-RED-L',
    ARRAY['https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000003',
    'd0000001-0000-0000-0000-000000000002',
    'M (38)',
    'Indigo Blue',
    25,
    NULL,
    'ANK-IND-M',
    ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000004',
    'd0000001-0000-0000-0000-000000000002',
    'L (40)',
    'Indigo Blue',
    18,
    NULL,
    'ANK-IND-L',
    ARRAY['https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000005',
    'd0000001-0000-0000-0000-000000000003',
    'L (40)',
    'Gold / Navy',
    15,
    NULL,
    'KUR-GLD-L',
    ARRAY['https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000006',
    'd0000001-0000-0000-0000-000000000004',
    'Free Size',
    'Emerald Green',
    30,
    NULL,
    'SAR-EMR-FS',
    ARRAY['https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80']
  ),
  (
    'e0000001-0000-0000-0000-000000000007',
    'd0000001-0000-0000-0000-000000000005',
    'UK 8',
    'Tan Brown',
    20,
    NULL,
    'JUT-TAN-UK8',
    ARRAY['https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80']
  )
ON CONFLICT (id) DO NOTHING;

-- 8. PRODUCT PRIMARY IMAGES
INSERT INTO public.product_images (
  id, product_id, url, is_primary, display_order
) VALUES
  ('f1000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80', true, 0),
  ('f1000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&w=800&q=80', true, 0),
  ('f1000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1520006403909-838d6b92c22e?auto=format&fit=crop&w=800&q=80', true, 0),
  ('f1000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000004', 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80', true, 0),
  ('f1000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000005', 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=800&q=80', true, 0)
ON CONFLICT (id) DO NOTHING;

-- 9. DELIVERY PARTNER PROFILE & ADDRESSES
INSERT INTO public.delivery_partner_profiles (
  id, vehicle_type, vehicle_number, driving_license_url, is_online, current_location, verification_status
) VALUES (
  '00000000-0000-0000-0000-000000000003',
  'Motorcycle (Hero Splendor)',
  'RJ 14 AB 1234',
  'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=400&q=80',
  true,
  ST_SetSRID(ST_MakePoint(75.8200, 26.9200), 4326),
  'verified'
) ON CONFLICT (id) DO UPDATE SET
  is_online = true,
  verification_status = 'verified';

INSERT INTO public.delivery_addresses (
  id, user_id, full_name, phone, address_line1, address_line2, city, state, pincode, is_default, latitude, longitude
) VALUES (
  'f0000001-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'Priya Sharma',
  '+91 98290 11111',
  'Flat 302, Royal Palms Residency',
  'C-Scheme',
  'Jaipur',
  'Rajasthan',
  '302001',
  true,
  26.9100,
  75.8050
) ON CONFLICT (id) DO NOTHING;

-- 10. PRODUCT REVIEWS
INSERT INTO public.product_reviews (
  id, product_id, consumer_id, rating, review_text
) VALUES (
  '90000001-0000-0000-0000-000000000001',
  'd0000001-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  5,
  'Absolutely breathtaking lehenga! The Gota work is real and so heavy. Delivered in just 2 hours in Jaipur!'
) ON CONFLICT (id) DO NOTHING;
