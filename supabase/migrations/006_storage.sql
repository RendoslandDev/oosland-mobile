-- Storage buckets and policies

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('posts', 'posts', true),
  ('folder-items', 'folder-items', true)
on conflict (id) do nothing;

create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Post media publicly accessible"
  on storage.objects for select
  using (bucket_id = 'posts');

create policy "Users can upload own post media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'posts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Folder items publicly accessible"
  on storage.objects for select
  using (bucket_id = 'folder-items');

create policy "Users can upload own folder items"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'folder-items'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
