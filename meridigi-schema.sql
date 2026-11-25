-- MeriDigi tables for the existing JRS Supabase project.
-- Does not alter JRS products, stock, profiles, or stock movements.
create extension if not exists pgcrypto;

create table if not exists public.meridigi_requests (
  id uuid primary key default gen_random_uuid(),
  request_type text not null check (request_type in ('BUILD','SEEKHO','NETWORK')),
  customer_name text not null,
  phone text not null,
  business_name text,
  package_name text,
  requirements text,
  contact_time text,
  consent boolean not null default false,
  status text not null default 'New request'
    check (status in ('New request','Contacted','Confirmed','Payment pending','Paid','In progress','Completed','Cancelled')),
  payment_amount numeric(10,2),
  payment_reference text,
  internal_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists meridigi_requests_created_idx
  on public.meridigi_requests(created_at desc);
create index if not exists meridigi_requests_type_idx
  on public.meridigi_requests(request_type,status);

create or replace function public.is_meridigi_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.meridigi_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists meridigi_requests_touch_updated_at on public.meridigi_requests;
create trigger meridigi_requests_touch_updated_at
before update on public.meridigi_requests
for each row execute function public.meridigi_touch_updated_at();

alter table public.meridigi_requests enable row level security;

drop policy if exists "MeriDigi public submit requests" on public.meridigi_requests;
create policy "MeriDigi public submit requests"
on public.meridigi_requests for insert to anon, authenticated
with check (consent = true);

drop policy if exists "MeriDigi admin read requests" on public.meridigi_requests;
create policy "MeriDigi admin read requests"
on public.meridigi_requests for select to authenticated
using (public.is_meridigi_admin());

drop policy if exists "MeriDigi admin update requests" on public.meridigi_requests;
create policy "MeriDigi admin update requests"
on public.meridigi_requests for update to authenticated
using (public.is_meridigi_admin())
with check (public.is_meridigi_admin());

grant insert on public.meridigi_requests to anon, authenticated;
grant select, update on public.meridigi_requests to authenticated;

-- Important: public visitors cannot read, edit, or delete submitted requests.
-- Only the account whose profiles.role is exactly 'admin' can view/manage them.
