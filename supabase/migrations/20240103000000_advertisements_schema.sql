-- ========================================================
-- PARIDHAN SELLER ADVERTISEMENTS & CAMPAIGNS SCHEMA & RLS
-- ========================================================

CREATE TABLE IF NOT EXISTS public.advertisements (
  id text PRIMARY KEY,
  seller_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  shop_id text,
  shop_name text NOT NULL DEFAULT 'Boutique Store',
  seller_email text,
  seller_phone text,
  title text NOT NULL,
  subtitle text NOT NULL DEFAULT '',
  tag text NOT NULL DEFAULT 'BOUTIQUE SPOTLIGHT',
  banner_image_url text NOT NULL,
  placement text NOT NULL DEFAULT 'home_hero', -- 'home_hero', 'category_header', 'featured_feed'
  target_type text NOT NULL DEFAULT 'shop',    -- 'shop', 'product', 'category', 'offer'
  target_id text,
  target_category text,
  button_text text NOT NULL DEFAULT 'Explore Collection',
  badge_text text,
  duration_days integer NOT NULL DEFAULT 15,
  budget numeric(10, 2) NOT NULL DEFAULT 1499.00,
  payment_id text,
  payment_status text NOT NULL DEFAULT 'paid', -- 'paid', 'pending', 'failed'
  payment_method text NOT NULL DEFAULT 'razorpay',
  status text NOT NULL DEFAULT 'pending',      -- 'pending', 'approved', 'live', 'rejected', 'paused', 'completed'
  admin_notes text,
  is_paused boolean NOT NULL DEFAULT false,
  impressions integer NOT NULL DEFAULT 0,
  clicks integer NOT NULL DEFAULT 0,
  orders_count integer NOT NULL DEFAULT 0,
  revenue_generated numeric(10, 2) NOT NULL DEFAULT 0.00,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  approved_at timestamptz,
  expires_at timestamptz
);

-- Indices for rapid consumer discovery and seller dashboard queries
CREATE INDEX IF NOT EXISTS idx_advertisements_status_placement ON public.advertisements(status, placement);
CREATE INDEX IF NOT EXISTS idx_advertisements_seller_id ON public.advertisements(seller_id);
CREATE INDEX IF NOT EXISTS idx_advertisements_expires_at ON public.advertisements(expires_at);
CREATE INDEX IF NOT EXISTS idx_advertisements_target_category ON public.advertisements(target_category);

-- Enable RLS
ALTER TABLE public.advertisements ENABLE ROW LEVEL SECURITY;

-- 1. Public / Consumer read policy: Only active, approved/live, unpaused and unexpired ads
CREATE POLICY "Public consumers can view active approved ads"
  ON public.advertisements FOR SELECT
  USING (
    status IN ('approved', 'live')
    AND is_paused = false
    AND (expires_at IS NULL OR expires_at > now())
  );

-- 2. Seller read policy: Sellers can read their own ads
CREATE POLICY "Sellers can view own advertisements"
  ON public.advertisements FOR SELECT
  TO authenticated
  USING (
    seller_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 3. Seller insert policy: Verified sellers can insert ad requests
CREATE POLICY "Sellers can insert ad requests"
  ON public.advertisements FOR INSERT
  TO authenticated
  WITH CHECK (
    seller_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 4. Seller & Admin update policy
CREATE POLICY "Sellers and Admins can update advertisements"
  ON public.advertisements FOR UPDATE
  TO authenticated
  USING (
    seller_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 5. Admin delete policy
CREATE POLICY "Admins and owners can delete advertisements"
  ON public.advertisements FOR DELETE
  TO authenticated
  USING (
    seller_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Ad Analytics Interaction Table
CREATE TABLE IF NOT EXISTS public.ad_interactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id text REFERENCES public.advertisements(id) ON DELETE CASCADE,
  interaction_type text NOT NULL, -- 'impression', 'click', 'conversion'
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.ad_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public inserting ad interactions"
  ON public.ad_interactions FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Allow admins and sellers to read interactions"
  ON public.ad_interactions FOR SELECT
  TO authenticated
  USING (true);
