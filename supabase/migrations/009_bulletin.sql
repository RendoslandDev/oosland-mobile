-- Bulletin Space: photo review board inside a chat room

create table public.bulletin_photos (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.chat_rooms (id) on delete cascade,
  challenge_id uuid references public.monthly_challenges (id) on delete set null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  image_url text not null,
  caption text default '',
  created_at timestamptz not null default now()
);

create table public.bulletin_reviews (
  id uuid primary key default gen_random_uuid(),
  photo_id uuid not null references public.bulletin_photos (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.bulletin_photo_likes (
  photo_id uuid not null references public.bulletin_photos (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (photo_id, user_id)
);

create or replace view public.bulletin_photo_stats as
select
  bp.id as photo_id,
  count(distinct bpl.user_id) as like_count,
  count(distinct br.id) as review_count
from public.bulletin_photos bp
left join public.bulletin_photo_likes bpl on bpl.photo_id = bp.id
left join public.bulletin_reviews br on br.photo_id = bp.id
group by bp.id;

-- Storage bucket for bulletin uploads.
insert into storage.buckets (id, name, public)
values ('bulletin', 'bulletin', true)
on conflict (id) do nothing;

alter table public.bulletin_photos enable row level security;
alter table public.bulletin_reviews enable row level security;
alter table public.bulletin_photo_likes enable row level security;

create policy "Bulletin photos viewable"
  on public.bulletin_photos for select to authenticated using (true);

create policy "Bulletin photos insertable by author"
  on public.bulletin_photos for insert to authenticated with check (auth.uid() = user_id);

create policy "Bulletin photos deletable by author"
  on public.bulletin_photos for delete to authenticated using (auth.uid() = user_id);

create policy "Bulletin reviews viewable"
  on public.bulletin_reviews for select to authenticated using (true);

create policy "Bulletin reviews insertable by author"
  on public.bulletin_reviews for insert to authenticated with check (auth.uid() = user_id);

create policy "Bulletin photo likes viewable"
  on public.bulletin_photo_likes for select to authenticated using (true);

create policy "Bulletin photo likes insertable"
  on public.bulletin_photo_likes for insert to authenticated with check (auth.uid() = user_id);

create policy "Bulletin photo likes deletable by user"
  on public.bulletin_photo_likes for delete to authenticated using (auth.uid() = user_id);

create policy "Bulletin media publicly accessible"
  on storage.objects for select
  using (bucket_id = 'bulletin');

create policy "Users can upload own bulletin media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'bulletin'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
