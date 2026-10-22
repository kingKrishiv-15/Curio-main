# Supabase setup for Curio

This guide takes a Supabase project from empty to a working Curio sign-up:
a parent enters their email and a password, receives a verification code by
email, types it in, sets up their explorer, and lands on Home. The same code
flow handles **password resets** and password-free **"email me a code"**
sign-in.

Work through the steps in order the first time. Each one says exactly where to
click. Supabase occasionally renames dashboard menus — if a label differs
slightly, look for the nearest match on the same page.

| Step | What | Time |
|---|---|---|
| 1 | Understand which keys go where | 2 min |
| 2 | Create the database tables | 3 min |
| 3 | Connect the app | 2 min |
| 4 | Turn on email sign-up with codes | 3 min |
| 5 | Custom SMTP (required for real users) | 10–20 min |
| 6 | Paste the three email templates | 5 min |
| 7 | Rate limits and URLs | 2 min |
| 8 | Test the whole journey | 5 min |
| 9 | Weekly emails, reminders & account deletion (edge functions) | 15 min |
| 10 | Server-checked Loophole puzzles (optional) | 3 min |

---

## 1. Keys: what goes in the app, and what never does

Open **Project Settings → API Keys**. You'll see:

| Value | Looks like | Where it belongs |
|---|---|---|
| Project URL | `https://abcd1234.supabase.co` | `config/supabase.json` ✅ |
| **Publishable** key | `sb_publishable_…` | `config/supabase.json` ✅ — designed to be public; Row Level Security protects the data |
| **Secret** key | `sb_secret_…` | **Never in the app.** Only server code. Curio's Edge Functions don't need you to paste it anywhere — Supabase injects the project's service key into them as `SUPABASE_SERVICE_ROLE_KEY` |
| JWKS URL | `…/auth/v1/.well-known/jwks.json` | Not needed by the app. Only for a server that verifies Curio's sign-in tokens itself |
| Database password | — | Password manager only. Never in the repo |

`config/supabase.json` is bundled inside the app, so anything in it can be
read by anyone who installs Curio. The app **refuses to start** if that file
contains a secret key, and a test fails the build for the same reason.

> **If a secret key was ever pasted somewhere public — a chat, an issue, a
> commit — rotate it now:** Project Settings → API Keys → the secret key's
> **⋯** menu → create a new secret key, then delete the old one. Nothing in
> the Flutter app needs changing.

## 2. Create or repair Curio’s database

For dashboard setup, use **one file**: [`supabase/setup.sql`](supabase/setup.sql).
Open Supabase **SQL Editor → New query**, paste the entire file, and run it.
Wait for `Curio database setup complete`.

This installer creates the tables, functions, policies and rewards in order.
It also works after an interrupted setup, is safe to run again, and preserves
existing accounts, XP, completed games and discoveries. Existing parent profiles
and settings are backfilled when needed. No dummy learners or demo scores are
inserted.

If you saw `relation "public.activity_rewards" does not exist`, a later migration
was run before the base schema. Run the entire installer above instead of
running another isolated numbered file. Regenerate it after changing a migration:

```bash
python3 tool/build_supabase_setup.py
```

