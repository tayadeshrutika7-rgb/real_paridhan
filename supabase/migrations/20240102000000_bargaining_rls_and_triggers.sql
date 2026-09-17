-- ============================================================================
-- PARIDHAN MIGRATION #002
-- Phase 4: Bargaining Engine — Auto-cart trigger & RLS policies
-- ============================================================================

-- Trigger: auto-add to cart when bargain is accepted
create or replace function public.auto_cart_on_bargain_accepted()
returns trigger as $$
begin
  if new.status = 'accepted' and old.status != 'accepted' then
    -- Upsert cart_items with the agreed price
    insert into public.cart_items (consumer_id, variant_id, quantity, agreed_price)
    values (new.consumer_id, new.variant_id, 1, new.agreed_price)
    on conflict (consumer_id, variant_id)
    do update set
      quantity = 1,
      agreed_price = excluded.agreed_price,
      updated_at = now();
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_auto_cart_on_bargain_accepted
  after update on public.bargains
  for each row execute function public.auto_cart_on_bargain_accepted();

-- ============================================================================
-- RLS Policies for bargains table
-- ============================================================================

alter table public.bargains enable row level security;

-- Consumer can see their own bargains
create policy "consumer_read_own_bargains"
  on public.bargains for select
  using (auth.uid() = consumer_id);

-- Seller can see bargains for their shop
create policy "seller_read_shop_bargains"
  on public.bargains for select
  using (auth.uid() = seller_id);

-- Consumer can create bargains (offer)
create policy "consumer_create_bargain"
  on public.bargains for insert
  with check (auth.uid() = consumer_id);

-- Seller can update status / counter_offer on their bargains
create policy "seller_update_bargain"
  on public.bargains for update
  using (auth.uid() = seller_id);

-- Consumer can update (accept seller counter)
create policy "consumer_update_bargain"
  on public.bargains for update
  using (auth.uid() = consumer_id);

-- ============================================================================
-- RLS Policies for bargain_messages table
-- ============================================================================

alter table public.bargain_messages enable row level security;

-- Both parties can read messages in their bargain
create policy "bargain_parties_read_messages"
  on public.bargain_messages for select
  using (
    exists (
      select 1 from public.bargains b
      where b.id = bargain_id
        and (b.consumer_id = auth.uid() or b.seller_id = auth.uid())
    )
  );

-- Either party can insert messages in their bargain
create policy "bargain_parties_insert_messages"
  on public.bargain_messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.bargains b
      where b.id = bargain_id
        and (b.consumer_id = auth.uid() or b.seller_id = auth.uid())
        and b.status in ('open', 'countered')
    )
  );

-- ============================================================================
-- Enable Supabase Realtime for bargaining tables
-- ============================================================================

alter publication supabase_realtime add table public.bargains;
alter publication supabase_realtime add table public.bargain_messages;
