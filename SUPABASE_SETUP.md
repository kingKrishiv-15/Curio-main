# Supabase setup for Curio

The app already contains email/password authentication, Google sign-in, session
handling, protected progress storage, sign-out, mobile callbacks, and a demo
mode for development without Supabase credentials.

## 1. Create the Supabase project

1. Go to [database.new](https://database.new/) and create a project.
2. Store its database password safely. It does **not** go in this app.
3. Wait until the project dashboard says the project is ready.

## 2. Create Curio's database tables

1. In Supabase, open **SQL Editor**.
2. Open `supabase/migrations/202608270001_initial_schema.sql` locally.
3. Copy the complete file into a new SQL query and press **Run**.
4. In **Table Editor**, confirm that five new tables are visible.

The script enables Row Level Security, so a parent can only access data tied to
their own signed-in account.

## 3. Connect the app

1. Press **Connect** at the top of the Supabase project dashboard.
2. Copy the **Project URL** and **Publishable key**. A legacy `anon` key works,
   but a publishable key is preferred for a new project.
3. Duplicate `config/supabase.example.json`, naming the copy
   `config/supabase.json`.
4. Replace both placeholders in the copy with the values from Supabase.

The real config file is ignored by Git. Never add a database password or a
`service_role`/secret key to a Flutter application.

Run on a phone or emulator:

```bash
flutter run --dart-define-from-file=config/supabase.json
```

Run on Chrome at a stable callback address:

```bash
flutter run -d chrome --web-port 3000 --dart-define-from-file=config/supabase.json
```

Without that option Curio intentionally opens in demo mode.

## 4. Configure email login and callback URLs

1. Open **Authentication → URL Configuration** in Supabase.
2. Set the development Site URL to `http://localhost:3000`.
3. Add these Redirect URLs:
   - `http://localhost:3000/**`
   - `io.curio.app://login-callback/**`
   - your future production URL, such as `https://curio.example.com/**`
4. Under **Authentication → Providers → Email**, leave Email enabled.

Email confirmation is normally enabled. After creating an account, confirm it
from the message Supabase sends before signing in.

## 5. Optional: enable Google sign-in later

You can skip this entire section. Email and password authentication is complete
and does not require Google Cloud Console.

1. In [Google Cloud Console](https://console.cloud.google.com/), create or
   choose a project and configure the Google Auth Platform consent screen.
2. Create an OAuth client of type **Web application**.
3. Add `http://localhost:3000` and your production origin to Authorized
   JavaScript origins.
4. Add this Authorized redirect URI exactly:
   `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
5. Copy the Google Client ID and Client Secret.
6. In Supabase open **Authentication → Providers → Google**, enable it, paste
   both values, and save.
7. Change `ENABLE_GOOGLE_AUTH` in `config/supabase.json` to `true`.

The Android manifest and iOS Info.plist already accept the finished login at
`io.curio.app://login-callback/`.

## 6. Test everything

1. Start the app with the configuration command from step 3.
2. Create an email account, confirm it, and sign in.
3. Rename the explorer and complete one game.
4. Check Supabase **Table Editor** for the new child and progress rows.
5. Sign out from **Profile**, sign back in, and confirm progress reloads.
6. Repeat using **Continue with Google**.

If login returns to the browser, compare the redirect URL exactly. If progress
does not save, confirm that the SQL ran fully and check the Profile sync status.

## 7. Seed dummy data to verify the database

This is the part you actually do *in Supabase*, step by step. Everything
else in this file is one-time project setup; this step is the one that
puts test data in front of you.

1. Open your project at [supabase.com/dashboard](https://supabase.com/dashboard)
   and click **SQL Editor** in the left sidebar.
2. Click **New query**.
3. Open the file `supabase/seed_five_students.sql` in this repo, select
   all its text, and paste it into the SQL Editor.
4. Click **Run** (or press Cmd/Ctrl+Enter).
5. That's it — it creates 5 complete, ready-to-use accounts by itself:
   nothing needs to exist beforehand, and nothing else needs configuring.

What you get, across all 5 tables at once:

| Email | Password | XP | Streak |
|---|---|---|---|
| `maya@curio.test` | `CurioDemo123!` | 980 | 9 |
| `arjun@curio.test` | `CurioDemo123!` | 120 | 1 |
| `zara@curio.test` | `CurioDemo123!` | 540 | 3 |
| `leo@curio.test` | `CurioDemo123!` | 710 | 6 |
| `priya@curio.test` | `CurioDemo123!` | 430 | 0 |

Each also has different discoveries unlocked and different skill mastery —
see the comments at the top of the file for the full breakdown.

**To check it worked:**
- In **Table Editor**, open `child_profiles` — you should see 5 rows named
  Maya, Arjun, Zara, Leo, Priya. Open `activity_completions`,
  `unlocked_discoveries`, and `skill_progress` — each has rows tied to
  those same 5 children.
- In the app itself, sign in on the Login screen with any email/password
  pair above. Home, Profile, Skill Quest, and the Parent dashboard will
  all show that student's exact seeded numbers, because they all read
  live from these same tables (`lib/core/services/supabase_progress_store.dart`) —
  there's no separate "demo data" path.

Re-running the script is safe for the activity/discovery/skill rows (it
skips duplicates), but the 5 accounts themselves can only be created once —
running it twice will error on the second pass with a duplicate email. To
reset and reseed from scratch, run the commented-out `delete` block at the
bottom of the file first.

If you'd rather seed just *your own* already-created account instead of
5 fresh test ones, use `supabase/seed_dummy_data.sql` instead — see the
comment at its top for the one line you need to edit.

## 8. Build for production

```bash
flutter build web --release --dart-define-from-file=config/supabase.json
```

Use the same configuration option for Android and iOS release builds, and add
the deployed website to Supabase's Site URL and Redirect URLs.
