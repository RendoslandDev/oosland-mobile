-- Gifting

create table public.gift_types (
  id text primary key,
  name text not null,
  icon text not null,
  point_value int not null default 0
);

insert into public.gift_types (id, name, icon, point_value) values
  ('rose', 'Rose', '🌹', 1),
  ('crown', 'Crown', '👑', 5),
  ('sparkle', 'Sparkle', '✨', 3);

create table public.gifts (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid references public.posts (id) on delete set null,
  campaign_id uuid references public.campaigns (id) on delete set null,
  gift_type text not null references public.gift_types (id),
  message text default '',
  created_at timestamptz not null default now()
);

alter table public.gift_types enable row level security;
alter table public.gifts enable row level security;

create policy "Gift types viewable"
  on public.gift_types for select to authenticated using (true);

create policy "Gifts viewable by sender or recipient"
  on public.gifts for select to authenticated
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

create policy "Gifts insertable by sender"
  on public.gifts for insert to authenticated with check (auth.uid() = sender_id);
