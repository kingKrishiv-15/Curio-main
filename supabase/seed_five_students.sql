-- Curio: 5 fully self-contained dummy student accounts.
--
-- Unlike seed_dummy_data.sql (which fills in ONE account you've already
-- signed up in the app), this script needs nothing from the app first —
-- it creates 5 real, sign-in-able parent accounts directly, one child
-- profile each, and different activity/discovery/skill data per child.
--
-- HOW TO RUN
--   1. Supabase → SQL Editor → paste this whole file → Run.
--   2. It only touches your project's own database — nothing to configure.
--   3. Every account uses the password: CurioDemo123!
--      (change DUMMY_PASSWORD below if you'd rather use your own)
--   4. Safe to re-run: emails are unique, so a second run raises a
--      duplicate-key error instead of creating duplicates — drop the rows
--      first (see the cleanup block at the bottom, commented out) if you
--      want to reset and reseed.
--
-- WHAT YOU GET
--   maya@curio.test    — strong all-rounder, 9-day streak, 980 XP
--   arjun@curio.test   — just started, 1-day streak, 120 XP
--   zara@curio.test    — patterns specialist, 3-day streak, 540 XP
--   leo@curio.test     — reasoning/logic specialist, 6-day streak, 710 XP
--   priya@curio.test   — evidence-focused, streak lapsed to 0, 430 XP
--
-- Sign in as any of them on the Login screen to see that student's data
-- in Home / Profile / Skill Quest / Parent dashboard. Or just browse the
-- 5 tables directly in Table Editor.

do $$
declare
  dummy_password text := 'CurioDemo123!'; -- <-- change if you want a different password
  v_maya uuid := gen_random_uuid();
  v_arjun uuid := gen_random_uuid();
  v_zara uuid := gen_random_uuid();
  v_leo uuid := gen_random_uuid();
  v_priya uuid := gen_random_uuid();
  c_maya uuid := gen_random_uuid();
  c_arjun uuid := gen_random_uuid();
  c_zara uuid := gen_random_uuid();
  c_leo uuid := gen_random_uuid();
  c_priya uuid := gen_random_uuid();
begin
  -- 1. Five real auth users (this also fires the existing
  --    handle_new_user trigger, which creates their public.profiles row).
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) values
    ('00000000-0000-0000-0000-000000000000', v_maya, 'authenticated', 'authenticated',
     'maya@curio.test', crypt(dummy_password, gen_salt('bf')), now(), now(),
     '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_arjun, 'authenticated', 'authenticated',
     'arjun@curio.test', crypt(dummy_password, gen_salt('bf')), now(), now(),
     '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_zara, 'authenticated', 'authenticated',
     'zara@curio.test', crypt(dummy_password, gen_salt('bf')), now(), now(),
     '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_leo, 'authenticated', 'authenticated',
     'leo@curio.test', crypt(dummy_password, gen_salt('bf')), now(), now(),
     '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_priya, 'authenticated', 'authenticated',
     'priya@curio.test', crypt(dummy_password, gen_salt('bf')), now(), now(),
     '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values
    (gen_random_uuid(), v_maya, v_maya::text,
     jsonb_build_object('sub', v_maya::text, 'email', 'maya@curio.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_arjun, v_arjun::text,
     jsonb_build_object('sub', v_arjun::text, 'email', 'arjun@curio.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_zara, v_zara::text,
     jsonb_build_object('sub', v_zara::text, 'email', 'zara@curio.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_leo, v_leo::text,
     jsonb_build_object('sub', v_leo::text, 'email', 'leo@curio.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_priya, v_priya::text,
     jsonb_build_object('sub', v_priya::text, 'email', 'priya@curio.test'), 'email', now(), now(), now());

  -- 2. One child profile per parent, each with different XP/streak.
  insert into public.child_profiles (id, parent_id, name, total_xp, streak) values
    (c_maya, v_maya, 'Maya', 980, 9),
    (c_arjun, v_arjun, 'Arjun', 120, 1),
    (c_zara, v_zara, 'Zara', 540, 3),
    (c_leo, v_leo, 'Leo', 710, 6),
    (c_priya, v_priya, 'Priya', 430, 0);

  -- 3. Activity completions — ids follow the app's own
  --    "<activity>_<YYYYMMDD>" format, dated relative to today so the
  --    "practiced this week" card lines up whenever you run this.
  insert into public.activity_completions (child_id, activity_id) values
    (c_maya, 'squeeze_' || to_char(current_date, 'YYYYMMDD')),
    (c_maya, 'link_lab_' || to_char(current_date - 1, 'YYYYMMDD')),
    (c_maya, 'signal_grid_' || to_char(current_date - 2, 'YYYYMMDD')),
    (c_maya, 'pattern_forge_' || to_char(current_date - 3, 'YYYYMMDD')),
    (c_maya, 'evidence_garden_' || to_char(current_date - 4, 'YYYYMMDD')),
    (c_maya, 'squeeze_' || to_char(current_date - 5, 'YYYYMMDD')),

    (c_arjun, 'squeeze_' || to_char(current_date, 'YYYYMMDD')),

    (c_zara, 'pattern_forge_' || to_char(current_date, 'YYYYMMDD')),
    (c_zara, 'pattern_forge_' || to_char(current_date - 2, 'YYYYMMDD')),
    (c_zara, 'squeeze_' || to_char(current_date - 3, 'YYYYMMDD')),

    (c_leo, 'link_lab_' || to_char(current_date, 'YYYYMMDD')),
    (c_leo, 'signal_grid_' || to_char(current_date - 1, 'YYYYMMDD')),
    (c_leo, 'link_lab_' || to_char(current_date - 2, 'YYYYMMDD')),
    (c_leo, 'signal_grid_' || to_char(current_date - 4, 'YYYYMMDD')),

    (c_priya, 'evidence_garden_' || to_char(current_date - 8, 'YYYYMMDD')),
    (c_priya, 'evidence_garden_' || to_char(current_date - 10, 'YYYYMMDD'))
  on conflict (child_id, activity_id) do nothing;

  -- 4. Discoveries unlocked — ids match the real catalog in
  --    lib/features/discoveries/domain/discovery.dart (9 total).
  insert into public.unlocked_discoveries (child_id, discovery_id) values
    (c_maya, 'octopus_hearts'), (c_maya, 'shortest_war'), (c_maya, 'diwali_light'),
    (c_maya, 'prime_numbers'), (c_maya, 'fibonacci_nature'),
    (c_maya, 'classification_science'), (c_maya, 'binary_patterns'),

    (c_arjun, 'prime_numbers'),

    (c_zara, 'fibonacci_nature'), (c_zara, 'octopus_hearts'),
    (c_zara, 'prime_numbers'), (c_zara, 'shortest_war'),

    (c_leo, 'classification_science'), (c_leo, 'binary_patterns'),
    (c_leo, 'diwali_light'), (c_leo, 'octopus_hearts'), (c_leo, 'shortest_war'),

    (c_priya, 'weather_evidence'), (c_priya, 'octopus_hearts'), (c_priya, 'diwali_light')
  on conflict (child_id, discovery_id) do nothing;

  -- 5. Skill mastery — one row per skill per child, each student's
  --    strongest/weakest areas reflecting the activities above.
  insert into public.skill_progress (child_id, skill_key, mastery) values
    (c_maya, 'Number sense', 0.78), (c_maya, 'Patterns', 0.55),
    (c_maya, 'Evidence', 0.40), (c_maya, 'Reasoning', 0.70),

    (c_arjun, 'Number sense', 0.15), (c_arjun, 'Patterns', 0.05),
    (c_arjun, 'Evidence', 0.00), (c_arjun, 'Reasoning', 0.10),

    (c_zara, 'Number sense', 0.30), (c_zara, 'Patterns', 0.85),
    (c_zara, 'Evidence', 0.20), (c_zara, 'Reasoning', 0.35),

    (c_leo, 'Number sense', 0.45), (c_leo, 'Patterns', 0.40),
    (c_leo, 'Evidence', 0.35), (c_leo, 'Reasoning', 0.88),

    (c_priya, 'Number sense', 0.50), (c_priya, 'Patterns', 0.42),
    (c_priya, 'Evidence', 0.66), (c_priya, 'Reasoning', 0.48)
  on conflict (child_id, skill_key)
    do update set mastery = excluded.mastery, updated_at = now();

  raise notice 'Seeded 5 students: Maya %, Arjun %, Zara %, Leo %, Priya %',
    c_maya, c_arjun, c_zara, c_leo, c_priya;
end $$;

-- To wipe these 5 test accounts and start over, uncomment and run:
-- delete from auth.users where email in
--   ('maya@curio.test','arjun@curio.test','zara@curio.test','leo@curio.test','priya@curio.test');
-- (cascades to profiles, child_profiles, and everything under them)
