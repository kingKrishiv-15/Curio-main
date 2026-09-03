-- ============================================================================
-- Curio - daily minigames shared infrastructure
-- ============================================================================
-- One set of tables + RPCs shared by all five daily minigames (Loophole,
-- Odd Cluster, Sequence, Cascade, Bridge), keyed by daily_puzzle.puzzle_type
-- rather than five bespoke sets of tables. Game-specific shapes live in
-- jsonb columns, so adding a sixth game is "a new puzzle_type + one new
-- validator function", not a new schema and not an edit to anything here.
--
-- Design notes worth reading before changing anything:
--
-- 1. WHERE THE ANSWER LIVES. daily_puzzle already splits every puzzle into
--    `public_config` (jsonb, client-readable - the statement text, the 16
--    tile labels, the start/target numbers) and `encrypted_answer` (bytea,
--    which anon/authenticated have no SELECT grant on at all - see 0001's
--    daily_puzzle section). That split holds for all five games: anything
--    the client may see goes in public_config, the solution goes in
--    encrypted_answer as encrypted JSON. The client never receives the
--    answer in any form - it submits a move and gets back only an outcome.
--
-- 2. WHY POSTGRES RPCs, NOT EDGE FUNCTIONS. 0001 described Squeeze's
--    validation as an Edge Function holding the decryption key in its own
--    environment, so the key never touched Postgres. These five games use
--    SECURITY DEFINER Postgres functions instead. The security property that
--    actually matters is unchanged - no client-reachable path returns the
--    plaintext answer, because encrypted_answer has no client SELECT grant
--    and the RPCs return only outcomes. The trade is a smaller, testable
--    surface: these ship as ordinary migrations (applyable from the SQL
--    editor, exercised by pgTAP in CI) rather than five separately-deployed
--    Deno functions. If Squeeze later wants key custody genuinely outside
--    the database, it can still use an Edge Function against these tables.
--
-- 3. WHERE THE KEY LIVES. In `app_secret` below - a table no client role can
--    read, populated once per environment (see the ONE-TIME SETUP note on
--    that table). Supabase Vault would be the more purpose-built home and is
--    a clean swap later; it is deliberately not used here because this
--    migration has to apply identically on hosted Supabase and on the local
--    CLI stack CI runs against, and Vault's availability in that image
--    could not be verified from this machine. Swapping to Vault means
--    changing one function body (minigame_encryption_key) and nothing else.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- daily_puzzle: one puzzle per type per day, not one puzzle per day
-- ----------------------------------------------------------------------------
-- 0001 assumed a single daily puzzle (Squeeze). Five games now publish on the
-- same date, so uniqueness moves to the (date, type) pair. Everything else
-- about the table - including the encrypted_answer column grants - is
-- unchanged.
alter table public.daily_puzzle drop constraint daily_puzzle_puzzle_date_key;
alter table public.daily_puzzle add constraint daily_puzzle_date_type_key unique (puzzle_date, puzzle_type);

-- ----------------------------------------------------------------------------
-- Retire the Squeeze-specific attempt/guess tables
-- ----------------------------------------------------------------------------
-- These were created in 0001 for Squeeze specifically (guess_value int, a
-- too_low/too_high/correct result) and no application code was ever written
-- against them. Rather than leaving a bespoke pair of tables beside the
-- generic ones - exactly the "five sets of bespoke tables" shape this
-- migration exists to avoid - Squeeze becomes another puzzle_type on the
-- generic tables below when it's built.
drop table if exists public.squeeze_guess;
drop table if exists public.squeeze_attempt;

-- ----------------------------------------------------------------------------
-- app_secret
-- ----------------------------------------------------------------------------
-- Server-side secrets that must be readable by SECURITY DEFINER functions
-- but by nobody else. RLS is on with zero policies, so no client role can
-- read a row through PostgREST no matter what; the definer functions below
-- bypass RLS as the table owner.
--
-- ONE-TIME SETUP per environment (never commit the value):
--   insert into app_secret (name, value)
--   values ('minigame_encryption_key', '<a long random string>');
--
-- Puzzle-seeding scripts encrypt answers with the same key:
--   pgp_sym_encrypt(<answer jsonb>::text, (select value from app_secret where name = 'minigame_encryption_key'))
create table public.app_secret (
  name text primary key,
  value text not null,
  created_at timestamptz not null default now()
);

