-- ==============================================================================
-- FIX RLS POLICIES FOR CART, BARGAINS & MESSAGES
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/zuhwilxfukdrmnmhyibg/sql/new
-- ==============================================================================

-- 1. CART ITEMS POLICIES
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow cart select" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart insert" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart update" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart delete" ON public.cart_items;

CREATE POLICY "Allow cart select" ON public.cart_items FOR SELECT USING (true);
CREATE POLICY "Allow cart insert" ON public.cart_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow cart update" ON public.cart_items FOR UPDATE USING (true);
CREATE POLICY "Allow cart delete" ON public.cart_items FOR DELETE USING (true);

-- 2. BARGAINS POLICIES
ALTER TABLE public.bargains ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow bargains select" ON public.bargains;
DROP POLICY IF EXISTS "Allow bargains insert" ON public.bargains;
DROP POLICY IF EXISTS "Allow bargains update" ON public.bargains;

CREATE POLICY "Allow bargains select" ON public.bargains FOR SELECT USING (true);
CREATE POLICY "Allow bargains insert" ON public.bargains FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow bargains update" ON public.bargains FOR UPDATE USING (true);

-- 3. BARGAIN MESSAGES POLICIES
ALTER TABLE public.bargain_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow bargain messages select" ON public.bargain_messages;
DROP POLICY IF EXISTS "Allow bargain messages insert" ON public.bargain_messages;

CREATE POLICY "Allow bargain messages select" ON public.bargain_messages FOR SELECT USING (true);
CREATE POLICY "Allow bargain messages insert" ON public.bargain_messages FOR INSERT WITH CHECK (true);

-- 4. Enable Supabase Realtime for bargains and bargain_messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.bargains;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bargain_messages;
