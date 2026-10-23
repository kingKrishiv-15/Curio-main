# Curio Design System

This is the living reference for Curio's visual language: one evergreen
**clay** system (soft, puffed-up surfaces — see §5) with a genuine **dark
and light mode**, both rolled out app-wide with a persisted toggle. Read
this before touching UI code; it exists so the app stays visually
consistent as more screens are added, and so hard-won lessons (about
surfaces and blur, and about what actually needs to flip between modes)
aren't relearned the hard way.

Source of truth in code:
- [`lib/core/theme/curio_colors.dart`](lib/core/theme/curio_colors.dart) — every **dark**-mode colour token
- [`lib/core/theme/curio_colors_light.dart`](lib/core/theme/curio_colors_light.dart) — the **light**-mode counterpart, same field names
- [`lib/core/theme/curio_theme.dart`](lib/core/theme/curio_theme.dart) — builds both `ThemeData`s from the two token classes
- [`lib/core/theme/theme_controller.dart`](lib/core/theme/theme_controller.dart) — holds and persists the current mode
- [`lib/core/widgets/curio_clay.dart`](lib/core/widgets/curio_clay.dart) — `CurioClay`, the one surface every card, tile and chip is built from (§5)
- [`lib/core/widgets/curio_ui.dart`](lib/core/widgets/curio_ui.dart) — shared page shell/components, all brightness-aware
- [`lib/features/home/presentation/home_page.dart`](lib/features/home/presentation/home_page.dart) — the reference implementation, both modes; when in doubt, match Home

## 1. Philosophy

Curio is a learning product for kids, used day-to-day by a parent who sets
it up and checks in on progress. The UI needs to do two things at once,
**in both light and dark mode**:

- **Feel premium and calm, not garish**, in its chrome — a deep textured
  evergreen backdrop in dark mode, a clean warm cream backdrop in light
  mode. Depth and quality over primary-colour loudness, either way.
- **Feel warm and alive for a kid**, especially anywhere a child is
  looking at their own progress or picking a game: bright, saturated
  accent colour, a bit of motion (a pulsing streak flame, cards
  fading/sliding in), and banner art that pops rather than a muted wash —
  in *both* modes, not just one.

Those two moods live in different places: the **chrome** (backgrounds,
nav, structural cards) is the register that changes between dark and
light; **content that represents play and progress** (game banners, skill
accents, badges) is vivid, full-saturation colour regardless of mode. See
§4 and §7.

## 2. The two-palette system

Every colour is a named token that exists **twice** — once on
`CurioColors` (dark values) and once on `CurioColorsLight` (light
values), always under the **same field name**. That symmetry is the
entire point: converting any colour reference from dark-only to
mode-aware is always a mechanical 1:1 swap, never a judgement call about
which token or `ColorScheme` slot something maps to.

The swap itself goes through one helper, exported from `curio_ui.dart` and
available anywhere it's imported (i.e. everywhere):

```dart
Color curioColor(BuildContext context, Color darkColor, Color lightColor) {
  return Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
}
```

```dart
// ✅ adapts to the toggle
final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);

// ❌ always dark, even in light mode
final ink = CurioColors.ink;
```

`CurioTheme` (`curio_theme.dart`) builds both `ThemeData`s from one shared
`_build({required bool dark})` function using the exact same `c(dark, light)`
pattern internally — so anything that goes through `Theme.of(context)`
(text styles, default button/input/dialog colours) already adapts for
free. You only need `curioColor(...)` for colours a widget reaches for
*directly* instead of through the theme.

Home's private palettes (`_HomeDark` / `_HomeLight` in `home_page.dart`)
follow the identical pattern at a smaller scope, via a local `_hc(...)`
helper — Home predates the shared `CurioColors`/`CurioColorsLight` split
and keeps its own bespoke tokens, but the *mechanism* is the same one
described here.

### Toggling and persistence

