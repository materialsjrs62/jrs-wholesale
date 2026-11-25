-- MeriDigi editable customer-page controls. Run once in Supabase SQL Editor.
create table if not exists public.meridigi_update_links (
 id uuid primary key default gen_random_uuid(), label text not null, url text not null unique,
 is_enabled boolean not null default true, sort_order integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint meridigi_update_links_http check (url ~* '^https?://')
);
create table if not exists public.meridigi_services (
 id uuid primary key default gen_random_uuid(), category text not null check(category in ('BUILD','SEEKHO')),
 name text not null, description text, details text, regular_price numeric(10,2), discounted_price numeric(10,2),
 discount_label text, offer_start date, offer_end date, feature_in_newsletter boolean not null default false,
 button_text text not null default 'Request on WhatsApp', whatsapp_number text not null default '917894531187',
 is_enabled boolean not null default true, sort_order integer not null default 0,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint meridigi_service_discount_valid check(discounted_price is null or regular_price is null or discounted_price < regular_price)
);
create table if not exists public.meridigi_site_settings (
 id integer primary key default 1 check(id=1), join_whatsapp_number text not null default '917894531187',
 join_message text not null default 'May I join?', updated_at timestamptz not null default now()
);
insert into public.meridigi_site_settings(id) values(1) on conflict(id) do nothing;
insert into public.meridigi_update_links(label,url,is_enabled,sort_order)
values('WhatsApp Channel','https://whatsapp.com/channel/0029VbEtDJMIHphLba3Ibx1tne',true,1) on conflict(url) do nothing;
insert into public.meridigi_services(category,name,description,details,regular_price,button_text,whatsapp_number,sort_order)
select 'BUILD','QUICK','A practical starter digital setup.','E-commerce setup; Online showroom in social media; WhatsApp Business catalogue; Telegram Channel; YouTube Channel',399,'WhatsApp for QUICK','917894531187',1
where not exists(select 1 from public.meridigi_services where category='BUILD' and name='QUICK');
insert into public.meridigi_services(category,name,description,details,regular_price,button_text,whatsapp_number,sort_order)
select 'BUILD','PROFESSIONAL','Includes all QUICK services.','Professional Reels – 10; Social media posts – 20; Total 30 content pieces in 90 days',799,'WhatsApp for PROFESSIONAL','917894531187',2
where not exists(select 1 from public.meridigi_services where category='BUILD' and name='PROFESSIONAL');
insert into public.meridigi_services(category,name,description,details,regular_price,button_text,whatsapp_number,sort_order)
select 'SEEKHO','Starter learning option','Learn practical digital skills step by step.','Free workshop; Free checklist; Starter learning option; Full batch and advanced learning details on request',399,'WhatsApp for SEEKHO','917894531187',1
where not exists(select 1 from public.meridigi_services where category='SEEKHO' and name='Starter learning option');
create or replace function public.meridigi_touch_control_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end; $$;
drop trigger if exists meridigi_update_links_touch on public.meridigi_update_links;
create trigger meridigi_update_links_touch before update on public.meridigi_update_links for each row execute function public.meridigi_touch_control_updated_at();
drop trigger if exists meridigi_services_touch on public.meridigi_services;
create trigger meridigi_services_touch before update on public.meridigi_services for each row execute function public.meridigi_touch_control_updated_at();
drop trigger if exists meridigi_site_settings_touch on public.meridigi_site_settings;
create trigger meridigi_site_settings_touch before update on public.meridigi_site_settings for each row execute function public.meridigi_touch_control_updated_at();
alter table public.meridigi_update_links enable row level security;
alter table public.meridigi_services enable row level security;
alter table public.meridigi_site_settings enable row level security;
drop policy if exists "MeriDigi public read enabled update links" on public.meridigi_update_links;
create policy "MeriDigi public read enabled update links" on public.meridigi_update_links for select to anon,authenticated using(is_enabled=true or public.is_meridigi_admin());
drop policy if exists "MeriDigi admin manage update links" on public.meridigi_update_links;
create policy "MeriDigi admin manage update links" on public.meridigi_update_links for all to authenticated using(public.is_meridigi_admin()) with check(public.is_meridigi_admin());
drop policy if exists "MeriDigi public read enabled services" on public.meridigi_services;
create policy "MeriDigi public read enabled services" on public.meridigi_services for select to anon,authenticated using(is_enabled=true or public.is_meridigi_admin());
drop policy if exists "MeriDigi admin manage services" on public.meridigi_services;
create policy "MeriDigi admin manage services" on public.meridigi_services for all to authenticated using(public.is_meridigi_admin()) with check(public.is_meridigi_admin());
drop policy if exists "MeriDigi public read site settings" on public.meridigi_site_settings;
create policy "MeriDigi public read site settings" on public.meridigi_site_settings for select to anon,authenticated using(true);
drop policy if exists "MeriDigi admin manage site settings" on public.meridigi_site_settings;
create policy "MeriDigi admin manage site settings" on public.meridigi_site_settings for all to authenticated using(public.is_meridigi_admin()) with check(public.is_meridigi_admin());
grant select on public.meridigi_update_links,public.meridigi_services,public.meridigi_site_settings to anon,authenticated;
grant insert,update,delete on public.meridigi_update_links,public.meridigi_services,public.meridigi_site_settings to authenticated;

-- Apply the approved MeriDigi launch discounts on both first setup and reruns.
update public.meridigi_services
set regular_price=399, discounted_price=299, discount_label='SPECIAL DISCOUNT',
    feature_in_newsletter=true, offer_start=null, offer_end=null
where category='BUILD' and name='QUICK';

update public.meridigi_services
set regular_price=799, discounted_price=499, discount_label='SPECIAL DISCOUNT',
    feature_in_newsletter=true, offer_start=null, offer_end=null
where category='BUILD' and name='PROFESSIONAL';

update public.meridigi_services
set regular_price=399, discounted_price=299, discount_label='SPECIAL DISCOUNT',
    feature_in_newsletter=true, offer_start=null, offer_end=null
where category='SEEKHO' and name='Starter learning option';
