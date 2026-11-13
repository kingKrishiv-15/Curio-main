-- ============================================================================
-- Second Opinion - the daily anchor game, validated on the server
-- ============================================================================
-- An AI-written brief contains exactly three claims that do not hold up.
-- The player may reveal up to three of six follow-up probes, then flags
-- three of eight claim cards and submits once. A single five minute
-- countdown starts when the attempt row is created and never pauses.
--
-- There is no live model call anywhere. Every word the player sees was
-- authored ahead of time and stored as one daily_puzzles row.
--
-- Shapes
--
--   public_config (client-readable)
--     { "number": 142, "topic": "...", "brief": "...",
--       "probes": [ { "id": "source", "question": "How do you know that?" }, ... 6 ],
--       "claims": [ { "id": "c1", "text": "..." }, ... 8 ],
--       "seconds": 300 }
--
--   encrypted_answer (server only)
--     { "replies": { "source": "...", ... 6 },
--       "exposes": { "source": ["c3"], ... },      -- probes that catch an error
--       "flawed":  { "c3": { "type": "fabricated", "probe": "source", "why": "..." }, ... 3 } }
--
--   attempt.state
--     { "probes": ["example", "source"] }
--
--   move_data from the client
--     { "type": "probe",  "probe": "source" }
--     { "type": "submit", "claims": ["c1", "c4", "c7"] }
--
-- What a verdict may contain: a probe move returns only that probe's
-- pre-written reply. Nothing says whether the probe exposed anything, and
-- nothing about which claims are flawed leaves the server until the one
-- submission has been graded.
-- ============================================================================

do $$
begin
  if to_regclass('public.activity_rewards') is not null then
    insert into public.activity_rewards (activity, xp, skill, fact, dated) values
      ('second_opinion', 120, 'Evidence', 'fluent_not_right', true)
    on conflict (activity) do update
      set xp = excluded.xp, skill = excluded.skill, fact = excluded.fact, dated = excluded.dated;
  end if;
end $$;

create or replace function public.validate_second_opinion_move(
  p_attempt_id uuid, p_move_data jsonb, p_answer jsonb
)
returns jsonb
language plpgsql
set search_path = '' as $$
declare
  v_state jsonb;
  v_started timestamptz;
  v_limit integer;
  v_probes jsonb;
  v_type text := p_move_data ->> 'type';
  v_probe text;
  v_chosen text[];
  v_valid text[];
  v_flawed text[];
  v_hits integer;
  v_false integer;
  v_good integer;
  v_elapsed integer;
  v_left integer;
  v_base integer;
  v_penalty integer;
  v_probe_bonus integer;
  v_time_bonus integer;
  v_score integer;
begin
  select coalesce(a.state, '{}'::jsonb), a.started_at,
         coalesce((d.public_config ->> 'seconds')::integer, 300),
         array(select c ->> 'id' from jsonb_array_elements(d.public_config -> 'claims') as c)
    into v_state, v_started, v_limit, v_valid
  from public.puzzle_attempts a
  join public.daily_puzzles d on d.id = a.puzzle_id
  where a.id = p_attempt_id;

  v_probes := coalesce(v_state -> 'probes', '[]'::jsonb);

  if v_type = 'probe' then
    v_probe := p_move_data ->> 'probe';
    if v_probe is null or not (p_answer -> 'replies') ? v_probe then
      raise exception 'unknown probe %', v_probe;
    end if;
    if v_probes ? v_probe then
      raise exception 'probe % was already asked', v_probe;
    end if;
    if jsonb_array_length(v_probes) >= 3 then
      raise exception 'only three probes may be asked';
    end if;

    v_probes := v_probes || to_jsonb(v_probe);
    update public.puzzle_attempts
    set state = jsonb_build_object('probes', v_probes)
    where id = p_attempt_id;

    return jsonb_build_object(
      'type', 'probe',
      'probe', v_probe,
      'reply', p_answer -> 'replies' ->> v_probe,
      'probes_used', jsonb_array_length(v_probes),
      'finished', false
    );
  end if;

  if v_type <> 'submit' or jsonb_typeof(p_move_data -> 'claims') <> 'array' then
    raise exception 'unsupported move';
  end if;

  select array_agg(distinct value) into v_chosen
  from jsonb_array_elements_text(p_move_data -> 'claims') as value;
  if coalesce(array_length(v_chosen, 1), 0) <> 3 then
    raise exception 'flag exactly three different claims';
  end if;
  if not v_chosen <@ v_valid then
    raise exception 'unknown claim in submission';
  end if;

  select array_agg(key) into v_flawed from jsonb_object_keys(p_answer -> 'flawed') as key;

  select count(*) into v_hits from unnest(v_chosen) as c where c = any(v_flawed);
  v_false := 3 - v_hits;

  -- A chosen probe is "good" when it exposes at least one of today's errors.
  select count(*) into v_good
  from jsonb_array_elements_text(v_probes) as p
  where jsonb_array_length(coalesce(p_answer -> 'exposes' -> p, '[]'::jsonb)) > 0;

  v_elapsed := floor(extract(epoch from (now() - v_started)))::integer;
  v_left := greatest(0, v_limit - v_elapsed);

  v_base := 400 * v_hits;
  v_penalty := 150 * v_false;
  v_probe_bonus := case when v_good >= 1 then 200 + 100 * (v_good - 1) else 0 end;
  v_time_bonus := least(v_left, 300);
  v_score := greatest(0, v_base - v_penalty + v_probe_bonus + v_time_bonus);

  update public.puzzle_attempts
  set status = case when v_hits = 3 then 'won' else 'lost' end,
      score = v_score,
      completed_at = now()
  where id = p_attempt_id;

  return jsonb_build_object(
    'type', 'submit',
    'finished', true,
    'chosen', to_jsonb(v_chosen),
    'hits', v_hits,
    'false_flags', v_false,
    'good_probes', v_good,
    'seconds_left', v_left,
    'score', v_score,
    'breakdown', jsonb_build_object(
      'base', v_base, 'penalty', v_penalty,
      'probes', v_probe_bonus, 'time', v_time_bonus
    ),
    'probes', v_probes,
    'exposes', p_answer -> 'exposes',
    'flawed', p_answer -> 'flawed'
  );
