-- Aesthetic chat rooms + realtime messaging

create table public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  group_id uuid references public.groups (id) on delete set null,
  challenge_id uuid references public.monthly_challenges (id) on delete set null,
  name text not null,
  description text default '',
  cover_url text,
  created_at timestamptz not null default now()
);

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  parent_id uuid references public.chat_messages (id) on delete cascade,  -- threaded replies / comments
  body text not null,
  created_at timestamptz not null default now()
);

-- Engagement loop: messages can be liked (mirrors post_likes).
create table public.chat_message_likes (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create or replace view public.chat_message_stats as
select
  m.id as message_id,
  count(distinct ml.user_id) as like_count,
  count(distinct r.id) as reply_count
from public.chat_messages m
left join public.chat_message_likes ml on ml.message_id = m.id
left join public.chat_messages r on r.parent_id = m.id
group by m.id;

-- Realtime: stream new messages + likes to subscribed clients.
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.chat_message_likes;

alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_message_likes enable row level security;

create policy "Chat rooms viewable"
  on public.chat_rooms for select to authenticated using (true);

create policy "Chat rooms creatable by owner"
  on public.chat_rooms for insert to authenticated with check (auth.uid() = owner_id);

create policy "Chat rooms updatable by owner"
  on public.chat_rooms for update to authenticated using (auth.uid() = owner_id);

create policy "Chat messages viewable"
  on public.chat_messages for select to authenticated using (true);

create policy "Chat messages insertable by author"
  on public.chat_messages for insert to authenticated with check (auth.uid() = user_id);

create policy "Chat messages deletable by author"
  on public.chat_messages for delete to authenticated using (auth.uid() = user_id);

create policy "Message likes viewable"
  on public.chat_message_likes for select to authenticated using (true);

create policy "Message likes insertable"
  on public.chat_message_likes for insert to authenticated with check (auth.uid() = user_id);

create policy "Message likes deletable by user"
  on public.chat_message_likes for delete to authenticated using (auth.uid() = user_id);
