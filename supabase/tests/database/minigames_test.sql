-- ============================================================================
-- Integration tests: minigames infrastructure (202609030001)
-- ============================================================================
-- Proves the properties the games depend on and that can't be checked by
-- reading the SQL: the answer is unreachable from a client, attempts resume
-- instead of duplicating, moves are graded server-side, idempotency keys
-- don't cost a player a guess, and streaks move on the right day boundaries.
begin;
select plan(16);

create extension if not exists pgtap;

-- ----------------------------------------------------------------------------
-- Fixtures
-- ----------------------------------------------------------------------------
-- A parent (the handle_new_user trigger creates their profiles row), an
-- encryption key, and one puzzle of a fake type whose validator is defined
-- here - so the shared layer is tested independently of any real game.
insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '55555555-5555-5555-5555-555555555555',
  'authenticated', 'authenticated', 'minigames@test.curio.dev',
  crypt('test-password', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}'
);

insert into public.app_secrets (name, value)
values ('minigame_encryption_key', 'test-key-not-a-real-secret');

insert into public.daily_puzzles (id, puzzle_date, puzzle_type, public_config, encrypted_answer, published_at)
values (
  '66666666-6666-6666-6666-666666666666',
  current_date,
  'testgame',
  '{"tokens":["recommended","by","90%","of","dentists","surveyed"]}'::jsonb,
  pgp_sym_encrypt('{"target":"surveyed"}', 'test-key-not-a-real-secret'),
  now()
);

-- A future puzzle, to prove it stays hidden until its date.
insert into public.daily_puzzles (puzzle_date, puzzle_type, public_config, encrypted_answer, published_at)
values (
  current_date + 1, 'testgame', '{}'::jsonb,
  pgp_sym_encrypt('{"target":"tomorrow"}', 'test-key-not-a-real-secret'), now()
);

-- The validator contract submit_puzzle_move expects.
create function public.validate_testgame_move(p_attempt_id uuid, p_move_data jsonb, p_answer jsonb)
returns jsonb language plpgsql as $$
declare
  v_correct boolean;
begin
  v_correct := (p_move_data ->> 'token') = (p_answer ->> 'target');

  if v_correct then
    update public.puzzle_attempts
    set status = 'won', score = 100, completed_at = now()
    where id = p_attempt_id;
  end if;

  return jsonb_build_object('correct', v_correct, 'finished', v_correct);
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '55555555-5555-5555-5555-555555555555', 'role', 'authenticated')::text,
  true
);

insert into public.child_profiles (id, parent_id, name)
values ('77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555', 'Player');

-- ----------------------------------------------------------------------------
-- Reading a puzzle
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::int from public.get_daily_puzzle('testgame', current_date)),
  1,
  'get_daily_puzzle returns today''s puzzle'
);

select is(
  (select public_config -> 'tokens' ->> 5 from public.get_daily_puzzle('testgame', current_date)),
  'surveyed',
  'get_daily_puzzle exposes public_config'
);

select is(
  (select count(*)::int from public.get_daily_puzzle('testgame', current_date + 1)),
  0,
  'get_daily_puzzle hides a future-dated puzzle'
);

-- The puzzle table itself is not client-readable, so a column added to it
-- later is private by default rather than public by accident.
select throws_like(
  $$ select encrypted_answer from public.daily_puzzles limit 1 $$,
  '%permission denied for table daily_puzzles%',
  'authenticated cannot read the puzzle table directly'
);

-- The decrypt helper must be unreachable. Revoking only from PUBLIC would
-- leave this callable, because Supabase grants EXECUTE to authenticated by
-- name - which would hand out every answer in the game.
select throws_like(
  $$ select public.puzzle_answer('66666666-6666-6666-6666-666666666666') $$,
  '%permission denied for function puzzle_answer%',
  'authenticated cannot call the decrypt helper'
);

-- ----------------------------------------------------------------------------
-- Attempts
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::int from public.start_puzzle_attempt(
    '77777777-7777-7777-7777-777777777777',
    '66666666-6666-6666-6666-666666666666'
  )),
  1,
  'starting an attempt returns a row'
);

select public.start_puzzle_attempt(
  '77777777-7777-7777-7777-777777777777',
  '66666666-6666-6666-6666-666666666666'
);

select is(
  (select count(*)::int from public.puzzle_attempts),
  1,
  'starting twice resumes rather than creating a second attempt'
);

-- ----------------------------------------------------------------------------
-- Moves
-- ----------------------------------------------------------------------------
select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"token":"dentists"}'::jsonb, 'move-key-1'
  ) ->> 'correct'),
  'false',
  'a wrong move is graded incorrect'
);

select is(
  (select count(*)::int from public.puzzle_moves),
  1,
  'the move is logged'
);

select public.submit_puzzle_move(
  (select id from public.puzzle_attempts limit 1),
  '{"token":"dentists"}'::jsonb, 'move-key-1'
);

select is(
  (select count(*)::int from public.puzzle_moves),
  1,
  'replaying an idempotency key does not log or grade a second time'
);

select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"token":"surveyed"}'::jsonb, 'move-key-2'
  ) ->> 'correct'),
  'true',
  'the correct move validates against the decrypted answer'
);

select is(
  (select status from public.puzzle_attempts limit 1),
  'won',
  'the validator updated the attempt'
);

select throws_like(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"token":"surveyed"}'::jsonb, 'move-key-3'
     ) $$,
  '%is already won%',
  'a finished attempt takes no further moves'
);

-- ----------------------------------------------------------------------------
-- Streaks
-- ----------------------------------------------------------------------------
select is(
  (select current_count from public.record_puzzle_streak(
    '77777777-7777-7777-7777-777777777777', 'testgame', current_date - 1
  )),
  1,
  'the first qualifying day starts a streak'
);

select is(
  (select current_count from public.record_puzzle_streak(
    '77777777-7777-7777-7777-777777777777', 'testgame', current_date
  )),
  2,
  'a consecutive day extends the streak'
);

select is(
  (select current_count from public.record_puzzle_streak(
    '77777777-7777-7777-7777-777777777777', 'testgame', current_date + 3
  )),
  1,
  'a gap resets the streak'
);

-- ----------------------------------------------------------------------------
-- Signed-out access
-- ----------------------------------------------------------------------------
reset role;
set local role anon;

select throws_like(
  $$ select public.submit_puzzle_move(
       '00000000-0000-0000-0000-000000000000'::uuid, '{}'::jsonb, 'anon-key'
     ) $$,
  '%permission denied for function submit_puzzle_move%',
  'anon cannot submit moves'
);

reset role;

select * from finish();
rollback;
