-- ============================================================================
-- Curio - daily minigames infrastructure
-- ============================================================================
-- Adds the server-authoritative daily-puzzle layer the games need, on top of
-- the existing profiles/child_profiles schema. Follows the conventions in
-- 202608270001_initial_schema.sql: plural table names, identity columns for
-- log tables, `(select auth.uid())` inside policies, and explicit grants.
--
-- WHY THIS EXISTS. Today every game hardcodes its own answers in Dart
-- (link_lab's `_groups`, signal_grid's `_solution`, pattern's `_questions`).
-- That ships the answer inside the app binary, gives every player a
-- different puzzle depending on when they installed, and makes an archive
-- impossible. This migration moves puzzle content server-side so that:
--   * everyone gets the same puzzle on the same date (shared results),
--   * the answer is never sent to a client, only compared against,
--   * past days stay playable.
--
-- HOW THE ANSWER IS PROTECTED. Each puzzle splits in two: `public_config`
-- (jsonb, freely readable - the tiles, the statement, the start/target) and
-- `encrypted_answer` (bytea, pgp_sym_encrypt'd, with no client grant at all).
-- Only the SECURITY DEFINER functions below can decrypt, and they return a
-- verdict, never the answer. The key lives in `app_secrets`, which no client
-- role can read.
--
-- ONE-TIME SETUP per environment (the key is generated in-database, so it
-- never appears in this file, in git, or in a chat log):
--   insert into public.app_secrets (name, value)
--   values ('minigame_encryption_key', encode(gen_random_bytes(32), 'hex'));
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Secrets
-- ----------------------------------------------------------------------------
-- RLS on with zero policies plus revoked grants: unreachable through
-- PostgREST by any client role, readable by definer functions as the owner.
create table public.app_secrets (
  name text primary key,
  value text not null,
  created_at timestamptz not null default now()
);

alter table public.app_secrets enable row level security;
revoke all on public.app_secrets from anon, authenticated;

-- ----------------------------------------------------------------------------
-- Puzzles
-- ----------------------------------------------------------------------------
create table public.daily_puzzles (
  id uuid primary key default gen_random_uuid(),
  puzzle_date date not null,
  puzzle_type text not null,
  public_config jsonb not null default '{}'::jsonb,
  encrypted_answer bytea not null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique (puzzle_date, puzzle_type)
);

alter table public.daily_puzzles enable row level security;

-- Clients read puzzles only through get_daily_puzzle(), which returns the
-- safe columns and nothing else.
--
-- RLS with no policy would already return zero rows, but that protects the
-- data only as long as nobody adds a policy - and someone eventually will,
-- for a good reason, and take encrypted_answer public with it. Revoking the
-- grant outright makes "a column added to this table is private by default"
-- an actual property rather than a comment. A pgTAP test asserts it.
revoke all on public.daily_puzzles from anon, authenticated;

create table public.puzzle_attempts (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  puzzle_id uuid not null references public.daily_puzzles(id) on delete cascade,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'won', 'lost')),
  state jsonb not null default '{}'::jsonb,
  score integer,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (child_id, puzzle_id)
);

alter table public.puzzle_attempts enable row level security;

create table public.puzzle_moves (
  id bigint generated always as identity primary key,
  attempt_id uuid not null references public.puzzle_attempts(id) on delete cascade,
  move_number integer not null,
  move_data jsonb not null,
  result jsonb,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  unique (attempt_id, move_number)
);

alter table public.puzzle_moves enable row level security;

create table public.puzzle_streaks (
  id bigint generated always as identity primary key,
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  puzzle_type text not null,
  current_count integer not null default 0,
  longest_count integer not null default 0,
  last_qualified_date date,
  updated_at timestamptz not null default now(),
  unique (child_id, puzzle_type)
);

alter table public.puzzle_streaks enable row level security;

create index puzzle_attempts_child_id_idx on public.puzzle_attempts(child_id);
create index puzzle_moves_attempt_id_idx on public.puzzle_moves(attempt_id, move_number);
create index daily_puzzles_type_date_idx on public.daily_puzzles(puzzle_type, puzzle_date desc);

-- ----------------------------------------------------------------------------
-- Ownership helper
-- ----------------------------------------------------------------------------
-- Same check the existing policies inline; extracted because the minigame
-- tables and RPCs need it in a dozen places.
create or replace function public.owns_child(target_child_id uuid)
returns boolean language sql security definer stable set search_path = '' as $$
  select exists (
    select 1 from public.child_profiles c
    where c.id = target_child_id and c.parent_id = (select auth.uid())
  );
$$;

