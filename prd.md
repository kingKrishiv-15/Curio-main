# Curio — Product Requirements Document

**Status:** describes the product as it exists in this repository today,
not an aspirational future state. Where the two differ, it's called out
explicitly (see §9).

## 1. Summary

Curio is a Flutter learning app for curious kids, built around short daily
"brain break" mini-games, a light story/discovery layer, and skill
tracking — with a parent-facing dashboard and account so one family's
progress is private and persists across devices.

One line: **a small, well-made daily habit for curious kids, with enough
visibility for a parent to trust it.**

## 2. Problem & audience

- **Primary user: a child**, roughly early-to-mid primary-school age,
  playing for a few minutes at a time, most days. They want something that
  feels like a game, not homework — quick wins, a streak worth keeping,
  and small facts worth collecting.
- **Secondary user: a parent**, who creates and owns the account, wants to
  see that their child is actually building skill (not just tapping
  through), and wants light control (what to nudge, when) without needing
  to play the games themselves.

The product bets that **daily, bite-sized, varied practice** (a number
game, a logic grid, a categorisation puzzle, a critical-thinking exercise,
a branching story) builds more durable engagement than one long-form app,
and that a visible streak + XP + a "collect all the facts" loop is enough
gamification to sustain a daily habit without becoming just a rewards
treadmill.

## 3. Current scope (what's built)

### 3.1 Account & access
- Email/password sign-up, sign-in, password reset, resend-confirmation,
  sign-out (`lib/features/auth`). Google sign-in is wired but
  off by default (`ENABLE_GOOGLE_AUTH`).
- **Demo mode**: if no Supabase project is configured
  (`config/supabase.json` absent/placeholder), the app skips login
  entirely and runs on an in-memory local profile — used for
  development/design work without needing a backend.
- One child per parent account today — there is no multi-child switcher
  in the UI yet (see §9).

### 3.2 Home
The daily landing screen: greeting, a "what will you solve today"
prompt, a weekly practice tracker (days practised this week vs. a
5-day goal, with day-by-day checkmarks), a horizontally-scrolling shelf of
today's picks (all five games, with the daily-quest game badged), and a
skill-filtered "pick your next adventure" section that surfaces one
in-progress skill and its matching game(s).

### 3.3 Games (five, all complete-and-scored in one sitting)
| Game | Skill | What it teaches |
|---|---|---|
| Squeeze | Number sense | Binary-search-style number guessing with range narrowing |
| Link Lab | Reasoning | Sort 16 words into 4 hidden category groups |
| Signal Grid | Reasoning | Binary-logic grid puzzle (balance rows/columns, no guessing) |
| Pattern Forge | Patterns | Spot-the-rule numeric sequence questions, three per session |
| Evidence Detective | Evidence | Rank clues as strong/weak/misleading in a short "case" |

Each game: awards fixed XP on first completion per day, unlocks exactly
one discovery fact tied to that game, and nudges the matching skill's
mastery value up slightly. Completion is keyed by
`"<game>_<YYYYMMDD>"` so a game can be replayed for fun but only counts
once per calendar day.

### 3.4 Story
`Frostlands` — a three-scene branching narrative (`lib/features/story`)
with binary choices, no scoring, ends with a discovery unlock. Currently
one story exists; the pattern is built to add more.

### 3.5 Discoveries
A collected-facts library (`lib/features/discoveries`) — nine facts total
today, each tied to one game or story completion, shown as a locked/
unlocked card grid with a completion ring.

### 3.6 Skill Quest
A learning-map view (`lib/features/skills`) showing mastery (0–100%) for
the four tracked skills — Number sense, Patterns, Evidence, Reasoning —
each with a level derived from mastery and a "play this next" nudge.

### 3.7 Profile
The child-facing settings surface: rename, XP/streak/discoveries summary,
"companion" stage progress (a lightweight meta-progression tied to total
XP), links into Skills, Badges (placeholder), Parent dashboard, and
Accessibility settings (placeholder), plus sign-out and live sync status.