- `ThemeController` (`theme_controller.dart`) is a `ChangeNotifier` holding
  the current `ThemeMode`, created once in `CurioApp` and exposed to the
  whole tree via `CurioThemeScope.of(context)`. It persists the choice
  with `shared_preferences` and defaults to **dark**.
- `MaterialApp` is given both `theme: CurioTheme.light` and
  `darkTheme: CurioTheme.dark`, with `themeMode: controller.mode` — the
  actual mode switch is Flutter's own well-tested `Theme` mechanism, not
  anything hand-rolled.
- **The one toggle switch lives in Profile** (`_ThemeToggleTile` in
  `profile_page.dart`), a "Dark mode" row with a `Switch` bound to
  `CurioThemeScope.of(context).toggle()`. Don't add a second toggle
  elsewhere without a real reason — one clear, discoverable place beats a
  quick-access icon scattered into headers too.

## 3. Colour tokens

Values below are dark / light side by side. Never hardcode a hex value in
a page — if you need a colour that doesn't exist yet, add a named token
to *both* classes under the same field name.

### Backdrop & surfaces

| Token | Dark | Light | Use |
|---|---|---|---|
| `canvas` | `#05100D` | `#FDF1E2` | Deepest/page background |
| `canvasDeep` | `#0A1A15` | `#FFF8EE` | Gradient mid-stop |
| `surface` | `#232A2C` | `#FFFFFF` | Material's surface (`ColorScheme.surface`) |
| `clay` | `#2E3538` | `#FFFCF7` | The default clay body — every card, tile and quiet button (§5) |
| `surfaceMuted` | `#15191A` | `#F3E9D8` | Sunken/recessed fill (chips, empty states) |
| `night` | `#05100D` | `#2E2417` | "The darkest possible ink" — spinners/icons on a bright button, not a page background |
| `navy` | `#123A30` | `#E24A3D` | A deep/bold **hero card** fill, independent of `ink`/`canvas`. One bold stat/reward display per screen (e.g. Squeeze's secret-range card), not general cards |

Dark mode's `clay` is a neutral warm slate, deliberately **not** a green
tint, so cards separate from the page by hue as well as brightness (see
§4). Light mode's `clay` is a warm white rather than pure white, so its
highlight and shadows read as soft clay instead of paper.

### Text

| Token | Dark | Light | Use |
|---|---|---|---|
| `ink` / `onDark` | `#F4FAF6` | `#2E2417` | Primary text/icons |
| `inkSoft` | `#C7D0CC` | `#5B4E3B` | Secondary text |
| `inkMuted` | `#8D948F` | `#8C7C63` | Tertiary/caption text, faint labels |
| `outline` | white @ 24% | ink @ 12% | Visible borders |
| `outlineSoft` | white @ 14% | ink @ 8% | Faint dividers/borders |

`ink`/`onDark` are the same value in dark mode (kept as two names because
call sites already expect "light text" semantics from `onDark`); in light
mode `onDark` stays a literal white (`CurioColorsLight.onDark`), used
specifically for text/icons sitting on a bright-accent-coloured surface in
*either* mode (e.g. the icon inside the brand logo mark), while `ink`
is the page's primary (mode-appropriate) text colour.

### Accent hues

| Token | Dark | Light | Personality |
|---|---|---|---|
| `coral` | `#E49577` | `#F2564A` | Primary interactive accent — buttons, links, focus rings, active nav pill |
| `saffron` / `gold` | `#E7BE6B` | `#DB9A2C` | Number sense / rewards / "featured" badges |
| `blue` / `frost` | `#8FC3D9` | `#2E9FD6` | Evidence / calm, analytical |
| `plum` / `pink` | `#BFA6E0` | `#8467E0` | Reasoning / secondary highlight |
| `forest` | `#49BB8C` | `#25A369` | Brand primary — logo mark, brand gradient, default icon accent |
| `success` / `green` | `#4FD69B` | `#25A369` | Correct answers, positive state |
| `danger` | `#F0685A` | `#D8362B` | Errors, destructive state |

Each has a `*Strong` (deeper, still opaque, for text/borders needing a
little more weight) and a `*Soft` variant (a **translucent wash**, ~16%
opacity — for a card fill only; see §7 for why it must never be a text or
icon colour).

**Every accent is a *bright*, saturated colour in both modes** — that's
new versus the very first dark-only iteration, where several of these
(`coral` especially) were dark, muted tones meant to sit on a light page.
When `onPrimary`/button foreground colour was ported to dark mode, that
mismatch (light text on a now-bright accent) was a real shipped bug —
see §7.

### Skill colour mapping

Curio's four skills each own one accent hue, used consistently for tabs,
progress bars, and badges wherever that skill appears, in both modes:

- **Number sense** → gold
- **Patterns** → coral (shared token) / `rose` (Home's own naming)
- **Evidence** → blue/frost / `sky` (Home's own naming)
- **Reasoning** → plum/violet

### Gradients

- `brandGradient` — the logo mark and any small brand-coloured surface.
  Dark: `forestStrong → forest`. Light: `coral → coralStrong`.
- `pageGradient` — the default page backdrop, drawn by `CurioPage`. Dark:
  a three-stop teal → near-black wash. Light: a two-stop warm cream wash.
- `heroGradient` — a richer full-bleed hero panel (e.g. the Frostlands
  story scene).
- `markGradient`, `markGlyph`, `spark` — the logo's own colours (§13).
  `markGradient`/`markGlyph` hold **identical values on both classes**: the
  mark stays evergreen in both modes. `spark` differs slightly (a deeper
  amber on light) so the wordmark's i-dot stays visible on cream.

## 4. Backdrop, texture, and the "cards must not blend into the page" rule

Early dark-mode iterations made cards a slightly-lighter version of the
same green as the page background — it read as flat and monotonous. The
fix that stuck: **cards are a neutral, slightly warm slate in dark mode**
(not a green tint at all), and **warm white in light mode** — either way,
cards separate from the page by *hue* as well as brightness, not by
brightness alone.

The page backdrop itself is never a flat fill in either mode —
`CurioPage` (and Home's own bespoke copy of the same idea) layers:
1. `pageGradient` (dark: teal → near-black; light: cream → warm cream)
2. A `CustomPainter` texture: two large, very-low-alpha soft "blob" glows
   (one warm/gold, one cool/blue) plus a fine grain of low-alpha dots —
   enough to keep the eye interested without reading as a pattern. The
   grain dot colour itself flips too (white flecks on dark, ink-coloured
   flecks on light) — a light grain on a light page would just vanish.

If you add a new full-page screen, use `CurioPage` and you get this for
free, in both modes. Don't build a flat `Scaffold(backgroundColor: canvas)`.

## 5. Clay surfaces

Every surface in Curio — cards, tiles, chips, game tokens, buttons, the
nav capsule — is **clay**: soft, rounded, and a little inflated, like
something a kid could squish. It replaced an earlier glass look (October
2026); the reasons it suits Curio are the same as §1 — warm and tactile
for a child, calm enough for a parent.

### Anatomy

`CurioClay` (`curio_clay.dart`) paints, back to front:

1. **A drop shadow in the body's own hue** (a yellow tile casts a warm
   shadow, not a grey one; plain black in dark mode). Only ever outside
   the body.
2. **An opaque body.** Pass `color:` — opaque, or a translucent accent
   wash (`accent.withValues(alpha: .16)`, a `*Soft` token), which
   `clayFill` tints onto the `clay` token so it becomes a pastel body
   rather than a see-through one. Never alpha-blend by hand.
3. **Two inner shadows**: a light one along the top-left edge and a deeper
   one along the bottom-right, which is what makes it look puffed up.

Depth scales with size (7% of the shortest side, 2–8px), so one widget
works from a 36px day bubble to a full card.

### Raised, pressed, outlined

- **Raised** (default): anything that holds content or can be tapped.
- **`pressed: true`**: the inner shadows swap sides and the drop shadow
  goes, so it reads as a **dent** — empty slots, wells, drop targets,
  progress tracks, "not yet" days. Home's week row is the reference:
  played days puff up, the rest are dents.
- **`outline:`**: a 2px ring just inside the edge, for selected, featured
  or "today" — state that clay's shading alone can't carry.

A state that was ever distinguishable must stay distinguishable: express
it with tint and/or `outline`, and keep the icon or text that carried it.

### Buttons

`FilledButton` and `OutlinedButton` are clay through the theme, so call
sites don't change: the button's Material paints the body, its
**elevation** paints the drop shadow (a button clips its background
layer, so it can't paint one itself), and `clayButtonLayer` — a
`ButtonStyle.backgroundBuilder` — adds the inner shadows. While held,
elevation drops to 0 and the inner shadows swap: the button squishes in
under the finger. `OutlinedButton` has no outline any more; it's the
quiet, `clay`-coloured button beside a coral `FilledButton`. Text fields
are wells: `surfaceMuted` fill, no outline until focused.

### Rules learned the hard way

- **HSL saturation runs to 100% on near-whites**, so tinting a warm-white
  card's shadow by its own hue gave it an orange shadow. `paintClay` caps
  saturation at 55% before deepening.
- **Over vivid art the light highlight washes colour out.** Game art gets
  only the inner shadows, with a much weaker highlight (`fill: false`).
- **`CurioClay` clips its child to its radius.** Anything that used to
  poke past a rounded corner (a sparkle, a badge) gets cut off — put the
  clay *behind* it in a `Stack` instead (see `MascotBadge`).
- **Faint borders are a glass habit.** They separated a translucent card
  from the page; clay's shadows already do that. `CurioCard` ignores a
  `borderColor` at or under 50% alpha and draws stronger ones as a ring.
- **Widget tests draw elevation shadows as solid outlines**
  (`debugDisableShadows`), so clay buttons look ringed in test
  screenshots. Turn it off (and back on before the test ends) when
  rendering previews.
- **Still no `BackdropFilter`.** The glass era learned that several
  independent blurs in one frame render in the wrong place on Impeller.
  Clay needs none — its shadows are `MaskFilter` blurs on the element's
  own canvas, not reads of the pixels behind it. Don't reintroduce a
  backdrop blur.

## 6. Navigation

The bottom nav is a floating pill, not a `Scaffold.bottomNavigationBar`.
That's also load-bearing, not a style choice: Scaffold's bottom-nav slot
paints its own background independent of whatever widget lives in it,
which is exactly what caused a stray coloured bar to show up behind the
pill on a real device. The fix was to stop using the slot at all — the
nav is a `Positioned` widget inside the *same* `Stack` as the page body,
so there is structurally no other layer that can paint behind it.

- The pill is a clay capsule with one sliding, puffed-up selection tinted
  in the accent: evergreen in dark mode, coral in light. It flips with the
  **global** mode; `_FloatingNav`'s `light` parameter is driven by
  `Theme.of(context).brightness`, computed once in `MainShell.build`.
- Desktop/wide layouts get a side rail (`_CurioRail` in `main_shell.dart`)
  instead — a `clay`-coloured panel, same tokens, same brightness-aware
  pattern.

## 7. Hard-won contrast rules

These read as obvious in hindsight but each one caused a real, shipped bug
during the dark-mode (and later dual-mode) migration — checklist before
you hand-write a colour pairing:

- **A bright accent background needs dark text, not light text.** Before
  this system, accents like `coral` were dark, so light text on them made
  sense. They're bright now, in both modes. `FilledButton`/`PrimaryButton`
  already do the right thing via the theme (`foregroundColor` resolves to
  the dark ink in both modes) — but anything with its own inline
  spinner/icon on a coral button needs the same explicit dark-ink colour,
  not the page's "light text" token.
- **A `*Soft` token is a fill, never a text or icon colour.** It's a ~16%
  alpha wash — used standalone as an icon colour it's nearly invisible.
- **`navy` is a fill, `ink` is text — don't cross them.** `navy` exists
  specifically so a "hero" card can be a bold, independent colour instead
  of reusing the page's primary text colour as a background. If you see
  `navy` anywhere outside a card's `color:`/`backgroundColor:` parameter,
  it's almost certainly wrong.
- Check contrast against **both** the page background and the translucent
  card fill blended over it — a colour can pass against one and fail
  against the other. Do this check in **both modes**; a pairing validated
  only in dark mode is not validated.
- When converting a file from dark-only to dual-mode, the mechanical
  `curioColor(context, CurioColors.x, CurioColorsLight.x)` swap (§2) is
  always correct *if the field itself represents the right role* — it
  cannot save you from a token that was semantically wrong to begin with
  (e.g. don't swap-convert a value that was already misusing `navy` as
  text; fix the misuse first, then convert).

## 8. Spacing & radius

`CurioSpace` (`curio_ui.dart`): `xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 48`.

`CurioRadius`: `small 10 · medium 14 · large 20 · hero 26`. Hero cards and
the floating nav go further — 22–28px on bespoke cards, full `999`
(stadium) on pills and tab chips. Nothing in the current system uses a
radius under 10; the pre-redesign sharp corners (2–4px) are gone on
purpose — round everything. Same scale in both modes.

## 9. Components inventory

| Widget | Where | Use |
|---|---|---|
| `CurioPage` | `curio_ui.dart` | Standard page shell: gradient + textured backdrop (both modes), optional `AppBar`, max-width content column |
| `CurioClay` | `curio_clay.dart` | The clay surface (§5): raised, `pressed` dent, `outline` ring, tinted `color`. Build bespoke tiles, chips and game pieces from it |
| `ClayPainter` / `paintClay` | `curio_clay.dart` | The same clay for custom painters (board cells, progress bars, art panels) |
| `clayButtonLayer` | `curio_clay.dart` | The theme's button `backgroundBuilder` that makes `FilledButton`/`OutlinedButton` clay — not for direct use |
| `GlassCard` | `curio_ui.dart` | Standard card: clay with an ink ripple when tappable; `tint` becomes the clay colour. (Named from the glass era) |
| `CurioCard` | `curio_ui.dart` | Same clay card with a `color`, a ring for a strong `borderColor` (faint ones are ignored, §5), and a tap ripple — fine for dense list rows |
| `ModeTile` | `curio_ui.dart` | Clay icon tile + title/subtitle list row (game/mode pickers) |
| `PrimaryButton` | `curio_ui.dart` | Full-width `FilledButton` wrapper; inherits theme colours by default — pass `color:` explicitly only when you also know the right foreground pairing (see §7) |
| `CurioStatTile` / `CurioStatRow` | `curio_ui.dart` | Pastel stat tiles (big Fraunces number over a short label) in gold, plum, forest or coral; the row keeps them equal height and stacks them at large text sizes. Home's weekly growth and Profile's totals |
| `ExplorerAvatar` | `curio_ui.dart` | The explorer's round letter avatar — Home's header (opens Profile) and Profile's header |
| `CurioIconTile` | `curio_ui.dart` | An icon on a soft tinted square — list rows, info cards |
| `CurioProgressBar` / `ProgressRing` | `curio_ui.dart` | Animated linear/circular progress, colour passed in per skill or defaults to the theme accent |
| `MascotBadge` / `CurioBrand` | `curio_ui.dart` | Mascot avatar; `CurioBrand` is the logo lockup used in page headers |
| `CurioLogo` / `CurioLogoMark` / `CurioWordmark` | `curio_logo.dart` | The logo (§13): lockup, square mark, wordmark alone |
| `CurioFadeSlideIn` / `CurioFloat` | `curio_motion.dart` | Public entrance and gentle-bob motion (§10) |
| `AuthFrame` / `WelcomePanel` | `auth_layout.dart` | Frame for every signed-out step: back + logo, one column on phones, art beside the form when wide |
| `OrbitHero`, `GameFanArt`, `DiscoveryArt`, `GrowthArt`, `InboxArt` | `features/auth/presentation/widgets/welcome_art.dart` | Illustrations for the landing page and intro slides — decorative, excluded from semantics |
| `OtpCodeField` | `features/auth/presentation/widgets/otp_code_field.dart` | Digit boxes over one real text field (paste, iOS code autofill, screen readers) |
| `gameCatalog` / `skillColor` | `features/games/game_catalog.dart` | The one list of activities (title, tagline, icon, duration) that Home, Learn and Skill Quest render, plus the per-skill colour and icon. Add a game here, not on each screen |
| `gameRewards` / `awardDaily` | `features/games/common/game_rewards.dart`, `game_kit.dart` | XP, skill and discovery per activity — mirrors the server's `activity_rewards` table (a test compares them) |
| `GameHeader`, `GameResultCard`, `PracticeBadge`, `showHowToPlay` | `features/games/common/game_kit.dart` | Shared game chrome: header, end-of-game card (says "already earned" on replays), practice rounds |
| `GameCard` (`tile` / `row` / `hero` / `spotlight`) | `features/games/presentation/game_card.dart` | The one way a game is shown anywhere: art panel in the skill gradient, title, tagline, skill · time · XP chips, and a Play / Play again action. `tile` for grids and shelves, `row` for lists, `hero` for today's featured quest, `spotlight` (big art, round play button on its edge) for Home's carousel. Badges on the art: DONE, QUEST, NEW |
| `GameArt` / `gameColor` | `game_card.dart`, `game_banner.dart` | The art panel: one bold solid colour per game (kept within its skill's colour family, settled slightly in dark mode via `bannerFill`), a faded icon and the game's preview. A card's Play button and borders use the same colour; the skill chip keeps the skill colour. Home's skill tiles use `skillSolidColor`. New game → add its colour, or it falls back to the skill colour |
| `GamePreview` | `features/games/presentation/game_preview.dart` | A tiny drawing of each game's board (tiles, chips, grid, scales…) on a fixed 150×84 canvas that scales down. New game → add a case, or it falls back to its icon |
| `GameGrid` | `game_card.dart` | Equal-height rows of tiles; 1–4 columns by width. Use it instead of `GridView` so cards never clip at large text sizes |
| `SkillGamesPage` | `features/learn/presentation/skill_games_page.dart` | One skill's level and games, opened from Home's skill tiles |
| `BadgeShelf`, `BadgeMedal`, `showBadgesSheet` | `features/profile/presentation/badges_view.dart` | Profile's badges: medals coloured by family once earned, ringed by progress until then. The badges themselves are computed from activity history in `profile/domain/badges.dart`, never stored |
| `ParentalGate` | `core/widgets/parental_gate.dart` | Account-password verification on each entry to the parent dashboard and privacy pages |
| `showTextPrompt` | `core/widgets/text_prompt_dialog.dart` | One-field dialog that owns its controller — use it instead of disposing a controller after `showDialog` |
| `_ThemeToggleTile` | `profile_page.dart` | The one light/dark switch (§2) |
| `_FloatingNav` | `main_shell.dart` | Bottom pill nav (§6) — private to the shell, not reused elsewhere |

## 10. Motion

Kept deliberately light-touch and dependency-free (no animation package),
identical in both modes:

- **Entrance:** sections fade + slide up on first paint, staggered ~60ms
  apart (`_FadeSlideIn` in `home_page.dart`) — a page should feel like it
  arrives, not just appear.
- **Living state:** a subtle looping scale pulse (`_Pulse`) on "this is
  active right now" icons — the streak flame in the header chip and on
  today's day-marker.
- Both are plain `AnimationController` + implicit-animation patterns.
  Don't reach for a new dependency for a UI animation until these two
  patterns genuinely can't do the job.
- Outside Home, use the public versions in `curio_motion.dart`:
  `CurioFadeSlideIn` (entrance) and `CurioFloat` (a slow bob for
  illustration pieces). Any looping controller should start through
  `syncLoop(controller, context)` from `didChangeDependencies`, so it
  doesn't tick at all when reduce motion is on — returning a static child
  while the ticker keeps running still costs battery.

## 11. Kid-facing vs parent-facing tone

- **Kid-facing surfaces** (Home's game banners, skill badges, discovery
  cards): full-saturation colour, in both modes. Banner art is a fully
  opaque two-tone vivid gradient per skill colour (see
  `_CardArt._vividGradient` in `home_page.dart`) with a solid white icon —
  never a low-alpha tint of the accent blended into the card, which reads
  as muddy rather than playful.
- **Parent-facing surfaces** (Login, Parent dashboard, Profile settings
  rows): same chrome as the rest of the app, calmer — accent colour used
  for actions and status, not for large fills.

## 12. When adding a new screen

1. Wrap it in `CurioPage` unless you have a specific reason not to (Home
   is the only current exception, and only because it needs full-bleed
   edge-to-edge control the shared shell doesn't offer — even so, Home
   still supports both modes internally).
2. Reach for `GlassCard`, `CurioCard`, `PrimaryButton`, `ModeTile` before
   writing a new bespoke container — they already handle both modes. When
   you do need a bespoke surface, build it from `CurioClay` (raised,
   `pressed` or `outline`d, §5), never a bordered `BoxDecoration`.
3. Pick colours from §3 — if the right one doesn't exist, add a named
   token to *both* `CurioColors` and `CurioColorsLight` under the same
   field name, not just one.
4. Any direct colour reference (not going through `Theme.of(context)`)
   must go through `curioColor(context, CurioColors.x, CurioColorsLight.x)`
   — never reference `CurioColors.x` alone in page-level widget code.
5. Re-read §7 before pairing a background with a text/icon colour by hand.
6. If it needs to feel alive, prefer the existing `_Pulse`/`_FadeSlideIn`
   patterns over inventing a new animation approach.
7. Test both modes before calling a screen done — toggle it from Profile.

## 13. The logo

**Idea.** A "C" for Curio with a magnifying lens resting on its tip — the
look-closer every game asks for. Flat and calm on purpose: one even mint
stroke, a gold lens ring with a short handle reaching into the C's
opening, and a clean gap where the C passes behind the lens, so it reads
as depth without gloss, glass rims or shadows. On the landing page the
same C becomes Nova's orbit, with the four skills travelling around it
(`OrbitHero`).

**Construction.** All geometry lives in `CurioMarkGeometry`
(`lib/core/widgets/curio_logo.dart`) in a 1×1 unit square: the C is an
arc (centre .452/.52, radius .25, weight .122, round caps) opening to the
right and sweeping 274°; the lens (centre .667/.295, radius .1, ring .048)
has a .054-wide handle at 45°, and a .028 gap is cut out of the C around
it. Change the numbers there and everything follows.

**Colours.** `markGradient` (a deep evergreen tile with only a whisper of
gradient), `markGlyph` (mint, the C) and `spark` (gold, the lens). The
lens holds a faint clear-glass tint and one small glint.

**Parts.**
- `CurioLogoMark` — the evergreen tile. Minimum size 16px; it still reads.
- `CurioWordmark` — "curio" in Fraunces with the i's dot in the mark's
  gold (the text uses a dotless ı, U+0131, which Fraunces includes).
- `CurioLogo` — mark + wordmark, horizontal or `vertical`.

**Rules.**
- The tile is always `markGradient` with a `markGlyph` C and a `spark`
  lens — in **both** modes. Don't recolour it to match a screen.
- Don't place the mark on another green; it sits on `canvas`, cards, or
  photos with enough contrast.
- Give it clear space of at least a quarter of its own width.
- Launcher icons, the favicon and `assets/brand/curio-mark.svg` are
  generated from the same painter — never edit those files by hand:

  ```bash
  flutter test tool/generate_brand_assets.dart
  ```

  It writes Android (legacy + adaptive + themed), iOS (opaque, as the App
  Store requires), macOS, and web (incl. maskable) icons.
