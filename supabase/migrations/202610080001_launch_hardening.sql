-- ============================================================================
-- Launch hardening
-- ============================================================================
-- 1. Rewards live in a table, and the five newer games are in it. Before
--    this, sync_learning_progress only knew six activity ids and silently
--    dropped odd_cluster, sequence, bridge, cascade and loophole — their XP,
--    discoveries and streak days vanished on the next load.
-- 2. Streak discoveries: octopus_hearts, shortest_war and diwali_light unlock
--    at a best run of 3, 7 and 14 practice days (mirrors
--    CurioState.streakDiscoveries). Previously nothing could award them.
-- 3. No back-dated rewards: activities dated before the learner existed are
--    ignored.
-- 4. New learners start at 0 XP and a 0 streak (the old defaults were demo
--    values).
-- 5. Scheduler/outbox functions are no longer callable with the publishable
--    key. Supabase grants EXECUTE to anon and authenticated by name, so the
--    earlier `revoke ... from public` alone didn't remove it.
-- 6. Consent: the database stamps consent_at when the agreed version changes;
--    ordinary settings saves can't clear the version or re-stamp the date.
-- 7. Clients can't delete their family_settings row (the app always needs
--    one) or write puzzle tables directly (every write goes through RPCs).
-- 8. record_puzzle_streak only accepts a date around today.
-- 9. The weekly-email outbox only sends reports from the last two weeks, so
--    configuring email late doesn't flood parents with old reports.
-- Safe to re-run.
-- ============================================================================

-- 1. Reward catalogue ---------------------------------------------------------
create table if not exists public.activity_rewards (
  activity text primary key,
  xp integer not null check (xp between 0 and 500),
  skill text not null check (skill in ('Number sense', 'Patterns', 'Evidence', 'Reasoning')),
  fact text,
  -- Daily games are recorded as "<id>_YYYYMMDD"; one-off activities aren't.
  dated boolean not null default true
);
alter table public.activity_rewards enable row level security;
drop policy if exists "Signed-in users can read rewards" on public.activity_rewards;
create policy "Signed-in users can read rewards" on public.activity_rewards
  for select to authenticated using (true);
revoke all on public.activity_rewards from anon, authenticated;
grant select on public.activity_rewards to authenticated;
grant all on public.activity_rewards to service_role;

-- Keep in sync with the XP each game page awards (a Flutter test parses this).
insert into public.activity_rewards (activity, xp, skill, fact, dated) values
  ('squeeze', 80, 'Number sense', 'prime_numbers', true),
  ('link_lab', 90, 'Reasoning', 'classification_science', true),
  ('signal_grid', 100, 'Reasoning', 'binary_patterns', true),
  ('pattern_forge', 60, 'Patterns', 'fibonacci_nature', true),
  ('evidence_garden', 70, 'Evidence', 'weather_evidence', true),
  ('frostlands_night_1', 50, 'Reasoning', 'aurora_lights', false),
  ('odd_cluster', 100, 'Reasoning', 'giant_rings', true),
  ('sequence', 80, 'Patterns', 'triangular_numbers', true),
  ('bridge', 80, 'Number sense', 'order_matters', true),
  ('cascade', 90, 'Evidence', 'traffic_evaporation', true),
  ('loophole', 70, 'Evidence', 'sample_size', true)
on conflict (activity) do update
  set xp = excluded.xp, skill = excluded.skill, fact = excluded.fact, dated = excluded.dated;

-- 2 + 3. Progress sync ------------------------------------------------------------
create or replace function public.sync_learning_progress(child_id uuid, learner_name text, activities text[])
returns void
language plpgsql security definer set search_path = '' as $$
declare
  activity text;
  base text;
  reward public.activity_rewards;
  inserted integer;
  played_on date;
  born date;
  days date[];
  cursor_day date;
  run integer := 0;
  best integer := 0;
