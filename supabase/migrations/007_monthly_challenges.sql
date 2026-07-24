-- Monthly challenge engine

create table public.monthly_challenges (
  id uuid primary key default gen_random_uuid(),
  month date not null unique,            -- normalized to the first day of the month
  title text not null,
  theme text not null default '',
  description text default '',
  cover_url text,
  prize_pool_cents int not null default 0,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Entries tie a user (and optionally a published post) to a challenge.
create table public.challenge_entries (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.monthly_challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid references public.posts (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (challenge_id, user_id, post_id)
);

-- Convenience view: the challenge whose window contains "now".
create or replace view public.current_challenge as
  select *
  from public.monthly_challenges
  where now() between starts_at and ends_at
  order by starts_at desc
  limit 1;

alter table public.monthly_challenges enable row level security;
alter table public.challenge_entries enable row level security;

create policy "Challenges viewable"
  on public.monthly_challenges for select to authenticated using (true);

create policy "Challenge entries viewable"
  on public.challenge_entries for select to authenticated using (true);

create policy "Challenge entries insertable by user"
  on public.challenge_entries for insert to authenticated with check (auth.uid() = user_id);

create policy "Challenge entries deletable by user"
  on public.challenge_entries for delete to authenticated using (auth.uid() = user_id);
