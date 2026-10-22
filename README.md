# Curio

For authentication and cloud-progress setup, follow
[SUPABASE_SETUP.md](SUPABASE_SETUP.md).

## Run it

```bash
cp config/supabase.example.json config/supabase.json   # then add your URL + publishable key
flutter run                                            # landing → sign-up with an emailed code → Home
flutter run --dart-define=CURIO_DEMO=true              # demo mode: no login, on-device profile
flutter test                                           # includes the auth-flow suite
flutter test tool/generate_brand_assets.dart           # regenerate app icons from the logo code
```

Curio is a polished Flutter learning-and-puzzle platform for curious young
thinkers. It combines finite daily brain breaks, skill-building adventures,
knowledge rewards and family insight in one responsive product experience.

## Daily learning

- Three daily sections: **Maths**, **Memory**, and **English**.
- Exactly one scheduled game per section, shared by Home and Games.
- Games rotate by the device's local calendar date and refresh at midnight or
  when the app resumes. A run opened before midnight keeps its original date.
- A game's puzzle bank advances on each appearance so the rotation does not
  accidentally repeat the same puzzle every time.
- Memory Match and Memory Trail teach picture and sequence recall. Word Wise
  and Word Builder add vocabulary, reading, grammar and spelling practice.
- Existing number, pattern, logic and reading games join their section's rotation.
- Daily goals range from one to three sections. XP is earned once per daily
  game; practice rounds add no extra XP. New learners start at zero.
- Total XP, today's XP, daily completion and weekly progress are shown separately.
- Guest progress is saved on the device. Signed-in progress uses Supabase with
  a durable retry queue; unsynced rewards remain on the device.

For Supabase SQL Editor setup, run the complete [`supabase/setup.sql`](supabase/setup.sql)
installer. It creates dependencies in order and can repair a partial setup while
preserving existing learning progress. CLI-managed projects should continue to
apply their ordered migrations with `supabase db push`.

Email confirmation, sign-in and password recovery accept the full 6–10 digit
code from Supabase. The app waits for the parent to submit, so an eight-digit
code is never truncated or submitted after its sixth digit.

For Android publishing, see [`RELEASE.md`](RELEASE.md). Run
`python3 tool/release_check.py --platform android` before building. Release builds
require the real upload keystore and never fall back to debug signing.

## Source layout

```text
lib/
  app/                 application bootstrap
  core/
    navigation/        shared navigation helpers
    state/             lightweight progression state
    theme/             Curio color and typography system
    widgets/           reusable cards, buttons and page shells
  features/
    discoveries/
    games/
      evidence/
      link_lab/
      pattern/
      signal_grid/
      squeeze/
    home/
    learn/
    parent/
    profile/
    shell/
    skills/
    story/
resources/
  mmd_files/           production architecture maps
```

Each feature owns its presentation and domain logic. Shared scheduling lives in
`lib/features/games/common/daily_schedule.dart`; rewards are declared in
`game_rewards.dart` and mirrored in the Supabase migrations.

## Run and verify

```bash
flutter run
flutter analyze
flutter test
flutter build web
```