-- ----------------------------------------------------------------------------
-- Read policies
-- ----------------------------------------------------------------------------
-- Read-only on purpose. Attempts and moves are written exclusively by the
-- SECURITY DEFINER functions below - that is what stops a client inventing a
-- finished, high-scoring attempt or a move the server never graded.
create policy "Parents can read child attempts" on public.puzzle_attempts
for select to authenticated using (public.owns_child(child_id));

create policy "Parents can read child moves" on public.puzzle_moves
for select to authenticated
using (exists (
  select 1 from public.puzzle_attempts a
  where a.id = attempt_id and public.owns_child(a.child_id)
));

create policy "Parents can read child streaks" on public.puzzle_streaks
for select to authenticated using (public.owns_child(child_id));

-- ----------------------------------------------------------------------------
-- Private helpers
-- ----------------------------------------------------------------------------
-- NOTE: these are revoked from anon and authenticated *by name*, not just
-- from PUBLIC. Supabase grants EXECUTE on new functions to those roles
-- explicitly, and an explicit grant survives a revoke aimed at PUBLIC - so
-- revoking only from PUBLIC would leave puzzle_answer() callable by any
-- signed-in user, handing out the answer to every puzzle in the game.
create or replace function public.minigame_encryption_key()
returns text language sql security definer stable set search_path = '' as $$
  select value from public.app_secrets where name = 'minigame_encryption_key';
$$;

revoke execute on function public.minigame_encryption_key() from public, anon, authenticated;

-- search_path names `extensions` because that is where hosted Supabase keeps
-- pgcrypto; a local stack may instead have it in public.
create or replace function public.puzzle_answer(p_puzzle_id uuid)
returns jsonb language plpgsql security definer stable
set search_path = public, extensions as $$
declare
  v_key text;
  v_answer jsonb;
begin
  v_key := public.minigame_encryption_key();
  if v_key is null then
    raise exception 'minigame_encryption_key is not set - see app_secrets in migration 202609030001';
  end if;

  select pgp_sym_decrypt(encrypted_answer, v_key)::jsonb into v_answer
  from public.daily_puzzles where id = p_puzzle_id;

  if v_answer is null then
    raise exception 'no answer stored for puzzle %', p_puzzle_id;
  end if;

  return v_answer;
end;
$$;

revoke execute on function public.puzzle_answer(uuid) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Client-facing RPCs
-- ----------------------------------------------------------------------------

-- Today's puzzle, or a past date for archive play. Never returns
-- encrypted_answer, and never a puzzle dated in the future.
create or replace function public.get_daily_puzzle(p_puzzle_type text, p_puzzle_date date)
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
    and d.puzzle_date = p_puzzle_date
    and d.published_at is not null
    and d.puzzle_date <= current_date;
$$;

revoke execute on function public.get_daily_puzzle(text, date) from public, anon;
grant execute on function public.get_daily_puzzle(text, date) to authenticated;

-- Which past days are playable, and how this child did on each. A null
-- status means they have never opened that day.
create or replace function public.list_puzzle_archive(
  p_child_id uuid, p_puzzle_type text, p_limit integer default 30
)
returns table (
  puzzle_id uuid,
  puzzle_date date,
  status text,
  score integer
)
language sql security definer stable set search_path = '' as $$
  select d.id, d.puzzle_date, a.status, a.score
  from public.daily_puzzles d
  left join public.puzzle_attempts a
    on a.puzzle_id = d.id and a.child_id = p_child_id
  where d.puzzle_type = p_puzzle_type
    and d.published_at is not null
    and d.puzzle_date <= current_date
    and public.owns_child(p_child_id)
  order by d.puzzle_date desc
  limit p_limit;
$$;

revoke execute on function public.list_puzzle_archive(uuid, text, integer) from public, anon;
grant execute on function public.list_puzzle_archive(uuid, text, integer) to authenticated;

-- Start an attempt, or return the in-flight one so closing the app mid-puzzle
-- resumes rather than restarts. Idempotent via the unique (child, puzzle) key.
create or replace function public.start_puzzle_attempt(p_child_id uuid, p_puzzle_id uuid)
returns public.puzzle_attempts
language plpgsql security definer set search_path = '' as $$
declare
  v_attempt public.puzzle_attempts;
begin
  if not public.owns_child(p_child_id) then
    raise exception 'not your child';
  end if;

  if not exists (
    select 1 from public.daily_puzzles
    where id = p_puzzle_id and published_at is not null and puzzle_date <= current_date
  ) then
    raise exception 'puzzle % is not available', p_puzzle_id;
  end if;

  select * into v_attempt from public.puzzle_attempts
  where child_id = p_child_id and puzzle_id = p_puzzle_id;

  if found then
    return v_attempt;
  end if;

  insert into public.puzzle_attempts (child_id, puzzle_id)
  values (p_child_id, p_puzzle_id)
  returning * into v_attempt;

  return v_attempt;
end;
$$;

