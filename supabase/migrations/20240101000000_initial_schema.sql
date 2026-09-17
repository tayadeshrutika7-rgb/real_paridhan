-- ============================================================================
-- PARIDHAN DATABASE SCHEMA MIGRATION #001
-- Hyperlocal Fashion Marketplace with Bargaining & AI
-- ============================================================================

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";
create extension if not exists postgis;

-- 2. CUSTOM ENUMS
create type user_role as enum ('consumer', 'seller', 'delivery', 'admin');
create type push_platform as enum ('ios', 'android', 'web');
create type shop_status as enum ('pending', 'verified', 'rejected', 'suspended');
create type kyc_status as enum ('not_started', 'pending', 'verified', 'rejected');
create type product_status as enum ('active', 'draft', 'out_of_stock', 'removed');
create type bargain_status as enum ('open', 'countered', 'accepted', 'rejected', 'expired');
create type bargain_actor as enum ('consumer', 'seller');
create type bargain_message_type as enum ('offer', 'counter', 'accept', 'reject', 'text');
create type order_status as enum ('placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled', 'return_requested', 'returned');
create type payment_method as enum ('cod', 'razorpay');
create type payment_status as enum ('pending', 'paid', 'failed', 'refunded', 'partially_refunded');
create type return_status as enum ('requested', 'approved', 'rejected', 'picked_up', 'refunded');
create type payout_status as enum ('pending', 'processing', 'paid', 'failed');
create type remittance_status as enum ('pending', 'remitted');
create type verification_status as enum ('pending', 'verified', 'rejected');
create type notification_type as enum ('order', 'bargain', 'system', 'promo', 'return');
create type report_target_type as enum ('shop', 'product', 'user', 'order');
create type report_status as enum ('open', 'reviewing', 'resolved', 'dismissed');

-- 3. HELPER FUNCTIONS & TRIGGERS
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 4. CORE TABLES

-- 4.1 Profiles (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'consumer',
  full_name text,
  phone text unique,
  email text unique,
  avatar_url text,
  skin_tone_pref text,
  accepted_terms_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute function update_updated_at_column();

-- Helper function: check if caller is an admin
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer;

-- 4.2 Push Subscriptions
create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  onesignal_player_id text not null,
  platform push_platform not null,
  created_at timestamptz not null default now(),
  unique(user_id, onesignal_player_id)
);

-- 4.3 Categories & Brands
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_id uuid references public.categories(id) on delete set null,
  icon_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.brands (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  logo_url text,
  created_at timestamptz not null default now()
);

-- 4.4 Shops
create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text,
  logo_url text,
  banner_url text,
  address text not null,
  location geography(Point, 4326) not null,
  status shop_status not null default 'pending',
  category_ids uuid[] default '{}',
  avg_rating numeric(3,2) default 0.0,
  razorpay_linked_account_id text,
  kyc_status kyc_status not null default 'not_started',
  commission_rate numeric(5,2) not null default 10.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_shops_location on public.shops using gist(location);
create index if not exists idx_shops_seller on public.shops(seller_id);

create trigger update_shops_updated_at
  before update on public.shops
  for each row execute function update_updated_at_column();

-- 4.5 Products
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  category_id uuid not null references public.categories(id),
  brand_id uuid references public.brands(id) on delete set null,
  title text not null,
  description text,
  base_price numeric(10,2) not null check (base_price >= 0),
  min_bargain_price numeric(10,2) not null check (min_bargain_price >= 0 and min_bargain_price <= base_price),
  bargain_enabled boolean not null default true,
  status product_status not null default 'draft',
  search_vector tsvector,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_products_shop on public.products(shop_id);
create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_products_search on public.products using gin(search_vector);

