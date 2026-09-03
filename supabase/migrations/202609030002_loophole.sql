-- ============================================================================
-- Loophole - server-side validation
-- ============================================================================
-- A statement that is technically true but misleading; the player taps the
-- one token doing the deceptive work. Three statements a day, two guesses
-- each.
--
-- Shapes this validator works with:
--
--   public_config (client-readable)
--     { "rounds": [ { "statement": "...", "tokens": ["This","toothpaste",...] }, ... ] }
--
--   encrypted_answer (server only)
--     { "rounds": [ { "target": 6, "explanation": "..." }, ... ] }
--
--   attempt.state
--     { "round": 0, "guesses": 0, "marks": [2,1] }
--       marks: 2 = found on the first guess, 1 = on the second, 0 = missed.
--
--   move_data from the client
--     { "round": 0, "token_index": 6 }
--
-- The target is a token *index*, not the word itself - statements repeat
-- words ("less sugar than less fat"), and an index says exactly which one.
--
-- What the verdict may contain: whether the tap was right, and once a round
-- is over, the answer and its explanation. Mid-round it says nothing that
-- would narrow down the remaining guess - the explanation is the teaching
-- payoff for finishing, not a hint.
-- ============================================================================

create or replace function public.validate_loophole_move(
  p_attempt_id uuid, p_move_data jsonb, p_answer jsonb
)
returns jsonb
language plpgsql
set search_path = '' as $$
declare
  v_state jsonb;
  v_round integer;
  v_guesses integer;
  v_marks jsonb;
  v_total_rounds integer;
  v_target integer;
  v_explanation text;
  v_correct boolean;
  v_round_over boolean;
  v_finished boolean;
  v_mark integer;
  v_score integer;
  v_status text;
begin
  select coalesce(state, '{}'::jsonb) into v_state
  from public.puzzle_attempts where id = p_attempt_id;

  v_round := coalesce((v_state ->> 'round')::integer, 0);
  v_guesses := coalesce((v_state ->> 'guesses')::integer, 0);
  v_marks := coalesce(v_state -> 'marks', '[]'::jsonb);
  v_total_rounds := jsonb_array_length(p_answer -> 'rounds');

  -- The client says which round it thinks it is on. If that disagrees with
  -- the server, something is out of sync (a stale screen, a replayed move
  -- with a fresh key) and guessing on the wrong round would silently burn a
  -- guess on the wrong statement.
  if coalesce((p_move_data ->> 'round')::integer, -1) <> v_round then
    raise exception 'move is for round % but the attempt is on round %',
      p_move_data ->> 'round', v_round;
  end if;

  v_target := (p_answer -> 'rounds' -> v_round ->> 'target')::integer;
  v_explanation := p_answer -> 'rounds' -> v_round ->> 'explanation';
  v_correct := coalesce((p_move_data ->> 'token_index')::integer, -1) = v_target;

  v_guesses := v_guesses + 1;
  v_round_over := v_correct or v_guesses >= 2;

  if v_round_over then
    v_mark := case when v_correct then (case when v_guesses = 1 then 2 else 1 end) else 0 end;
    v_marks := v_marks || to_jsonb(v_mark);
    v_finished := (v_round + 1) >= v_total_rounds;
  else
    v_finished := false;
  end if;

  if v_finished then
    select coalesce(sum(value::integer), 0) into v_score
    from jsonb_array_elements_text(v_marks) as value;

    -- "Won" means every statement was cracked within its two guesses;
    -- anything less still finishes the day, it just isn't a clean sheet.
    select case when count(*) = 0 then 'won' else 'lost' end into v_status
    from jsonb_array_elements_text(v_marks) as value
    where value::integer = 0;

    update public.puzzle_attempts
    set state = jsonb_build_object('round', v_round + 1, 'guesses', 0, 'marks', v_marks),
        status = v_status,
        score = v_score,
        completed_at = now()
    where id = p_attempt_id;
  elsif v_round_over then
    update public.puzzle_attempts
    set state = jsonb_build_object('round', v_round + 1, 'guesses', 0, 'marks', v_marks)
    where id = p_attempt_id;
  else
    update public.puzzle_attempts
    set state = jsonb_build_object('round', v_round, 'guesses', v_guesses, 'marks', v_marks)
    where id = p_attempt_id;
  end if;

  return jsonb_build_object(
    'correct', v_correct,
    'round', v_round,
    'guesses_used', v_guesses,
    'round_over', v_round_over,
    'finished', v_finished,
    'marks', v_marks
  )
  -- The answer and the why are released only once the round can no longer
  -- be guessed at.
  || case when v_round_over
       then jsonb_build_object('target', v_target, 'explanation', v_explanation)
       else '{}'::jsonb end
  || case when v_finished
       then jsonb_build_object('score', v_score, 'status', v_status)
       else '{}'::jsonb end;
end;
$$;