end;
$$;

-- Only submit_puzzle_move (security definer) may call the validator. On
-- Supabase, revoking from public does not remove the explicit grants to
-- anon and authenticated, so each role is named.
revoke execute on function public.validate_second_opinion_move(uuid, jsonb, jsonb)
  from public, anon, authenticated;

-- Opens (or resumes) today's attempt. The countdown is measured from the
-- attempt's started_at on the server clock, so the client is told how many
-- seconds are left rather than working it out from its own clock. On a
-- resume it also returns the replies to probes already asked, and, once the
-- attempt is finished, the graded verdict.
create or replace function public.open_second_opinion(p_child_id uuid, p_puzzle_id uuid)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_attempt public.puzzle_attempts;
  v_limit integer;
  v_type text;
  v_answer jsonb;
  v_replies jsonb := '{}'::jsonb;
  v_probe text;
  v_verdict jsonb;
begin
  select puzzle_type, coalesce((public_config ->> 'seconds')::integer, 300)
    into v_type, v_limit
  from public.daily_puzzles where id = p_puzzle_id;
  if v_type is distinct from 'second_opinion' then
    raise exception 'puzzle % is not a second opinion puzzle', p_puzzle_id;
  end if;

  -- Checks ownership and availability, and creates the row on first open.
  v_attempt := public.start_puzzle_attempt(p_child_id, p_puzzle_id);

  if jsonb_array_length(coalesce(v_attempt.state -> 'probes', '[]'::jsonb)) > 0 then
    v_answer := public.puzzle_answer(p_puzzle_id);
    for v_probe in select jsonb_array_elements_text(v_attempt.state -> 'probes') loop
      v_replies := v_replies || jsonb_build_object(v_probe, v_answer -> 'replies' ->> v_probe);
    end loop;
  end if;

  if v_attempt.status <> 'in_progress' then
    select result into v_verdict from public.puzzle_moves
    where attempt_id = v_attempt.id and result ->> 'type' = 'submit'
    order by move_number desc limit 1;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'status', v_attempt.status,
    'probes', coalesce(v_attempt.state -> 'probes', '[]'::jsonb),
    'replies', v_replies,
    'seconds_left', greatest(
      0, v_limit - floor(extract(epoch from (now() - v_attempt.started_at)))::integer
    ),
    'verdict', v_verdict
  );
end;
$$;

revoke execute on function public.open_second_opinion(uuid, uuid) from public, anon;
grant execute on function public.open_second_opinion(uuid, uuid) to authenticated;

-- Today's puzzle of one type, where "today" is the server's date. The
-- client never has to say what day it thinks it is.
create or replace function public.todays_puzzle(p_puzzle_type text)
returns table (
  id uuid,
  puzzle_date date,
  puzzle_type text,
  public_config jsonb
)
language sql security definer stable set search_path = '' as $$
  select d.id, d.puzzle_date, d.puzzle_type, d.public_config
  from public.daily_puzzles d
  where d.puzzle_type = p_puzzle_type
    and d.puzzle_date = current_date
    and d.published_at is not null;
$$;

revoke execute on function public.todays_puzzle(text) from public, anon;
grant execute on function public.todays_puzzle(text) to authenticated;
