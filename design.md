# Curio Design System

This is the living reference for Curio's visual language: one evergreen
"glass" system with a genuine **dark and light mode**, both rolled out
app-wide with a persisted toggle. Read this before touching UI code; it
exists so the app stays visually consistent as more screens are added,
and so hard-won lessons (mostly about glass/blur, and about what actually
needs to flip between modes) aren't relearned the hard way.

Source of truth in code:
- [`lib/core/theme/curio_colors.dart`](lib/core/theme/curio_colors.dart) — every **dark**-mode colour token
- [`lib/core/theme/curio_colors_light.dart`](lib/core/theme/curio_colors_light.dart) — the **light**-mode counterpart, same field names
- [`lib/core/theme/curio_theme.dart`](lib/core/theme/curio_theme.dart) — builds both `ThemeData`s from the two token classes
- [`lib/core/theme/theme_controller.dart`](lib/core/theme/theme_controller.dart) — holds and persists the current mode
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
| `surface` | `#232A2C` | `#FFFFFF` | Default card/glass base |
| `surfaceMuted` | `#15191A` | `#F3E9D8` | Sunken/recessed fill (chips, empty states) |
| `night` | `#05100D` | `#2E2417` | "The darkest possible ink" — spinners/icons on a bright button, not a page background |
| `navy` | `#123A30` | `#E24A3D` | A deep/bold **hero card** fill, independent of `ink`/`canvas`. One bold stat/reward display per screen (e.g. Squeeze's secret-range card), not general cards |

Dark mode's `surface` is a neutral warm slate, deliberately **not** a
green tint, so cards separate from the page by hue as well as brightness
(see §4). Light mode's `surface` is plain white for the same reason it
would be redundant to tint it — white already reads as distinctly
"elevated" against the cream backdrop.

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

## 4. Backdrop, texture, and the "cards must not blend into the page" rule

Early dark-mode iterations made cards a slightly-lighter version of the
same green as the page background — it read as flat and monotonous. The
fix that stuck: **cards are a neutral, slightly warm slate in dark mode**
(not a green tint at all), and **plain white in light mode** — either way,
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

## 5. Glass cards — and the mistakes not to repeat

`GlassCard` (`curio_ui.dart`) is the standard elevated-card look: a
translucent tinted fill, a crisp border, a soft top-left sheen, and a lift
shadow — in dark mode. In light mode it's simply a plain white card with a
soft shadow; a translucent "glass" fill is a dark-mode trick that just
reads as solid-white-with-extra-steps once the backdrop is already light,
so `GlassCard` and Home's `_GlassPanel` both branch on brightness
internally rather than trying to force one recipe to cover both.

**It does not use a real `BackdropFilter` blur.** Two things went wrong
before this was fixed, in this order:

1. **Opacity too high.** The first dark-mode version tinted at ~70%
   opacity — that just reads as a solid, flatly-coloured card, not glass.
   Real glassmorphism needs a *light* fill (roughly 30–35%, sometimes
   lower) so blur (or, here, the neutral surface colour plus a bright
   border and sheen) does the work of separating it from the backdrop.
2. **Stacked blur.** Every card additionally had its own `BackdropFilter`.
   With several cards in a scrolling shelf plus the nav bar all blurring
   independently in the same frame, blur started rendering in visibly
   wrong places on a real device (Impeller), even though it looked fine
   in web testing (Skia). The fix was architectural, not another value
   tweak: **there is exactly one real `BackdropFilter` in the entire
   app**, on the bottom nav pill, clipped tightly to the pill's own
   stadium shape so only the pixels directly behind it blur. Every card
   fakes the rest of the "glass" look with plain translucency (or, in
   light mode, doesn't need to fake anything — a plain white fill already
   separates cleanly).

If you're tempted to add blur to a new card: don't. Reach for `GlassCard`
as-is. If a screen genuinely needs a frosted look, treat it the same way
the nav bar is treated — one `BackdropFilter`, clipped to exactly the
shape that needs it, nothing else blurring in the same frame.

## 6. Navigation

The bottom nav is a floating pill, not a `Scaffold.bottomNavigationBar`.
That's also load-bearing, not a style choice: Scaffold's bottom-nav slot
paints its own background independent of whatever widget lives in it,
which is exactly what caused a stray coloured bar to show up behind the
pill on a real device. The fix was to stop using the slot at all — the
nav is a `Positioned` widget inside the *same* `Stack` as the page body,
so there is structurally no other layer that can paint behind it.

- The pill's whole treatment flips with the **global** mode (not per tab
  — every tab shares one mode now): dark-glass with a lime active pill in
  dark mode, warm cream-glass with a coral active pill in light mode.
  `_FloatingNav`'s `light` parameter is driven by
  `Theme.of(context).brightness`, computed once in `MainShell.build`.
- The one `BackdropFilter` blur (§5) lives here, clipped to the pill.
- Desktop/wide layouts get a side rail (`_CurioRail` in `main_shell.dart`)
  instead — same tokens, different shape, same brightness-aware pattern.

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
| `GlassCard` | `curio_ui.dart` | Standard elevated card (§5), both modes |
| `CurioCard` | `curio_ui.dart` | Simpler opaque card (no glass sheen) — fine for dense list rows |
| `ModeTile` | `curio_ui.dart` | Icon + title/subtitle + accent stripe list row (game/mode pickers) |
| `PrimaryButton` | `curio_ui.dart` | Full-width `FilledButton` wrapper; inherits theme colours by default — pass `color:` explicitly only when you also know the right foreground pairing (see §7) |
| `StatPill` / `CurioIconTile` | `curio_ui.dart` | Small stat readouts with an icon medallion |
| `CurioProgressBar` / `ProgressRing` | `curio_ui.dart` | Animated linear/circular progress, colour passed in per skill or defaults to the theme accent |
| `MascotBadge` / `CurioBrand` | `curio_ui.dart` | Brand mark and mascot avatar |
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
   writing a new bespoke container — they already handle both modes.
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
