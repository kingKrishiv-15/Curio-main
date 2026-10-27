-- For dashboard setup, run the complete supabase/setup.sql installer.
do $$ begin
  if to_regclass('public.activity_rewards') is null then
    raise exception 'Curio base schema is missing. Run the entire supabase/setup.sql file first.'
      using hint = 'The numbered migrations must be applied in order; setup.sql handles this for fresh and partial projects.';
  end if;
end $$;

-- Memory Grid, Word Trails and Crowns join the memory, English and maths
-- rotations. Must match gameRewards in
-- lib/features/games/common/game_rewards.dart (a Flutter test compares
-- them). Safe to re-run.
insert into public.activity_rewards (activity, xp, skill, fact, dated) values
  ('memory_grid', 80, 'Memory', 'memory_chunks', true),
  ('word_trails', 80, 'English', 'context_clues', true),
  ('crowns', 100, 'Reasoning', 'elimination', true)
on conflict (activity) do update
  set xp = excluded.xp, skill = excluded.skill,
      fact = excluded.fact, dated = excluded.dated;
