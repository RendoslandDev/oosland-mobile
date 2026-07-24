-- Campaigns and groups

create type campaign_status as enum ('draft', 'active', 'ended');
create type group_member_role as enum ('owner', 'admin', 'member');

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text default '',
  is_public boolean not null default true,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role group_member_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text default '',
  theme text default '',
  starts_at timestamptz,
  ends_at timestamptz,
  status campaign_status not null default 'draft',
  cover_url text,
  group_id uuid references public.groups (id) on delete set null,
  is_starter_post boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.campaign_members (
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  score int not null default 0,
  primary key (campaign_id, user_id)
);

-- Post drafts (Phase 1 complete, Phase 2 pending)
create table public.post_drafts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  clothes_image_url text not null,
  caption text default '',
  campaign_id uuid references public.campaigns (id) on delete set null,
  group_id uuid references public.groups (id) on delete set null,
  start_new_campaign boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_members enable row level security;
alter table public.post_drafts enable row level security;

create policy "Public groups viewable"
  on public.groups for select to authenticated using (is_public or owner_id = auth.uid());

create policy "Groups creatable by authenticated"
  on public.groups for insert to authenticated with check (auth.uid() = owner_id);

create policy "Groups updatable by owner"
  on public.groups for update to authenticated using (auth.uid() = owner_id);

create policy "Group members viewable"
  on public.group_members for select to authenticated using (true);

create policy "Group members join"
  on public.group_members for insert to authenticated with check (auth.uid() = user_id);

create policy "Campaigns viewable"
  on public.campaigns for select to authenticated using (true);

create policy "Campaigns creatable"
  on public.campaigns for insert to authenticated with check (auth.uid() = creator_id);

create policy "Campaigns updatable by creator"
  on public.campaigns for update to authenticated using (auth.uid() = creator_id);

create policy "Campaign members viewable"
  on public.campaign_members for select to authenticated using (true);

create policy "Campaign members join"
  on public.campaign_members for insert to authenticated with check (auth.uid() = user_id);

create policy "Post drafts owned by author"
  on public.post_drafts for all to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);
