-- Profiles and auth trigger

create type user_role as enum ('stylist', 'model', 'designer', 'gifter', 'fan');
create type user_tier as enum ('standard', 'pre_celeb', 'celebrity');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  username text unique not null,
  bio text default '',
  avatar_url text,
  role user_role not null default 'fan',
  tier user_tier not null default 'standard',
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', 'User'),
    coalesce(
      new.raw_user_meta_data ->> 'username',
      'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

create policy "Profiles are viewable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);
