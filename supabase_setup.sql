-- UsTwo Supabase setup
-- Run this entire script in Supabase Dashboard > SQL Editor > New query.
-- In Authentication > Providers, enable Anonymous Sign-Ins.
-- Create a PRIVATE Storage bucket named: couple-private

create extension if not exists pgcrypto;

create table if not exists public.couple_rooms (
  id uuid primary key default gen_random_uuid(),
  invite_code text not null unique,
  created_at timestamptz not null default now()
);
create table if not exists public.couple_members (
  room_id uuid not null references public.couple_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Partner',
  joined_at timestamptz not null default now(),
  primary key(room_id,user_id),
  unique(user_id,room_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.couple_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null default 'Partner',
  body text not null,
  kind text not null default 'text' check(kind in ('text','audio')),
  created_at timestamptz not null default now()
);
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.couple_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  caption text not null default '',
  file_path text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.daily_answers (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.couple_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  question text not null,
  answer text not null,
  answer_date date not null default current_date,
  created_at timestamptz not null default now(),
  unique(room_id,user_id,answer_date)
);

create or replace function public.is_room_member(p_room uuid)
returns boolean language sql security definer stable set search_path=public
as $$ select exists(select 1 from public.couple_members m where m.room_id=p_room and m.user_id=auth.uid()); $$;
revoke all on function public.is_room_member(uuid) from public;
grant execute on function public.is_room_member(uuid) to authenticated;

create or replace function public.create_couple_room(p_code text,p_name text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare new_room uuid; clean_code text;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 clean_code := upper(regexp_replace(trim(p_code),'[^A-Z0-9_-]','','g'));
 if length(clean_code)<4 or length(clean_code)>24 then raise exception 'Room code must be 4–24 characters'; end if;
 if exists(select 1 from public.couple_members where user_id=auth.uid()) then
   raise exception 'This account already belongs to a room';
 end if;
 insert into public.couple_rooms(invite_code) values(clean_code) returning id into new_room;
 insert into public.couple_members(room_id,user_id,display_name) values(new_room,auth.uid(),left(coalesce(nullif(trim(p_name),''),'Partner'),40));
 return new_room;
end; $$;

create or replace function public.join_couple_room(p_code text,p_name text)
returns uuid language plpgsql security definer set search_path=public
as $$
declare target_room uuid; member_count int;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 select id into target_room from public.couple_rooms where invite_code=upper(trim(p_code));
 if target_room is null then raise exception 'Invite code not found'; end if;
 if exists(select 1 from public.couple_members where room_id=target_room and user_id=auth.uid()) then return target_room; end if;
 select count(*) into member_count from public.couple_members where room_id=target_room;
 if member_count>=2 then raise exception 'This room already has two members'; end if;
 if exists(select 1 from public.couple_members where user_id=auth.uid()) then raise exception 'This account already belongs to a room'; end if;
 insert into public.couple_members(room_id,user_id,display_name) values(target_room,auth.uid(),left(coalesce(nullif(trim(p_name),''),'Partner'),40));
 return target_room;
end; $$;
revoke all on function public.create_couple_room(text,text) from public;
revoke all on function public.join_couple_room(text,text) from public;
grant execute on function public.create_couple_room(text,text) to authenticated;
grant execute on function public.join_couple_room(text,text) to authenticated;

alter table public.couple_rooms enable row level security;
alter table public.couple_members enable row level security;
alter table public.messages enable row level security;
alter table public.memories enable row level security;
alter table public.daily_answers enable row level security;

create policy "members can view own room" on public.couple_rooms for select to authenticated using (public.is_room_member(id));
create policy "members can view room members" on public.couple_members for select to authenticated using (public.is_room_member(room_id));
create policy "members can read messages" on public.messages for select to authenticated using (public.is_room_member(room_id));
create policy "members can send messages as self" on public.messages for insert to authenticated with check (public.is_room_member(room_id) and user_id=auth.uid());
create policy "members can read memories" on public.memories for select to authenticated using (public.is_room_member(room_id));
create policy "members can add memories as self" on public.memories for insert to authenticated with check (public.is_room_member(room_id) and user_id=auth.uid());
create policy "members can read daily answers" on public.daily_answers for select to authenticated using (public.is_room_member(room_id));
create policy "members can add own answers" on public.daily_answers for insert to authenticated with check (public.is_room_member(room_id) and user_id=auth.uid());
create policy "members can update own daily answers" on public.daily_answers for update to authenticated using (public.is_room_member(room_id) and user_id=auth.uid()) with check (public.is_room_member(room_id) and user_id=auth.uid());

-- Private bucket. Create it in Storage UI as a PRIVATE bucket called couple-private.
insert into storage.buckets(id,name,public) values('couple-private','couple-private',false)
on conflict(id) do update set public=false;

create policy "room members can upload their files" on storage.objects for insert to authenticated
with check (bucket_id='couple-private' and public.is_room_member(((storage.foldername(name))[1])::uuid));
create policy "room members can view room files" on storage.objects for select to authenticated
using (bucket_id='couple-private' and public.is_room_member(((storage.foldername(name))[1])::uuid));

-- Enable realtime for messages if not already included.
do $$ begin
 alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
