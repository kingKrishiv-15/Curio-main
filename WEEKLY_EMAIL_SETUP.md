# Enable weekly parent report emails

The app now offers an opt-in directly in **Parent dashboard → Weekly report
emails**, as well as in Family preferences and onboarding. It stays off until
the parent enables it. The saved choice alone does not configure email delivery.

Each email includes **all explorers** in that parent's account: completed games
and practice days for the completed Monday–Sunday week, lifetime XP, discoveries,
and the full skill snapshot, including Memory and English. A report is queued
after 8 AM on Monday in the family's selected time zone. The hourly job retries
delivery; it uses an idempotency key to avoid duplicate emails during retries.
These are progress summaries, not formal assessments.

## One-time live setup

1. Create a Resend account and verify a domain you own. Choose a sender such as
   `Curio <reports@your-domain.com>`. The Gmail support address can remain your
   support contact, but the sending address needs your verified domain.
   See [Resend's verified-domain instructions](https://resend.com/docs/dashboard/domains/introduction).
2. Create a Resend API key and set these **Supabase Edge Function secrets**:

   ```text
   RESEND_API_KEY=re_your_key
   CURIO_EMAIL_FROM=Curio <reports@your-domain.com>
   CURIO_APP_URL=https://your-public-app-or-support-site.com
   CURIO_CRON_SECRET=your-long-random-secret
   ```

3. Deploy `parent-digest` from this repository using the Supabase CLI. Configure
   the matching Vault secrets and run `supabase/enable_family_schedule.sql`.
   Exact commands are in [SUPABASE_SETUP.md, step 9](SUPABASE_SETUP.md#9-weekly-emails-reminders-and-account-deletion).
4. In the app, enter the parent's password to open Parent dashboard, enable
   **Email me weekly reports**, and check the family's time zone.
5. Confirm a completed week's report in the parent inbox, a `sent` row in
   `email_outbox`, and receipt in the verified parent's email. Check the
   `parent-digest` logs if delivery fails. Opting out cancels future delivery;
   the sender checks the preference again immediately before sending.

Resend is not configured for the live project yet. No real report email has
been sent or verified from this workspace.
