-- Keep the original RPC shape for installed clients and provide an exact
-- server timestamp for clients that refresh at the UTC date boundary.
create or replace function public.get_daily_set()
returns jsonb
language plpgsql security definer stable set search_path = '' as $$
declare
  v_now timestamptz := statement_timestamp();
  v_today date := (v_now at time zone 'UTC')::date;
  v_day integer := v_today - date '2026-01-01';
  v_maths text[] := array['squeeze', 'bridge', 'scale', 'sequence', 'mirror', 'number_hunt', 'pattern_forge'];
  v_logic text[] := array['crowns', 'whos_who', 'signal_grid', 'link_lab', 'odd_cluster'];
  v_thinking text[] := array['verdict', 'cascade', 'loophole', 'evidence_garden'];
  v_memory text[] := array['memory_match', 'memory_trail', 'memory_grid'];
  v_english text[] := array['word_wise', 'word_builder', 'word_trails'];
  v_thinking_index integer := (v_day % cardinality(v_thinking) + cardinality(v_thinking)) % cardinality(v_thinking);
  v_puzzles jsonb;
  v_featured text;
begin
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', d.id, 'puzzle_type', d.puzzle_type, 'public_config', d.public_config
         ) order by d.puzzle_type), '[]'::jsonb)
    into v_puzzles
  from public.daily_puzzles d
  where d.puzzle_date = v_today and d.published_at <= v_now;

  if v_puzzles @> '[{"puzzle_type":"second_opinion"}]'::jsonb then
    v_featured := 'second_opinion';
  else
    v_featured := v_thinking[
      1 + (v_thinking_index + cardinality(v_thinking) / 2) % cardinality(v_thinking)
    ];
  end if;

  return jsonb_build_object(
    'date', to_char(v_today, 'YYYY-MM-DD'),
    'server_time', v_now,
    'day_number', v_day,
    'games', jsonb_build_array(
      v_featured,
      v_maths[1 + (v_day % cardinality(v_maths) + cardinality(v_maths)) % cardinality(v_maths)],
      v_logic[1 + (v_day % cardinality(v_logic) + cardinality(v_logic)) % cardinality(v_logic)],
      v_thinking[1 + v_thinking_index],
      v_memory[1 + (v_day % cardinality(v_memory) + cardinality(v_memory)) % cardinality(v_memory)],
      v_english[1 + (v_day % cardinality(v_english) + cardinality(v_english)) % cardinality(v_english)]
    ),
    'puzzles', v_puzzles
  );
end;
$$;

revoke execute on function public.get_daily_set() from public, anon;
grant execute on function public.get_daily_set() to authenticated;
