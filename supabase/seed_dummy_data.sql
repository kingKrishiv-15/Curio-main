-- Curio: dummy progress data for one test account.
--
-- Run this in Supabase → SQL Editor AFTER:
--   1. The schema migration (202608270001_initial_schema.sql) has been run.
--   2. You have signed up + confirmed one test account in the app itself,
--      and opened it at least once while signed in (Home/Profile). That
--      first load is what auto-creates the child_profiles row — this
--      script only fills it in, it does not create the account.
--
-- Only one line needs editing: target_email below.

do $$
declare
  target_email text := 'demo@curio.app'; -- <-- change to the email you signed up with
  v_parent_id uuid;
  v_child_id uuid;
begin
  select id into v_parent_id from auth.users where email = target_email;
  if v_parent_id is null then
    raise exception
      'No auth user found for %. Sign up with this email in the app first.',
      target_email;
  end if;

  select id into v_child_id
  from public.child_profiles
  where parent_id = v_parent_id
  order by created_at
  limit 1;

  if v_child_id is null then
    raise exception
      'No child profile yet for %. Open the app once while signed in first — Home or Profile creates it automatically.',
      target_email;
  end if;

  update public.child_profiles
  set name = 'Maya', total_xp = 640, streak = 4, updated_at = now()
  where id = v_child_id;

  -- Activity ids are built from the real date so the "practiced this week"
  -- card and streak checkmarks line up with today, whenever this runs.
  insert into public.activity_completions (child_id, activity_id) values
    (v_child_id, 'squeeze_' || to_char(current_date, 'YYYYMMDD')),
    (v_child_id, 'pattern_forge_' || to_char(current_date - 1, 'YYYYMMDD')),
    (v_child_id, 'link_lab_' || to_char(current_date - 2, 'YYYYMMDD')),
    (v_child_id, 'squeeze_' || to_char(current_date - 3, 'YYYYMMDD')),
    (v_child_id, 'pattern_forge_' || to_char(current_date - 4, 'YYYYMMDD'))
  on conflict (child_id, activity_id) do nothing;

  -- Matches the real discovery catalog in lib/features/discoveries/domain —
  -- 6 of 9 unlocked, 3 left locked so the Discoveries tab shows both states.
  insert into public.unlocked_discoveries (child_id, discovery_id) values
    (v_child_id, 'octopus_hearts'),
    (v_child_id, 'shortest_war'),
    (v_child_id, 'diwali_light'),
    (v_child_id, 'prime_numbers'),
    (v_child_id, 'fibonacci_nature'),
    (v_child_id, 'classification_science')
  on conflict (child_id, discovery_id) do nothing;

  insert into public.skill_progress (child_id, skill_key, mastery) values
    (v_child_id, 'Number sense', 0.62),
    (v_child_id, 'Patterns', 0.35),
    (v_child_id, 'Evidence', 0.18),
    (v_child_id, 'Reasoning', 0.42)
  on conflict (child_id, skill_key)
    do update set mastery = excluded.mastery, updated_at = now();

  raise notice 'Seeded dummy progress for child %', v_child_id;
end $$;
