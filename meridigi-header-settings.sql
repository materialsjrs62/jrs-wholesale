-- MeriDigi header settings managed from the admin panel.
alter table public.meridigi_site_settings
  add column if not exists header_tagline text not null default 'Apna digital growth apne haath mein',
  add column if not exists header_subtitle text not null default 'Grow Digital Marketing by Tapas',
  add column if not exists header_founder_text text not null default 'Founder of Confident Closer',
  add column if not exists header_founder_url text not null default 'https://remotepmc.github.io/confident-closer-pwa/index.html?refresh=15',
  add column if not exists header_brand_size integer not null default 36,
  add column if not exists header_tagline_size integer not null default 23,
  add column if not exists header_subtitle_size integer not null default 19,
  add column if not exists header_founder_size integer not null default 17;
