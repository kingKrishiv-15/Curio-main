-- ============================================================================
-- Integration tests: Second Opinion (202611130001)
-- ============================================================================
-- What matters: the client can never learn which claims are flawed before
-- its one submission, the countdown is the server's, and a retried
-- submission returns the first verdict instead of grading twice.
begin;
select plan(17);

create extension if not exists pgtap;

insert into auth.users (
  instance_id, id, aud, role, email,
  encrypted_password, email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '77777777-7777-7777-7777-777777777777',
  'authenticated', 'authenticated', 'second-opinion@test.curio.dev',
  crypt('test-password', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}', '{}'
);

insert into public.app_secrets (name, value)
values ('minigame_encryption_key', 'test-key-not-a-real-secret')
on conflict (name) do nothing;

-- Flawed: c1, c2, c3. "source" exposes c1, "current" exposes c2 and c3.
insert into public.daily_puzzles (id, puzzle_date, puzzle_type, public_config, encrypted_answer, published_at)
values (
  '66666666-6666-6666-6666-666666666666',
  current_date,
  'second_opinion',
  '{"number":1,"topic":"t","brief":"b","seconds":300,
    "probes":[{"id":"source","question":"q"},{"id":"current","question":"q"},
              {"id":"example","question":"q"},{"id":"counter","question":"q"},
              {"id":"scope","question":"q"},{"id":"unsure","question":"q"}],
    "claims":[{"id":"c1","text":"1"},{"id":"c2","text":"2"},{"id":"c3","text":"3"},
              {"id":"c4","text":"4"},{"id":"c5","text":"5"},{"id":"c6","text":"6"},
              {"id":"c7","text":"7"},{"id":"c8","text":"8"}]}'::jsonb,
  pgp_sym_encrypt(
    '{"replies":{"source":"r-source","current":"r-current","example":"r-example",
                 "counter":"r-counter","scope":"r-scope","unsure":"r-unsure"},
      "exposes":{"source":["c1"],"current":["c2","c3"]},
      "flawed":{"c1":{"type":"fabricated","probe":"source","why":"w1"},
                "c2":{"type":"out_of_date","probe":"current","why":"w2"},
                "c3":{"type":"confident_guess","probe":"current","why":"w3"}}}',
    'test-key-not-a-real-secret'
  ),
  now()
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '77777777-7777-7777-7777-777777777777', 'role', 'authenticated')::text,
  true
);

insert into public.child_profiles (id, parent_id, name)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-7777-7777-7777-777777777777', 'Player');

-- ----------------------------------------------------------------------------
-- The answer never reaches a signed-in client.
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ select encrypted_answer from public.daily_puzzles $$,
  '42501', null,
  'authenticated cannot read encrypted_answer'
);

select throws_ok(
  $$ select public.puzzle_answer('66666666-6666-6666-6666-666666666666') $$,
  '42501', null,
  'authenticated cannot execute the decrypt helper'
);

select throws_ok(
  $$ select public.validate_second_opinion_move(
       gen_random_uuid(), '{"type":"submit","claims":["c1","c2","c3"]}'::jsonb, '{}'::jsonb) $$,
  '42501', null,
  'authenticated cannot call the validator directly'
);

select is(
  (select public_config ? 'flawed' or public_config ? 'exposes' or public_config ? 'replies'
   from public.get_daily_puzzle('second_opinion', current_date)),
  false,
  'the public config carries no replies, exposes or flawed keys'
);

-- ----------------------------------------------------------------------------
-- Opening starts the server clock.
-- ----------------------------------------------------------------------------
select ok(
  (select (public.open_second_opinion(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '66666666-6666-6666-6666-666666666666'
  ) ->> 'seconds_left')::integer between 295 and 300),
  'a fresh attempt has the full five minutes'
);

-- ----------------------------------------------------------------------------
-- Probes: a reply and nothing else.
-- ----------------------------------------------------------------------------
select is(
  (select public.submit_puzzle_move(
    (select id from public.puzzle_attempts limit 1),
    '{"type":"probe","probe":"source"}'::jsonb, 'so-p1'
  ) ->> 'reply'),
  'r-source',
  'a probe returns its pre-written reply'
);

select is(
  (select r ? 'flawed' or r ? 'exposes' or r ? 'hits'
   from public.submit_puzzle_move(
     (select id from public.puzzle_attempts limit 1),
     '{"type":"probe","probe":"example"}'::jsonb, 'so-p2'
   ) as r),
  false,
  'a probe verdict says nothing about which claims are flawed'
);

select throws_ok(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"type":"probe","probe":"source"}'::jsonb, 'so-p-dup') $$,
  'probe source was already asked',
  'the same probe cannot be asked twice'
);

select lives_ok(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"type":"probe","probe":"unsure"}'::jsonb, 'so-p3') $$,
  'a third probe is allowed'
);

select throws_ok(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"type":"probe","probe":"scope"}'::jsonb, 'so-p4') $$,
  'only three probes may be asked',
  'a fourth probe is refused'
);

select is(
  (select public.open_second_opinion(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '66666666-6666-6666-6666-666666666666'
  ) -> 'replies' ->> 'example'),
  'r-example',
  'resuming returns the replies already revealed'
);

-- ----------------------------------------------------------------------------
-- One submission, graded on the server.
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"type":"submit","claims":["c1","c2"]}'::jsonb, 'so-short') $$,
  'flag exactly three different claims',
  'a submission must flag exactly three claims'
);

-- c1 and c2 are flawed, c4 is clean: 800 base, 150 penalty. One of the three
-- probes (source) exposed an error: 200. Time is whatever is left.
select is(
  (select (r ->> 'score')::integer - (r -> 'breakdown' ->> 'time')::integer
   from public.submit_puzzle_move(
     (select id from public.puzzle_attempts limit 1),
     '{"type":"submit","claims":["c1","c2","c4"]}'::jsonb, 'so-submit'
   ) as r),
  850,
  'two hits, one false flag and one good probe score 850 before time'
);

select is(
  (select status from public.puzzle_attempts limit 1),
  'lost',
  'missing a flawed claim finishes the day without a clean sheet'
);

select is(
  (select r -> 'flawed' -> 'c3' ->> 'type'
   from public.submit_puzzle_move(
     (select id from public.puzzle_attempts limit 1),
     '{"type":"submit","claims":["c1","c2","c3"]}'::jsonb, 'so-submit'
   ) as r),
  'confident_guess',
  'a repeated submission with the same idempotency key returns the original verdict'
);

select is(
  (select (r ->> 'hits')::integer
   from public.submit_puzzle_move(
     (select id from public.puzzle_attempts limit 1),
     '{"type":"submit","claims":["c1","c2","c3"]}'::jsonb, 'so-submit'
   ) as r),
  2,
  'the repeated submission is not graded again'
);

select throws_ok(
  $$ select public.submit_puzzle_move(
       (select id from public.puzzle_attempts limit 1),
       '{"type":"submit","claims":["c1","c2","c3"]}'::jsonb, 'so-second-try') $$,
  null, null,
  'a second submission under a new key is refused'
);

select * from finish();
rollback;
