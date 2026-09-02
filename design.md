# Curio Design System

This is the living reference for Curio's visual language — the dark
"evergreen glass" system introduced across the Home screen and rolled out
app-wide. Read this before touching UI code; it exists so the app stays
visually consistent as more screens are added, and so hard-won lessons
(mostly about glass/blur) aren't relearned the hard way.

Source of truth in code:
- [`lib/core/theme/curio_colors.dart`](lib/core/theme/curio_colors.dart) — every colour token
- [`lib/core/theme/curio_theme.dart`](lib/core/theme/curio_theme.dart) — `ThemeData`, text styles, button/input/dialog themes
- [`lib/core/widgets/curio_ui.dart`](lib/core/widgets/curio_ui.dart) — shared page shell and components
- [`lib/features/home/presentation/home_page.dart`](lib/features/home/presentation/home_page.dart) — the reference implementation; when in doubt, match Home

## 1. Philosophy

Curio is a learning product for kids, used day-to-day by a parent who sets
it up and checks in on progress. The UI needs to do two things at once:

- **Feel premium and calm, not garish.** A deep, textured evergreen
  backdrop instead of a flat colour — depth and quality over primary-colour
  loudness.
- **Feel warm and alive for a kid**, especially anywhere a child is looking
  at their own progress or picking a game: bright, saturated accent colour,
  a bit of motion (a pulsing streak flame, cards fading/sliding in), and
  banner art that pops rather than a muted dark wash.

Those two moods live in different places: the **chrome** (backgrounds,
nav, structural cards) stays in the calm dark-glass register; **content
that represents play and progress** (game banners, skill accents, badges)
gets full-saturation colour. See §4 and §7.

## 2. Colour

All colours are semantic tokens on `CurioColors` — never hardcode a hex
value in a page. If you need a colour that doesn't exist yet, add a named
token, don't inline it.

### Backdrop & surfaces

