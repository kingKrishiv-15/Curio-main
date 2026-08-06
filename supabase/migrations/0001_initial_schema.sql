-- ============================================================================
-- Curio - initial schema (Phase 0)
-- ============================================================================
-- Applies the full data model from the Phase 0 brief: every table, RLS on
-- every table, and the two RPCs needed for parent onboarding. No Squeeze /
-- story / maths / admin-tool logic lives here - that's later phases - but
-- the tables those phases need already exist so later migrations only ever
-- ADD, never restructure what earlier phases built on.
--
-- Design notes that apply throughout this file:
--
-- 1. AUTH_USER. The brief's ER diagram lists an AUTH_USER table, but Supabase
--    already provides this as the built-in `auth.users` table (managed by
--    Supabase Auth - GoTrue). Creating a second, parallel `auth_user` table
--    would duplicate and drift from the real one, so PROFILE.id is both the
--    primary key and a foreign key straight to `auth.users(id)` instead.
--    This is the standard Supabase "profile" pattern.
--
-- 2. Server-authoritative columns. Anywhere a column represents something
--    only server-side logic should ever set (scores, correctness, XP,
--    mastery, an encrypted puzzle answer) two layers protect it:
--      a) Row Level Security (RLS) controls which ROWS a role can touch.
--      b) Column-level GRANT controls which COLUMNS of a visible row a role
--         can read or write - Postgres supports privileges at column
--         granularity, and RLS alone can't express "you may see this row but
--         not this one column of it."
--    Supabase's `service_role` (used by Edge Functions) has BYPASSRLS and
--    keeps its own full table-level grants throughout, so it always retains
--    full access. `anon`/`authenticated` (used by the Flutter app via
--    PostgREST) are the roles this section restricts.
--
--    IMPORTANT: table-level and column-level grants in Postgres are
--    independent and additive - a role can read/write a column if EITHER
--    grant covers it. Supabase's platform bootstrap runs
--    `alter default privileges in schema public grant all on tables to
--    anon, authenticated, service_role`, so every table created below
--    starts out with a table-level grant already covering every column for
--    anon/authenticated. That means `revoke <priv> (<column>) ... from
--    anon` on its own is a no-op: the table-level grant still covers that
--    column regardless (see PostgreSQL docs on GRANT/REVOKE - "granting the
--    privilege at the table level and then revoking it for one column will
--    not do what one might wish"). The only way to actually lock a column
--    down is to revoke the table-level privilege entirely and re-grant it
--    column-by-column, explicitly excluding the protected column(s) - that
--    is the pattern used everywhere below (search for "column privileges").
--
-- 3. Forced-RPC tables. A few tables (profile, consent_record, child,
--    child_skill) have NO direct INSERT policy for anon/authenticated at
--    all. Creation only happens through the RPCs below, which are
--    SECURITY DEFINER and therefore bypass RLS/column grants internally -
--    but only after checking auth.uid() themselves. This guarantees the
--    behavioral spec's invariant (a profile never exists without its
--    consent record; a child never exists without its baseline skills)
--    can't be bypassed by a direct table write.

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- Helper functions (used throughout the RLS policies below)
-- ----------------------------------------------------------------------------

-- True if the given child belongs to the currently authenticated parent.
create or replace function public.is_own_child(target_child_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.child
    where id = target_child_id
      and parent_id = auth.uid()
  );
$$;

-- True if the currently authenticated user's profile has role = 'admin'.
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profile
    where id = auth.uid()
      and role = 'admin'
  );
$$;