-- Trigger to maintain search_vector automatically
create or replace function products_search_vector_update() returns trigger as $$
begin
  new.search_vector :=
    setweight(to_tsvector('english', coalesce(new.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(new.description, '')), 'B');
  return new;
end;
$$ language plpgsql;

create trigger trg_products_search_vector
  before insert or update on public.products
  for each row execute function products_search_vector_update();

create trigger update_products_updated_at
  before update on public.products
  for each row execute function update_updated_at_column();

-- 4.6 Product Variants
create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  size text not null,
  color text not null,
  stock_qty int not null default 0 check (stock_qty >= 0),
  price_override numeric(10,2) check (price_override is null or price_override >= 0),
  sku text,
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_variants_product on public.product_variants(product_id);

create trigger update_product_variants_updated_at
  before update on public.product_variants
  for each row execute function update_updated_at_column();

-- 4.7 Bargains
create table if not exists public.bargains (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  consumer_id uuid not null references public.profiles(id),
  seller_id uuid not null references public.profiles(id),
  status bargain_status not null default 'open',
  current_offer numeric(10,2) not null,
  current_offer_by bargain_actor not null,
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_bargains_consumer on public.bargains(consumer_id);
create index if not exists idx_bargains_seller on public.bargains(seller_id);
create index if not exists idx_bargains_product on public.bargains(product_id);

create trigger update_bargains_updated_at
  before update on public.bargains
  for each row execute function update_updated_at_column();

-- 4.8 Bargain Messages & Server-side Floor Price Gatekeeper
create table if not exists public.bargain_messages (
  id uuid primary key default gen_random_uuid(),
  bargain_id uuid not null references public.bargains(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  offer_amount numeric(10,2),
  message_type bargain_message_type not null,
  text text,
  created_at timestamptz not null default now()
);

create index if not exists idx_bargain_messages_bargain on public.bargain_messages(bargain_id);

-- Enforce min_bargain_price server-side trigger
create or replace function check_min_bargain_price() returns trigger as $$
declare
  v_product_id uuid;
  v_min_price numeric;
  v_base_price numeric;
  v_bargain_enabled boolean;
begin
  if new.offer_amount is not null then
    select p.id, p.min_bargain_price, p.base_price, p.bargain_enabled
    into v_product_id, v_min_price, v_base_price, v_bargain_enabled
    from public.bargains b
    join public.products p on p.id = b.product_id
    where b.id = new.bargain_id;

    if not coalesce(v_bargain_enabled, false) then
      raise exception 'Bargaining is not enabled for this product.';
    end if;

    if new.offer_amount < v_min_price then
      raise exception 'Offer amount % is below the seller minimum acceptable floor price %', new.offer_amount, v_min_price;
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_check_min_bargain_price
  before insert or update on public.bargain_messages
  for each row execute function check_min_bargain_price();

-- 4.9 Cart Items
create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  consumer_id uuid not null references public.profiles(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  agreed_price numeric(10,2) check (agreed_price is null or agreed_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(consumer_id, variant_id)
);

create index if not exists idx_cart_items_consumer on public.cart_items(consumer_id);

create trigger update_cart_items_updated_at
  before update on public.cart_items
  for each row execute function update_updated_at_column();

-- 4.10 Wishlists
create table if not exists public.wishlists (
  id uuid primary key default gen_random_uuid(),
  consumer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(consumer_id, product_id)
);

-- 4.11 Addresses
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  consumer_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'Home',
  line1 text not null,
  line2 text,
  city text not null,
  state text not null,
  pincode text not null,
  location geography(Point, 4326),
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_addresses_consumer on public.addresses(consumer_id);
create index if not exists idx_addresses_location on public.addresses using gist(location);

create trigger update_addresses_updated_at
  before update on public.addresses
  for each row execute function update_updated_at_column();

-- 4.12 Delivery Partner Profile
create table if not exists public.delivery_partner_profile (
  id uuid primary key references public.profiles(id) on delete cascade,
  vehicle_type text not null,
  vehicle_number text not null,
  license_url text not null,
  is_available boolean not null default false,
  current_location geography(Point, 4326),
  verification_status verification_status not null default 'pending',
  bank_account_details jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_delivery_location on public.delivery_partner_profile using gist(current_location);

create trigger update_delivery_partner_updated_at
  before update on public.delivery_partner_profile
  for each row execute function update_updated_at_column();

-- 4.13 Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  consumer_id uuid not null references public.profiles(id),
  shop_id uuid not null references public.shops(id),
  delivery_partner_id uuid references public.profiles(id),
  status order_status not null default 'placed',
  payment_method payment_method not null,
  payment_status payment_status not null default 'pending',
  razorpay_order_id text,
  razorpay_transfer_id text,
  subtotal numeric(10,2) not null check (subtotal >= 0),
  delivery_fee numeric(10,2) not null default 0.00 check (delivery_fee >= 0),
  commission_amount numeric(10,2) not null default 0.00 check (commission_amount >= 0),
  seller_payout_amount numeric(10,2) not null default 0.00 check (seller_payout_amount >= 0),
  total numeric(10,2) not null check (total >= 0),
  cod_collected boolean not null default false,
  cod_collected_at timestamptz,
  delivery_address jsonb not null,
  cancel_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_orders_consumer on public.orders(consumer_id);
create index if not exists idx_orders_shop on public.orders(shop_id);
create index if not exists idx_orders_delivery_partner on public.orders(delivery_partner_id);

create trigger update_orders_updated_at
  before update on public.orders
  for each row execute function update_updated_at_column();

-- 4.14 Order Items
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id),
  quantity int not null check (quantity > 0),
  unit_price numeric(10,2) not null check (unit_price >= 0)
);

create index if not exists idx_order_items_order on public.order_items(order_id);

-- 4.15 Returns & Refunds
create table if not exists public.returns_refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  reason text not null,
  photo_urls text[] default '{}',
  status return_status not null default 'requested',
  refund_amount numeric(10,2),
  resolved_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_returns_order on public.returns_refunds(order_id);

create trigger update_returns_refunds_updated_at
  before update on public.returns_refunds
  for each row execute function update_updated_at_column();

-- 4.16 Payouts
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  gross_sales numeric(10,2) not null default 0.00,
  commission_deducted numeric(10,2) not null default 0.00,
  net_payout numeric(10,2) not null default 0.00,
  status payout_status not null default 'pending',
  razorpay_payout_id text,
  created_at timestamptz not null default now()
);

create index if not exists idx_payouts_seller on public.payouts(seller_id);

-- 4.17 COD Remittance
create table if not exists public.cod_remittance (
  id uuid primary key default gen_random_uuid(),
  delivery_partner_id uuid not null references public.profiles(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  amount numeric(10,2) not null check (amount >= 0),
  status remittance_status not null default 'pending',
  remitted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_cod_remittance_delivery on public.cod_remittance(delivery_partner_id);

-- 4.18 Reviews
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  shop_id uuid references public.shops(id) on delete set null,
  reviewer_id uuid not null references public.profiles(id),
  rating int not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists idx_reviews_product on public.reviews(product_id);
create index if not exists idx_reviews_shop on public.reviews(shop_id);

-- 4.19 Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type notification_type not null,
  deep_link text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications(user_id, read);

-- 4.20 AI Interactions
create table if not exists public.ai_interactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_context text not null,
  query text not null,
  response text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_ai_interactions_user on public.ai_interactions(user_id);

-- 4.21 Reports & Complaints
create table if not exists public.reports_complaints (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id),
  target_type report_target_type not null,
  target_id uuid not null,
  reason text not null,
  status report_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger update_reports_updated_at
  before update on public.reports_complaints
  for each row execute function update_updated_at_column();

-- 4.22 Platform Configuration
create table if not exists public.platform_config (
  key text primary key,
  value jsonb not null
);

-- Insert initial platform configuration
insert into public.platform_config (key, value) values
  ('default_commission_rate', '{"rate": 10.0}'::jsonb),
  ('delivery_fee_rules', '{"base_fee": 30.0, "per_km_rate": 5.0, "free_above": 999.0}'::jsonb),
  ('feature_flags', '{"bargaining_enabled": true, "ai_helpdesk_enabled": true, "skin_tone_recommendations": false}'::jsonb)
on conflict (key) do nothing;

-- 5. RPC FUNCTION: Geospatial PostGIS Radius Discovery
create or replace function public.get_nearby_shops(
  lat double precision,
  lng double precision,
  radius_km double precision default 10.0
)
returns table (
  id uuid,
  seller_id uuid,
  name text,
  description text,
  logo_url text,
  banner_url text,
  address text,
  distance_meters double precision,
  avg_rating numeric,
  category_ids uuid[]
) as $$
begin
  return query
  select
    s.id,
    s.seller_id,
    s.name,
    s.description,
    s.logo_url,
    s.banner_url,
    s.address,
    st_distance(s.location, st_setsrid(st_makepoint(lng, lat), 4326)::geography) as distance_meters,
    s.avg_rating,
    s.category_ids
  from public.shops s
  where s.status = 'verified'
    and st_dwithin(s.location, st_setsrid(st_makepoint(lng, lat), 4326)::geography, radius_km * 1000)
  order by distance_meters asc;
end;
$$ language plpgsql security definer;

-- 6. AUTH TRIGGER: Auto-create Profile on Signup
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_role user_role := 'consumer';
  v_meta_role text;
begin
  -- Read role requested during signup metadata, if valid
  v_meta_role := new.raw_user_meta_data->>'role';
  if v_meta_role in ('consumer', 'seller', 'delivery') then
    v_role := v_meta_role::user_role;
  end if;
  -- Notice: 'admin' role cannot be self-selected via metadata; defaults to consumer or must be granted manually.

  insert into public.profiles (
    id,
    role,
    full_name,
    phone,
    email,
    avatar_url,
    accepted_terms_at
  ) values (
    new.id,
    v_role,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    new.phone,
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    case when (new.raw_user_meta_data->>'accepted_terms')::boolean = true then now() else null end
  )
  on conflict (id) do update set
    email = excluded.email,
    phone = coalesce(excluded.phone, profiles.phone),
    full_name = coalesce(nullif(excluded.full_name, ''), profiles.full_name);

  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 7. ROW LEVEL SECURITY (RLS) POLICIES
alter table public.profiles enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.categories enable row level security;
alter table public.brands enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.bargains enable row level security;
alter table public.bargain_messages enable row level security;
alter table public.cart_items enable row level security;
alter table public.wishlists enable row level security;
alter table public.addresses enable row level security;
alter table public.delivery_partner_profile enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.returns_refunds enable row level security;
alter table public.payouts enable row level security;
alter table public.cod_remittance enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.ai_interactions enable row level security;
alter table public.reports_complaints enable row level security;
alter table public.platform_config enable row level security;

-- Policies for profiles
create policy "Public profiles are viewable by everyone"
  on public.profiles for select using (true);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id or is_admin());

-- Push subscriptions
create policy "Users can manage own push subscriptions"
  on public.push_subscriptions for all using (auth.uid() = user_id or is_admin());

-- Categories & Brands (read all, write admin)
create policy "Anyone can view categories" on public.categories for select using (true);
create policy "Admins can manage categories" on public.categories for all using (is_admin());

create policy "Anyone can view brands" on public.brands for select using (true);
create policy "Admins can manage brands" on public.brands for all using (is_admin());

-- Shops
create policy "Public can view verified shops"
  on public.shops for select using (status = 'verified' or auth.uid() = seller_id or is_admin());

create policy "Sellers can manage own shop"
  on public.shops for all using (auth.uid() = seller_id or is_admin());

-- Products
create policy "Anyone can view active products of verified shops"
  on public.products for select using (
    status = 'active'
    or exists (select 1 from public.shops s where s.id = products.shop_id and (s.seller_id = auth.uid() or is_admin()))
  );

create policy "Sellers manage own products"
  on public.products for all using (
    exists (select 1 from public.shops s where s.id = products.shop_id and s.seller_id = auth.uid())
    or is_admin()
  );

-- Product variants
create policy "Anyone can view product variants"
  on public.product_variants for select using (true);

create policy "Sellers manage own variants"
  on public.product_variants for all using (
    exists (
      select 1 from public.products p
      join public.shops s on s.id = p.shop_id
      where p.id = product_variants.product_id and (s.seller_id = auth.uid() or is_admin())
    )
  );

-- Bargains (consumer & seller participation)
create policy "Participants and admin can view bargains"
  on public.bargains for select using (
    auth.uid() = consumer_id or auth.uid() = seller_id or is_admin()
  );

create policy "Consumers can initiate bargains"
  on public.bargains for insert with check (auth.uid() = consumer_id);

create policy "Participants can update bargains"
  on public.bargains for update using (
    auth.uid() = consumer_id or auth.uid() = seller_id or is_admin()
  );

-- Bargain messages
create policy "Participants can view bargain messages"
  on public.bargain_messages for select using (
    exists (
      select 1 from public.bargains b
      where b.id = bargain_messages.bargain_id and (b.consumer_id = auth.uid() or b.seller_id = auth.uid() or is_admin())
    )
  );

create policy "Participants can insert bargain messages"
  on public.bargain_messages for insert with check (
    auth.uid() = sender_id and
    exists (
      select 1 from public.bargains b
      where b.id = bargain_messages.bargain_id and (b.consumer_id = auth.uid() or b.seller_id = auth.uid() or is_admin())
    )
  );

-- Cart items & Wishlists
create policy "Users manage own cart"
  on public.cart_items for all using (auth.uid() = consumer_id or is_admin());

create policy "Users manage own wishlist"
  on public.wishlists for all using (auth.uid() = consumer_id or is_admin());

-- Addresses
create policy "Users manage own addresses"
  on public.addresses for all using (auth.uid() = consumer_id or is_admin());

-- Delivery partner profile
create policy "Delivery partner can view and update own profile"
  on public.delivery_partner_profile for all using (auth.uid() = id or is_admin());

create policy "Admins and assignment system view delivery partners"
  on public.delivery_partner_profile for select using (true);

-- Orders
create policy "Parties involved can view orders"
  on public.orders for select using (
    auth.uid() = consumer_id
    or exists (select 1 from public.shops s where s.id = orders.shop_id and s.seller_id = auth.uid())
    or auth.uid() = delivery_partner_id
    or is_admin()
  );

create policy "Consumers can insert orders"
  on public.orders for insert with check (auth.uid() = consumer_id);

create policy "Involved parties and admin can update orders"
  on public.orders for update using (
    auth.uid() = consumer_id
    or exists (select 1 from public.shops s where s.id = orders.shop_id and s.seller_id = auth.uid())
    or auth.uid() = delivery_partner_id
    or is_admin()
  );

-- Order items
create policy "Parties involved can view order items"
  on public.order_items for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
      and (
        o.consumer_id = auth.uid()
        or exists (select 1 from public.shops s where s.id = o.shop_id and s.seller_id = auth.uid())
        or o.delivery_partner_id = auth.uid()
        or is_admin()
      )
    )
  );

create policy "Consumers can insert order items"
  on public.order_items for insert with check (
    exists (select 1 from public.orders o where o.id = order_items.order_id and o.consumer_id = auth.uid())
  );

-- Returns & Refunds
create policy "Involved parties can view returns"
  on public.returns_refunds for select using (
    auth.uid() = requested_by
    or exists (
      select 1 from public.orders o
      join public.shops s on s.id = o.shop_id
      where o.id = returns_refunds.order_id and s.seller_id = auth.uid()
    )
    or is_admin()
  );

create policy "Consumers can request return"
  on public.returns_refunds for insert with check (auth.uid() = requested_by);

create policy "Sellers and admin can update return status"
  on public.returns_refunds for update using (
    exists (
      select 1 from public.orders o
      join public.shops s on s.id = o.shop_id
      where o.id = returns_refunds.order_id and s.seller_id = auth.uid()
    )
    or is_admin()
  );

-- Payouts
create policy "Sellers can view own payouts"
  on public.payouts for select using (auth.uid() = seller_id or is_admin());

create policy "Admins can manage payouts"
  on public.payouts for all using (is_admin());

-- COD Remittance
create policy "Delivery partners can view own remittances"
  on public.cod_remittance for select using (auth.uid() = delivery_partner_id or is_admin());

create policy "Admins can manage remittances"
  on public.cod_remittance for all using (is_admin());

-- Reviews
create policy "Anyone can read reviews"
  on public.reviews for select using (true);

create policy "Reviewer can insert own review"
  on public.reviews for insert with check (auth.uid() = reviewer_id);

-- Notifications
create policy "Users can view and update own notifications"
  on public.notifications for all using (auth.uid() = user_id or is_admin());

-- AI Interactions
create policy "Users can view and create own AI interactions"
  on public.ai_interactions for all using (auth.uid() = user_id or is_admin());

-- Reports & Complaints
create policy "Users can create complaints and see own"
  on public.reports_complaints for all using (auth.uid() = reporter_id or is_admin());

-- Platform config
create policy "Anyone can read platform config"
  on public.platform_config for select using (true);

create policy "Admins can update platform config"
  on public.platform_config for all using (is_admin());
