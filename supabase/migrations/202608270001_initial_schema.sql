create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Explorer' check (char_length(name) between 1 and 18),
  total_xp integer not null default 360 check (total_xp >= 0),
  streak integer not null default 4 check (streak >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activity_completions (
  id bigint generated always as identity primary key,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  activity_id text not null,
  completed_at timestamptz not null default now(),
  unique (child_id, activity_id)
);

create table public.unlocked_discoveries (
  id bigint generated always as identity primary key,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  discovery_id text not null,
  unlocked_at timestamptz not null default now(),
  unique (child_id, discovery_id)
);

create table public.skill_progress (
  id bigint generated always as identity primary key,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  skill_key text not null,
  mastery double precision not null default 0 check (mastery between 0 and 1),
  updated_at timestamptz not null default now(),
  unique (child_id, skill_key)
);

create index child_profiles_parent_id_idx on public.child_profiles(parent_id);
create index activity_completions_child_id_idx on public.activity_completions(child_id);
create index unlocked_discoveries_child_id_idx on public.unlocked_discoveries(child_id);
create index skill_progress_child_id_idx on public.skill_progress(child_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)));
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.child_profiles enable row level security;
alter table public.activity_completions enable row level security;
alter table public.unlocked_discoveries enable row level security;
alter table public.skill_progress enable row level security;

create policy "Users can read their profile" on public.profiles
for select to authenticated using ((select auth.uid()) = id);
create policy "Users can update their profile" on public.profiles
for update to authenticated using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);
create policy "Parents can manage their children" on public.child_profiles
for all to authenticated using ((select auth.uid()) = parent_id)
with check ((select auth.uid()) = parent_id);

create policy "Parents can manage child activities" on public.activity_completions
for all to authenticated
using (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())))
with check (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())));
create policy "Parents can manage child discoveries" on public.unlocked_discoveries
for all to authenticated
using (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())))
with check (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())));
create policy "Parents can manage child skills" on public.skill_progress
for all to authenticated
using (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())))
with check (exists (select 1 from public.child_profiles c where c.id = child_id and c.parent_id = (select auth.uid())));

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles, public.child_profiles,
  public.activity_completions, public.unlocked_discoveries, public.skill_progress to authenticated;
grant usage, select on all sequences in schema public to authenticated;
