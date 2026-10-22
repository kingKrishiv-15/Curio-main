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
- **Landing page** for signed-out visitors (`landing_page.dart`): the
  promise, both ways in above the fold on a phone, then how it works, the
  games, and what parents get.
- **Intro**: three swipeable slides (Play / Discover / Grow), shown once per
  device (`intro_page.dart`).
- **Sign-up**: email + password (8+ characters, letters and numbers) and a
  parent/guardian agreement, confirmed with a **6-digit code emailed by
  Supabase** (`verify_code_page.dart`). Already-registered addresses are
  steered to sign-in; unconfirmed accounts get a fresh code on sign-in.
- **Sign-in**: password, or password-free with an emailed code. **Password
  reset** also uses a code, then asks for a new password. Google sign-in is
  wired but off by default (`ENABLE_GOOGLE_AUTH`).
- **Learner setup** after confirming (`onboarding_page.dart`): nickname,
  daily goal (1/3/5 games), reminders + weekly email + time zone, then a
  welcome summary. Saved to `child_profiles` and `family_settings`
  (including `consent_version`).
- **Demo mode**: when no Supabase project is configured
  (`config/supabase.json` absent/placeholder) or `CURIO_DEMO=true`, the app
  skips login and runs on an on-device profile — for development/design
  work without a backend. A plain `flutter run` uses Supabase whenever the
  config file exists.
- **Guest mode**: "Continue as guest" on the landing and sign-in screens
  skips the account entirely. Progress is saved on the device only
  (`LocalProgressStore`), Profile says so plainly, and offers "Create a
  family account" or "Erase guest progress".
- One child per parent account today — there is no multi-child switcher
  in the UI yet (see §9).

### 3.2 Home
Five sections, each with one job:
1. **Greeting** — "Hello, <name>!", a one-line prompt, family messages and
   the avatar (opens Profile).
2. **This week** — today's date and streak, a flame for every day played
   Monday–Sunday, and today's goal ("1 of 3 games") with a progress bar.
3. **Weekly growth** — three pastel tiles counted for this week: games
   played, XP earned, skills practised (x/4). They stack into full-width
   rows at large text sizes.
4. **Today's picks** — a carousel of big game cards (five daily games that
   rotate by date; the first is today's featured quest), with "See all"
   jumping to the Games tab.
5. **Explore by skill** — a tile per skill (game count, mastery); each
   opens that skill's games with its level.

Every game everywhere is drawn by the same `GameCard`: a skill-coloured
art panel with a tiny preview of the board, skill · time · XP chips, and
DONE / QUEST / NEW badges.

### 3.3 Games (fourteen daily games, each finished and scored in one sitting)
| Game | Skill | What it teaches |
|---|---|---|
| Odd Cluster | Reasoning | 16 tiles, 4 knowledge groups (one easy, two medium, one sneaky); "one away" on near misses, 4 mistakes ends it |
| Sequence | Patterns | Guess the next number early for more points, or pay to reveal more; guessing opens only once the rule is unambiguous |
| Bridge | Number sense | Order every operation tile to turn a start number into a target; built backwards from a solution so it's always solvable |
| Cascade | Evidence | Chain five consequences of a claim; side effects and evidence-contradicted myths are the decoys |
| Loophole | Evidence | Tap the word making a true statement misleading; server-validated when signed in, offline set for guests |
| Squeeze | Number sense | Binary-search-style number guessing with range narrowing |
| Link Lab | Reasoning | Sort 16 words into 4 hidden category groups |
| Signal Grid | Reasoning | Binary-logic grid puzzle (balance rows/columns, no guessing) |
| Pattern Forge | Patterns | Spot-the-rule numeric sequence questions, three per session |
| Evidence Detective | Evidence | Rank clues as strong/weak/misleading in a short "case" |
| Tip the Scale | Number sense | Eight comparisons a day across fractions, decimals, percentages and small sums; the working puts both sides in one form ("3/4 = 0.750 · 5/8 = 0.625") |
| Mirror | Patterns | Paint the reflection of a pattern across a vertical, horizontal, then diagonal mirror; three checks per board |
| Verdict | Evidence | Five claims a day, each with one piece of evidence: supports it, goes against it, or can't tell yet — with the thinking tool named (fair test, counter-example, together isn't because…) |
| Who's Who | Reasoning | Generated logic-grid puzzles (3 then 4 children); every clue is needed, exactly one answer, and solvable without guessing |

Each game: awards fixed XP on first completion per day, unlocks exactly
one discovery fact tied to that game, and nudges the matching skill's
mastery value up slightly. Completion is keyed by
`"<game>_<YYYYMMDD>"` so a game can be replayed for fun but only counts
once per calendar day. The newer games pick today's puzzle from a
bank by date (`DailyPick`) and offer practice rounds afterwards, which
earn no XP. Their rules live in pure-Dart `domain/` files with tests that
enforce fairness (unique answers, unambiguous sequences, solvable bridges).

### 3.4 Story
`Frostlands` — a three-scene branching narrative (`lib/features/story`)
with binary choices, no scoring, ends with a discovery unlock. Currently
one story exists; the pattern is built to add more.

### 3.5 Discoveries
A collected-facts library (`lib/features/discoveries`) — eighteen facts:
one for each game and the story, plus three for 3-, 7- and 14-day streaks.
Shown as a locked/unlocked card grid with a completion ring; a locked
card says which game unlocks it.

### 3.6 Skill Quest
A learning-map view (`lib/features/skills`) showing mastery (0–100%) for
the four tracked skills — Number sense, Patterns, Evidence, Reasoning —
each with a level derived from mastery and a "play this next" nudge.

### 3.7 Profile
The child-facing settings surface: rename, XP/streak/discoveries summary,
"companion" stage progress (a lightweight meta-progression tied to total
XP), a badge shelf, links into Skills, Parent dashboard, and
Accessibility settings, plus sign-out and live sync status. The twelve
badges (first steps, busy brain, 3/7/14-day streaks, all-rounder, try
every daily game, story time, discovery and XP milestones) are computed
from the activity history rather than stored, each shows its progress
("3 / 7 days"), and the shelf names the one closest to being earned.

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
