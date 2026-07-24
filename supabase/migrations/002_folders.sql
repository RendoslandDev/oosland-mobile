-- Folders

create table public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  description text default '',
  cover_url text,
  created_at timestamptz not null default now()
);

create table public.folder_items (
  id uuid primary key default gen_random_uuid(),
  folder_id uuid not null references public.folders (id) on delete cascade,
  image_url text not null,
  caption text default '',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.folders enable row level security;
alter table public.folder_items enable row level security;

create policy "Folders viewable by owner"
  on public.folders for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Folders insertable by owner"
  on public.folders for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Folders updatable by owner"
  on public.folders for update
  to authenticated
  using (auth.uid() = user_id);

create policy "Folders deletable by owner"
  on public.folders for delete
  to authenticated
  using (auth.uid() = user_id);

create policy "Folder items viewable by folder owner"
  on public.folder_items for select
  to authenticated
  using (
    exists (
      select 1 from public.folders f
      where f.id = folder_id and f.user_id = auth.uid()
    )
  );

create policy "Folder items insertable by folder owner"
  on public.folder_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.folders f
      where f.id = folder_id and f.user_id = auth.uid()
    )
  );

create policy "Folder items updatable by folder owner"
  on public.folder_items for update
  to authenticated
  using (
    exists (
      select 1 from public.folders f
      where f.id = folder_id and f.user_id = auth.uid()
    )
  );

create policy "Folder items deletable by folder owner"
  on public.folder_items for delete
  to authenticated
  using (
    exists (
      select 1 from public.folders f
      where f.id = folder_id and f.user_id = auth.uid()
    )
  );