-- ----------------------------------------------------------------------------
-- profile
-- Mirrors auth.users 1:1. Created only via create_parent_profile() below -
-- see "Forced-RPC tables" note above.
-- ----------------------------------------------------------------------------
create table public.profile (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('parent', 'child', 'admin')),
  display_name text not null,
  preferred_language text not null default 'en',
  status text not null default 'active' check (status in ('active', 'suspended', 'deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profile enable row level security;

create policy "profile: read own" on public.profile
  for select using (id = auth.uid());

create policy "profile: admin read all" on public.profile
  for select using (public.is_admin());

create policy "profile: update own" on public.profile
  for update using (id = auth.uid()) with check (id = auth.uid());

-- No insert policy for anon/authenticated - see create_parent_profile().

-- ----------------------------------------------------------------------------
-- consent_record
-- Created only via create_parent_profile() below, in the same transaction as
-- the profile row it belongs to.
-- ----------------------------------------------------------------------------
create table public.consent_record (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profile (id) on delete cascade,
  consent_type text not null,
  policy_version text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz
);

alter table public.consent_record enable row level security;

create policy "consent_record: read own" on public.consent_record
  for select using (parent_id = auth.uid());

-- A parent can revoke their own consent (sets revoked_at) but can't touch
-- granted_at/policy_version/consent_type after the fact - those are a
-- historical record of what was actually agreed to.
create policy "consent_record: revoke own" on public.consent_record
  for update using (parent_id = auth.uid()) with check (parent_id = auth.uid());

-- Column privileges: only revoked_at is updatable (see "Server-authoritative
-- columns" note above for why a plain REVOKE alone wouldn't work here).
revoke update on public.consent_record from anon, authenticated;
grant update (revoked_at) on public.consent_record to anon, authenticated;

-- ----------------------------------------------------------------------------
-- child
-- Created only via add_child_profile() below, together with its baseline
-- child_skill rows - see "Forced-RPC tables" note above.
-- ----------------------------------------------------------------------------
create table public.child (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profile (id) on delete cascade,
  display_name text not null,
  avatar_key text,
  age_band text not null,
  preferred_language text not null default 'en',
  total_xp int not null default 0,
  dragon_stage int not null default 1,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.child enable row level security;

create policy "child: read own" on public.child
  for select using (parent_id = auth.uid());

create policy "child: update own" on public.child
  for update using (parent_id = auth.uid()) with check (parent_id = auth.uid());

-- total_xp/dragon_stage are server-computed from reward_ledger entries by
-- the (not-yet-built, Phase 2+) reward-awarding RPC - a parent can rename,
-- reassign the age band, or deactivate their child, but can't hand them XP
-- or a dragon stage directly (column privileges - see "Server-authoritative
-- columns" note above for why a plain REVOKE alone wouldn't work here).
revoke update on public.child from anon, authenticated;
grant update (display_name, avatar_key, age_band, preferred_language, active, updated_at)
  on public.child to anon, authenticated;

-- No insert policy for anon/authenticated - see add_child_profile().

-- ----------------------------------------------------------------------------
-- device
-- One row per device a profile has signed in on (for push notifications and
-- basic diagnostics).
-- ----------------------------------------------------------------------------
create table public.device (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profile (id) on delete cascade,
  platform text not null,
  push_token text,
  app_version text,
  last_seen_at timestamptz not null default now()
);

alter table public.device enable row level security;

create policy "device: read own" on public.device
  for select using (profile_id = auth.uid());

create policy "device: insert own" on public.device
  for insert with check (profile_id = auth.uid());

create policy "device: update own" on public.device
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- ----------------------------------------------------------------------------
-- skill
-- The fixed catalogue of critical-thinking skills and maths domains.
-- ----------------------------------------------------------------------------
create table public.skill (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  category text not null,
  name text not null,
  description text,
  active boolean not null default true
);

alter table public.skill enable row level security;

create policy "skill: public read" on public.skill
  for select to anon, authenticated using (true);

-- ----------------------------------------------------------------------------
-- child_skill
-- Each child's mastery/confidence in each skill. Rows are created only by
-- add_child_profile() (baseline, at signup) and updated only by the
-- not-yet-built mastery-update RPC (Phase 2+) - never directly by a parent.
-- ----------------------------------------------------------------------------
create table public.child_skill (
  child_id uuid not null references public.child (id) on delete cascade,
  skill_id uuid not null references public.skill (id) on delete cascade,
  mastery_score numeric(5, 4) not null default 0 check (mastery_score between 0 and 1),
  confidence_score numeric(5, 4) not null default 0 check (confidence_score between 0 and 1),
  attempts_count int not null default 0,
  last_practiced_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (child_id, skill_id)
);

alter table public.child_skill enable row level security;

create policy "child_skill: read own child" on public.child_skill
  for select using (public.is_own_child(child_id));

-- No insert/update policy for anon/authenticated - see add_child_profile()
-- and the "Forced-RPC tables" note. Mastery updates land here in Phase 2+
-- via the same SECURITY DEFINER RPC pattern used below.

-- ----------------------------------------------------------------------------
-- content_item / content_version
-- Every piece of authored content (stories, activities, questions) is
-- versioned: content_item is the stable identity, content_version is one
-- immutable version of it. Nothing is ever edited in place.
-- ----------------------------------------------------------------------------
create table public.content_item (
  id uuid primary key default gen_random_uuid(),
  content_type text not null,
  stable_key text not null unique,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_by uuid references public.profile (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.content_item enable row level security;

create policy "content_item: public read" on public.content_item
  for select to anon, authenticated using (true);

create table public.content_version (
  id uuid primary key default gen_random_uuid(),
  content_item_id uuid not null references public.content_item (id) on delete cascade,
  version_number int not null,
  language text not null default 'en',
  title text not null,
  body jsonb not null default '{}'::jsonb,
  review_status text not null default 'draft' check (review_status in ('draft', 'in_review', 'approved', 'published', 'rejected')),
  published_at timestamptz,
  unique (content_item_id, version_number)
);

alter table public.content_version enable row level security;

-- Clients only ever see published content. Draft/in-review versions are
-- visible to admins (for the not-yet-built review tool) and to whichever
-- role authored them via the service role in the admin flow.
create policy "content_version: public read published" on public.content_version
  for select to anon, authenticated using (review_status = 'published');

create policy "content_version: admin read all" on public.content_version
  for select using (public.is_admin());

-- ----------------------------------------------------------------------------
-- activity_version
-- One playable activity, built from a published content_version.
-- ----------------------------------------------------------------------------
create table public.activity_version (
  id uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references public.content_version (id) on delete cascade,
  mode text not null,
  age_band text not null,
  difficulty int not null check (difficulty between 1 and 5),
  estimated_minutes int,
  rules jsonb not null default '{}'::jsonb
);

alter table public.activity_version enable row level security;

create policy "activity_version: public read" on public.activity_version
  for select to anon, authenticated using (true);

-- ----------------------------------------------------------------------------
-- question / question_version
-- Versioned the same way as content - a question's wording, options, and
-- correct-answer rule are never edited in place, only superseded.
-- ----------------------------------------------------------------------------
create table public.question (
  id uuid primary key default gen_random_uuid(),
  stable_key text not null unique,
  question_type text not null,
  created_at timestamptz not null default now()
);

alter table public.question enable row level security;

create policy "question: public read" on public.question
  for select to anon, authenticated using (true);

create table public.question_version (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.question (id) on delete cascade,
  version_number int not null,
  language text not null default 'en',
  prompt text not null,
  options jsonb,
  validation_rule jsonb not null,
  explanation jsonb,
  difficulty int check (difficulty between 1 and 5),
  unique (question_id, version_number)
);

alter table public.question_version enable row level security;

-- validation_rule encodes how to grade the question (e.g. the correct
-- option key, or a numeric range) - it must stay server-side-readable-only
-- in spirit, but unlike daily_puzzle's answer it's not a single shared
-- secret reused across every child, so table-level public read is
-- acceptable here; grading still always happens server-side (RPC/Edge
-- Function), never by trusting a client-computed is_correct.
create policy "question_version: public read" on public.question_version
  for select to anon, authenticated using (true);

-- ----------------------------------------------------------------------------
-- activity_question / question_skill
-- Join tables: which questions make up an activity, and which skills a
-- question exercises.
-- ----------------------------------------------------------------------------
create table public.activity_question (
  activity_version_id uuid not null references public.activity_version (id) on delete cascade,
  question_version_id uuid not null references public.question_version (id) on delete cascade,
  position int not null,
  required boolean not null default true,
  primary key (activity_version_id, question_version_id)
);

alter table public.activity_question enable row level security;

create policy "activity_question: public read" on public.activity_question
  for select to anon, authenticated using (true);

create table public.question_skill (
  question_version_id uuid not null references public.question_version (id) on delete cascade,
  skill_id uuid not null references public.skill (id) on delete cascade,
  weight numeric(4, 3) not null default 1.0 check (weight > 0),
  primary key (question_version_id, skill_id)
);

alter table public.question_skill enable row level security;

create policy "question_skill: public read" on public.question_skill
  for select to anon, authenticated using (true);

-- ----------------------------------------------------------------------------
-- learning_session
-- One row per attempt at an activity. Clients can start a session and mark
-- it abandoned; only the (not-yet-built) finalize RPC ever sets score or
-- xp_awarded - see "Server-authoritative columns" note above.
-- ----------------------------------------------------------------------------
create table public.learning_session (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child (id) on delete cascade,
  activity_version_id uuid not null references public.activity_version (id) on delete restrict,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  idempotency_key text not null unique,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  score int,
  xp_awarded int,
  client_version text
);

alter table public.learning_session enable row level security;

create policy "learning_session: read own child" on public.learning_session
  for select using (public.is_own_child(child_id));

create policy "learning_session: insert own child" on public.learning_session
  for insert with check (public.is_own_child(child_id));

create policy "learning_session: update own child" on public.learning_session
  for update using (public.is_own_child(child_id));

-- Column privileges: score/xp_awarded are never client-writable at all -
-- not on insert, not on update (see "Server-authoritative columns" note
-- above for why a plain REVOKE alone wouldn't work here). Once started, the
-- only thing a client can legitimately change is status (e.g. -> abandoned)
-- and completed_at; child_id/activity_version_id/idempotency_key are
-- write-once at creation. `id` is insertable (not just server-defaulted) so
-- the offline sync queue (local/ layer) can pre-generate a UUID for a
-- session started while offline and safely replay that exact insert once
-- reconnected - idempotency_key is what makes the replay itself safe to
-- retry, `id` being client-choosable is what lets local-first code
-- reference the row before the server has ever seen it.
revoke insert, update on public.learning_session from anon, authenticated;
grant insert (id, child_id, activity_version_id, status, idempotency_key, started_at, client_version)
  on public.learning_session to anon, authenticated;
grant update (status, completed_at) on public.learning_session to anon, authenticated;

-- ----------------------------------------------------------------------------
-- response
-- One row per answer submitted within a session. is_correct is always
-- server-computed - see "Server-authoritative columns" note above.
-- ----------------------------------------------------------------------------
create table public.response (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.learning_session (id) on delete cascade,
  question_version_id uuid not null references public.question_version (id) on delete restrict,
  response_value jsonb not null,
  is_correct boolean,
  attempt_number int not null default 1,
  duration_ms int,
  idempotency_key text not null unique,
  answered_at timestamptz not null default now()
);

alter table public.response enable row level security;

create policy "response: read own child" on public.response
  for select using (
    exists (
      select 1 from public.learning_session
      where learning_session.id = response.session_id
        and public.is_own_child(learning_session.child_id)
    )
  );

create policy "response: insert own child" on public.response
  for insert with check (
    exists (
      select 1 from public.learning_session
      where learning_session.id = response.session_id
        and public.is_own_child(learning_session.child_id)
    )
  );

-- Column privileges: is_correct is never client-writable (see
-- "Server-authoritative columns" note above for why a plain REVOKE alone
-- wouldn't work here). There's no UPDATE policy on this table at all, so
-- update access is already fully blocked at the RLS layer regardless.
revoke insert on public.response from anon, authenticated;
grant insert (session_id, question_version_id, response_value, attempt_number, duration_ms, idempotency_key, answered_at)
  on public.response to anon, authenticated;

-- ----------------------------------------------------------------------------
-- daily_puzzle
-- ============================================================================
-- CRITICAL: encrypted_answer must never be readable by anon/authenticated.
--
-- How the encryption works:
--   - encrypted_answer is produced with pgcrypto's pgp_sym_encrypt(), keyed
--     by DAILY_PUZZLE_ENCRYPTION_KEY - a secret that lives ONLY in the
--     Squeeze Edge Function's environment (Supabase Edge Function secrets),
--     never in the database, never in this repo, never sent to the client.
--   - Write path (Edge Function, using the service_role key so it can write
--     the puzzle before it's "live"):
--       insert into daily_puzzle (puzzle_date, puzzle_type, encrypted_answer, public_config)
--       values ($1, $2, pgp_sym_encrypt($3::text, $4), $5)
--       -- $3 = the plaintext target number, $4 = DAILY_PUZZLE_ENCRYPTION_KEY
--       -- (passed in from the Edge Function's env on every call, never
--       -- persisted as a column or a Postgres setting).
--   - Validate path (Edge Function, service_role): decrypts, compares
--     against the child's guess, and returns ONLY the outcome
--     ('too_low' | 'too_high' | 'correct') to the client - the decrypted
--     value itself is never part of any response body.
--       select pgp_sym_decrypt(encrypted_answer, $1) = $2::text
--       from daily_puzzle where puzzle_date = $3
--
-- Why RLS alone isn't enough here: RLS decides which ROWS are visible, and
-- children legitimately need to see today's row (for puzzle_type and
-- public_config, e.g. the guessable number range). A `for select using
-- (true)` policy would make the whole visible row's columns readable,
-- including encrypted_answer, unless something else blocks that column
-- specifically. That "something else" is a column-level grant, done
-- carefully: `revoke select (encrypted_answer) ... from anon` on its own
-- would NOT work, because Supabase's default privileges already grant
-- anon/authenticated table-level SELECT on every new table, and Postgres
-- table-level and column-level grants are independent/additive - a
-- column-level revoke can't take away access a table-level grant already
-- provides (see "Server-authoritative columns" note at the top of this
-- file). So instead: revoke the table-level SELECT entirely, then grant
-- SELECT back explicitly listing every column except encrypted_answer. That
-- way there is no grant path - table-level or column-level - through which
-- anon/authenticated can ever read that column. service_role is never
-- touched by either statement, so the Edge Function's decrypt path (which
-- runs as service_role) is unaffected.
-- ============================================================================
create table public.daily_puzzle (
  id uuid primary key default gen_random_uuid(),
  puzzle_date date not null unique,
  puzzle_type text not null,
  encrypted_answer bytea not null,
  public_config jsonb not null default '{}'::jsonb,
  published_at timestamptz
);

alter table public.daily_puzzle enable row level security;

create policy "daily_puzzle: public read" on public.daily_puzzle
  for select to anon, authenticated using (true);

revoke select on public.daily_puzzle from anon, authenticated;
grant select (id, puzzle_date, puzzle_type, public_config, published_at)
  on public.daily_puzzle to anon, authenticated;

-- Operational gotcha for whoever builds the Squeeze client query (Phase 2+):
-- `select * from daily_puzzle` (or supabase-flutter's `.select()` with no
-- explicit column list, which defaults to `*`) expands to every column at
-- parse time - if any expanded column lacks privilege, Postgres rejects the
-- WHOLE query with "permission denied for column encrypted_answer", it does
-- not silently return just the visible columns. Any client-side read of
-- this table must explicitly list columns, e.g.
-- `.select('id, puzzle_date, puzzle_type, public_config, published_at')`.

-- ----------------------------------------------------------------------------
-- squeeze_attempt / squeeze_guess
-- A child's attempt at a daily puzzle, and each individual guess within it.
-- Guesses are written by the Squeeze Edge Function (service_role) only,
-- since validating a guess requires decrypting daily_puzzle.encrypted_answer
-- (see above) - clients never insert squeeze_guess rows directly.
-- ----------------------------------------------------------------------------
create table public.squeeze_attempt (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child (id) on delete cascade,
  puzzle_id uuid not null references public.daily_puzzle (id) on delete restrict,
  status text not null default 'in_progress' check (status in ('in_progress', 'won', 'lost', 'abandoned')),
  guesses_used int not null default 0,
  score int,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.squeeze_attempt enable row level security;

create policy "squeeze_attempt: read own child" on public.squeeze_attempt
  for select using (public.is_own_child(child_id));

create policy "squeeze_attempt: insert own child" on public.squeeze_attempt
  for insert with check (public.is_own_child(child_id));

-- Column privileges: score (and guesses_used/status, which only the
-- Squeeze Edge Function should progress) are never client-writable (see
-- "Server-authoritative columns" note above for why a plain REVOKE alone
-- wouldn't work here). There's no UPDATE policy on this table at all, so
-- update access is already fully blocked at the RLS layer regardless.
revoke insert on public.squeeze_attempt from anon, authenticated;
grant insert (child_id, puzzle_id) on public.squeeze_attempt to anon, authenticated;

create table public.squeeze_guess (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.squeeze_attempt (id) on delete cascade,
  guess_value int not null,
  result text check (result in ('too_low', 'too_high', 'correct')),
  revealed_fact jsonb,
  idempotency_key text not null unique,
  created_at timestamptz not null default now()
);

alter table public.squeeze_guess enable row level security;

create policy "squeeze_guess: read own child" on public.squeeze_guess
  for select using (
    exists (
      select 1 from public.squeeze_attempt
      where squeeze_attempt.id = squeeze_guess.attempt_id
        and public.is_own_child(squeeze_attempt.child_id)
    )
  );

-- No insert policy for anon/authenticated - guesses are submitted through
-- the Squeeze Edge Function (service_role), which is the only path that can
-- decrypt daily_puzzle.encrypted_answer to compute `result`.

-- ----------------------------------------------------------------------------
-- streak
-- ----------------------------------------------------------------------------
create table public.streak (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child (id) on delete cascade,
  streak_type text not null,
  current_count int not null default 0,
  longest_count int not null default 0,
  last_qualified_date date,
  updated_at timestamptz not null default now(),
  unique (child_id, streak_type)
);

alter table public.streak enable row level security;

create policy "streak: read own child" on public.streak
  for select using (public.is_own_child(child_id));

-- No insert/update policy for anon/authenticated - streak counters are
-- maintained by server-side session-finalization logic (Phase 2+), the same
-- way total_xp and dragon_stage are.

-- ----------------------------------------------------------------------------
-- reward / reward_ledger
-- reward is the catalogue (badges, cosmetics, etc). reward_ledger is the
-- append-only record of what's actually been awarded to a child - always
-- written by server-side logic (session finalization, reward-awarding RPC),
-- never by the client, and never edited after the fact.
-- ----------------------------------------------------------------------------
create table public.reward (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  reward_type text not null,
  name text not null,
  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true
);

alter table public.reward enable row level security;

create policy "reward: public read" on public.reward
  for select to anon, authenticated using (true);

create table public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child (id) on delete cascade,
  reward_id uuid not null references public.reward (id) on delete restrict,
  session_id uuid references public.learning_session (id) on delete set null,
  xp_delta int not null,
  reason text not null,
  idempotency_key text not null unique,
  awarded_at timestamptz not null default now()
);

alter table public.reward_ledger enable row level security;

create policy "reward_ledger: read own child" on public.reward_ledger
  for select using (public.is_own_child(child_id));

-- No insert/update policy for anon/authenticated at all - this table is
-- service_role-write-only (the reward-awarding RPC/Edge Function).

-- ----------------------------------------------------------------------------
-- fact / child_fact
-- The general-knowledge fact library and which facts a child has collected.
-- ----------------------------------------------------------------------------
create table public.fact (
  id uuid primary key default gen_random_uuid(),
  stable_key text not null unique,
  theme text not null,
  language text not null default 'en',
  title text not null,
  content text not null,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived'))
);

alter table public.fact enable row level security;

create policy "fact: public read published" on public.fact
  for select to anon, authenticated using (status = 'published');

create policy "fact: admin read all" on public.fact
  for select using (public.is_admin());

create table public.child_fact (
  child_id uuid not null references public.child (id) on delete cascade,
  fact_id uuid not null references public.fact (id) on delete cascade,
  source_session_id uuid references public.learning_session (id) on delete set null,
  collected_at timestamptz not null default now(),
  primary key (child_id, fact_id)
);

alter table public.child_fact enable row level security;

create policy "child_fact: read own child" on public.child_fact
  for select using (public.is_own_child(child_id));

create policy "child_fact: insert own child" on public.child_fact
  for insert with check (public.is_own_child(child_id));

-- ----------------------------------------------------------------------------
-- admin_audit_log
-- Append-only log of admin actions. Admin-only read, no client write path
-- at all (the not-yet-built admin tool writes via service_role).
-- ----------------------------------------------------------------------------
create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references public.profile (id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  changes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.admin_audit_log enable row level security;

create policy "admin_audit_log: admin read" on public.admin_audit_log
  for select using (public.is_admin());

-- ============================================================================
-- RPCs: parent onboarding (Phase 0/1)
-- ============================================================================
-- Both are SECURITY DEFINER so they can write to tables that otherwise have
-- no direct INSERT policy for anon/authenticated (see "Forced-RPC tables"
-- note at the top of this file). Both derive identity exclusively from
-- auth.uid() - never from a caller-supplied parameter - so a signed-in
-- parent can only ever create their own profile/consent/child, never
-- someone else's. `set search_path = public` plus fully-qualified
-- `public.` references on every table/function protects against
-- search_path-hijacking, the standard risk with SECURITY DEFINER functions.
--
-- Atomicity comes from Postgres itself: a PL/pgSQL function body runs inside
-- the calling statement's transaction, so if any statement inside raises an
-- unhandled exception, every change the function made up to that point is
-- rolled back automatically - there is no partial-success state to clean up.

-- Step 2 of onboarding: create the parent's profile and consent record
-- together, atomically. If the consent insert fails for any reason, the
-- profile insert is rolled back too - a profile can never exist without a
-- matching consent record.
create or replace function public.create_parent_profile(
  p_display_name text,
  p_preferred_language text,
  p_consent_type text,
  p_policy_version text
)
returns public.profile
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profile;
begin
  if auth.uid() is null then
    raise exception 'create_parent_profile requires an authenticated user';
  end if;

  if p_consent_type is null or p_policy_version is null then
    raise exception 'consent_type and policy_version are required';
  end if;

  insert into public.profile (id, role, display_name, preferred_language)
  values (auth.uid(), 'parent', p_display_name, coalesce(p_preferred_language, 'en'))
  returning * into v_profile;

  insert into public.consent_record (parent_id, consent_type, policy_version)
  values (auth.uid(), p_consent_type, p_policy_version);

  return v_profile;
end;
$$;

revoke execute on function public.create_parent_profile(text, text, text, text) from public;
grant execute on function public.create_parent_profile(text, text, text, text) to authenticated;

-- Step 3 of onboarding: create a child profile and initialize baseline
-- child_skill rows for every active skill, atomically. A child can never
-- exist without a full set of baseline skill rows.
create or replace function public.add_child_profile(
  p_display_name text,
  p_avatar_key text,
  p_age_band text,
  p_preferred_language text
)
returns public.child
language plpgsql
security definer
set search_path = public
as $$
declare
  v_child public.child;
begin
  if auth.uid() is null then
    raise exception 'add_child_profile requires an authenticated user';
  end if;

  if not exists (select 1 from public.profile where id = auth.uid() and role = 'parent') then
    raise exception 'only a parent profile can add a child';
  end if;

  if p_display_name is null or p_age_band is null then
    raise exception 'display_name and age_band are required';
  end if;

  insert into public.child (parent_id, display_name, avatar_key, age_band, preferred_language)
  values (auth.uid(), p_display_name, p_avatar_key, p_age_band, coalesce(p_preferred_language, 'en'))
  returning * into v_child;

  insert into public.child_skill (child_id, skill_id)
  select v_child.id, skill.id
  from public.skill
  where skill.active = true;

  return v_child;
end;
$$;

revoke execute on function public.add_child_profile(text, text, text, text) from public;
grant execute on function public.add_child_profile(text, text, text, text) to authenticated;

-- ============================================================================
-- Seed data: the fixed skill catalogue
-- ============================================================================
insert into public.skill (code, category, name, description) values
  ('pattern_recognition', 'critical_thinking', 'Pattern Recognition', 'Spotting recurring structures, sequences, and relationships in information.'),
  ('hidden_assumptions', 'critical_thinking', 'Hidden Assumptions', 'Noticing the unstated beliefs an argument or claim depends on.'),
  ('evaluating_evidence', 'critical_thinking', 'Evaluating Evidence', 'Judging how strong, relevant, and reliable a piece of evidence really is.'),
  ('consequential_thinking', 'critical_thinking', 'Consequential Thinking', 'Tracing the likely knock-on effects of a decision before making it.'),
  ('arithmetic', 'maths', 'Arithmetic', 'Working confidently with numbers - operations, fractions, percentages.'),
  ('algebra', 'maths', 'Algebra', 'Using symbols and equations to represent and solve problems.'),
  ('geometry', 'maths', 'Geometry', 'Reasoning about shapes, space, angles, and measurement.'),
  ('number_logic', 'maths', 'Number & Logic', 'Number theory, sequences, and logical deduction puzzles.');
