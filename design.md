# Curio design budget

Curio is light, in the original warm palette (dark mode is off, and there
is no dark theme at the moment). Everything visual comes from `lib/theme/curio_tokens.dart`
(`CurioTokens`, a `ThemeExtension`). If a screen needs a value that is not
listed here, the screen is wrong, not the list.

`test/design_rules_test.dart` enforces the rules marked (tested).

## Colour: 13 tokens (tested)

| Token | Value | Use |
| --- | --- | --- |
| `base` | `#FDF1E2` | Page background (cream) |
| `surface` | `#FFFFFF` | Panels, inputs, sheets, the raised block |
| `surfaceRaised` | `#F3E9D8` | Tracks, pressed and disabled fills |
| `border` | ink at 12% | The 1px rule between rows and around panels |
| `textPrimary` | `#2E2417` | Headings and body |
| `textSecondary` | `#5B4E3B` | Supporting text and metadata |
| `accent` | `#F2564A` | Primary action, selection, links (coral) |
| `onAccent` | `#2E2417` | Text and icons on `accent` |
| `correct` | `#15803F` | Right answers |
| `wrong` | `#D8362B` | Wrong answers and errors |
| `tintMaths` | `#DB9A2C` | Maths section |
| `tintLogic` | `#2E9FD6` | Logic section |
| `tintThinking` | `#8467E0` | Thinking section |

No `Color(0x...)` literal may appear outside the tokens file. A section tint
may be washed over `surface` at low opacity with `CurioTokens.wash(tint)`.
Puzzle boards that need several distinguishable regions reuse the six hues
above (accent, correct, wrong and the three tints), never new ones.

These are the values of the original light palette: canvas, white surface,
ink, coral, forest, saffron, blue and plum.

The signed-out and onboarding screens (`lib/features/auth/`) were restored
to their original design on request. They use the original palette files,
clay surfaces, art and type scale, and the tested rules below do not apply
to them.

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
