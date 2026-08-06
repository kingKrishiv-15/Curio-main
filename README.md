# Curio

Curio is an adaptive learning platform for children aged 8-14, built as a
Flutter app (iOS + Android) backed by Supabase. This is a from-scratch,
production-grade rebuild - see `legacy_prototype/` for the earlier
client-trusted, Firebase-oriented prototype, which this rebuild does not
build on top of (only borrows UX ideas from, later).

## Non-negotiable principles

These hold across every layer of the app, and every architectural choice
below exists to serve them:

1. **Server-authoritative everything.** Scores, correctness, XP, and mastery
   are never computed or trusted client-side.
2. **Idempotency by default.** Any write that could plausibly be retried
   carries an idempotency key and is safe to call twice.
3. **Offline-first, sync-safe.** The app works with no connection for an
   active session and reconciles safely on reconnect.
4. **Content is versioned.** Nothing is edited in place - new versions are
   created, reviewed, and published.
5. **Privacy and safety are structural.** RLS on all child data, tracked
   parental consent, full audit logging on admin actions.

## Architecture

Clean Architecture, strict separation, one direction of dependency:

```text
lib/
  presentation/   UI widgets, screens, Riverpod-backed state
  domain/         entities, repository interfaces, use cases - pure Dart,
                   zero Flutter/Supabase dependency, unit-testable in isolation
  repository/     implementations of domain/'s interfaces - the only layer
                   that knows both the domain models and Supabase/Drift
  local/          offline database (Drift) + sync queue
  secure/         flutter_secure_storage-backed token storage
  app/            bootstrap, routing, the Riverpod provider graph
  core/           cross-cutting config/theme with no business logic
```

**State management: Riverpod**, not Bloc. Curio's screens lean on a lot of
small, independently-cacheable pieces of server state (child profile, skill
levels, session status) rather than one big linear event stream per feature -
Riverpod's provider graph and built-in caching/invalidation fit that shape
with less boilerplate than Bloc's event/state classes per feature.

**Local database: Drift**, not sqflite. The sync queue and cached-content
tables benefit from compile-time-checked queries and generated type-safe row
classes; with sqflite those queries are raw SQL strings with no compile-time
safety - exactly where an offline sync queue tends to grow subtle bugs.

**Crash reporting: Sentry**, not Firebase Crashlytics. The backend is
Supabase, not Firebase - Sentry's free tier and first-class Flutter SDK don't
require pulling in the Firebase SDK/config just for crash reports.

Each choice is also commented at its point of use in `pubspec.yaml`.

## Environment configuration

Config (Supabase URL/publishable key, Sentry DSN) is never hardcoded and
never committed. It's loaded per-environment via `flutter_dotenv` from
`assets/env/.env.<environment>`, selected at build/run time with
`--dart-define=ENVIRONMENT=dev|staging|prod` (defaults to `dev`).

Setup:

```bash
cp assets/env/.env.example assets/env/.env.dev
# edit assets/env/.env.dev with your dev Supabase project's URL + publishable key
```

Repeat for `.env.staging` / `.env.prod` as those environments come online.
Only `.env.example` is committed - see `.gitignore`. Running without the
matching file present throws a clear `StateError` telling you to copy the
template, rather than silently falling back to something.

```bash
flutter run --dart-define=ENVIRONMENT=dev
flutter build apk --dart-define=ENVIRONMENT=prod
```

## Database migrations (Supabase)

Schema lives in `supabase/migrations/`, applied via the Supabase CLI - never
edited by hand against a live project.

**Locally** (spins up an ephemeral local Postgres + Auth + Studio via
Docker):

```bash
supabase start          # first time; prints local Studio/API URLs
supabase db reset        # (re)applies every migration + supabase/seed.sql if present
supabase test db         # applies migrations, then runs supabase/tests/database/*.sql (pgTAP)
```

**Against a real project** (dev/staging/prod are separate Supabase
projects - link and push per environment):

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

Adding a new migration:

```bash
supabase migration new <short_description>
# edit the generated file under supabase/migrations/
supabase db reset   # verify it applies cleanly + pgTAP tests still pass
```

### `daily_puzzle.encrypted_answer`

The one column that needs special handling: it's encrypted with pgcrypto,
keyed by a secret that lives only in the Squeeze Edge Function's environment
(never in Postgres, never in this repo), and `anon`/`authenticated` have
`SELECT` explicitly revoked on that column - see the long comment above
`create table public.daily_puzzle` in `0001_initial_schema.sql` for exactly
how encryption/decryption and the column-privilege enforcement work.

## Monitoring

Sentry (`sentry_flutter`) initializes in `lib/app/bootstrap.dart` if
`SENTRY_DSN` is set for the current environment; if it's blank (e.g. a
developer left it out of `.env.dev`), the app runs without crash reporting
rather than failing to start. To verify reporting actually works end to end
once a DSN is configured, trigger a test error (e.g.
`throw Exception('sentry test')` behind a temporary debug button) and confirm
it shows up in the Sentry project's Issues tab.

## CI

`.github/workflows/ci.yml` runs on every push to `krishiv`/`vaibhav`/`main`
and on PRs into `main`:

- `flutter analyze` + `flutter test` + `flutter build apk --debug`
- an iOS build check (`flutter build ios --no-codesign`) on a macOS runner -
  the only place iOS actually gets verified, since local development happens
  on Windows, which can't build iOS at all
- `supabase test db` against an ephemeral local Supabase stack, applying
  every migration and running the pgTAP integration tests

Every job must pass - none of them are allowed to fail silently.

## Run and verify locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=ENVIRONMENT=dev
```

On Windows, building for Android/iOS/desktop plugin targets requires
Developer Mode enabled (Settings > For Developers > Developer Mode) - Flutter
needs symlink support to resolve plugins.

## Source layout

```text
lib/
  app/                       bootstrap, router, Riverpod provider graph
  core/
    config/                  AppEnvironment, EnvConfig (env loading)
    theme/                   Curio theme (placeholder - full design system
                              lands with the presentation-layer screens)
  domain/
    auth/
      entities/              ParentProfile, ChildProfile
      repositories/          AuthRepository interface, AuthFailure
      usecases/              SignUpParent, SignInParent,
                              AcceptConsentAndCreateProfile, AddChildProfile
      consent_policy.dart    current consent_type/policy_version constants
  repository/
    auth/                    SupabaseAuthRepository (implements AuthRepository)
  local/
    tables/                  Drift table definitions (sync queue for now)
    app_database.dart        Drift database
  secure/
    secure_token_storage.dart  flutter_secure_storage-backed Supabase LocalStorage
  presentation/
    splash/                  initial auth-state routing decision
    auth/                    sign-up, sign-in, verify-email, consent, add-child
    home/                    placeholder post-onboarding screen
supabase/
  migrations/                versioned schema (0001_initial_schema.sql)
  tests/database/            pgTAP integration tests
  config.toml                Supabase CLI project config
assets/env/                  per-environment config (.env.example committed only)
legacy_prototype/            archived earlier prototype - reference only
```

## Status

**Phase 0 (this rebuild's foundation) is in progress.** Done: project
scaffold, CI, env config, full initial schema + RLS, parent-onboarding auth
screens wired to Supabase Auth and the `create_parent_profile` /
`add_child_profile` RPCs, Sentry wiring. Not yet built: Squeeze game logic,
story worlds, maths content, the parent dashboard, the admin content tool -
all later phases, deliberately out of scope here.
