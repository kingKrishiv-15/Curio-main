-- Inbox reports and email delivery use the same weekly snapshot. Reuse an
-- existing report if the parent enables email after its inbox copy was made.
create or replace function public.queue_family_updates() returns integer
language plpgsql security definer set search_path = '' as $$
declare
  family record;
  local_now timestamp;
  week_start_date date;
  report_id uuid;
  summary jsonb;
  added integer := 0;
begin
  for family in
    select s.*, u.email_confirmed_at
    from public.family_settings s
    join auth.users u on u.id = s.parent_id
  loop
    local_now := now() at time zone family.timezone;
    if family.reminders_enabled and extract(hour from local_now) = family.reminder_hour then
      insert into public.notifications(parent_id, kind, title, body, dedupe_key)
      values (family.parent_id, 'reminder', 'A little discovery is waiting',
              'Ready for today’s learning goal? A small step is a great start.',
              'reminder:' || local_now::date)
      on conflict do nothing;
    end if;

    if local_now < date_trunc('week', local_now) + interval '8 hours' then
      continue;
    end if;
    week_start_date := date_trunc('week', local_now)::date - 7;
    select r.id into report_id from public.parent_reports r
    where r.parent_id = family.parent_id and r.week_start = week_start_date;

    if report_id is null then
      select jsonb_build_object(
        'week_start', week_start_date,
        'week_end', week_start_date + 6,
        'learners', coalesce(jsonb_agg(explorer.payload order by explorer.created_at, explorer.id), '[]'::jsonb)
      ) into summary
      from (
        select c.id, c.created_at, jsonb_build_object(
          'name', c.name,
          'total_xp', c.total_xp,
          'activities', activity.games_played,
          'practice_days', activity.practice_days,
          'discoveries', (select count(*) from public.unlocked_discoveries d where d.child_id = c.id),
          'skills', (select coalesce(jsonb_object_agg(p.skill_key, p.mastery), '{}'::jsonb)
                     from public.skill_progress p where p.child_id = c.id)
        ) as payload
        from public.child_profiles c
        cross join lateral (
          select count(*) as games_played,
                 count(distinct right(a.activity_id, 8)) as practice_days
          from public.activity_completions a
          where a.child_id = c.id
            and a.activity_id ~ '_[0-9]{8}$'
            and right(a.activity_id, 8) between to_char(week_start_date, 'YYYYMMDD')
                                           and to_char(week_start_date + 6, 'YYYYMMDD')
        ) activity
        where c.parent_id = family.parent_id
          and c.created_at < (week_start_date + 7)::timestamp at time zone family.timezone
      ) explorer;
      if jsonb_array_length(summary->'learners') = 0 then
        continue;
      end if;

      insert into public.parent_reports as r(parent_id, week_start, summary)
      values (family.parent_id, week_start_date, summary)
      on conflict do nothing returning r.id into report_id;
      if report_id is not null then
        added := added + 1;
        insert into public.notifications(parent_id, kind, title, body, dedupe_key, report_id)
        values (family.parent_id, 'weekly_report', 'Your weekly learning report',
                'See the small steps your learner took last week.',
                'week:' || week_start_date, report_id)
        on conflict do nothing;
      else
        -- Another scheduler run may have created this same report.
        select r.id into report_id from public.parent_reports r
        where r.parent_id = family.parent_id and r.week_start = week_start_date;
      end if;
    end if;

    if report_id is not null and family.weekly_email_enabled and family.email_confirmed_at is not null then
      insert into public.email_outbox(parent_id, report_id)
      values (family.parent_id, report_id) on conflict do nothing;
    end if;
  end loop;
  delete from public.notifications where created_at < now() - interval '90 days';
  return added;
end $$;

revoke all on function public.queue_family_updates() from public, anon, authenticated;
grant execute on function public.queue_family_updates() to service_role;
