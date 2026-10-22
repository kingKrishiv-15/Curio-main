-- Memory and English rewards use the same server-owned, idempotent XP path.
begin;
create extension if not exists pgtap;
select plan(5);

insert into auth.users (
  id, aud, role, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data
) values (
  'a1220000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
  'daily-sections@test.curio.dev', now(), '{"provider":"email"}', '{}'
);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"a1220000-0000-0000-0000-000000000001","role":"authenticated"}', true);
insert into public.child_profiles (id, parent_id, name)
values ('a1220000-0000-0000-0000-000000000002', 'a1220000-0000-0000-0000-000000000001', 'Explorer');

select public.sync_learning_progress(
  'a1220000-0000-0000-0000-000000000002', 'Explorer',
  array[
    'memory_match_' || to_char(current_date, 'YYYYMMDD'),
    'memory_trail_' || to_char(current_date, 'YYYYMMDD'),
    'word_wise_' || to_char(current_date, 'YYYYMMDD'),
    'word_builder_' || to_char(current_date, 'YYYYMMDD')
  ]
);
select is((select total_xp from public.child_profiles where id = 'a1220000-0000-0000-0000-000000000002'), 320, 'four new games earn their canonical XP');
select is((select count(*)::integer from public.activity_completions where child_id = 'a1220000-0000-0000-0000-000000000002'), 4, 'all four game IDs are accepted');
select is((select count(*)::integer from public.unlocked_discoveries where child_id = 'a1220000-0000-0000-000000000002'), 4, 'all four discoveries unlock');
select is((select count(*)::integer from public.skill_progress where child_id = 'a1220000-0000-0000-000000000002' and skill_key in ('Memory', 'English') and mastery between .239 and .241), 2, 'both new skills grow');

select public.sync_learning_progress(
  'a1220000-0000-0000-0000-000000000002', 'Explorer',
  array['memory_match_' || to_char(current_date, 'YYYYMMDD'), 'word_wise_' || to_char(current_date, 'YYYYMMDD')]
);
select is((select total_xp from public.child_profiles where id = 'a1220000-0000-0000-0000-000000000002'), 320, 'repeated sync never awards XP twice');
select * from finish();
rollback;
