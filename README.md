# Curio

Curio is a playful Flutter learning platform for children. This workspace is a
Flutter reimplementation and expansion of the earlier React design prototype.

## Prototype features

- Mobile-first Home, Learn, Discoveries and Profile navigation
- Daily Squeeze number-hunting game with range narrowing and maths clues
- Pattern Forge multi-question pattern game with explanations
- Evidence Detective source-ranking critical-thinking game
- Frostlands branching story prototype
- Skill Quest mastery map
- XP, streak, companion-stage and discovery progression
- Parent dashboard with skill insights and family controls
- Responsive layouts that remain constrained and readable on larger displays

Progress currently lives in an in-memory `CurioState`. The architecture maps in
`resources/mmd_files` define the Firebase production boundary. Scores, answers,
rewards, streaks and mastery will eventually be validated by callable Cloud
Functions rather than trusted to the Flutter client.

## Source layout

```text
lib/
  app/                 application bootstrap
  core/
    navigation/        shared navigation helpers
    state/             prototype progression state
    theme/             Curio color and typography system
    widgets/           reusable cards, buttons and page shells
  features/
    discoveries/
    games/
      evidence/
      pattern/
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
