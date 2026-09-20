-- ==============================================================================
-- FIX BARGAINS: Ensure seller_id is populated & RLS allows bargain operations
-- ==============================================================================

-- 1. Ensure RLS is enabled on bargains
ALTER TABLE public.bargains ENABLE ROW LEVEL SECURITY;

-- 2. Drop & recreate all bargain policies
DROP POLICY IF EXISTS "Consumers can create bargains" ON public.bargains;
DROP POLICY IF EXISTS "Consumers can view their bargains" ON public.bargains;
DROP POLICY IF EXISTS "Sellers can view bargains for their products" ON public.bargains;
DROP POLICY IF EXISTS "Sellers can update bargains for their products" ON public.bargains;
DROP POLICY IF EXISTS "bargains_select_policy" ON public.bargains;
DROP POLICY IF EXISTS "bargains_insert_policy" ON public.bargains;
DROP POLICY IF EXISTS "bargains_update_policy" ON public.bargains;
DROP POLICY IF EXISTS "Allow all bargain operations" ON public.bargains;
DROP POLICY IF EXISTS "Authenticated users manage bargains" ON public.bargains;

-- Permissive: authenticated users can do everything (simplest fix for dev)
CREATE POLICY "Authenticated users manage bargains"
  ON public.bargains
  FOR ALL
  TO authenticated
  USING (
    auth.uid() = consumer_id OR auth.uid() = seller_id
  )
  WITH CHECK (
    auth.uid() = consumer_id OR auth.uid() = seller_id
  );

-- 3. Fix bargain_messages RLS
ALTER TABLE public.bargain_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all bargain_messages operations" ON public.bargain_messages;
DROP POLICY IF EXISTS "bargain_messages_select_policy" ON public.bargain_messages;
DROP POLICY IF EXISTS "bargain_messages_insert_policy" ON public.bargain_messages;
DROP POLICY IF EXISTS "Authenticated users manage bargain_messages" ON public.bargain_messages;

CREATE POLICY "Authenticated users manage bargain_messages"
  ON public.bargain_messages
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (auth.uid() = sender_id);

-- 4. Delete any corrupted bargains that have empty or null seller_id
DELETE FROM public.bargains WHERE seller_id::text = '' OR seller_id IS NULL;

-- 5. Show current bargains for verification
SELECT 
  b.id,
  b.consumer_id,
  b.seller_id,
  b.product_id,
  b.status,
  b.consumer_offer,
  b.created_at
FROM public.bargains b
ORDER BY b.created_at DESC
LIMIT 20;
