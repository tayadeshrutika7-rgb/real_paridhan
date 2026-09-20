-- ==============================================================================
-- FIX AUTH TRIGGER & PERMISSIONS IN SUPABASE
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/zuhwilxfukdrmnmhyibg/sql/new
-- ==============================================================================

-- 1. Ensure accepted_terms_at exists on profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accepted_terms_at timestamptz DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2. Create a bulletproof handle_new_user() trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role public.user_role := 'consumer';
  v_meta_role text;
BEGIN
  v_meta_role := new.raw_user_meta_data->>'role';
  
  IF v_meta_role = 'seller' THEN
    v_role := 'seller'::public.user_role;
  ELSIF v_meta_role = 'delivery' OR v_meta_role = 'delivery_partner' THEN
    v_role := 'delivery'::public.user_role;
  ELSIF v_meta_role = 'admin' THEN
    v_role := 'admin'::public.user_role;
  ELSE
    v_role := 'consumer'::public.user_role;
  END IF;

  INSERT INTO public.profiles (id, email, full_name, role, avatar_url, accepted_terms_at, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    v_role,
    COALESCE(new.raw_user_meta_data->>'avatar_url', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80'),
    now(),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    role = COALESCE(EXCLUDED.role, public.profiles.role),
    updated_at = now();

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-attach the trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Clean and re-insert the 4 default test users with matching passwords
DELETE FROM auth.users WHERE email IN ('consumer@paridhan.com', 'seller@paridhan.com', 'delivery@paridhan.com', 'admin@paridhan.com');

INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES 
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'consumer@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Priya Sharma","role":"consumer"}', now(), now()),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'seller@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rajesh Khandelwal","role":"seller"}', now(), now()),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'delivery@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Vikram Singh","role":"delivery"}', now(), now()),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@paridhan.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Super Admin","role":"admin"}', now(), now())
ON CONFLICT (id) DO NOTHING;