alter table public.app_secret enable row level security;
revoke all on public.app_secret from anon, authenticated;

-- ----------------------------------------------------------------------------
-- minigame_attempt
-- One row per child per puzzle (today's, or an archive one played later).
-- `state` is whatever that game needs to resume mid-puzzle: which groups Odd
-- Cluster has solved, how many numbers Sequence has revealed, which of
-- Loophole's three statements the player is on. Written only by the RPCs
-- below - never directly by a client.
-- ----------------------------------------------------------------------------
create table public.minigame_attempt (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child (id) on delete cascade,
  puzzle_id uuid not null references public.daily_puzzle (id) on delete restrict,
  status text not null default 'in_progress' check (status in ('in_progress', 'won', 'lost', 'abandoned')),
  state jsonb not null default '{}'::jsonb,
  score int,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (child_id, puzzle_id)
);

alter table public.minigame_attempt enable row level security;

create policy "minigame_attempt: read own child" on public.minigame_attempt
  for select using (public.is_own_child(child_id));

-- No insert/update policy for anon/authenticated at all: attempts are created
-- and advanced exclusively by the SECURITY DEFINER RPCs below, which is what
-- stops a client inventing a finished, high-scoring attempt.

-- ----------------------------------------------------------------------------
-- minigame_move
-- Append-only log of every guess/action in an attempt. `move_data` is what
-- the player did (a tapped token, four selected tiles, a predicted number, an
-- ordering); `result` is what the server decided about it. Both jsonb so all
-- five games share the table.
-- ----------------------------------------------------------------------------
create table public.minigame_move (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.minigame_attempt (id) on delete cascade,
  move_number int not null,
  move_data jsonb not null,
  result jsonb,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  unique (attempt_id, move_number)
);

alter table public.minigame_move enable row level security;

create policy "minigame_move: read own child" on public.minigame_move
  for select using (
    exists (
      select 1 from public.minigame_attempt
      where minigame_attempt.id = minigame_move.attempt_id
        and public.is_own_child(minigame_attempt.child_id)
    )
  );

-- No insert policy either - a move is only ever written by
-- submit_minigame_move(), which is also the only thing that can decrypt the
-- answer to decide `result`.

create index minigame_attempt_child_idx on public.minigame_attempt (child_id, started_at desc);
create index minigame_move_attempt_idx on public.minigame_move (attempt_id, move_number);

-- ============================================================================
-- Internal helpers (never granted to a client role)
-- ============================================================================

-- NOTE on the revokes below: `revoke ... from public` is NOT sufficient on
-- Supabase. Its bootstrap grants EXECUTE on new functions in this schema to
-- anon/authenticated *explicitly*, and an explicit grant to a role survives a
-- revoke aimed at PUBLIC - so these helpers stayed callable by any signed-in
-- user until the roles were named directly. That was a real hole: calling
-- minigame_answer() would have handed a client the decrypted answer to every
-- puzzle. Named revokes, and a pgTAP test asserting the denial, are what
-- close it. Same reasoning as the table-level grants in 0001.
create or replace function public.minigame_encryption_key()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select value from public.app_secret where name = 'minigame_encryption_key';
$$;

revoke execute on function public.minigame_encryption_key() from public, anon, authenticated;

-- search_path includes `extensions` because that is where a hosted Supabase
-- project keeps pgcrypto (the local CLI stack may instead have it in
-- public) - without it, pgp_sym_decrypt resolves on one and not the other.
create or replace function public.minigame_answer(p_puzzle_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public, extensions
as $$
declare
  v_key text;
  v_answer jsonb;
begin
  v_key := public.minigame_encryption_key();
  if v_key is null then
    raise exception 'minigame_encryption_key is not configured - see app_secret in migration 0002';
  end if;

  select pgp_sym_decrypt(encrypted_answer, v_key)::jsonb
  into v_answer
  from public.daily_puzzle
  where id = p_puzzle_id;

  if v_answer is null then
    raise exception 'no answer found for puzzle %', p_puzzle_id;
  end if;

  return v_answer;
end;
$$;

revoke execute on function public.minigame_answer(uuid) from public, anon, authenticated;

-- ============================================================================
-- RPCs the client calls
-- ============================================================================

-- Fetch a puzzle by type and date (today's, or any past date for the
-- archive). Returns only the client-safe half - never encrypted_answer. A
-- function rather than a view so "which columns are safe" lives in one
-- obvious place, and so a future-dated puzzle can't be pulled early.
create or replace function public.get_minigame_puzzle(p_puzzle_type text, p_puzzle_date date)
returns table (
  id uuid,
  puzzle_date date,
  puzzle_type text,
  public_config jsonb,
  published_at timestamptz
)
language sql
security invoker
stable
set search_path = public
as $$
  select d.id, d.puzzle_date, d.puzzle_type, d.public_config, d.published_at
  from public.daily_puzzle d
  where d.puzzle_type = p_puzzle_type
    and d.puzzle_date = p_puzzle_date
    and d.published_at is not null
    and d.puzzle_date <= current_date;
$$;

grant execute on function public.get_minigame_puzzle(text, date) to anon, authenticated;

-- The archive list: which dates of a given game are playable, and whether
-- this child has finished each one. Again, no answer data.
create or replace function public.list_minigame_archive(
  p_child_id uuid,
  p_puzzle_type text,
  p_limit int default 30
)
returns table (
  puzzle_id uuid,
  puzzle_date date,
  status text,
  score int
)
language sql
security invoker
stable
set search_path = public
as $$
  select d.id, d.puzzle_date, a.status, a.score
  from public.daily_puzzle d
  left join public.minigame_attempt a
    on a.puzzle_id = d.id and a.child_id = p_child_id
  where d.puzzle_type = p_puzzle_type
    and d.published_at is not null
    and d.puzzle_date <= current_date
  order by d.puzzle_date desc
  limit p_limit;
$$;

grant execute on function public.list_minigame_archive(uuid, text, int) to authenticated;

-- Start today's attempt, or return the existing one so a player who closes
-- the app mid-puzzle picks up exactly where they left off. Idempotent by
-- construction via the unique (child_id, puzzle_id) constraint.
create or replace function public.start_or_resume_minigame_attempt(
  p_child_id uuid,
  p_puzzle_id uuid
)
returns public.minigame_attempt
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.minigame_attempt;
begin
  if not public.is_own_child(p_child_id) then
    raise exception 'not your child';
  end if;

  if not exists (
    select 1 from public.daily_puzzle
    where id = p_puzzle_id
      and published_at is not null
      and puzzle_date <= current_date
  ) then
    raise exception 'puzzle % is not available yet', p_puzzle_id;
  end if;

  select * into v_attempt
  from public.minigame_attempt
  where child_id = p_child_id and puzzle_id = p_puzzle_id;

  if found then
    return v_attempt;
  end if;

  insert into public.minigame_attempt (child_id, puzzle_id)
  values (p_child_id, p_puzzle_id)
  returning * into v_attempt;

  return v_attempt;
end;
$$;

revoke execute on function public.start_or_resume_minigame_attempt(uuid, uuid) from public, anon, authenticated;
grant execute on function public.start_or_resume_minigame_attempt(uuid, uuid) to authenticated;

-- Submit one move. The only path that can see the answer, and it returns only
-- an outcome.
--
-- Per-game validation is dispatched by name to validate_<puzzle_type>_move(),
-- which each game's own migration creates. Dispatching dynamically (rather
-- than a CASE here) means adding a game never edits this function. The
-- puzzle_type comes from daily_puzzle - server-authored content, not client
-- input - and is additionally constrained to a plain identifier below before
-- it is ever interpolated.
--
-- The validator contract: it receives (attempt_id, move_data, answer),
-- returns a jsonb outcome, and is responsible for updating the attempt's
-- state/status/score. It runs inside this function's SECURITY DEFINER
-- context, so it can write those tables without being definer itself.
--
-- Idempotency: replaying a key returns that move's original result rather
-- than scoring it twice, so a retry after a dropped connection can't cost the
-- player a guess.
create or replace function public.submit_minigame_move(
  p_attempt_id uuid,
  p_move_data jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.minigame_attempt;
  v_puzzle_type text;
  v_existing public.minigame_move;
  v_answer jsonb;
  v_outcome jsonb;
  v_next_move_number int;
begin
  select * into v_existing from public.minigame_move where idempotency_key = p_idempotency_key;
  if found then
    return v_existing.result;
  end if;

  select * into v_attempt from public.minigame_attempt where id = p_attempt_id;
  if not found then
    raise exception 'attempt % not found', p_attempt_id;
  end if;

  if not public.is_own_child(v_attempt.child_id) then
    raise exception 'not your attempt';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'attempt % is already %', p_attempt_id, v_attempt.status;
  end if;

  select puzzle_type into v_puzzle_type from public.daily_puzzle where id = v_attempt.puzzle_id;

  if v_puzzle_type !~ '^[a-z_]+$' then
    raise exception 'unsupported puzzle_type %', v_puzzle_type;
  end if;

  if to_regprocedure(format('public.validate_%s_move(uuid, jsonb, jsonb)', v_puzzle_type)) is null then
    raise exception 'puzzle_type % has no validator yet', v_puzzle_type;
  end if;

  v_answer := public.minigame_answer(v_attempt.puzzle_id);

  execute format('select public.validate_%s_move($1, $2, $3)', v_puzzle_type)
  into v_outcome
  using p_attempt_id, p_move_data, v_answer;

  select coalesce(max(move_number), 0) + 1 into v_next_move_number
  from public.minigame_move where attempt_id = p_attempt_id;

  insert into public.minigame_move (attempt_id, move_number, move_data, result, idempotency_key)
  values (p_attempt_id, v_next_move_number, p_move_data, v_outcome, p_idempotency_key);

  return v_outcome;
end;
$$;

revoke execute on function public.submit_minigame_move(uuid, jsonb, text) from public, anon, authenticated;
grant execute on function public.submit_minigame_move(uuid, jsonb, text) to authenticated;

-- Record a completed day against this game's streak. streak_type is the
-- puzzle_type, so each game keeps its own streak on the existing table from
-- 0001 rather than inventing a per-game one.
create or replace function public.record_minigame_streak(p_child_id uuid, p_puzzle_type text, p_played_on date)
returns public.streak
language plpgsql
security definer
set search_path = public
as $$
declare
  v_streak public.streak;
begin
  if not public.is_own_child(p_child_id) then
    raise exception 'not your child';
  end if;

  select * into v_streak
  from public.streak
  where child_id = p_child_id and streak_type = p_puzzle_type;

  if not found then
    insert into public.streak (child_id, streak_type, current_count, longest_count, last_qualified_date)
    values (p_child_id, p_puzzle_type, 1, 1, p_played_on)
    returning * into v_streak;
    return v_streak;
  end if;

  -- Same day replay changes nothing; consecutive day extends; a gap resets.
  if v_streak.last_qualified_date = p_played_on then
    return v_streak;
  elsif v_streak.last_qualified_date = p_played_on - 1 then
    update public.streak
    set current_count = current_count + 1,
        longest_count = greatest(longest_count, current_count + 1),
        last_qualified_date = p_played_on,
        updated_at = now()
    where id = v_streak.id
    returning * into v_streak;
  else
    update public.streak
    set current_count = 1,
        longest_count = greatest(longest_count, 1),
        last_qualified_date = p_played_on,
        updated_at = now()
    where id = v_streak.id
    returning * into v_streak;
  end if;

  return v_streak;
end;
$$;

revoke execute on function public.record_minigame_streak(uuid, text, date) from public, anon, authenticated;
grant execute on function public.record_minigame_streak(uuid, text, date) to authenticated;
