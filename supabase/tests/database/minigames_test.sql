-- ============================================================================
-- Integration tests: minigames shared infrastructure (migration 0002)
-- ============================================================================
-- Covers the plumbing every one of the five games depends on: puzzle
-- fetching hides the answer, attempts start/resume idempotently, move
-- submission dispatches per puzzle_type and is idempotent, and streaks
-- extend/reset on the right day boundaries.
begin;
select plan(17);

create extension if not exists pgtap;

-- ----------------------------------------------------------------------------
-- Fixtures: a parent, a child, an encryption key, and one puzzle of a fake
-- game type with a validator we define here (so the shared layer is tested
-- independently of any real game's rules).
-- ----------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '33333333-3333-3333-3333-333333333333',
  'authenticated', 'authenticated', 'minigames@test.curio.dev',
  crypt('test-password', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}'
);

insert into public.app_secret (name, value) values ('minigame_encryption_key', 'test-key-not-a-real-secret');

-- A "testgame" puzzle whose answer is only in encrypted_answer.
insert into public.daily_puzzle (id, puzzle_date, puzzle_type, encrypted_answer, public_config, published_at)
values (
  '44444444-4444-4444-4444-444444444444',
  current_date,
  'testgame',
  pgp_sym_encrypt('{"target":"surveyed"}', 'test-key-not-a-real-secret'),
  '{"tokens":["recommended","by","90%","of","dentists","surveyed"]}'::jsonb,
  now()
);

-- A validator for the fake game, matching the contract submit_minigame_move
-- expects: (attempt_id, move_data, answer) -> jsonb outcome, and it owns
-- updating the attempt.
create function public.validate_testgame_move(p_attempt_id uuid, p_move_data jsonb, p_answer jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_correct boolean;
begin
  v_correct := (p_move_data ->> 'token') = (p_answer ->> 'target');

  if v_correct then
    update public.minigame_attempt
    set status = 'won', score = 100, completed_at = now()
    where id = p_attempt_id;
  end if;

  return jsonb_build_object('correct', v_correct);
end;
$$;

-- Sign in as the parent and set up their profile + child through the real
-- onboarding RPCs, so this test exercises the same path the app uses.
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text,
  true
);
set local role authenticated;

select public.create_parent_profile('Minigames Parent', 'en', 'privacy_policy', 'v1');
select public.add_child_profile('Player', 'fox', '11-14', 'en');

-- ----------------------------------------------------------------------------
-- get_minigame_puzzle: returns the playable half, never the answer
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::int from public.get_minigame_puzzle('testgame', current_date)),
  1,
  'get_minigame_puzzle returns today''s puzzle for that type'
);

select is(
  (select public_config -> 'tokens' ->> 0 from public.get_minigame_puzzle('testgame', current_date)),
  'recommended',
  'get_minigame_puzzle exposes public_config'
);

select is(
  (select count(*)::int from public.get_minigame_puzzle('testgame', current_date + 1)),
  0,
  'get_minigame_puzzle will not return a future-dated puzzle'
);

-- The answer column is unreadable to this role no matter how it's asked for
-- (this is 0001's column grant doing the work, re-checked here because the
-- whole minigame design leans on it).
-- Postgres reports this at table granularity, not column: when a role holds
-- only column-level grants (0001 revokes the table-level SELECT and re-grants
-- the safe columns), asking for an ungranted column fails the table check
-- first. The protection is the same either way - and tests 1-2 above prove
-- the safe columns are still readable, so this is a carve-out, not a lockout.
select throws_like(
  $$ select encrypted_answer from public.daily_puzzle limit 1 $$,
  '%permission denied for table daily_puzzle%',
  'authenticated cannot read encrypted_answer directly'
);

select throws_like(
  $$ select public.minigame_answer('44444444-4444-4444-4444-444444444444') $$,
  '%permission denied for function minigame_answer%',
  'authenticated cannot call the internal decrypt helper'
);

-- ----------------------------------------------------------------------------
-- start_or_resume_minigame_attempt
-- ----------------------------------------------------------------------------
select is(
  (
    select count(*)::int from public.start_or_resume_minigame_attempt(
      (select id from public.child limit 1),
      '44444444-4444-4444-4444-444444444444'
    )
  ),
  1,
  'starting an attempt returns a row'
);

select is(
  (select count(*)::int from public.minigame_attempt),
  1,
  'starting an attempt creates exactly one attempt'
);

-- Calling again must resume, not create a second attempt.
select public.start_or_resume_minigame_attempt(
  (select id from public.child limit 1),
  '44444444-4444-4444-4444-444444444444'
);

select is(
  (select count(*)::int from public.minigame_attempt),
  1,
  'resuming does not create a second attempt'
);

-- ----------------------------------------------------------------------------
-- submit_minigame_move
-- ----------------------------------------------------------------------------
select is(
  (
    select public.submit_minigame_move(
      (select id from public.minigame_attempt limit 1),
      '{"token":"dentists"}'::jsonb,
      'test-move-key-1'
    ) ->> 'correct'
  ),
  'false',
  'a wrong move comes back incorrect'
);

select is(
  (select count(*)::int from public.minigame_move),
  1,
  'a move is logged'
);

-- Replaying the same idempotency key must not log a second move.
select public.submit_minigame_move(
  (select id from public.minigame_attempt limit 1),
  '{"token":"dentists"}'::jsonb,
  'test-move-key-1'
);

select is(
  (select count(*)::int from public.minigame_move),
  1,
  'replaying an idempotency key does not log a second move'
);

select is(
  (
    select public.submit_minigame_move(
      (select id from public.minigame_attempt limit 1),
      '{"token":"surveyed"}'::jsonb,
      'test-move-key-2'
    ) ->> 'correct'
  ),
  'true',
  'the correct move validates against the decrypted answer'
);

select is(
  (select status from public.minigame_attempt limit 1),
  'won',
  'the validator updated the attempt status'
);

-- A finished attempt takes no further moves.
select throws_like(
  $$ select public.submit_minigame_move(
       (select id from public.minigame_attempt limit 1),
       '{"token":"surveyed"}'::jsonb,
       'test-move-key-3'
     ) $$,
  '%is already won%',
  'a finished attempt rejects further moves'
);

-- ----------------------------------------------------------------------------
-- record_minigame_streak
-- ----------------------------------------------------------------------------
select is(
  (select current_count from public.record_minigame_streak((select id from public.child limit 1), 'testgame', current_date - 1)),
  1,
  'first qualifying day starts a streak at 1'
);

select is(
  (select current_count from public.record_minigame_streak((select id from public.child limit 1), 'testgame', current_date)),
  2,
  'a consecutive day extends the streak'
);

-- ----------------------------------------------------------------------------
-- The signed-out role gets nothing
-- ----------------------------------------------------------------------------
-- Supabase grants EXECUTE on new functions to anon explicitly, so this only
-- holds because 0002 revokes from anon by name rather than just from PUBLIC.
reset role;
set local role anon;

select throws_like(
  $$ select public.submit_minigame_move(
       '00000000-0000-0000-0000-000000000000'::uuid, '{}'::jsonb, 'anon-key'
     ) $$,
  '%permission denied for function submit_minigame_move%',
  'anon cannot submit moves at all'
);

reset role;

select * from finish();
rollback;
