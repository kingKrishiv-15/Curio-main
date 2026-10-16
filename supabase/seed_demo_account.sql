-- ============================================================================
-- Curio: one ready-to-use demo account (no email needed)
-- ============================================================================
-- Creates a confirmed parent account that has already finished learner
-- setup, so signing in goes straight to Home. Use it for testing before SMTP
-- is set up, and as the "App access" login for Google Play reviewers.
--
--   Email:    demo@curio.test
--   Password: CurioDemo123!
--
-- HOW TO RUN: Supabase → SQL Editor → New query → paste this file → Run.
-- Safe to re-run: if the account exists it just resets the password and
-- makes sure the learner profile is there. Progress is left alone.
-- ============================================================================

do $$
declare
  demo_email text := 'demo@curio.test';
  demo_password text := 'CurioDemo123!';
  demo_learner text := 'Alex';
  v_user uuid;
begin
  select id into v_user from auth.users where email = demo_email;

  if v_user is null then
    v_user := gen_random_uuid();
    -- Also fires the triggers that create the profiles and
    -- family_settings rows.
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user, 'authenticated', 'authenticated',
      demo_email, crypt(demo_password, gen_salt('bf')), now(), now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object(
        'onboarding_complete', true,
        'consent_version', '2026-09',
        'consent_at', now()
      ),
      now(), now(), '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_user, v_user::text,
      jsonb_build_object('sub', v_user::text, 'email', demo_email, 'email_verified', true),
      'email', now(), now(), now()
    );
  else
    update auth.users
    set encrypted_password = crypt(demo_password, gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
          || '{"onboarding_complete": true, "consent_version": "2026-09"}'::jsonb,
        updated_at = now()
    where id = v_user;
  end if;

  -- A learner, starting fresh (0 XP), so every game can be tried.
  if not exists (select 1 from public.child_profiles where parent_id = v_user) then
    insert into public.child_profiles (parent_id, name, total_xp, streak)
    values (v_user, demo_learner, 0, 0);
  end if;

  -- Family preferences with the parent/guardian agreement recorded.
  insert into public.family_settings (parent_id, daily_goal, timezone, consent_version)
  values (v_user, 3, 'Asia/Kolkata', '2026-09')
  on conflict (parent_id) do update
    set consent_version = coalesce(public.family_settings.consent_version, excluded.consent_version);

  raise notice 'Demo account ready: % / %', demo_email, demo_password;
end $$;

-- To remove it later (deletes the learner and progress too):
-- delete from auth.users where email = 'demo@curio.test';
