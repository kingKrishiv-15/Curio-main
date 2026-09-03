-- ============================================================================
-- Integration test: parent-onboarding RPC atomicity
-- ============================================================================
-- Run locally with `supabase test db` (spins up a fresh local Postgres,
-- applies every migration, then runs every file in supabase/tests/database
-- with pg_prove). Also run in CI on every push - see .github/workflows/ci.yml.
--
-- This is the "real integration test, not just manual clicking" required by
-- the Phase 0 brief: it proves create_parent_profile() actually rolls back
-- the profile insert when the consent insert fails partway through, by
-- deterministically forcing that failure with a trigger rather than hoping
-- to hit it by accident.
begin;
select plan(9);

create extension if not exists pgtap;

-- ----------------------------------------------------------------------------
-- Fixtures: two fake auth.users rows to act as test parents. Mirrors the
-- columns Supabase Auth (GoTrue) actually requires for a usable user row.
-- ----------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at,
  created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111111',
    'authenticated', 'authenticated', 'happy-path@test.curio.dev',
    crypt('test-password', gen_salt('bf')), now(),
    now(), now(),
    '{"provider":"email","providers":["email"]}', '{}'
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '22222222-2222-2222-2222-222222222222',
    'authenticated', 'authenticated', 'rollback@test.curio.dev',
    crypt('test-password', gen_salt('bf')), now(),
    now(), now(),
    '{"provider":"email","providers":["email"]}', '{}'
  );

-- A trigger that fails ONLY for a magic consent_type value, so the rollback
-- test below can force a failure partway through create_parent_profile()
-- deterministically instead of relying on an incidental constraint clash.
create function test_force_consent_failure() returns trigger
language plpgsql as $$
begin
  if new.consent_type = '__force_failure__' then
    raise exception 'simulated failure for rollback test';
  end if;
  return new;
end;
$$;

create trigger force_failure_trigger
  before insert on public.consent_record
  for each row execute function test_force_consent_failure();

-- ----------------------------------------------------------------------------
-- Happy path: profile + consent_record are both created, atomically.
-- ----------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated')::text,
  true
);
set local role authenticated;

select public.create_parent_profile('Happy Parent', 'en', 'privacy_policy', 'v1');

select is(
  (select count(*)::int from public.profile where id = '11111111-1111-1111-1111-111111111111'),
  1,
  'happy path: profile row was created'
);
select is(
  (select count(*)::int from public.consent_record where parent_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'happy path: consent_record row was created'
);
select is(
  (select role from public.profile where id = '11111111-1111-1111-1111-111111111111'),
  'parent',
  'happy path: profile role is parent'
);

reset role;

-- ----------------------------------------------------------------------------
-- Rollback: the consent insert fails partway through, so the profile insert
-- that already happened earlier in the same function call must be undone
-- too - a profile must never be left behind without its consent record.
-- ----------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text,
  true
);
set local role authenticated;

select throws_ok(
  $$ select public.create_parent_profile('Rollback Parent', 'en', '__force_failure__', 'v1') $$,
  'simulated failure for rollback test',
  'create_parent_profile raises when the consent insert fails'
);

reset role;

select is(
  (select count(*)::int from public.profile where id = '22222222-2222-2222-2222-222222222222'),
  0,
  'rollback: the profile row was NOT left behind after the consent insert failed'
);
select is(
  (select count(*)::int from public.consent_record where parent_id = '22222222-2222-2222-2222-222222222222'),
  0,
  'rollback: no consent_record row was created either'
);

-- ----------------------------------------------------------------------------
-- add_child_profile: happy path creates baseline child_skill rows for every
-- active skill, atomically, as the signed-in parent from the happy path above.
-- ----------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated')::text,
  true
);
set local role authenticated;

select public.add_child_profile('Test Child', 'fox', '8-10', 'en');

select is(
  (select count(*)::int from public.child where parent_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'add_child_profile: child row was created'
);
select is(
  (
    select count(*)::int from public.child_skill
    where child_id = (select id from public.child where parent_id = '11111111-1111-1111-1111-111111111111')
  ),
  (select count(*)::int from public.skill where active = true),
  'add_child_profile: one child_skill row per active skill was created'
);

-- ----------------------------------------------------------------------------
-- Client-side column protection: authenticated cannot set score/xp_awarded
-- directly, even on a row it otherwise owns (see 0001_initial_schema.sql's
-- "Server-authoritative columns" note).
-- ----------------------------------------------------------------------------
select throws_like(
  $$
    insert into public.learning_session (child_id, activity_version_id, idempotency_key, score)
    values (
      (select id from public.child where parent_id = '11111111-1111-1111-1111-111111111111'),
      gen_random_uuid(),
      'test-idempotency-key-1',
      100
    )
  $$,
  -- Reported at table granularity: with only column-level grants held, the
  -- table-level check fails first. Access is denied either way.
  '%permission denied for table learning_session%',
  'authenticated cannot insert learning_session.score directly'
);

reset role;

select * from finish();
rollback;