| Token | Value | Use |
|---|---|---|
| `canvas` | `#05100D` | Deepest page background |
| `canvasDeep` | `#0A1A15` | Gradient mid-stop |
| `surface` | `#232A2C` | Default card/glass base — lighter than canvas, not another shade of green (see §4) |
| `surfaceMuted` | `#15191A` | Sunken/recessed fill (chips, empty states) |
| `night` | `#05100D` | Same as canvas; used where "the deepest possible fill" is the point (spinners on bright buttons, snackbar text colour target) |
| `navy` | `#123A30` | A deep, jewel-toned **hero card** fill — deliberately independent of `ink`. Use for one bold stat/reward display per screen (e.g. Squeeze's secret-range card), not for general cards |

### Text

| Token | Value | Use |
|---|---|---|
| `ink` / `onDark` | `#F4FAF6` | Primary text/icons on any dark surface. These two are equal in value; `onDark` is the older name, kept because call sites already expect "light text" semantics from it |
| `inkSoft` | `#C7D0CC` | Secondary text |
| `inkMuted` | `#8D948F` | Tertiary/caption text, faint labels |
| `outline` | `#FFFFFF` @ 24% | Visible borders on dark surfaces |
| `outlineSoft` | `#FFFFFF` @ 14% | Faint dividers/borders |

**Rule:** every one of these is already a *light* colour meant to sit on a
dark surface. Never use `ink`/`onDark` as a background fill, and never use
`surface`/`canvas`/`navy` as a text colour — see the anti-pattern in §7.

### Accent hues (brightened for dark backgrounds)

| Token | Value | Personality |
|---|---|---|
| `coral` | `#E49577` | Primary interactive accent — buttons, links, focus rings |
| `saffron` / `gold` | `#E7BE6B` | Number sense / rewards / "featured" badges |
| `blue` / `frost` | `#8FC3D9` | Reasoning / calm, analytical |
| `plum` / `pink` | `#BFA6E0` | Secondary highlight, evidence-adjacent |
| `forest` | `#49BB8C` | Brand primary — logo mark, brand gradient, default icon accent |
| `success` / `green` | `#4FD69B` | Correct answers, positive state |
| `danger` | `#F0685A` | Errors, destructive state |

Each has a `*Strong` (deeper, still opaque, for text/borders that need a
little more weight) and a `*Soft` variant (a **translucent wash**, ~16%
opacity — for a card fill only, see §7 for why it must never be a text or
icon colour).

`lime` (`#DCE66A`) is a fifth accent used specifically for **CTA / "this
is active right now"** moments — the daily quest badge, the active bottom
nav pill, a pulsing streak flame. It currently lives only in
`home_page.dart` / `main_shell.dart` (not yet promoted to `CurioColors`);
promote it if a third screen needs the same "this is the one live thing"
treatment.

### Skill colour mapping

Curio's four skills each own one of the accent hues, used consistently for
tabs, progress bars, and badges wherever that skill appears:

- **Number sense** → gold
- **Patterns** → coral
- **Evidence** → blue/frost
- **Reasoning** → plum/violet

### Gradients

- `brandGradient` (`forestStrong → forest`) — the logo mark, and anywhere
  a small brand-coloured surface is needed.
- `pageGradient` (`#0E211B → #0A1A15 → canvas`, top to bottom) — the
  default page backdrop, drawn by `CurioPage`.
- `heroGradient` — a richer three-stop dark-teal gradient for a full-bleed
  hero panel (e.g. the Frostlands story scene).

## 3. Typography

- **Display font — Fraunces** (serif): headlines, the "curio" wordmark,
  section titles. Set with slightly negative letter-spacing at large
  sizes for a tight, confident feel.
- **Body font — DM Sans**: everything else.
- Type scale is defined once in `CurioTheme` (`displayLarge` down to
  `labelLarge`) — use `Theme.of(context).textTheme.*` rather than hand-rolled
  `TextStyle`s so a scale change propagates everywhere.

## 4. Backdrop & the "cards must not be another shade of green" rule

Early iterations made cards a slightly-lighter version of the same green
as the page background — it read as flat and monotonous. The fix that
stuck: **cards are a neutral, slightly warm slate (`surface`), not a green
tint at all.** The page background carries the brand colour; cards
separate from it by *hue*, not just brightness.

The page backdrop itself is never a flat fill — `CurioPage` (and Home's
own bespoke copy of the same idea) layers:
1. `pageGradient` (a three-stop vertical gradient, dark teal → near-black)
2. A `CustomPainter` texture: two large, very-low-alpha soft "blob" glows
   (one warm/gold top-right, one cool/blue bottom-left) plus a fine grain
   of low-alpha dots — enough to keep the eye interested without being
   visible as a pattern.

If you add a new full-page screen, use `CurioPage` and you get this for
free. Don't build a flat `Scaffold(backgroundColor: canvas)` — see the
Login page for the before/after (it used to be flat; now it's `CurioPage`
+ a `GlassCard` for the form).

## 5. Glass cards — and the mistake not to repeat

`GlassCard` (`curio_ui.dart`) is the standard elevated-card look: a
translucent tinted fill, a crisp bright border, a soft top-left sheen, and
a lift shadow.

**It does not use a real `BackdropFilter` blur.** Two things went wrong
before this was fixed, in this order:

1. **Opacity too high.** The first version tinted at ~70% opacity — that
   just reads as a solid, flatly-coloured card, not glass. Real
   glassmorphism needs a *light* fill (roughly 30–35%, sometimes lower)
   so blur (or in this case, the neutral `surface` colour plus a bright
   border and sheen) does the work of separating it from the backdrop.
2. **Stacked blur.** Every card additionally had its own `BackdropFilter`.
   With several cards in a scrolling shelf plus the nav bar all blurring
   independently in the same frame, blur started rendering in visibly
   wrong places on a real device (Impeller), even though it looked fine
   in web testing (Skia). The fix was architectural, not another value
   tweak: **there is exactly one real `BackdropFilter` in the entire
   app**, on the bottom nav pill, clipped tightly to the pill's own
   stadium shape so only the pixels directly behind it blur. Every card
   fakes the rest of the "glass" look with plain translucency.

If you're tempted to add blur to a new card: don't. Reach for `GlassCard`
as-is. If a screen genuinely needs a frosted look (a modal over busy
content, say), treat it the same way the nav bar is treated — one
`BackdropFilter`, clipped to exactly the shape that needs it, and nothing
else blurring in the same frame.

## 6. Navigation

The bottom nav is a floating pill, not a `Scaffold.bottomNavigationBar`.
That's also load-bearing, not a style choice: Scaffold's bottom-nav slot
paints its own background independent of whatever widget lives in it,
which is exactly what caused a stray coloured bar to show up behind the
pill on a real device. The fix was to stop using the slot at all — the
nav is a `Positioned` widget inside the *same* `Stack` as the page body,
so there is structurally no other layer that can paint behind it.

- Selected item: expands to icon + label in a lime pill with a soft glow.
- Unselected items: icon only, muted white.
- The one `BackdropFilter` blur (§5) lives here, clipped to the pill.
- Desktop/wide layouts get a side rail (`_CurioRail` in `main_shell.dart`)
  instead — same tokens, different shape.

## 7. Hard-won contrast rules

These read as obvious in hindsight but each one caused a real, shipped bug
during the dark-mode migration — checklist before you hand-write a colour
pairing:

- **A bright accent background needs dark text, not light text.** Before
  this system, accents like `coral` were dark, so `onDark` (light) text on
  them made sense. They're bright now. `FilledButton`/`PrimaryButton`
  already do the right thing via the theme (`foregroundColor: night`) —
  but anything with its own inline spinner/icon on a coral button (the
  auth pages had this bug twice) needs to explicitly use `night`, not
  `onDark`.
- **A `*Soft` token is a fill, never a text or icon colour.** It's a ~16%
  alpha wash — used standalone as an icon colour it's nearly invisible
  (this happened in Signal Grid's empty-cell icon).
- **`navy` is a fill, `ink` is text — they used to be the same value and
  no longer are.** Any old code that used `CurioColors.navy` as a *text*
  colour on top of a `surface`-coloured tile broke when the palette went
  dark (Link Lab's word tiles were dark-text-on-dark-tile until this was
  caught). If you see `navy` anywhere outside a card's `color:`/
  `backgroundColor:` parameter, it's almost certainly wrong.
- Check contrast against **both** the page background and the translucent
  card fill blended over it — a colour can pass against one and fail
  against the other.

## 8. Spacing & radius

`CurioSpace` (`curio_ui.dart`): `xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 48`.

`CurioRadius`: `small 10 · medium 14 · large 20 · hero 26`. Hero cards and
the floating nav go further — 22–28px on bespoke cards, full `999` (stadium)
on pills and tab chips. Nothing in the current system uses a radius under
10; the pre-redesign sharp corners (2–4px) are gone on purpose — round
everything.

## 9. Components inventory

| Widget | Where | Use |
|---|---|---|
| `CurioPage` | `curio_ui.dart` | Standard page shell: gradient + textured backdrop, optional `AppBar`, max-width content column |
| `GlassCard` | `curio_ui.dart` | Standard elevated card (§5) |
| `CurioCard` | `curio_ui.dart` | Simpler opaque card (no glass sheen) — fine for dense list rows |
| `ModeTile` | `curio_ui.dart` | Icon + title/subtitle + accent stripe list row (game/mode pickers) |
| `PrimaryButton` | `curio_ui.dart` | Full-width `FilledButton` wrapper; inherits theme colours, don't override `foregroundColor` per call site |
| `StatPill` / `CurioIconTile` | `curio_ui.dart` | Small stat readouts with an icon medallion |
| `CurioProgressBar` / `ProgressRing` | `curio_ui.dart` | Animated linear/circular progress, colour passed in per skill |
| `MascotBadge` / `CurioBrand` | `curio_ui.dart` | Brand mark and mascot avatar, used on auth screens and Profile |
| `_FloatingNav` | `main_shell.dart` | Bottom pill nav (§6) — private to the shell, not reused elsewhere |

## 10. Motion

Kept deliberately light-touch and dependency-free (no animation package):

- **Entrance:** sections fade + slide up on first paint, staggered ~60ms
  apart (`_FadeSlideIn` in `home_page.dart`) — a page should feel like it
  arrives, not just appear.
- **Living state:** a subtle looping scale pulse (`_Pulse`) on "this is
  active right now" icons — the streak flame in the header chip and on
  today's day-marker.
- Both are plain `AnimationController` + implicit-animation patterns.
  Don't reach for a new dependency for a UI animation until these two
  patterns genuinely can't do the job.

## 11. Kid-facing vs parent-facing tone

- **Kid-facing surfaces** (Home's game banners, skill badges, discovery
  cards): full-saturation colour. Banner art is a fully opaque two-tone
  vivid gradient per skill colour (see `_CardArt._vividGradient` in
  `home_page.dart`) with a solid white icon — never a low-alpha tint of
  the accent blended into the dark card, which reads as muddy rather than
  playful.
- **Parent-facing surfaces** (Login, Parent dashboard, Profile settings
  rows): same dark-glass chrome, calmer — accent colour used for actions
  and status, not for large fills.

## 12. When adding a new screen

1. Wrap it in `CurioPage` unless you have a specific reason not to (Home
   is the only current exception, and only because it needs full-bleed
   edge-to-edge control the shared shell doesn't offer).
2. Reach for `GlassCard`, `CurioCard`, `PrimaryButton`, `ModeTile` before
   writing a new bespoke container.
3. Pick colours from the tables in §2 — if the right one doesn't exist,
   add a named token to `CurioColors` rather than inlining a hex value.
4. Re-read §7 before pairing a background with a text/icon colour by hand.
5. If it needs to feel alive, prefer the existing `_Pulse`/`_FadeSlideIn`
   patterns over inventing a new animation approach.
