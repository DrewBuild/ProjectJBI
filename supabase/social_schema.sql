-- Just Bean It social/profile foundation.
-- Run this in Supabase SQL editor after the base profiles table exists.

alter table public.profiles
    add column if not exists profile_photo_url text,
    add column if not exists backdrop_photo_url text,
    add column if not exists backdrop_offset_x double precision default 0,
    add column if not exists backdrop_offset_y double precision default 0,
    add column if not exists backdrop_scale double precision default 1,
    add column if not exists is_private boolean default false;

create table if not exists public.follows (
    id uuid primary key default gen_random_uuid(),
    follower_id uuid not null references public.profiles(id) on delete cascade,
    following_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique (follower_id, following_id),
    constraint follows_no_self_follow check (follower_id <> following_id)
);

create table if not exists public.follow_requests (
    id uuid primary key default gen_random_uuid(),
    requester_id uuid not null references public.profiles(id) on delete cascade,
    target_user_id uuid not null references public.profiles(id) on delete cascade,
    status text not null default 'pending',
    created_at timestamptz not null default now(),
    unique (requester_id, target_user_id),
    constraint follow_requests_status_check check (status in ('pending', 'accepted', 'declined'))
);

alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.follow_requests enable row level security;

drop policy if exists "Profiles are readable by authenticated users" on public.profiles;
create policy "Profiles are readable by authenticated users"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Follows are readable by authenticated users" on public.follows;
create policy "Follows are readable by authenticated users"
on public.follows for select
to authenticated
using (true);

drop policy if exists "Users can follow as themselves" on public.follows;
create policy "Users can follow as themselves"
on public.follows for insert
to authenticated
with check (auth.uid() = follower_id);

drop policy if exists "Users can delete their own follows" on public.follows;
create policy "Users can delete their own follows"
on public.follows for delete
to authenticated
using (auth.uid() = follower_id);

drop policy if exists "Follow requests are readable by involved users" on public.follow_requests;
create policy "Follow requests are readable by involved users"
on public.follow_requests for select
to authenticated
using (auth.uid() = requester_id or auth.uid() = target_user_id);

drop policy if exists "Users can request follows as themselves" on public.follow_requests;
create policy "Users can request follows as themselves"
on public.follow_requests for insert
to authenticated
with check (auth.uid() = requester_id);

drop policy if exists "Users can update requests targeted to them" on public.follow_requests;
create policy "Users can update requests targeted to them"
on public.follow_requests for update
to authenticated
using (auth.uid() = target_user_id)
with check (auth.uid() = target_user_id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

insert into storage.buckets (id, name, public)
values ('backdrops', 'backdrops', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Public avatar reads" on storage.objects;
create policy "Public avatar reads"
on storage.objects for select
to public
using (bucket_id = 'avatars');

drop policy if exists "Users manage own avatar folder" on storage.objects;
create policy "Users manage own avatar folder"
on storage.objects for all
to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Public backdrop reads" on storage.objects;
create policy "Public backdrop reads"
on storage.objects for select
to public
using (bucket_id = 'backdrops');

drop policy if exists "Users manage own backdrop folder" on storage.objects;
create policy "Users manage own backdrop folder"
on storage.objects for all
to authenticated
using (bucket_id = 'backdrops' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'backdrops' and (storage.foldername(name))[1] = auth.uid()::text);

-- App storage paths:
-- avatars/{userId}/profile.jpg
-- backdrops/{userId}/backdrop.jpg
-- The iOS client compresses selected images before upload and stores public URLs on profiles.
