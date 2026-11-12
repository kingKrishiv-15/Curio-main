# Curio design budget

Curio is dark only. Everything visual comes from `lib/theme/curio_tokens.dart`
(`CurioTokens`, a `ThemeExtension`). If a screen needs a value that is not
listed here, the screen is wrong, not the list.

`test/design_rules_test.dart` enforces the rules marked (tested).

## Colour: 13 tokens (tested)

| Token | Value | Use |
| --- | --- | --- |
| `base` | `#05100D` | Page background |
| `surface` | `#15191A` | Flat panels, inputs, sheets |
| `surfaceRaised` | `#232A2C` | The one raised element, pressed and selected fills |
| `border` | white at 14% | The 1px rule between rows and around panels |
| `textPrimary` | `#F4FAF6` | Headings and body |
| `textSecondary` | `#8D948F` | Supporting text and metadata |
| `accent` | `#49BB8C` | Primary action, selection, links |
| `onAccent` | `#05100D` | Text and icons on `accent` |
| `correct` | `#4FD69B` | Right answers |
| `wrong` | `#F0685A` | Wrong answers and errors |
| `tintMaths` | `#E7BE6B` | Maths section |
| `tintLogic` | `#8FC3D9` | Logic section |
| `tintThinking` | `#BFA6E0` | Thinking section |

No `Color(0x...)` literal may appear outside the tokens file. A section tint
may be washed over `surface` at low opacity with `CurioTokens.wash(tint)`.
Puzzle boards that need several distinguishable regions reuse the six hues
above (accent, correct, wrong and the three tints), never new ones.

How the old palette maps: canvas, night and cream became `base`. surface and
surfaceMuted became `surface`. clay, navy and every `*Soft` wash became
`surfaceRaised`. ink became `textPrimary`, inkSoft and inkMuted became
`textSecondary`. outline and outlineSoft became `border`. forest, jade, teal
and ice became `accent`. success became `correct`. danger and coral became
`wrong`. saffron, gold and spark became `tintMaths`. blue and frost became
`tintLogic`. plum and rose became `tintThinking`. The light palette is gone.

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

None, except inside a progress or timer fill.

## Type: 2 faces, 5 roles

Fraunces for `display` (32) and `title` (20). DM Sans for `body` (16),
`bodySmall` (14) and `label` (13). `label` is the body face one step
smaller, sentence case, untracked. No tracked capitals, no small caps, no
eyebrow line above a heading.

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
