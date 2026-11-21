begin;
create extension if not exists pgtap;
select plan(1);

do $$
declare
  opted_in constant uuid := 'b1220000-0000-0000-0000-000000000001';
  opted_out constant uuid := 'b1220000-0000-0000-0000-000000000002';
  unconfirmed constant uuid := 'b1220000-0000-0000-0000-000000000003';
  alex constant uuid := 'b1220000-0000-0000-0000-000000000004';
  maya constant uuid := 'b1220000-0000-0000-0000-000000000005';
  family_zone text;
  week date;
  report jsonb;
  job_id uuid;
begin
  -- Pick a real family time zone where this week's queue is open. This
  -- fixture works even on CI runs before Monday morning in UTC.
  select zone, date_trunc('week', local_now)::date - 7 into family_zone, week
  from (
    select zone, now() at time zone zone as local_now
    from unnest(array['UTC', 'Pacific/Kiritimati', 'Pacific/Honolulu']) as zones(zone)
  ) local_times
  where local_now >= date_trunc('week', local_now) + interval '8 hours'
  limit 1;
  if week is null then raise exception 'Failed to choose the report fixture week'; end if;

  insert into auth.users (id, aud, role, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data)
  values
    (opted_in, 'authenticated', 'authenticated', 'weekly-on@example.test', now(), '{}', '{}'),
    (opted_out, 'authenticated', 'authenticated', 'weekly-off@example.test', now(), '{}', '{}'),
    (unconfirmed, 'authenticated', 'authenticated', 'weekly-unconfirmed@example.test', null, '{}', '{}');

  update public.family_settings
  set timezone = family_zone, weekly_email_enabled = parent_id <> opted_out
  where parent_id in (opted_in, opted_out, unconfirmed);

  insert into public.child_profiles(id, parent_id, name, total_xp, created_at)
  values
    (alex, opted_in, 'Alex', 240, (week - 1)::timestamp at time zone family_zone),
    (maya, opted_in, 'Maya', 80, (week + 1)::timestamp at time zone family_zone),
    ('b1220000-0000-0000-0000-000000000006', opted_out, 'Ash', 80, (week + 1)::timestamp at time zone family_zone),
    ('b1220000-0000-0000-0000-000000000007', unconfirmed, 'Sam', 0, (week + 1)::timestamp at time zone family_zone),
    ('b1220000-0000-0000-0000-000000000008', opted_in, 'New explorer', 0, (week + 7)::timestamp at time zone family_zone);

  insert into public.activity_completions(child_id, activity_id) values
    (alex, 'memory_match_' || to_char(week, 'YYYYMMDD')),
    (alex, 'word_wise_' || to_char(week, 'YYYYMMDD')),
    (alex, 'number_hunt_' || to_char(week + 6, 'YYYYMMDD')),
    (alex, 'word_builder_' || to_char(week + 7, 'YYYYMMDD')),
    (alex, 'frostlands_night_1'),
    (maya, 'memory_trail_' || to_char(week + 1, 'YYYYMMDD'));
  insert into public.skill_progress(child_id, skill_key, mastery) values
    (alex, 'Memory', .25), (alex, 'English', .5);

  perform public.queue_family_updates();
  select summary into report from public.parent_reports where parent_id = opted_in and week_start = week;
  if jsonb_array_length(report->'learners') is distinct from 2
      or not (report->'learners' @> '[{"name":"Alex","activities":3,"practice_days":2,"skills":{"Memory":0.25,"English":0.5}},{"name":"Maya","activities":1}]') then
    raise exception 'Incorrect weekly report: %', report;
  end if;
  if (select count(*) from public.notifications where parent_id in (opted_in, opted_out, unconfirmed) and kind = 'weekly_report') <> 3 then
    raise exception 'Each family should get one inbox report';
  end if;
  if (select count(*) from public.email_outbox where parent_id in (opted_in, opted_out, unconfirmed)) <> 1
      or not exists(select from public.email_outbox where parent_id = opted_in) then
    raise exception 'Only verified, opted-in families should have mail queued';
  end if;

  select id into job_id from public.claim_parent_emails() where parent_id = opted_in;
  if job_id is null or exists(select from public.claim_parent_emails() where id = job_id) then
    raise exception 'A claimed email should only be handed to one worker';
  end if;
  update public.email_outbox set status = 'failed', claimed_at = now() - interval '61 minutes' where id = job_id;
  if not exists(select from public.claim_parent_emails() where id = job_id and attempts = 2) then
    raise exception 'Retry must use the same outbox identifier';
  end if;

  update public.family_settings set weekly_email_enabled = true where parent_id = opted_out;
  perform public.queue_family_updates();
  perform public.queue_family_updates();
  if (select count(*) from public.email_outbox where parent_id = opted_out) <> 1
      or (select count(*) from public.parent_reports where parent_id = opted_out) <> 1
      or (select count(*) from public.notifications where parent_id = opted_out and kind = 'weekly_report') <> 1 then
    raise exception 'Late opt-in must add exactly one email and reuse the existing report';
  end if;
end $$;

select pass('weekly report snapshots, consent, late opt-in, and retry are correct');
select * from finish();
rollback;
