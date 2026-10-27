-- For dashboard setup, run the complete supabase/setup.sql installer.
do $$ begin
  if to_regclass('public.activity_rewards') is null then
    raise exception 'Curio base schema is missing. Run the entire supabase/setup.sql file first.'
      using hint = 'The numbered migrations must be applied in order; setup.sql handles this for fresh and partial projects.';
  end if;
end $$;

-- New daily memory and English games. Existing completion IDs and rewards
-- remain valid, so families keep all previously earned progress.
alter table public.activity_rewards
  drop constraint if exists activity_rewards_skill_check;
alter table public.activity_rewards
  add constraint activity_rewards_skill_check
  check (skill in ('Number sense', 'Patterns', 'Evidence', 'Reasoning', 'Memory', 'English'));

insert into public.activity_rewards (activity, xp, skill, fact, dated) values
  ('memory_match', 80, 'Memory', 'memory_pairs', true),
  ('memory_trail', 80, 'Memory', 'memory_order', true),
  ('word_wise', 80, 'English', 'word_synonyms', true),
  ('word_builder', 80, 'English', 'word_anagrams', true)
on conflict (activity) do update
  set xp = excluded.xp, skill = excluded.skill,
      fact = excluded.fact, dated = excluded.dated;

-- Older clients offered a five-game goal. There are now four daily slots
-- since Logic joined; capping at three here would undo a goal of four
-- whenever setup.sql is re-run.
update public.family_settings set daily_goal = least(daily_goal, 4)
where daily_goal > 4;
