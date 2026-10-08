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

## Prototype features

- Responsive phone, tablet and desktop navigation
- Refined indigo–teal design system with reusable product-grade components
- Personalised daily dashboard, XP, streak and three-challenge daily goal
- Link Lab daily categorisation puzzle with spoiler-free result sharing
- Signal Grid daily binary-logic puzzle with teaching hints
- Daily Squeeze number-hunting game with range narrowing and maths clues
- Pattern Forge multi-question pattern game with explanations
- Evidence Detective source-ranking critical-thinking game
- Frostlands branching story adventure
- Skill Quest mastery map
- XP, streak, companion-stage and discovery progression
- Parent dashboard with skill insights and family controls
- Accessible semantics, large tap targets, interaction feedback and page motion

Progress currently lives in an in-memory `CurioState`. Daily activity keys use a
full calendar date so completions cannot collide across months. The architecture maps in
`resources/mmd_files` define the Firebase production boundary. Scores, answers,
rewards, streaks and mastery will eventually be validated by callable Cloud
Functions rather than trusted to the Flutter client.

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

Each feature owns its presentation and, where needed, domain logic. Firebase
data sources and repository implementations can be added per feature without
moving UI code between modules.

## Run and verify

```bash
flutter run
flutter analyze
flutter test
flutter build web
```
