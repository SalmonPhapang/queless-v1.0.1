create table if not exists public.promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  message text not null default '',
  target_type text not null default 'product',
  target_id uuid not null,
  badge_text text not null default 'Promo',
  image_url text not null default '',
  is_active boolean not null default true,
  priority integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_promotions_is_active on public.promotions(is_active);
create index if not exists idx_promotions_target on public.promotions(target_type, target_id);
create index if not exists idx_promotions_priority on public.promotions(priority desc);

alter table public.promotions enable row level security;

create policy "Allow authenticated users to view promotions"
  on public.promotions for select
  to authenticated
  using (true);

