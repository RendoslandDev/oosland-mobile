-- Creator monetization: monthly likes -> proportional financial aid payout

-- Cumulative likes earned on a creator's posts, bucketed by the month the
-- like was given (the "monthly like volume").
create or replace view public.creator_monthly_likes as
select
  p.author_id as user_id,
  date_trunc('month', pl.created_at)::date as month,
  count(*) as like_count
from public.post_likes pl
join public.posts p on p.id = pl.post_id
group by p.author_id, date_trunc('month', pl.created_at);

create table public.monthly_payouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  month date not null,
  like_count int not null default 0,
  pool_cents int not null default 0,
  payout_cents int not null default 0,
  computed_at timestamptz not null default now(),
  unique (user_id, month)
);

-- Proportional fund share:
--   payout = pool * (creator_likes / total_likes_that_month)
-- Pool is taken from the month's challenge prize_pool_cents (0 if none).
-- Idempotent: re-running recomputes and upserts the month's rows.
create or replace function public.compute_monthly_payouts(
  p_month date default date_trunc('month', now())::date
)
returns setof public.monthly_payouts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pool int;
  v_total bigint;
begin
  select coalesce(prize_pool_cents, 0) into v_pool
  from monthly_challenges
  where month = p_month;
  v_pool := coalesce(v_pool, 0);

  select coalesce(sum(like_count), 0) into v_total
  from creator_monthly_likes
  where month = p_month;

  insert into monthly_payouts
    (user_id, month, like_count, pool_cents, payout_cents, computed_at)
  select
    cml.user_id,
    p_month,
    cml.like_count,
    v_pool,
    case
      when v_total > 0
        then floor(v_pool::numeric * cml.like_count / v_total)::int
      else 0
    end,
    now()
  from creator_monthly_likes cml
  where cml.month = p_month
  on conflict (user_id, month) do update set
    like_count = excluded.like_count,
    pool_cents = excluded.pool_cents,
    payout_cents = excluded.payout_cents,
    computed_at = now();

  return query
    select * from monthly_payouts where month = p_month;
end;
$$;

-- Allow gifts to be attributed to a chat room (gifting inside chats).
alter table public.gifts
  add column if not exists room_id uuid references public.chat_rooms (id) on delete set null;

alter table public.monthly_payouts enable row level security;

create policy "Payouts viewable by owner"
  on public.monthly_payouts for select to authenticated using (auth.uid() = user_id);
