-- ============================================================================
-- PARIDHAN SEED DATA
-- Default Categories, Brands, and Configuration
-- ============================================================================

-- Core Fashion Categories
insert into public.categories (id, name, parent_id, icon_url) values
  ('a0000001-0000-0000-0000-000000000001', 'Men', null, 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=128'),
  ('a0000001-0000-0000-0000-000000000002', 'Women', null, 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=128'),
  ('a0000001-0000-0000-0000-000000000003', 'Kids', null, 'https://images.unsplash.com/photo-1519457431-44ccd64a579b?w=128'),
  ('a0000001-0000-0000-0000-000000000004', 'Ethnic & Traditional', null, 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=128'),
  ('a0000001-0000-0000-0000-000000000005', 'Footwear', null, 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=128'),
  ('a0000001-0000-0000-0000-000000000006', 'Accessories', null, 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?w=128')
on conflict (id) do nothing;

-- Subcategories for Men & Women
insert into public.categories (id, name, parent_id, icon_url) values
  ('b0000001-0000-0000-0000-000000000001', 'Kurtas & Kurtis', 'a0000001-0000-0000-0000-000000000004', null),
  ('b0000001-0000-0000-0000-000000000002', 'Sarees', 'a0000001-0000-0000-0000-000000000004', null),
  ('b0000001-0000-0000-0000-000000000003', 'Shirts & T-Shirts', 'a0000001-0000-0000-0000-000000000001', null),
  ('b0000001-0000-0000-0000-000000000004', 'Trousers & Jeans', 'a0000001-0000-0000-0000-000000000001', null),
  ('b0000001-0000-0000-0000-000000000005', 'Dresses & Tops', 'a0000001-0000-0000-0000-000000000002', null)
on conflict (id) do nothing;

-- Sample Local Brands
insert into public.brands (name, logo_url) values
  ('Paridhan Handlooms', null),
  ('Jaipur Craft Co.', null),
  ('Khadi Heritage', null),
  ('Indie Weaves', null)
on conflict (name) do nothing;
