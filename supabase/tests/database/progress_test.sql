-- ============================================================================
-- Integration tests: progress sync and launch hardening (202610080001)
-- ============================================================================
-- Proves that every game the app ships earns its reward on the server, that
-- streak discoveries unlock, that dates are bounded, that fresh learners
-- start at zero, and that server-only functions refuse signed-in callers.
begin;
select plan(11);

create extension if not exists pgtap;

insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '88888888-8888-8888-8888-888888888888',
  'authenticated', 'authenticated', 'progress@test.curio.dev',
  crypt('test-password', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '88888888-8888-8888-8888-888888888888', 'role', 'authenticated')::text,
  true
);

-- Created three days ago, so a three-day streak is a legitimate history.
insert into public.child_profiles (id, parent_id, name)
values ('99999999-9999-9999-9999-999999999999', '88888888-8888-8888-8888-888888888888', 'Tester');
reset role;
update public.child_profiles set created_at = now() - interval '3 days'
where id = '99999999-9999-9999-9999-999999999999';
set local role authenticated;

select is(
  (select total_xp from public.child_profiles where id = '99999999-9999-9999-9999-999999999999'),
  0,
  'a new learner starts at 0 XP, not demo numbers'
);

select lives_ok(
  format(
    $$ select public.sync_learning_progress(
      '99999999-9999-9999-9999-999999999999', 'Tester',
      array['odd_cluster_%1$s', 'sequence_%1$s', 'bridge_%1$s', 'cascade_%1$s', 'loophole_%1$s',
            'squeeze_%2$s', 'squeeze_%3$s',
            'squeeze_20200101', 'not_a_game_%1$s', 'frostlands_night_1']
    ) $$,
    to_char(current_date, 'YYYYMMDD'),
    to_char(current_date - 1, 'YYYYMMDD'),
    to_char(current_date - 2, 'YYYYMMDD')
  ),
  'syncing a mix of new, old, back-dated and unknown activities succeeds'
);

select is(
  (select count(*)::integer from public.activity_completions
   where child_id = '99999999-9999-9999-9999-999999999999'),
  8,
  'the five new games, two squeeze days and the story are stored; junk is not'
);

select is(
  (select total_xp from public.child_profiles where id = '99999999-9999-9999-9999-999999999999'),
  100 + 80 + 80 + 90 + 70 + 80 * 2 + 50,
  'XP comes from the reward catalogue for every stored activity'
);

select ok(
  (select bool_and(d in (select discovery_id from public.unlocked_discoveries
     where child_id = '99999999-9999-9999-9999-999999999999'))
   from unnest(array['giant_rings', 'triangular_numbers', 'order_matters',
     'traffic_evaporation', 'sample_size']) d),
  'each new game unlocks its discovery'
);

select ok(
  exists (select 1 from public.unlocked_discoveries
    where child_id = '99999999-9999-9999-9999-999999999999' and discovery_id = 'octopus_hearts'),
  'a three-day run unlocks the first streak discovery'
);

select ok(
  not exists (select 1 from public.unlocked_discoveries
    where child_id = '99999999-9999-9999-9999-999999999999' and discovery_id = 'shortest_war'),
  'the seven-day discovery waits for seven days'
);

select is(
  (select streak from public.child_profiles where id = '99999999-9999-9999-9999-999999999999'),
  3,
  'the streak is recomputed from the stored days'
);

select lives_ok(
  format(
    $$ select public.sync_learning_progress(
      '99999999-9999-9999-9999-999999999999', 'Tester', array['odd_cluster_%s']) $$,
    to_char(current_date, 'YYYYMMDD')
  ),
  'syncing the same activity again is harmless'
);

select is(
  (select total_xp from public.child_profiles where id = '99999999-9999-9999-9999-999999999999'),
  100 + 80 + 80 + 90 + 70 + 80 * 2 + 50,
  'a repeated sync awards nothing twice'
);

select throws_ok(
  'select * from public.claim_parent_emails()',
  '42501',
  null,
  'signed-in users cannot claim the email outbox'
);

reset role;
select * from finish();
rollback;
