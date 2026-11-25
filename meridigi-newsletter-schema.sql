-- MeriDigi Daily Newsletter
-- Run this file in the existing JRS Supabase SQL Editor.
-- Uses the existing public.is_meridigi_admin() helper; does not change JRS data.

create table if not exists public.meridigi_newsletters (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  edition_date date not null default current_date,
  summary text,
  content text not null,
  image_url text,
  links jsonb not null default '[]'::jsonb,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint meridigi_newsletters_links_array check (jsonb_typeof(links) = 'array')
);

create index if not exists meridigi_newsletters_date_idx
  on public.meridigi_newsletters(edition_date desc, created_at desc);

drop trigger if exists meridigi_newsletters_touch_updated_at on public.meridigi_newsletters;
create trigger meridigi_newsletters_touch_updated_at
before update on public.meridigi_newsletters
for each row execute function public.meridigi_touch_updated_at();

alter table public.meridigi_newsletters enable row level security;

drop policy if exists "MeriDigi public read published newsletters" on public.meridigi_newsletters;
create policy "MeriDigi public read published newsletters"
on public.meridigi_newsletters for select to anon, authenticated
using (is_published = true);

drop policy if exists "MeriDigi admin manage newsletters" on public.meridigi_newsletters;
create policy "MeriDigi admin manage newsletters"
on public.meridigi_newsletters for all to authenticated
using (public.is_meridigi_admin())
with check (public.is_meridigi_admin());

grant select on public.meridigi_newsletters to anon, authenticated;
grant insert, update, delete on public.meridigi_newsletters to authenticated;

-- Public image bucket; only MeriDigi admins can upload, replace, or delete files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('meridigi-newsletter', 'meridigi-newsletter', true, 5242880,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = true, file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "MeriDigi public view newsletter images" on storage.objects;
create policy "MeriDigi public view newsletter images"
on storage.objects for select to public
using (bucket_id = 'meridigi-newsletter');

drop policy if exists "MeriDigi admin upload newsletter images" on storage.objects;
create policy "MeriDigi admin upload newsletter images"
on storage.objects for insert to authenticated
with check (bucket_id = 'meridigi-newsletter' and public.is_meridigi_admin());

drop policy if exists "MeriDigi admin update newsletter images" on storage.objects;
create policy "MeriDigi admin update newsletter images"
on storage.objects for update to authenticated
using (bucket_id = 'meridigi-newsletter' and public.is_meridigi_admin())
with check (bucket_id = 'meridigi-newsletter' and public.is_meridigi_admin());

drop policy if exists "MeriDigi admin delete newsletter images" on storage.objects;
create policy "MeriDigi admin delete newsletter images"
on storage.objects for delete to authenticated
using (bucket_id = 'meridigi-newsletter' and public.is_meridigi_admin());
