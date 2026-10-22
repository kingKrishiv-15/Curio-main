-- For dashboard setup, run the complete supabase/setup.sql installer.
do $$ begin
  if to_regclass('public.activity_rewards') is null then
    raise exception 'Curio base schema is missing. Run the entire supabase/setup.sql file first.'
      using hint = 'The numbered migrations must be applied in order; setup.sql handles this for fresh and partial projects.';
  end if;
end $$;

-- ============================================================================
-- Four more daily games: Tip the Scale, Mirror, Verdict and Who's Who.
-- ============================================================================
-- Rewards are looked up by sync_learning_progress (202610080001), so a game
-- the table doesn't know is silently dropped — every new game needs a row
-- here, matching gameRewards in lib/features/games/common/game_rewards.dart
-- (a Flutter test compares them). Safe to re-run.
-- ============================================================================
insert into public.activity_rewards (activity, xp, skill, fact, dated) values
  ('scale', 80, 'Number sense', 'equal_fractions', true),
  ('mirror', 80, 'Patterns', 'mirror_symmetry', true),
  ('verdict', 80, 'Evidence', 'correlation', true),
  ('whos_who', 100, 'Reasoning', 'logic_grid', true)
on conflict (activity) do update
  set xp = excluded.xp, skill = excluded.skill, fact = excluded.fact, dated = excluded.dated;
