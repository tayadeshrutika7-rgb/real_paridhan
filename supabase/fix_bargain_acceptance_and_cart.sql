-- ==============================================================================
-- FIX: Bargain Acceptance & Auto-Cart Price Sync
-- ==============================================================================

-- 1. Ensure RLS on cart_items is permissive for authenticated users
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow cart select" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart insert" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart update" ON public.cart_items;
DROP POLICY IF EXISTS "Allow cart delete" ON public.cart_items;
DROP POLICY IF EXISTS "cart_items_all_policy" ON public.cart_items;
DROP POLICY IF EXISTS "Authenticated users manage cart_items" ON public.cart_items;

CREATE POLICY "Authenticated users manage cart_items"
  ON public.cart_items
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 2. Create / Replace the automatic Cart-sync trigger on bargain acceptance
CREATE OR REPLACE FUNCTION public.auto_cart_on_bargain_accepted()
RETURNS trigger AS $$
BEGIN
  IF NEW.status = 'accepted' AND (OLD.status IS DISTINCT FROM 'accepted') THEN
    INSERT INTO public.cart_items (consumer_id, variant_id, quantity, agreed_price, updated_at)
    VALUES (NEW.consumer_id, NEW.variant_id, 1, NEW.agreed_price, now())
    ON CONFLICT (consumer_id, variant_id)
    DO UPDATE SET
      quantity = 1,
      agreed_price = EXCLUDED.agreed_price,
      updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach trigger to bargains table
DROP TRIGGER IF EXISTS trg_auto_cart_on_bargain_accepted ON public.bargains;
CREATE TRIGGER trg_auto_cart_on_bargain_accepted
  AFTER UPDATE ON public.bargains
  FOR EACH ROW EXECUTE FUNCTION public.auto_cart_on_bargain_accepted();

-- 4. Sync any existing accepted bargains right now to cart_items!
INSERT INTO public.cart_items (consumer_id, variant_id, quantity, agreed_price, updated_at)
SELECT b.consumer_id, b.variant_id, 1, b.agreed_price, now()
FROM public.bargains b
WHERE b.status = 'accepted' AND b.agreed_price IS NOT NULL
ON CONFLICT (consumer_id, variant_id)
DO UPDATE SET
  agreed_price = EXCLUDED.agreed_price,
  updated_at = now();

-- 5. Verification query to confirm cart items & agreed price
SELECT 
  c.id,
  c.consumer_id,
  c.variant_id,
  c.quantity,
  c.agreed_price,
  c.updated_at
FROM public.cart_items c
ORDER BY c.updated_at DESC
LIMIT 10;