### 3.8 Parent dashboard
Read-only view for the parent: XP/streak/discoveries at a glance, a full
skill-mastery snapshot, one auto-generated text insight ("strongest area
is X, encourage Y"), and family-control rows (daily goal minutes, reminder
time, privacy/consent) — the controls are currently presentational, not
yet wired to change app behaviour (see §9).

### 3.9 Data & sync
`CurioState` (`lib/core/state/curio_state.dart`) is the single in-memory
source of truth the whole UI reads from. When Supabase is configured, it
hydrates from and persists to five Postgres tables — `profiles`,
`child_profiles`, `activity_completions`, `unlocked_discoveries`,
`skill_progress` — behind Row Level Security scoped to the signed-in
parent (`supabase/migrations`, `SUPABASE_SETUP.md`). There is no
server-side validation of scores/XP/streak today — the client computes
and writes them directly (see §9).

## 4. Design system

Fully specified in [`design.md`](design.md) — dark "evergreen glass" chrome
with vivid, kid-friendly accent colour on anything representing play or
progress. Don't duplicate that content here; this PRD covers *what*, not
*how it looks*.

## 5. Success signals (product-level, not yet instrumented)

Nothing is currently tracked with analytics — these are the metrics the
product is designed around, useful context for what to instrument first:

- Day-over-day streak retention (does a child come back tomorrow).
- Daily-goal completion rate (3 activities/day, per `dailyGoalCompleted`).
- Spread across games — is one game doing all the work, or is play
  actually varied across the five.
- Discoveries unlocked over time, as a proxy for "playing enough distinct
  content to keep it fresh."
- Parent-side: does the parent dashboard get opened at all after week one.

## 6. Non-functional expectations

- **Platforms:** Flutter, targeting mobile (iOS/Android) and web/desktop
  via a responsive shell (bottom nav on narrow widths, a side rail at
  ≥900px — `main_shell.dart`).
- **Offline-first-ish:** demo mode already runs fully offline on local
  state; the Supabase-backed mode does not yet queue writes made while
  offline (see §9).
- **Accessibility:** semantics labels and large tap targets are used
  throughout; no formal WCAG audit has been done yet.
- **Privacy:** only what's needed to run the product is collected (email,
  a chosen display name, gameplay progress). No analytics/advertising
  integration exists in the codebase today.

## 7. Out of scope (deliberately, for now)

- Multiple children per parent account / a child-profile switcher.
- Any adaptive or server-authored content — all five games' questions are
  static, hand-authored constants in the Flutter client.
- A content-authoring/admin tool.
- Push notifications or scheduled reminders (the parent dashboard's
  "Learning reminders" row is a display value, not a working scheduler).
- Payments/subscriptions.

## 8. Risks & open questions

- **Client-trusted scoring.** XP, streak, and mastery are written by the
  client with no server-side validation (`SupabaseProgressStore.save`
  just upserts what the app computed). Fine for a trusted-family use case
  today; a blocker if this ever needs to support leaderboards or anything
  competitive.
- **Single child per account.** The schema (`child_profiles.parent_id`)
  already supports many children per parent; only the loading logic
  (`SupabaseProgressStore._child()` picks the first by `created_at`) and
  the UI assume one. Extending to multiple children is a moderate, not
  large, lift.
- **Static content ceiling.** Five games and one story is enough for a
  first impression, not for months of daily use, without either more
  hand-authored content or some form of variation/randomisation within
  existing games.

## 9. Relationship to the earlier architecture vision

`resources/mmd_files/` contains an earlier, considerably more ambitious
planning-stage architecture (Firebase Auth/Firestore/Cloud Functions,
server-validated rewards, adaptive quests, a content-ops/CMS layer,
offline write-queueing, parental-consent versioning, PIN-protected profile
switching, multi-child support). **That is a north-star document, not a
description of the current build** — the shipped product uses Supabase,
not Firebase, has no CMS, no adaptive content, and no server-side
validation. Treat those diagrams as directional inspiration for where the
product could grow (§7/§8 above map roughly to gaps between "now" and
"that vision"), and update or retire them if the Supabase direction is
the one being committed to long-term.
