# update_1: what changed

Branch `update_1`, cut from `main` at `d700a52`. Nothing on `main`, `krishiv`
or `krishiv-2` was touched and no pull request was opened.

Open `index.html` in this folder for the contact sheet.

## The final 12 games

| Section | Games |
| --- | --- |
| Maths (5) | Squeeze, Bridge, Tip the Scale, Sequence, Mirror |
| Logic (4) | Crowns, Who's Who, Signal Grid, Link Lab |
| Thinking (3) | Second Opinion (new, on every day), Verdict, Cascade |

A day is Second Opinion plus one rotating game from each section, four in
all. Frostlands Story stays in the app, outside the rotation, unchanged
apart from the token restyle.

## What was deleted

**Games (code, routes, tests, section entries):** Number Hunt, Odd Cluster,
Pattern Forge, Memory Match, Memory Trail, Memory Grid, Word Wise, Word
Builder, Word Trails, Evidence Detective, Loophole. The Memory and English
sections are gone. Their reward rows are kept on client and server so XP
already earned from them still counts. The Loophole SQL (validator, seed)
is left in place on the server and is simply no longer called.

**Screens and navigation:** the Games tab, its route and the test that
asserted Home and Games match. The bottom bar has three tabs: Home,
Discover, Profile. The light theme and its toggle (Curio is dark only).

**Decoration:** every eyebrow label, the NEW pill, the sparkle icons, the
dotted orbit art and the whole welcome illustration set, the mascot, the
floating animation, the giant quote glyph in Verdict, the glossy clay
painter and icon tiles, every gradient and every ad hoc shadow, the banner
game cards and game preview art, the page backdrop texture.

