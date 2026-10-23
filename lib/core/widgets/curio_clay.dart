import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/curio_colors.dart';
import '../theme/curio_colors_light.dart';

/// The default clay body: warm white on cream, a raised slate on evergreen.
Color clayBase(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? CurioColors.clay
    : CurioColorsLight.clay;

/// [color] as a clay body: as-is when opaque, otherwise tinted onto
/// [clayBase] — so a translucent accent wash (a `*Soft` token, say) makes a
/// pastel body rather than a see-through one.
Color clayFill(BuildContext context, Color? color) {
  if (color == null) return clayBase(context);
  if (color.a >= 1) return color;
  return Color.alphaBlend(color, clayBase(context));
}

/// Curio's surface: a soft, inflated body with a drop shadow in its own hue
/// and two inner shadows (light top-left, deeper bottom-right) that make it
/// look puffed up rather than flat. [pressed] swaps the inner shadows and
/// drops the shadow beneath, so it reads as a dent instead — for wells,
/// empty slots and "not yet" states.
class CurioClay extends StatelessWidget {
  const CurioClay({
    required this.child,
    this.color,
    this.outline,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.pressed = false,
    super.key,
  });

  final Widget child;

  /// The body colour; see [clayFill]. Defaults to [clayBase].
  final Color? color;

  /// A ring just inside the edge, for selected or featured surfaces.
  final Color? outline;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return CustomPaint(
      painter: ClayPainter(
        color: clayFill(context, color),
        radius: radius,
        dark: Theme.of(context).brightness == Brightness.dark,
        pressed: pressed,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Container(
          padding: padding,
          foregroundDecoration: outline == null
              ? null
              : BoxDecoration(
                  borderRadius: shape,
                  border: Border.all(color: outline!, width: 2),
                ),
          child: child,
        ),
      ),
    );
  }
}

/// Paints clay into its box — for custom painters and decorations that
/// can't wrap a [CurioClay]. See [paintClay] for the parameters.
class ClayPainter extends CustomPainter {
  const ClayPainter({
    required this.color,
    required this.radius,
    required this.dark,
    this.pressed = false,
    this.fill = true,
    this.lift = true,
  });

  final Color? color;
  final double radius;
  final bool dark, pressed, fill, lift;

  @override
  void paint(Canvas canvas, Size size) {
    paintClay(
      canvas,
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(math.min(radius, size.shortestSide / 2)),
      ),
      color,
      dark: dark,
      pressed: pressed,
      fill: fill,
      lift: lift,
    );
  }

  @override
  bool shouldRepaint(ClayPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dark != dark ||
      old.pressed != pressed ||
      old.fill != fill ||
      old.lift != lift;
}

/// Makes a themed button clay. The button's own Material paints the body
/// and, through its elevation, the drop shadow (a button clips this layer,
/// so it can't paint one); this adds the inner shadows, swapped while the
/// button is held so it squishes in under the finger. Disabled buttons stay
/// flat. The shadows are neutral rather than tinted, since a button's colour
/// can be overridden per call and isn't known here.
ButtonLayerBuilder clayButtonLayer({
  required double radius,
  required bool dark,
}) {
  return (context, states, child) {
    if (states.contains(WidgetState.disabled)) return child!;
    return CustomPaint(
      painter: ClayPainter(
        color: null,
        radius: radius,
        dark: dark,
        pressed: states.contains(WidgetState.pressed),
        fill: false,
        lift: false,
      ),
      child: child,
    );
  };
}

/// Paints a clay body into [body], with [color] deciding the tint of its
/// shadows. Without [fill] the body itself isn't painted, only its shadows —
/// for art or a Material that paints its own background first. Without
/// [lift] there's no drop shadow. A null [color] gives neutral shadows.
void paintClay(
  Canvas canvas,
  RRect body,
  Color? color, {
  required bool dark,
  bool pressed = false,
  bool fill = true,
  bool lift = true,
}) {
  final depth = (body.outerRect.shortestSide * .07).clamp(2.0, 8.0);
  // HSL saturation runs to 100% on near-whites, so cap it or a cream card
  // would cast an orange shadow.
  final hsl = color == null ? null : HSLColor.fromColor(color);
  Color deeper(double by, double alpha) => hsl == null
      ? CurioColorsLight.ink.withValues(alpha: alpha * .45)
      : hsl
            .withSaturation(math.min(hsl.saturation, .55))
            .withLightness((hsl.lightness - by).clamp(0.0, 1.0))
            .toColor()
            .withValues(alpha: alpha);

  if (lift && !pressed) {
    // Only ever outside the body, so it can't tint a body painted beneath.
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(body.outerRect.inflate(depth * 8))
          ..addRRect(body),
      )
      ..drawRRect(
        body.shift(Offset(0, depth * 1.3)),
        Paint()
          ..color = dark ? Colors.black.withValues(alpha: .5) : deeper(.34, .32)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 1.7),
      )
      ..restore();
  }
  if (fill && color != null) canvas.drawRRect(body, Paint()..color = color);

  // On light mode's near-white bodies the highlight has to be strong to
  // show at all, but over vivid art that strength washes the colour out.
  final highlight = Colors.white.withValues(
    alpha: dark
        ? (pressed ? .05 : .11)
        : pressed
        ? .7
        : fill
        ? .9
        : .3,
  );
  final shade = dark
      ? Colors.black.withValues(alpha: pressed ? .45 : .32)
      : pressed
      ? deeper(.3, .75)
      : deeper(.16, .5);
  final lit = Offset(depth * .8, depth);
  _inset(canvas, body, pressed ? -lit : lit, depth * .9, highlight);
  _inset(canvas, body, pressed ? lit : -lit, depth * 1.1, shade);
}

/// An inner shadow: everything inside [body] that a copy of it shifted by
/// [offset] doesn't cover, blurred by [sigma].
void _inset(Canvas canvas, RRect body, Offset offset, double sigma, Color c) {
  canvas
    ..save()
    ..clipRRect(body)
    ..drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(body.outerRect.inflate(offset.distance + sigma * 3))
        ..addRRect(body.shift(offset)),
      Paint()
        ..color = c
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    )
    ..restore();
}