The numbered files in `supabase/migrations/` remain the source for CLI projects.
Use `supabase db push` for a project whose migrations are already CLI-managed.
For an existing dashboard-managed project, keep using the single installer;
don’t mix the two history mechanisms without reconciling the migration history.
See [Supabase’s migration guide](https://supabase.com/docs/guides/deployment/database-migrations).

Do not run `seed_dummy_data.sql`, `seed_demo_account.sql`, `seed_five_students.sql`
or `seed_loophole.sql` to install the production app. Loophole already has an
on-device fallback. The optional server puzzle setup is described in step 10.

## 3. Connect the app

1. Copy `config/supabase.example.json` to `config/supabase.json` (it's
   git-ignored — every developer makes their own).
2. Fill in the two values from step 1:

   ```json
   {
     "SUPABASE_URL": "https://abcd1234.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_…",
     "ENABLE_GOOGLE_AUTH": "false",
     "OTP_LENGTH": "6"
   }
   ```

3. Run the app — no extra flags needed:

   ```bash
   flutter run
   ```

   Curio reads `config/supabase.json` by itself and opens on the landing page.
   On the web, use a fixed port so the Site URL in step 7 matches:

   ```bash
   flutter run -d chrome --web-port 3000
   ```

**How Curio picks its configuration** (first match wins):

1. `--dart-define` / `--dart-define-from-file` values — useful for CI or for
   pointing one run at a different project. The old command,
   `flutter run --dart-define-from-file=config/supabase.json`, still works.
2. The bundled `config/supabase.json`.
3. Neither → **demo mode**: no login, an on-device profile, straight to Home.

To use demo mode on purpose (design work, no account needed):

```bash
flutter run --dart-define=CURIO_DEMO=true
```

VS Code has both as launch configurations: **Curio** and **Curio (demo mode,
no login)**. After editing `config/supabase.json`, stop the app and run it
again — the file is read once, at start-up.

## 4. Turn on email sign-up with codes

Open **Authentication → Sign In / Providers**.

1. Under **User Signups**, make sure **Allow new users to sign up** is on and
   **Confirm email** is **on**. This is what makes Supabase email a verification
   code after sign-up. (With it off, sign-up signs people straight in with no
   email — Curio handles that too, but you lose the proof that the parent
   owns the address.)
2. Click **Email** in the provider list and set:

   | Setting | Value | Why |
   |---|---|---|
   | Enable Email provider | On | |
   | Secure email change | On | Both old and new address must confirm |
   | Secure password change | On | |
   | Minimum password length | `8` | Matches the app's checklist |
   | Password requirements | **Letters and digits** | Matches the app's checklist |
   | Email OTP expiration | `3600` seconds | Recommended expiry; use only the newest email |
   | Email OTP length | `6` or your current 6–10 digit setting | The app accepts the full code without truncating it |

3. Press **Save**.

## 5. Custom SMTP — required before real parents can sign up

Supabase's built-in mailer is only for trying things out: it delivers **only
to addresses that are members of your Supabase organization**, and only a
handful of emails per hour. Anyone else signing up gets no code (in a debug
build Curio shows "Supabase's built-in mailer only sends to your project's
team members…" so you know why).

For quick testing you can skip this step and sign up with your own team
email. For anyone else, connect a real email provider. Curio already uses
**Resend** for the weekly parent email, so it's the natural choice:

### Option A — Resend (recommended)

1. Sign in at [resend.com](https://resend.com) → **Domains → Add domain**.
   Use a domain you own, e.g. `curio.example.com` or `mail.example.com`.
2. Add the DNS records Resend shows you (SPF/MX and DKIM `TXT` records) at
   your domain registrar, then press **Verify** in Resend. It usually takes a
   few minutes; it can take up to a day.
3. **API Keys → Create API key** → permission **Sending access** → copy the
   `re_…` key.
4. In Supabase open **Authentication → Emails → SMTP Settings** and turn on
   **Enable custom SMTP**:

   | Field | Value |
   |---|---|
   | Sender email | `hello@your-verified-domain.com` |
   | Sender name | `Curio` |
   | Host | `smtp.resend.com` |
   | Port | `465` |
   | Username | `resend` |
   | Password | your `re_…` API key |
   | Minimum interval between emails | `60` seconds |

5. **Save**.

### Option B — Gmail (testing only, ~500 emails/day)

1. On the Google account, turn on **2-Step Verification**, then create an
   **App password** (Google Account → Security → App passwords).
2. SMTP Settings: Host `smtp.gmail.com`, Port `465`, Username = the full
   Gmail address, Password = the 16-character app password, Sender email =
   the same Gmail address.

Other providers (Brevo, Postmark, SendGrid, Amazon SES) work the same way —
use the SMTP host, port, username and password from their dashboard.

## 6. Paste the three email templates

Curio's templates send **only the code, never a link**. That's deliberate:
security scanners in some inboxes open links automatically, which can use up
a one-time token before the parent sees it — the most common cause of
"Token has expired or is invalid".

Open **Authentication → Emails → Templates**. For each row below, open the
template, set the subject, replace the whole **Message body** with the file's
contents, and **Save**:

| Supabase template | Subject | File |
|---|---|---|
| **Confirm signup** | `Your Curio confirmation code` | `supabase/templates/confirmation.html` |
| **Magic Link** | `Your Curio sign-in code` | `supabase/templates/magic_link.html` |
| **Reset Password** | `Reset your Curio password` | `supabase/templates/recovery.html` |

Each file contains `{{ .Token }}` — Supabase swaps in the complete code at the length configured in your project. Use
the **Preview** tab to check it; you should see a big code in a cream box and
no button.

What each template is used for in the app:

- **Confirm signup** — after "Create account", and again if someone tries to
  sign in before confirming (Curio sends a fresh code automatically).
- **Magic Link** — "Email me a sign-in code" on the sign-in screen.
- **Reset Password** — "Forgot password?".

## 7. Rate limits and URLs

1. **Authentication → Rate Limits** → *Rate limit for sending emails*. With
   custom SMTP on you can raise it; `100` per hour is a comfortable start.
   (Separately, Supabase allows one email per address every 60 seconds —
   Curio's code screen shows a matching countdown before "Send a new code".)
2. **Authentication → URL Configuration**
   - **Site URL:** `http://localhost:3000` while developing; your real
     website once it's live.
   - **Redirect URLs:** add `http://localhost:3000/**`,
     `io.curio.app://login-callback/**`, and later your production URL
     (e.g. `https://curio.example.com/**`).

   Codes don't need redirects, but Google sign-in and any link in an email
   do, so set these once and forget them.

## 8. Test the whole journey

Run `flutter run` and go through this list. It takes about five minutes.

1. **Landing** appears (not Home). Tap **Get started**.
2. Swipe through the three intro slides, then **Create a family account**.
3. Enter an email you can open (a team member's address if you skipped
   step 5), a password like `curious123`, tick the parent/guardian box, and
   tap **Create account**.
4. The **Confirm your email** screen opens. Within a minute the email
   arrives; enter every digit from the email, then tap **Confirm and continue**.
5. **Learner setup** opens: nickname → daily goal → reminders → "Welcome,
   _name_!" → **Start exploring** → Home.
6. In **Table Editor**, check `child_profiles` has the nickname and
   `family_settings` has your goal, reminder hour, time zone and
   `consent_version`.
7. **Profile → Sign out.** Back on the landing page, tap **I already have an
   account** and sign in with the password.
8. Sign out again. On sign-in tap **Forgot password?** → **Send reset code**
   → enter the code → choose a new password → you're back in.
9. Sign out once more and try **Email me a sign-in code**.
10. Try signing up again with the same email: Curio should switch to sign-in
    and say an account already exists.

### Testing locally with the Supabase CLI (optional)

`supabase start` runs a full stack on your machine using
`supabase/config.toml`, which already has confirmations, 6-digit codes and
the three templates set up. Emails don't leave your machine — read them in
Inbucket at <http://localhost:54324>. Point the app at it with
`"SUPABASE_URL": "http://127.0.0.1:54321"` (or `http://10.0.2.2:54321` from
the Android emulator) and the publishable key that `supabase start` prints.

## 9. Weekly emails, reminders and account deletion

Two small server functions live in `supabase/functions/`:

- **`parent-digest`** — runs every hour: creates inbox reminders, builds
  Monday's weekly reports and sends the weekly email.
- **`delete-account`** — permanently deletes a parent's account when they
  confirm with their password in Profile → Privacy and account. Google
  Play requires in-app account deletion, so deploy this one before
  publishing.

Without this step the app still works, but reminders and weekly reports
never appear, and "Delete family account" fails.

1. Install the Supabase CLI ([docs](https://supabase.com/docs/guides/cli)),
   then from the project folder:

   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   supabase functions deploy parent-digest delete-account
   ```

   Deploy with the CLI, not the dashboard editor: `supabase/config.toml`
   turns off the default JWT check for these two functions (each verifies
   its caller itself), and a dashboard deploy would leave it on — the
   hourly job would then be rejected.

2. Set the function secrets. Invent a long random string for
   `CURIO_CRON_SECRET` (e.g. `openssl rand -hex 32`):

   ```bash
   supabase secrets set \
     CURIO_CRON_SECRET=your-long-random-string \
     RESEND_API_KEY=re_your_resend_key \
     CURIO_EMAIL_FROM="Curio <hello@your-verified-domain.com>" \
     CURIO_APP_URL=https://your-website.com
   ```

   `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` and `SUPABASE_ANON_KEY` are
   provided to functions automatically. `CURIO_APP_URL` must start with
   `https://` — it's the link in the weekly email.

3. Give the database the two values the hourly job needs. In **SQL Editor**:

   ```sql
   select vault.create_secret('https://YOUR_PROJECT_REF.supabase.co', 'curio_project_url');
   select vault.create_secret('your-long-random-string', 'curio_cron_secret');
   ```

   No trailing slash on the URL, and the second value must be exactly the
   same as `CURIO_CRON_SECRET` above.

4. Run `supabase/enable_family_schedule.sql` in the SQL Editor. It turns on
   `pg_cron` and `pg_net` and schedules the job at five past every hour
   (which also suits half-hour time zones like India's).

5. Check it: **Integrations → Cron** shows `curio-family-updates`; after the
   next run, **Edge Functions → parent-digest → Logs** shows a 200.

Feedback from Help → "Tell us what could be better" is stored in the
`support_requests` table — check it in Table Editor; nothing emails you.

Parents who signed up **only with Google** have no password, so they can't
confirm in-app deletion yet; handle their requests by email (the
[deletion page](docs/delete-account.html) covers this).

## 10. Server-checked Loophole puzzles (optional)

Loophole works without this: the app ships the same 30 statements and plays
them on the device. Setting it up lets signed-in players' answers be checked
on the server, with a per-game streak.

1. Create the key that encrypts answers at rest. In **SQL Editor**:

   ```sql
   insert into public.app_secrets (name, value)
   values ('minigame_encryption_key', encode(gen_random_bytes(32), 'hex'));
   ```

2. Run `supabase/seed_loophole.sql`. It publishes 10 days of puzzles, ending
   today. On days with nothing published the app quietly falls back to its
   on-device set, so nothing breaks when they run out.

## Troubleshooting

| What you see | Cause and fix |
|---|---|
| `relation "public.activity_rewards" does not exist` or tables already exist | Run the entire `supabase/setup.sql` installer (step 2). It handles dependency order and repeated setup. |
| `flutter run` still opens Home without asking to sign in | Curio is in demo mode. The console says why: `config/supabase.json` is missing or still has the `YOUR_…` placeholders, or you ran with `CURIO_DEMO=true`. |
| App stops at launch: "…contains SUPABASE_SECRET_KEY…" | A secret key is in `config/supabase.json`. Remove it and rotate it (step 1). |
| No email arrives, or "Email address not authorized" | You're on the built-in mailer and the address isn't a team member. Set up custom SMTP (step 5). Also check spam. |
| The email has a "Confirm your mail" link instead of a code | The template wasn't replaced or saved. Redo step 6 for that template. |
| "That code isn't right or has expired" | Only the **newest** code works, each works once, and they expire after an hour. Tap **Send a new code**. |
| The code has 8 digits but the app shows 6 boxes | Update the app to this build: it accepts 6–10 digits, expands the boxes, and waits for you to submit. `OTP_LENGTH` only controls the initial display. |
| "Please wait 42 seconds before asking for another email" | Supabase allows one email per address per minute. Wait, then resend. |
| "We've sent a lot of emails…" | The project's hourly email limit was hit. Raise it (step 7) once custom SMTP is on, or wait an hour. |
| "We couldn't find a Curio account for that email" on code sign-in | Code sign-in only works for existing accounts, by design. Create an account instead. |
| New games' XP or discoveries vanish after reopening the app | Migration 5 (`202610080001_launch_hardening.sql`) hasn't been run. Run it (step 2) — it's safe to re-run. |
| "Delete family account" fails | The `delete-account` function isn't deployed (step 9). |
| No reminders or weekly reports ever appear | Step 9 isn't finished: check the function is deployed, the secrets are set, and `enable_family_schedule.sql` ran. |
| Learner setup says it couldn't save | The `family_settings` table is missing — run migration 4 (step 2). |
| "Please choose a stronger password" | The dashboard's password rules (step 4) are stricter than 8 characters with letters and numbers. Match them to the app's checklist. |

---

## Optional: Google sign-in

Email sign-up is complete on its own; skip this unless you want Google too.

1. In [Google Cloud Console](https://console.cloud.google.com/), create or
   choose a project and configure the Google Auth Platform consent screen.
2. Create an OAuth client of type **Web application**.
3. Add `http://localhost:3000` and your production origin to Authorized
   JavaScript origins.
4. Add this Authorized redirect URI exactly:
   `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
5. Copy the Google Client ID and Client Secret.
6. In Supabase open **Authentication → Sign In / Providers → Google**, enable
   it, paste both values, and save.
7. Set `"ENABLE_GOOGLE_AUTH": "true"` in `config/supabase.json`.

The Android manifest and iOS Info.plist already accept the finished login at
`io.curio.app://login-callback/`. Parents who join with Google confirm the
parent/guardian agreement during learner setup instead of at sign-up.

## A demo account (no email needed)

Run `supabase/seed_demo_account.sql` in the SQL Editor. It creates
**demo@curio.test / CurioDemo123!**: already confirmed, already through
learner setup, starting from 0 XP. Sign in with it on the sign-in screen —
no code or SMTP involved. It's also the login to give Google Play under
**App access**. Re-running it just resets the password.

## Seed dummy data to verify the database

1. Open **SQL Editor → New query**.
2. Paste all of `supabase/seed_five_students.sql` and press **Run**.
3. It creates 5 complete, ready-to-use accounts by itself:

| Email | Password | XP | Streak |
|---|---|---|---|
| `maya@curio.test` | `CurioDemo123!` | 980 | 9* |
| `arjun@curio.test` | `CurioDemo123!` | 120 | 1* |
| `zara@curio.test` | `CurioDemo123!` | 540 | 3* |
| `leo@curio.test` | `CurioDemo123!` | 710 | 6* |
| `priya@curio.test` | `CurioDemo123!` | 430 | 0* |

\* The streak shown in the app is recalculated from the seeded play dates
(and from today's date), so it can differ from the stored number — and it
goes down if the seed was run a few days ago.

Each has different discoveries unlocked and different skill mastery — see
the comments at the top of the file. Sign in on the sign-in screen with any
pair above; Home, Profile, Skill Quest and the Parent dashboard all read live
from these tables (`lib/core/services/supabase_progress_store.dart`).

The script runs as one block, so a second run stops at the first duplicate
account and changes nothing. To reseed, run the commented-out `delete` block
at the bottom of the file first. To seed
just your own account instead, use `supabase/seed_dummy_data.sql` (see the
comment at its top for the one line to edit).

## Build for production

```bash
flutter build web --release
flutter build appbundle --release   # Android
flutter build ipa --release         # iOS
```

Release builds bundle `config/supabase.json` exactly like `flutter run`. On a
CI machine, where that git-ignored file doesn't exist, either write it from a
CI secret before building or pass the values directly:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://abcd1234.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_…
```

Add the deployed website to **Site URL** and **Redirect URLs** (step 7).