begin
  if auth.uid() is null or not exists (
    select 1 from public.child_profiles c where c.id = child_id and c.parent_id = auth.uid()
  ) then
    raise exception 'Not authorized';
  end if;
  if char_length(trim(learner_name)) not between 1 and 18
     or coalesce(array_length(activities, 1), 0) > 10000 then
    raise exception 'Invalid progress';
  end if;

  select c.created_at::date into born
  from public.child_profiles c where c.id = child_id for update;

  foreach activity in array activities loop
    played_on := null;
    if activity ~ '_[0-9]{8}$' then
      base := regexp_replace(activity, '_[0-9]{8}$', '');
      begin
        played_on := to_date(right(activity, 8), 'YYYYMMDD');
      exception when others then
        continue;
      end;
      -- Nothing from the future, nothing from before this learner existed.
      if played_on > current_date + 1 or played_on < born - 1 then continue; end if;
    else
      base := activity;
    end if;

    select * into reward from public.activity_rewards r where r.activity = base;
    if not found then continue; end if;
    if reward.dated <> (played_on is not null) then continue; end if;

    insert into public.activity_completions (child_id, activity_id)
    values (child_id, activity) on conflict do nothing;
    get diagnostics inserted = row_count;
    if inserted > 0 then
      update public.child_profiles c set total_xp = c.total_xp + reward.xp where c.id = child_id;
      insert into public.skill_progress (child_id, skill_key, mastery)
      values (child_id, reward.skill, .12)
      on conflict on constraint skill_progress_child_id_skill_key_key do update
        set mastery = least(1, public.skill_progress.mastery + .12), updated_at = now();
      if reward.fact is not null then
        insert into public.unlocked_discoveries (child_id, discovery_id)
        values (child_id, reward.fact) on conflict do nothing;
      end if;
    end if;
  end loop;

  select array_agg(distinct to_date(right(a.activity_id, 8), 'YYYYMMDD')) into days
  from public.activity_completions a
  where a.child_id = sync_learning_progress.child_id and a.activity_id ~ '_[0-9]{8}$';

  -- Current streak, in the family's time zone.
  select (now() at time zone coalesce(
    (select timezone from public.family_settings where parent_id = auth.uid()), 'UTC'))::date
  into cursor_day;
  if not (cursor_day = any (coalesce(days, '{}'::date[]))) then cursor_day := cursor_day - 1; end if;
  while cursor_day = any (coalesce(days, '{}'::date[])) loop
    run := run + 1;
    cursor_day := cursor_day - 1;
  end loop;

  -- Best streak ever (gaps and islands), for the streak discoveries.
  select coalesce(max(island.run_length), 0) into best
  from (
    select count(*) as run_length
    from (
      select d, d - (row_number() over (order by d))::integer as grp
      from unnest(coalesce(days, '{}'::date[])) as d
    ) runs
    group by runs.grp
  ) island;

  insert into public.unlocked_discoveries (child_id, discovery_id)
  select sync_learning_progress.child_id, milestone.fact
  from (values (3, 'octopus_hearts'), (7, 'shortest_war'), (14, 'diwali_light'))
    as milestone(need, fact)
  where best >= milestone.need
  on conflict do nothing;

  update public.child_profiles c
  set name = trim(learner_name), streak = run, updated_at = now()
  where c.id = child_id;
end $$;
revoke all on function public.sync_learning_progress(uuid, text, text[]) from public, anon;
grant execute on function public.sync_learning_progress(uuid, text, text[]) to authenticated;

-- 4. Fresh learners start at zero ---------------------------------------------
alter table public.child_profiles alter column total_xp set default 0;
alter table public.child_profiles alter column streak set default 0;

-- 5. Server-only functions -------------------------------------------------------
revoke all on function public.queue_family_updates() from public, anon, authenticated;
grant execute on function public.queue_family_updates() to service_role;
revoke all on function public.claim_parent_emails() from public, anon, authenticated;
grant execute on function public.claim_parent_emails() to service_role;
-- Called only from inside submit_puzzle_move (as its definer).
revoke all on function public.validate_loophole_move(uuid, jsonb, jsonb) from public, anon, authenticated;

-- 6. Consent can only move forward --------------------------------------------
create or replace function public.validate_family_settings() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from pg_timezone_names where name = new.timezone) then
    raise exception 'Choose a valid time zone';
  end if;
  if tg_op = 'UPDATE' then
    if new.consent_version is null then
      new.consent_version := old.consent_version;
    end if;
    if new.consent_version is not distinct from old.consent_version then
      new.consent_at := old.consent_at;
    else
      new.consent_at := now();
    end if;
  else
    new.consent_at := case when new.consent_version is null then null else now() end;
  end if;
  new.updated_at := now();
  return new;
end $$;

-- 7. Tighter table privileges --------------------------------------------------
revoke delete on public.family_settings from anon, authenticated;
revoke insert, update, delete on public.puzzle_attempts, public.puzzle_moves, public.puzzle_streaks
  from anon, authenticated;

-- 8. Puzzle streaks only for (about) today -------------------------------------
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
  -- One day of slack either way for time zones; anything else is tampering.
  if p_played_on not between current_date - 1 and current_date + 1 then
    raise exception 'played_on must be today';
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

-- 9. Don't send stale weekly emails ---------------------------------------------
create or replace function public.claim_parent_emails() returns setof public.email_outbox
language sql security definer set search_path = '' as $$
  update public.email_outbox set status = 'sending', claimed_at = now(),
    first_attempt_at = coalesce(first_attempt_at, now()), attempts = attempts + 1
  where id in (
    select o.id from public.email_outbox o
    join public.parent_reports r on r.id = o.report_id
    where o.attempts < 5
      and r.created_at > now() - interval '14 days'
      and (o.status = 'pending'
        or (o.status = 'failed' and o.claimed_at < now() - interval '1 hour')
        or (o.status = 'sending' and o.claimed_at < now() - interval '15 minutes'))
      -- Never automatically retry beyond the provider's 24-hour idempotency window.
      and (o.first_attempt_at is null or o.first_attempt_at > now() - interval '23 hours')
    order by o.id for update of o skip locked limit 25
  ) returning *;
$$;
revoke all on function public.claim_parent_emails() from public, anon, authenticated;
grant execute on function public.claim_parent_emails() to service_role;
