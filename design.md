# Curio design budget

Curio follows Airbnb's style: a soft blush page, white panels with a 1px
hairline, one sans face where weight does the work, rounded pictures,
round grey buttons and plenty of whitespace. It is light only (there is
no dark theme at the moment). Everything visual comes from
`lib/theme/curio_tokens.dart` (`CurioTokens`, a `ThemeExtension`). If a
screen needs a value that is not listed here, the screen is wrong, not the
list.

`test/design_rules_test.dart` enforces the rules marked (tested).

## Colour: 13 tokens (tested)

| Token | Value | Use |
| --- | --- | --- |
| `base` | `#FEF7F6` | Page background (a whisper of coral over white) |
| `surface` | `#FFFFFF` | Panels, inputs, sheets, the raised block |
| `surfaceRaised` | `#F2F2F1` | Quiet grey fills: round buttons, tracks, empty cells, disabled |
| `border` | ink at 12% | The 1px rule between rows and around panels |
| `textPrimary` | `#2E2417` | Headings and body |
| `textSecondary` | `#5B4E3B` | Supporting text and metadata |
| `accent` | `#F2564A` | Primary action, selection, links (coral) |
| `onAccent` | `#2A2014` | Text and icons on `accent` |
| `correct` | `#15803F` | Right answers |
| `wrong` | `#D8362B` | Wrong answers and errors |
| `tintMaths` | `#DB9A2C` | Maths section |
| `tintLogic` | `#2E9FD6` | Logic section |
| `tintThinking` | `#8467E0` | Thinking section |

No `Color(0x...)` literal may appear outside the tokens file. A section tint
may be washed over `surface` at low opacity with `CurioTokens.wash(tint)`.
Puzzle boards that need several distinguishable regions reuse the six hues
above (accent, correct, wrong and the three tints), never new ones.

The accents are the original palette's coral, forest, saffron, blue and
plum. The logo mark keeps its own cream tile (`curio_logo.dart`).

The signed-out and onboarding screens (`lib/features/auth/`) follow the
same style. They still read some colours from the original palette files
(`CurioColorsLight`, now flattened to the same canvas and white panels),
and their illustrations keep their own art, so the tested rules below do
not apply to them.

## Radii: 2 (tested)

`radiusCard = 20` and `radiusPill = 999`. `BorderRadius.circular` accepts
only those two tokens.

## Elevation: 2 (tested)

`shadowNone` and `shadowRaised`. `shadowRaised` goes on exactly one element
per screen, the primary one. Everything else is flat and separated by the
1px `border` or by whitespace. `BoxShadow` may not be constructed outside
the tokens file.

## Spacing: one scale

4, 8, 12, 16, 24, 32, 48 (`s4` to `s48`). No other number is a padding,
margin or gap. Where a layout must clear the floating navigation it uses a
multiple of 48.

## Gradients (tested)

Use solid fills for app surfaces. Progress fills, timer fills and the
original game emblem artwork may use gradients.

## Type: 1 face, 5 roles

DM Sans for everything, as Airbnb uses one face: `display` (32, bold),
`title` (20, bold), `body` (16), `bodySmall` (14) and `label` (13).
Headings are bold and slightly tight; the Material text theme maps onto
the same face. Fraunces appears only in the "curio" wordmark. Sentence
case everywhere: no tracked capitals, no small caps. A short pill label
(`CurioEyebrow`) may sit above a heading.

## Components (lib/core/widgets/curio_kit.dart and curio_ui.dart)

Build screens from these so every page reads the same:

- `CurioPage` with a `title` gives the top bar: a round back button on the
  left (`CurioRoundIcon`), a small bold title in the middle.
- `SectionHeading`: a bold title, an optional quiet line under it, and,
  with `onMore`, a small round arrow after the words.
- `CurioClay` / `CurioCard`: white panels with a hairline. A screen's one
  primary block may be `raised`.
- `CurioListGroup` of `CurioListRow`: settings and links, line icon,
  name, quiet line, chevron, hairlines between.
- `CurioChip`, `XpChip`, `DoneBadge`: small pills and the done tick.
- `CurioIconButton`: a round grey icon button.
- `CurioPressable`: cards scale a touch when pressed instead of splashing.
- `CurioGrid`: cards two to a row on phones, three when wider.
- Games: `GameTile`, `GameListingCard` and `GameCompactCard`
  (`lib/features/games/presentation/game_cards.dart`) show a game as a
  pastel tile with its 3D emblem.

Tab pages run under the floating navigation pill and pad their end to
clear it, so no band of another colour shows behind it.

## Motion: 2 durations, 1 curve

`fast` (120ms) for state changes, `slow` (220ms) for transitions, `curve`
(ease out cubic) for both. Layout size is never animated. Anything that
moves checks `MediaQuery.disableAnimations` (use `CurioTokens.motion`).
Game mechanics that are themselves motion (a scale tipping, a beam
bouncing) keep their own timing.

## Writing (tested)

No em dashes or en dashes anywhere in `lib/`. Use commas, periods or
parentheses.

## Note on Hallmark

The brief asked for the Hallmark skill to be read as a reference. It is not
installed on this machine (nothing under `~/.claude/skills/hallmark`), so
these rules come straight from the brief.
