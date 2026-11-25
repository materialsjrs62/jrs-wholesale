-- JRS Wholesale: Supabase schema
-- Run this file in Supabase SQL Editor after creating a project.
-- The browser uses only the anon/publishable key. Never expose service_role keys.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'staff' check (role in ('admin','staff')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  sku text unique not null,
  name text not null,
  category text not null check (category in ('Plywood','Hardware','Laminate','False Ceiling')),
  size text,
  unit text not null default 'Nos',
  rate numeric(12,2) not null default 0 check (rate >= 0),
  stock numeric(12,2) not null default 0 check (stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id),
  movement_type text not null check (movement_type in ('OPENING','IN','OUT')),
  quantity numeric(12,2) not null check (quantity > 0),
  note text,
  source_key text unique,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists stock_movements_product_created_idx
  on public.stock_movements(product_id, created_at desc);

create or replace function public.is_jrs_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin','staff')
  );
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
before update on public.products
for each row execute function public.touch_updated_at();

create or replace function public.apply_stock_movement()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare
  delta numeric(12,2);
begin
  if new.movement_type in ('OPENING','IN') then
    delta := new.quantity;
  else
    delta := -new.quantity;
  end if;

  update public.products
     set stock = stock + delta,
         updated_at = now()
   where id = new.product_id
     and stock + delta >= 0;

  if not found then
    raise exception 'Stock movement rejected: product missing or OUT quantity exceeds available stock';
  end if;
  return new;
end;
$$;

drop trigger if exists stock_movement_apply on public.stock_movements;
create trigger stock_movement_apply
after insert on public.stock_movements
for each row execute function public.apply_stock_movement();

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.stock_movements enable row level security;

drop policy if exists "profiles self or admin read" on public.profiles;
create policy "profiles self or admin read" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_jrs_admin());

drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products
for select to anon, authenticated using (active = true or public.is_jrs_admin());

drop policy if exists "admin insert products" on public.products;
create policy "admin insert products" on public.products
for insert to authenticated with check (public.is_jrs_admin());

drop policy if exists "admin update products" on public.products;
create policy "admin update products" on public.products
for update to authenticated using (public.is_jrs_admin()) with check (public.is_jrs_admin());

drop policy if exists "admin delete products" on public.products;
create policy "admin delete products" on public.products
for delete to authenticated using (public.is_jrs_admin());

drop policy if exists "admin read stock movements" on public.stock_movements;
create policy "admin read stock movements" on public.stock_movements
for select to authenticated using (public.is_jrs_admin());

drop policy if exists "admin insert stock movements" on public.stock_movements;
create policy "admin insert stock movements" on public.stock_movements
for insert to authenticated with check (public.is_jrs_admin() and created_by = auth.uid());

-- No UPDATE or DELETE policy is intentionally provided for stock_movements.
-- This preserves an append-only stock audit trail.

-- Create your first admin user in Supabase Authentication > Users, then run:
-- update public.profiles set role = 'admin' where email = 'YOUR_LOGIN_EMAIL';

-- Seed the 8 source-workbook plywood items with zero stock first.
-- Opening stock is then recorded as immutable OPENING movements below.
insert into public.products (sku,name,category,size,unit,rate,stock,active) values
('PLY-001','Wigwam Excel - 19 — Lifetime Guarantee','Plywood','8×4','Nos',4622,0,true),
('PLY-002','Wigwam Excel - 12 — Lifetime Guarantee','Plywood','8×4','Nos',3175,0,true),
('PLY-003','Fabricate Gold - 19 BB — 25 Year Guarantee','Plywood','8×4','Nos',3604,0,true),
('PLY-004','Fabricate Prime - 19 — 25 Year Guarantee','Plywood','8×4','Nos',4114,0,true),
('PLY-005','Fabricate Prime - 12 — 25 Year Guarantee','Plywood','8×4','Nos',2874,0,true),
('PLY-006','Fabricate Prime - 6 — 25 Year Guarantee','Plywood','8×4','Nos',1583,0,true),
('PLY-007','MDP - 18 — 10 Year Guarantee','Plywood','8×4','Nos',3499,0,true),
('PLY-008','MDP - 12 — 10 Year Guarantee','Plywood','8×4','Nos',2408,0,true)
on conflict (sku) do update set
  name=excluded.name, category=excluded.category, size=excluded.size,
  unit=excluded.unit, rate=excluded.rate, active=true;

insert into public.stock_movements (product_id,movement_type,quantity,note,source_key)
select p.id,'OPENING',v.quantity,'Opening stock imported from DOC-20261124-WA0006.xlsx','xlsx-20261124-'||p.sku
from public.products p
join (values
 ('PLY-001',60::numeric),('PLY-002',20::numeric),('PLY-003',30::numeric),('PLY-004',40::numeric),
 ('PLY-005',20::numeric),('PLY-006',9::numeric),('PLY-007',90::numeric),('PLY-008',20::numeric)
) as v(sku,quantity) on v.sku=p.sku
on conflict (source_key) do nothing;
