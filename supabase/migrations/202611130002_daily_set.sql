-- ============================================================================
-- The daily set, decided on the server
-- ============================================================================
-- The server says what day it is and which games make up today's set, so a
-- device with the wrong clock (or a changed one) cannot move the day.
--
-- The set is the anchor game plus one rotating game from each section. The
-- rotation mirrors sectionRotation in
-- lib/features/games/common/daily_schedule.dart (a Flutter test parses the
-- pools below and compares them). Day 0 is 1 January 2026.
--
-- Returns
--   { "date": "2026-11-13", "day_number": 316,
--     "games": ["second_opinion", "squeeze", "crowns", "verdict"],
--     "puzzles": [ { "id": "...", "puzzle_type": "second_opinion", "public_config": {...} } ] }
--
-- "puzzles" holds today's published server-validated puzzles. It carries
-- public_config only, never an answer.
-- ============================================================================
create or replace function public.get_daily_set()
returns jsonb
language plpgsql security definer stable set search_path = '' as $$
declare
  v_today date := current_date;
  v_day integer := current_date - date '2026-01-01';
  v_maths text[] := array['squeeze', 'bridge', 'scale', 'sequence', 'mirror'];
  v_logic text[] := array['crowns', 'whos_who', 'signal_grid', 'link_lab'];
  v_thinking text[] := array['verdict', 'cascade'];
  v_puzzles jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', d.id, 'puzzle_type', d.puzzle_type, 'public_config', d.public_config
         ) order by d.puzzle_type), '[]'::jsonb)
    into v_puzzles
  from public.daily_puzzles d
  where d.puzzle_date = v_today and d.published_at is not null;

  return jsonb_build_object(
    'date', to_char(v_today, 'YYYY-MM-DD'),
    'day_number', v_day,
    'games', jsonb_build_array(
      'second_opinion',
      v_maths[1 + ((v_day % 5) + 5) % 5],
      v_logic[1 + ((v_day % 4) + 4) % 4],
      v_thinking[1 + ((v_day % 2) + 2) % 2]
    ),
    'puzzles', v_puzzles
  );
end;
$$;

revoke execute on function public.get_daily_set() from public, anon;
grant execute on function public.get_daily_set() to authenticated;