revoke execute on function public.start_puzzle_attempt(uuid, uuid) from public, anon;
grant execute on function public.start_puzzle_attempt(uuid, uuid) to authenticated;

-- Submit one move. The only path that can see the answer, and it returns a
-- verdict only.
--
-- Validation is dispatched by name to validate_<puzzle_type>_move(), which
-- each game's own migration creates, so adding a game never edits this
-- function. puzzle_type is server-authored content rather than client input,
-- and is additionally constrained to a plain identifier and checked with
-- to_regprocedure before it is interpolated.
--
-- The validator contract: it takes (attempt_id, move_data, answer), returns a
-- jsonb verdict, and owns updating the attempt's state/status/score. It runs
-- inside this function's definer context, so it needs no elevation itself.
--
-- Replaying an idempotency key returns the original verdict instead of
-- grading twice, so a retry after a dropped connection cannot cost a guess.
create or replace function public.submit_puzzle_move(
  p_attempt_id uuid, p_move_data jsonb, p_idempotency_key text
)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_attempt public.puzzle_attempts;
  v_puzzle_type text;
  v_existing_result jsonb;
  v_answer jsonb;
  v_verdict jsonb;
  v_next integer;
begin
  select result into v_existing_result from public.puzzle_moves
  where idempotency_key = p_idempotency_key;
  if found then
    return v_existing_result;
  end if;

  select * into v_attempt from public.puzzle_attempts where id = p_attempt_id;
  if not found then
    raise exception 'attempt % not found', p_attempt_id;
  end if;

  if not public.owns_child(v_attempt.child_id) then
    raise exception 'not your attempt';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'attempt % is already %', p_attempt_id, v_attempt.status;
  end if;

  select puzzle_type into v_puzzle_type from public.daily_puzzles
  where id = v_attempt.puzzle_id;

  if v_puzzle_type !~ '^[a-z_]+$' then
    raise exception 'unsupported puzzle type %', v_puzzle_type;
  end if;

  if to_regprocedure(format('public.validate_%s_move(uuid, jsonb, jsonb)', v_puzzle_type)) is null then
    raise exception 'puzzle type % has no validator yet', v_puzzle_type;
  end if;

  v_answer := public.puzzle_answer(v_attempt.puzzle_id);

  execute format('select public.validate_%s_move($1, $2, $3)', v_puzzle_type)
  into v_verdict using p_attempt_id, p_move_data, v_answer;

  select coalesce(max(move_number), 0) + 1 into v_next
  from public.puzzle_moves where attempt_id = p_attempt_id;

  insert into public.puzzle_moves (attempt_id, move_number, move_data, result, idempotency_key)
  values (p_attempt_id, v_next, p_move_data, v_verdict, p_idempotency_key);

  return v_verdict;
end;
$$;

revoke execute on function public.submit_puzzle_move(uuid, jsonb, text) from public, anon;
grant execute on function public.submit_puzzle_move(uuid, jsonb, text) to authenticated;

-- Per-game streaks: same day is a no-op, the next day extends, a gap resets.
create or replace function public.record_puzzle_streak(
  p_child_id uuid, p_puzzle_type text, p_played_on date
)
returns public.puzzle_streaks
language plpgsql security definer set search_path = '' as $$
declare
  v_streak public.puzzle_streaks;
begin
  if not public.owns_child(p_child_id) then
    raise exception 'not your child';
  end if;

  select * into v_streak from public.puzzle_streaks
  where child_id = p_child_id and puzzle_type = p_puzzle_type;

  if not found then
    insert into public.puzzle_streaks (child_id, puzzle_type, current_count, longest_count, last_qualified_date)
    values (p_child_id, p_puzzle_type, 1, 1, p_played_on)
    returning * into v_streak;
    return v_streak;
  end if;

  if v_streak.last_qualified_date = p_played_on then
    return v_streak;
  elsif v_streak.last_qualified_date = p_played_on - 1 then
    update public.puzzle_streaks
    set current_count = current_count + 1,
        longest_count = greatest(longest_count, current_count + 1),
        last_qualified_date = p_played_on,
        updated_at = now()
    where id = v_streak.id returning * into v_streak;
  else
    update public.puzzle_streaks
    set current_count = 1,
        longest_count = greatest(longest_count, 1),
        last_qualified_date = p_played_on,
        updated_at = now()
    where id = v_streak.id returning * into v_streak;
  end if;

  return v_streak;
end;
$$;

revoke execute on function public.record_puzzle_streak(uuid, text, date) from public, anon;
grant execute on function public.record_puzzle_streak(uuid, text, date) to authenticated;

-- Read access to the new tables (matching the explicit-grant style of the
-- initial migration). Only select: every write goes through the RPCs above.
grant select on public.puzzle_attempts, public.puzzle_moves, public.puzzle_streaks to authenticated;