**Home:** two of the three XP displays, the row of three stat tiles, the
week card, the greeting ("Hello, Explorer!", "What will you discover
today?").

**Discover:** the 26 locked "Keep exploring" cards, the progress ring and
the intro card. Locked ideas are not shown at all. With nothing collected
there is one sentence.

**Copy:** middle dot metadata, tracked capitals, lines that explain the UI
("Earn XP once per daily game...", "A new set arrives at midnight...",
"Tap a card to read..."), the two sentence headlines ("Little games. Big
discoveries.", "Five minutes. One big idea.", "Ideas worth keeping."), and
interchangeable praise. Feedback now says what the player did ("You picked
the left side, and it is more.", "Solved with no hints").

**Tooling:** three brand and store asset generators in `tool/` that drew
the old gradient look.

## What was added

- `DESIGN.md` and `lib/theme/curio_tokens.dart`: 13 colours, 2 radii, 2
  elevations, one spacing scale, 5 type roles, 2 durations and 1 curve.
- `test/design_rules_test.dart`: fails on a colour literal outside the
  tokens file, on any `BorderRadius.circular` that is not 20 or 999, on a
  shadow or gradient outside the allowed places, and on any em dash or en
  dash in `lib/`.
- One source of truth for section names and counts (`sectionNames`,
  `dailyGameCount`, `anchorGameId`), so the Welcome, onboarding, Home and
  settings strings cannot disagree again.
- Home, Discover and Profile rebuilt as one primary block plus rule
  separated rows (`CurioRow`, `GameRow`).
- **Second Opinion**: brief, six fixed probes (three may be asked), eight
  claim cards, one submission, a debrief that names the probe that would
  have caught each error, the spoiler safe share line, one five minute
  clock. No live model call anywhere.
  - Server: `validate_second_opinion_move`, `open_second_opinion` (starts
    the clock on the server, resumes, reports seconds left),
    `todays_puzzle`. Execute revoked by role name. 17 pgTAP assertions in
    `supabase/tests/database/second_opinion_test.sql`.
  - Content: 30 authored days plus one demo puzzle in
    `tool/second_opinion/`. `node tool/second_opinion/build.js` checks the
    rules (150 to 250 words, exactly 3 flawed claims, 1 or 2 exposing
    probes, no day with one failure type three times, no banned subjects)
    and writes `supabase/seed_second_opinion.sql`.
  - Client: gateway interface with a server implementation and a demo
    implementation. In demo mode one fixed puzzle is graded on the device.
    It is not part of the daily schedule.
- `get_daily_set`: the server returns its date, the day number, today's
  four games and today's published puzzles. The app adopts the server date
  once signed in, so changing the device clock no longer moves the day.
- Sequence now generates its rules (`sequenceRulesForDay`).

## Content bank sizes (the 90 day requirement)

A "day" below is one appearance of the game. With the rotation, a Maths
game appears every 5th day, a Logic game every 4th and a Thinking game
every 2nd.

| Game | Source | Distinct days today | 90 distinct days? |
| --- | --- | --- | --- |
| Squeeze | a target from 1 to 100 | up to 100 | not verified |
| Bridge | generated | unlimited | yes (tested) |
| Tip the Scale | generated | unlimited | yes (tested) |
| Sequence | generated (new) | unlimited | yes (tested), was 4 |
| Mirror | generated | unlimited | yes (tested) |
| Crowns | 32 boards x 8 orientations | 128+ | yes (tested) |
| Who's Who | generated | unlimited | expected, not verified |
| Signal Grid | 72 boards, givens vary by day | 90+ | yes (tested) |
| Link Lab | 12 hand written puzzles | 12 | **no** |
| Verdict | 45 hand written items, 5 a day | 9 | **no** |
| Cascade | 5 hand written claims | 5 | **no** |
| Second Opinion | 30 authored days | 30 | 30, as the brief asked for launch |

`test/content_days_test.dart` asserts the six "tested" rows.

## Not finished

1. **Link Lab, Verdict and Cascade do not have 90 days of content.** They
   need about 78 more Link Lab puzzles, about 405 more Verdict items and 85
   more Cascade claims to reach 90 appearances each (or 11, 180 and 40 to
   cover 90 calendar days under the rotation). I did not write these. Until
   they exist these three repeat: Cascade after 10 calendar days, Verdict
   after 18, Link Lab after 48.
2. **Phase 6 server validation covers 1 game of 12.** Only Second Opinion
   is graded on the server. Verdict, Cascade and Link Lab (the rest of the
   "first four") and Squeeze, Sequence, Bridge, Tip the Scale, Mirror,
   Crowns, Who's Who and Signal Grid still hold their answers in the client
   and grade on the device. None is half migrated. The date and the daily
   set do come from the server (`get_daily_set`).
3. **The SQL has not been run.** There is no Docker or Supabase CLI on this
   machine, so the two new migrations, the seed and the pgTAP file were
   written and read through but never executed. Run `supabase test db`
   before trusting them. `supabase/setup.sql` was regenerated.
4. **Nothing was applied to the hosted project.** To see Second Opinion
   against the real backend, apply the two migrations and then run
   `supabase/seed_second_opinion.sql` as the database owner. It publishes
   day 1 on the day it is run.
5. **The Hallmark skill is not installed** (`~/.claude/skills/hallmark`
   does not exist), so the design rules come from the brief alone.
6. **Screenshots are engine renders, not browser captures.** The demo web
   build compiles (`flutter build web --dart-define=CURIO_DEMO=true`), but
   the PNGs were produced by `tool/screens/capture_test.dart`, which gives
   exact control over game state. I did not click through the web build.
7. **Design budget gaps the tests do not catch.** `Radius.circular` inside
   custom painters and a few computed sizes still use their own numbers.
   Game mechanics keep their own animation timings. Some inner game
   screens (Crowns, Who's Who, Mirror, Squeeze, Signal Grid, Bridge) were
   restyled by the token migration only and were not reviewed one by one.
   Secondary pages (Parent dashboard, Family inbox, Help, Privacy,
   Accessibility, Skills, Badges sheet, sign in and sign up) likewise.
8. **Existing Cascade content mentions asthma and hospital visits.** It
   predates this work and was left alone. All Second Opinion content keeps
   clear of health and politics.
9. **Second Opinion facts should get a human read before launch.** The 150
   true claims and 90 corrections were written from memory with no live
   lookup. Records that can move (sport records, tallest building, title
   holders) are worded as dated events so they stay true, but a fact check
   is still worth an hour.
10. The test account still cannot sign in (email confirmation). Left alone
    as asked.

## Commits

| Phase | Commit |
| --- | --- |
| 1 Tokens and DESIGN.md | `8930ab5` |
| 2 Removal pass | `c2c24c7` |
| 3 One primary block per screen | `1b4704f` |
| 4 Cut to the surviving games | `a7d8231`, `8aabecc` (Sequence generator) |
| 5 Second Opinion | `499732e` |
| 6 Server date and daily set | `b21f0e8` |
| Deliverable | the commit that adds this file |
