-- Posts (two-phase required) and social interactions

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  campaign_id uuid references public.campaigns (id) on delete set null,
  group_id uuid references public.groups (id) on delete set null,
  title text not null default '',
  caption text default '',
  clothes_image_url text not null,
  walk_video_url text not null,
  walk_thumbnail_url text,
  aspect_ratio text not null default '9:16',
  is_starter_post boolean not null default false,
  created_at timestamptz not null default now(),
  constraint posts_two_phase_required check (
    clothes_image_url is not null and walk_video_url is not null
  )
);

create table public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.post_reposts (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create or replace view public.post_stats as
select
  p.id as post_id,
  count(distinct pl.user_id) as like_count,
  count(distinct pr.user_id) as repost_count,
  count(distinct pc.id) as comment_count
from public.posts p
left join public.post_likes pl on pl.post_id = p.id
left join public.post_reposts pr on pr.post_id = p.id
left join public.post_comments pc on pc.post_id = p.id
group by p.id;

alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_reposts enable row level security;

create policy "Posts viewable by authenticated"
  on public.posts for select to authenticated using (true);

create policy "Posts insertable by author"
  on public.posts for insert to authenticated with check (auth.uid() = author_id);

create policy "Post likes viewable"
  on public.post_likes for select to authenticated using (true);

create policy "Post likes insertable"
  on public.post_likes for insert to authenticated with check (auth.uid() = user_id);

create policy "Post likes deletable by user"
  on public.post_likes for delete to authenticated using (auth.uid() = user_id);

create policy "Post comments viewable"
  on public.post_comments for select to authenticated using (true);

create policy "Post comments insertable"
  on public.post_comments for insert to authenticated with check (auth.uid() = user_id);

create policy "Post reposts viewable"
  on public.post_reposts for select to authenticated using (true);

create policy "Post reposts insertable"
  on public.post_reposts for insert to authenticated with check (auth.uid() = user_id);

create policy "Post reposts deletable"
  on public.post_reposts for delete to authenticated using (auth.uid() = user_id);

-- Update campaign member score on like
create or replace function public.update_campaign_score_on_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_campaign_id uuid;
begin
  select campaign_id into v_campaign_id from posts where id = new.post_id;
  if v_campaign_id is not null then
    update campaign_members cm
    set score = (
      select count(*) from post_likes pl
      join posts p on p.id = pl.post_id
      where p.campaign_id = v_campaign_id and p.author_id = cm.user_id
    )
    where cm.campaign_id = v_campaign_id
      and cm.user_id = (select author_id from posts where id = new.post_id);
  end if;
  return new;
end;
$$;

create trigger on_post_like_update_score
  after insert on public.post_likes
  for each row execute function public.update_campaign_score_on_like();
