# Supabase setup for Curio

This guide takes a Supabase project from empty to a working Curio sign-up:
a parent enters their email and a password, receives a **6-digit code** by
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

---

## 1. Keys: what goes in the app, and what never does

Open **Project Settings → API Keys**. You'll see:

| Value | Looks like | Where it belongs |
|---|---|---|
| Project URL | `https://abcd1234.supabase.co` | `config/supabase.json` ✅ |
| **Publishable** key | `sb_publishable_…` | `config/supabase.json` ✅ — designed to be public; Row Level Security protects the data |
| **Secret** key | `sb_secret_…` | **Never in the app.** Only server code (Edge Functions get it automatically as an environment variable) |
| JWKS URL | `…/auth/v1/.well-known/jwks.json` | Not needed by the app. Only for a server that verifies Curio's sign-in tokens itself |
| Database password | — | Password manager only. Never in the repo |

`config/supabase.json` is bundled inside the app, so anything in it can be
read by anyone who installs Curio. The app **refuses to start** if that file
contains a secret key, and a test fails the build for the same reason.

> **If a secret key was ever pasted somewhere public — a chat, an issue, a
> commit — rotate it now:** Project Settings → API Keys → the secret key's
> **⋯** menu → create a new secret key, then delete the old one. Nothing in
> the Flutter app needs changing; Edge Functions pick up the new key
> automatically.

## 2. Create Curio's database tables

1. In the dashboard, open **SQL Editor → New query**.
2. Run each of these files **in this order** — open the file locally, copy all
   of it, paste, press **Run**, and wait for "Success" before the next:
   1. `supabase/migrations/202608270001_initial_schema.sql`
   2. `supabase/migrations/202609030001_minigames.sql`
   3. `supabase/migrations/202609030002_loophole.sql`
   4. `supabase/migrations/202609180001_family_launch.sql`
3. Open **Table Editor** and check you can see `profiles`, `child_profiles`,
   `activity_completions`, `unlocked_discoveries`, `skill_progress`,
   `family_settings` and `notifications`.

Every table has Row Level Security on, so a parent can only ever read and
write their own family's rows.

Using the Supabase CLI instead? `supabase link --project-ref <ref>` then
`supabase db push` applies the same migrations.

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
   **Confirm email** is **on**. This is what makes Supabase email the 6-digit
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
   | Email OTP expiration | `3600` seconds | The templates say "expires in 1 hour" |
   | Email OTP length | `6` | Must equal `OTP_LENGTH` in `config/supabase.json` |

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

Each file contains `{{ .Token }}` — Supabase swaps in the 6-digit code. Use
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
   arrives; type the 6 digits. The screen submits by itself.
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

## Troubleshooting

| What you see | Cause and fix |
|---|---|
| `flutter run` still opens Home without asking to sign in | Curio is in demo mode. The console says why: `config/supabase.json` is missing or still has the `YOUR_…` placeholders, or you ran with `CURIO_DEMO=true`. |
| App stops at launch: "…contains SUPABASE_SECRET_KEY…" | A secret key is in `config/supabase.json`. Remove it and rotate it (step 1). |
| No email arrives, or "Email address not authorized" | You're on the built-in mailer and the address isn't a team member. Set up custom SMTP (step 5). Also check spam. |
| The email has a "Confirm your mail" link instead of a code | The template wasn't replaced or saved. Redo step 6 for that template. |
| "That code isn't right or has expired" | Only the **newest** code works, each works once, and they expire after an hour. Tap **Send a new code**. |
| The code has 8 digits but the app shows 6 boxes | Set **Email OTP length** to 6 (step 4), or set `"OTP_LENGTH": "8"` in `config/supabase.json`. |
| "Please wait 42 seconds before asking for another email" | Supabase allows one email per address per minute. Wait, then resend. |
| "We've sent a lot of emails…" | The project's hourly email limit was hit. Raise it (step 7) once custom SMTP is on, or wait an hour. |
| "We couldn't find a Curio account for that email" on code sign-in | Code sign-in only works for existing accounts, by design. Create an account instead. |
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

## Seed dummy data to verify the database

1. Open **SQL Editor → New query**.
2. Paste all of `supabase/seed_five_students.sql` and press **Run**.
3. It creates 5 complete, ready-to-use accounts by itself:

| Email | Password | XP | Streak |
|---|---|---|---|
| `maya@curio.test` | `CurioDemo123!` | 980 | 9 |
| `arjun@curio.test` | `CurioDemo123!` | 120 | 1 |
| `zara@curio.test` | `CurioDemo123!` | 540 | 3 |
| `leo@curio.test` | `CurioDemo123!` | 710 | 6 |
| `priya@curio.test` | `CurioDemo123!` | 430 | 0 |

Each has different discoveries unlocked and different skill mastery — see
the comments at the top of the file. Sign in on the sign-in screen with any
pair above; Home, Profile, Skill Quest and the Parent dashboard all read live
from these tables (`lib/core/services/supabase_progress_store.dart`).

Re-running is safe for activity/discovery/skill rows, but the 5 accounts can
only be created once — a second run errors on the duplicate emails. To reset,
run the commented-out `delete` block at the bottom of the file first. To seed
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
