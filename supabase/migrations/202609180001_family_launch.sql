-- Parent-owned settings, notification inbox, reports and durable email outbox.
create table public.family_settings (
  parent_id uuid primary key references auth.users(id) on delete cascade,
  daily_goal integer not null default 3 check (daily_goal between 1 and 5),
  reminders_enabled boolean not null default false,
  reminder_hour integer not null default 18 check (reminder_hour between 0 and 23),
  timezone text not null default 'UTC',
  weekly_email_enabled boolean not null default false,
  consent_version text,
  consent_at timestamptz,
  updated_at timestamptz not null default now()
);
create function public.validate_family_settings() returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from pg_timezone_names where name = new.timezone) then
    raise exception 'Choose a valid time zone';
  end if;
  new.updated_at := now();
  return new;
end $$;
create trigger validate_family_settings before insert or update on public.family_settings for each row execute function public.validate_family_settings();
insert into public.family_settings(parent_id) select id from auth.users on conflict do nothing;
create function public.initialize_family_settings() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.family_settings(parent_id) values(new.id) on conflict do nothing;
  return new;
end $$;
create trigger initialize_family_settings after insert on auth.users for each row execute function public.initialize_family_settings();

create table public.parent_reports (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  summary jsonb not null,
  created_at timestamptz not null default now(),
  unique(parent_id, week_start)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('reminder', 'weekly_report')),
  title text not null,
  body text not null,
  dedupe_key text not null,
  report_id uuid references public.parent_reports(id) on delete cascade,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  unique(parent_id, dedupe_key)
);
create index notifications_parent_created on public.notifications(parent_id, created_at desc);
create table public.email_outbox (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  report_id uuid not null references public.parent_reports(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending', 'sending', 'sent', 'failed', 'cancelled')),
  attempts integer not null default 0,
  claimed_at timestamptz,
  first_attempt_at timestamptz,
  sent_at timestamptz,
  provider_id text,
  last_error text,
  unique(report_id)
);
create index email_outbox_pending on public.email_outbox(status, claimed_at);
alter table public.family_settings enable row level security;
alter table public.notifications enable row level security;
alter table public.parent_reports enable row level security;
alter table public.email_outbox enable row level security;
create policy "Own family settings" on public.family_settings for all to authenticated using (parent_id = (select auth.uid())) with check (parent_id = (select auth.uid()));
create policy "Own inbox" on public.notifications for select to authenticated using (parent_id = (select auth.uid()));
create policy "Own reports" on public.parent_reports for select to authenticated using (parent_id = (select auth.uid()));
grant select, insert, update on public.family_settings to authenticated;
grant select on public.notifications, public.parent_reports to authenticated;
revoke all on public.email_outbox from anon, authenticated;
grant all on public.family_settings, public.notifications, public.parent_reports, public.email_outbox to service_role;

create function public.mark_notification_read(notification_id uuid) returns void language sql security definer set search_path = '' as $$
  update public.notifications set read_at = coalesce(read_at, now()) where id = notification_id and parent_id = auth.uid();
$$;
revoke all on function public.mark_notification_read(uuid) from public;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- Read the completed calendar week in each family's chosen time zone.
create function public.queue_family_updates() returns integer language plpgsql security definer set search_path = '' as $$
declare f record; local_now timestamp; week date; report uuid; summary jsonb; added integer := 0;
begin
  for f in select s.*, u.email_confirmed_at from public.family_settings s join auth.users u on u.id = s.parent_id loop
    local_now := now() at time zone f.timezone;
    if f.reminders_enabled and extract(hour from local_now) = f.reminder_hour then
      insert into public.notifications(parent_id, kind, title, body, dedupe_key)
      values(f.parent_id, 'reminder', 'A little discovery is waiting', 'Ready for today’s learning goal? A small step is a great start.', 'reminder:' || local_now::date)
      on conflict do nothing;
    end if;
    -- Every day after 08:00 also catches up if Monday's scheduler was unavailable.
    if extract(hour from local_now) < 8 then continue; end if;
    week := date_trunc('week', local_now)::date - 7;
    select jsonb_build_object('week_start', week, 'week_end', week + 6, 'learners', coalesce(jsonb_agg(x.payload), '[]'::jsonb)) into summary
    from (
      select jsonb_build_object('name', c.name, 'total_xp', c.total_xp,
        'activities', (select count(*) from public.activity_completions a where a.child_id=c.id and right(a.activity_id,8) ~ '^[0-9]{8}$' and right(a.activity_id,8) between to_char(week,'YYYYMMDD') and to_char(week+6,'YYYYMMDD')),
        'practice_days', (select count(distinct right(a.activity_id,8)) from public.activity_completions a where a.child_id=c.id and right(a.activity_id,8) ~ '^[0-9]{8}$' and right(a.activity_id,8) between to_char(week,'YYYYMMDD') and to_char(week+6,'YYYYMMDD')),
        'discoveries', (select count(*) from public.unlocked_discoveries d where d.child_id=c.id),
        'skills', (select coalesce(jsonb_object_agg(p.skill_key, p.mastery),'{}'::jsonb) from public.skill_progress p where p.child_id=c.id)
      ) payload from public.child_profiles c where c.parent_id=f.parent_id and c.created_at < (week+7)::timestamp at time zone f.timezone
    ) x;
    if jsonb_array_length(summary->'learners') = 0 then continue; end if;
    report := null;
    insert into public.parent_reports(parent_id, week_start, summary) values(f.parent_id, week, summary)
    on conflict do nothing returning id into report;
    if report is not null then
      added := added + 1;
      insert into public.notifications(parent_id,kind,title,body,dedupe_key,report_id)
      values(f.parent_id,'weekly_report','Your weekly learning report','See the small steps your learner took last week.','week:' || week,report) on conflict do nothing;
      if f.weekly_email_enabled and f.email_confirmed_at is not null then
        insert into public.email_outbox(parent_id,report_id) values(f.parent_id,report) on conflict do nothing;
      end if;
    end if;
  end loop;
  -- Keep the inbox bounded; reports remain available until account deletion.
  delete from public.notifications where created_at < now() - interval '90 days';
  return added;
end $$;
revoke all on function public.queue_family_updates() from public;
grant execute on function public.queue_family_updates() to service_role;

create function public.claim_parent_emails() returns setof public.email_outbox language sql security definer set search_path = '' as $$
  update public.email_outbox set status='sending', claimed_at=now(), first_attempt_at=coalesce(first_attempt_at,now()), attempts=attempts+1
  where id in (
    select id from public.email_outbox where attempts < 5 and
      (status='pending' or (status='failed' and claimed_at < now()-interval '1 hour') or (status='sending' and claimed_at < now()-interval '15 minutes'))
      -- Never automatically retry beyond the provider's 24-hour idempotency window.
      and (first_attempt_at is null or first_attempt_at > now()-interval '23 hours')
    order by id for update skip locked limit 25
  ) returning *;
$$;
revoke all on function public.claim_parent_emails() from public;
grant execute on function public.claim_parent_emails() to service_role;

-- Atomic, idempotent progress writes. Awards are mapped here, not trusted from
-- a client total. This validates reward amounts, not puzzle answers.
create function public.sync_learning_progress(child_id uuid, learner_name text, activities text[]) returns void
language plpgsql security definer set search_path = '' as $$
declare activity text; base text; reward integer; skill text; fact text; inserted integer; days date[]; cursor_day date; run integer := 0;
begin
  if auth.uid() is null or not exists(select 1 from public.child_profiles c where c.id=child_id and c.parent_id=auth.uid()) then raise exception 'Not authorized'; end if;
  if char_length(trim(learner_name)) not between 1 and 18 or coalesce(array_length(activities,1),0)>10000 then raise exception 'Invalid progress'; end if;
  perform 1 from public.child_profiles c where c.id=child_id for update;
  foreach activity in array activities loop
    base := regexp_replace(activity, '_[0-9]{8}$', '');
    if activity <> 'frostlands_night_1' then
      if activity !~ '_[0-9]{8}$' then continue; end if;
      if to_date(right(activity,8),'YYYYMMDD') > current_date + 1 then continue; end if;
    end if;
    select r.xp,r.skill,r.fact into reward,skill,fact from (values
      ('squeeze',80,'Number sense','prime_numbers'), ('link_lab',90,'Reasoning','classification_science'),
      ('signal_grid',100,'Reasoning','binary_patterns'), ('pattern_forge',60,'Patterns','fibonacci_nature'),
      ('evidence_garden',70,'Evidence','weather_evidence'), ('frostlands_night_1',50,'Reasoning','aurora_lights')
    ) r(id,xp,skill,fact) where r.id=base;
    if reward is null then continue; end if;
    insert into public.activity_completions(child_id,activity_id) values(child_id,activity) on conflict do nothing;
    get diagnostics inserted = row_count;
    if inserted > 0 then
      update public.child_profiles c set total_xp=c.total_xp+reward where c.id=child_id;
      insert into public.skill_progress(child_id,skill_key,mastery) values(child_id,skill,.12)
        on conflict on constraint skill_progress_child_id_skill_key_key do update set mastery=least(1,public.skill_progress.mastery+.12),updated_at=now();
      insert into public.unlocked_discoveries(child_id,discovery_id) values(child_id,fact) on conflict do nothing;
    end if;
  end loop;
  select array_agg(distinct to_date(right(a.activity_id,8),'YYYYMMDD')) into days from public.activity_completions a where a.child_id=sync_learning_progress.child_id and a.activity_id ~ '_[0-9]{8}$';
  select (now() at time zone coalesce((select timezone from public.family_settings where parent_id=auth.uid()),'UTC'))::date into cursor_day;
  if not (cursor_day=any(coalesce(days,'{}'::date[]))) then cursor_day := cursor_day-1; end if;
  while cursor_day=any(coalesce(days,'{}'::date[])) loop run:=run+1; cursor_day:=cursor_day-1; end loop;
  update public.child_profiles c set name=trim(learner_name),streak=run,updated_at=now() where c.id=child_id;
end $$;
revoke all on function public.sync_learning_progress(uuid,text,text[]) from public;
grant execute on function public.sync_learning_progress(uuid,text,text[]) to authenticated;
-- Keep legacy reads; new clients use the atomic RPC above. Existing SQL game
-- endpoints retain their own RLS/permission contracts.

create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users(id) on delete cascade,
  message text not null check(char_length(message) between 10 and 4000),
  created_at timestamptz not null default now()
);
alter table public.support_requests enable row level security;
create policy "Own support requests" on public.support_requests for select to authenticated using(parent_id=(select auth.uid()));
create policy "Send own feedback" on public.support_requests for insert to authenticated with check(parent_id=(select auth.uid()));
grant select, insert on public.support_requests to authenticated;
grant all on public.support_requests to service_role;
