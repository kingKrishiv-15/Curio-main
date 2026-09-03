-- ============================================================================
-- Integration tests: Loophole validation (202609030002)
-- ============================================================================
-- The rules that matter here are the ones a player could otherwise exploit or
-- be cheated by: two guesses per statement, no explanation leaking before a
-- round is over, scoring that reflects how fast they found it, and a status
-- that only says "won" for a clean sheet.
begin;
select plan(14);

create extension if not exists pgtap;

insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '88888888-8888-8888-8888-888888888888',
  'authenticated', 'authenticated', 'loophole@test.curio.dev',
  crypt('test-password', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}'
);

insert into public.app_secrets (name, value)
values ('minigame_encryption_key', 'test-key-not-a-real-secret')
on conflict (name) do nothing;

-- Three rounds, targets at index 2, 0 and 1.
insert into public.daily_puzzles (id, puzzle_date, puzzle_type, public_config, encrypted_answer, published_at)
values (
  '99999999-9999-9999-9999-999999999999',
  current_date,
  'loophole',
  '{"rounds":[
     {"statement":"a b c","tokens":["a","b","c"]},
     {"statement":"d e f","tokens":["d","e","f"]},
     {"statement":"g h i","tokens":["g","h","i"]}
   ]}'::jsonb,
  pgp_sym_encrypt(
    '{"rounds":[
       {"target":2,"explanation":"because c"},
       {"target":0,"explanation":"because d"},
       {"target":1,"explanation":"because h"}
     ]}',
    'test-key-not-a-real-secret'
  ),
  now()
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '88888888-8888-8888-8888-888888888888', 'role', 'authenticated')::text,
  true
);

insert into public.child_profiles (id, parent_id, name)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '88888888-8888-8888-8888-888888888888', 'Player');

select public.start_puzzle_attempt(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '99999999-9999-9999-9999-999999999999'
);

-- ----------------------------------------------------------------------------
-- Round 1: wrong, then right. The first guess must give nothing away.
-- ----------------------------------------------------------------------------
select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":0}'::jsonb, 'lp-1'
  ) ->> 'correct'),
  'false',
  'a wrong tap is graded incorrect'
);

select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":0}'::jsonb, 'lp-1'
  ) ->> 'round_over'),
  'false',
  'one wrong guess does not end the round'
);

-- The spoiler-safety rule: nothing about the answer until the round closes.
select ok(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":0}'::jsonb, 'lp-1'
  ) -> 'explanation') is null,
  'no explanation is returned while a guess remains'
);

select ok(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":0}'::jsonb, 'lp-1'
  ) -> 'target') is null,
  'the target index is not returned while a guess remains'
);

select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":2}'::jsonb, 'lp-2'
  ) ->> 'correct'),
  'true',
  'the right tap on the second guess is graded correct'
);

select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":0,"token_index":2}'::jsonb, 'lp-2'
  ) ->> 'explanation'),
  'because c',
  'the explanation is released once the round is over'
);

select is(
  (select state ->> 'round' from public.puzzle_attempts limit 1),
  '1',
  'the attempt advances to the next round'
);

-- A move aimed at the wrong round must not silently burn a guess.
select throws_like(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"round":0,"token_index":1}'::jsonb, 'lp-stale'
     ) $$,
  '%but the attempt is on round 1%',
  'a move for a stale round is rejected'
);

-- ----------------------------------------------------------------------------
-- Round 2: missed entirely (two wrong guesses).
-- ----------------------------------------------------------------------------
select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":1,"token_index":1}'::jsonb, 'lp-3'
  ) ->> 'round_over'),
  'false',
  'round 2 survives one wrong guess'
);

select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":1,"token_index":2}'::jsonb, 'lp-4'
  ) ->> 'round_over'),
  'true',
  'a second wrong guess ends the round'
);

select is(
  (select state ->> 'marks' from public.puzzle_attempts limit 1),
  '[1, 0]',
  'marks record second-guess success then a miss'
);

-- ----------------------------------------------------------------------------
-- Round 3 closes the puzzle.
-- ----------------------------------------------------------------------------
select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"round":2,"token_index":1}'::jsonb, 'lp-5'
  ) ->> 'finished'),
  'true',
  'solving the last round finishes the puzzle'
);

select is(
  (select score from public.puzzle_attempts limit 1),
  3,
  'score sums the marks (1 + 0 + 2)'
);

-- One statement was missed, so this is not a clean sheet.
select is(
  (select status from public.puzzle_attempts limit 1),
  'lost',
  'missing any statement means the day is not won'
);

reset role;
select * from finish();
rollback;
