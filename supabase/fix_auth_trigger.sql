-- ==============================================================================
-- FIX AUTH TRIGGER & PERMISSIONS IN SUPABASE (faqtswmhgintutwvnkyy)
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/faqtswmhgintutwvnkyy/sql/new
-- ==============================================================================

-- 1. Ensure required profile columns exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS accepted_terms_at timestamptz DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 2. Create the bulletproof handle_new_user() trigger function
-- Fixes HTTP 500 by setting search_path = public, auth and explicitly casting to public.user_role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_role public.user_role := 'consumer';
  v_meta_role text;
BEGIN
  v_meta_role := new.raw_user_meta_data->>'role';
  
  -- Public registration only allows 'consumer', 'seller', and 'delivery' (Never admin)
  IF v_meta_role = 'seller' THEN
    v_role := 'seller'::public.user_role;
  ELSIF v_meta_role = 'delivery' OR v_meta_role = 'delivery_partner' THEN
    v_role := 'delivery'::public.user_role;
  ELSE
    v_role := 'consumer'::public.user_role;
  END IF;

  INSERT INTO public.profiles (
    id, role, full_name, phone, email, avatar_url, accepted_terms_at, created_at, updated_at
  ) VALUES (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.phone,
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    now(),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    phone = coalesce(EXCLUDED.phone, public.profiles.phone),
    full_name = coalesce(nullif(EXCLUDED.full_name, ''), public.profiles.full_name),
    role = coalesce(EXCLUDED.role, public.profiles.role),
    updated_at = now();

  RETURN new;
END;
$$;

-- 3. Attach trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
