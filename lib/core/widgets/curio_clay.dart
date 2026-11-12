import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/curio_tokens.dart';

/// The default panel body.
Color clayBase(BuildContext context) => CurioTokens.surface;

/// [color] as an opaque panel body: as-is when opaque, otherwise washed
/// onto [clayBase].
Color clayFill(BuildContext context, Color? color) {
  if (color == null) return CurioTokens.surface;
  if (color.a >= 1) return color;
  return Color.alphaBlend(color, CurioTokens.surface);
}

/// Curio's flat panel: one fill, one 1px border, no shadow. Pass
/// [raised] for the single primary element a screen is allowed to lift.
/// (The name is kept from the earlier clay look so call sites stay put.)
class CurioClay extends StatelessWidget {
  const CurioClay({
    required this.child,
    this.color,
    this.outline,
    this.radius = CurioTokens.radiusCard,
    this.padding = EdgeInsets.zero,
    this.pressed = false,
    this.raised = false,
    super.key,
  });

  final Widget child;
  final Color? color;

  /// Replaces the hairline border, for selected or featured panels.
  final Color? outline;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool pressed;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final shape = radius >= 40 ? CurioTokens.pillShape : CurioTokens.cardShape;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pressed ? CurioTokens.base : clayFill(context, color),
        borderRadius: shape,
        border: Border.all(
          color: outline ?? CurioTokens.border,
          width: outline == null ? 1 : 2,
        ),
        boxShadow: raised ? CurioTokens.shadowRaised : CurioTokens.shadowNone,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Paints a flat panel into its box, for custom painters.
class ClayPainter extends CustomPainter {
  const ClayPainter({
    required this.color,
    required this.radius,
    this.dark = true,
    this.pressed = false,
    this.fill = true,
    this.lift = true,
  });

  final Color? color;
  final double radius;
  final bool dark, pressed, fill, lift;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(radius, size.shortestSide / 2);
    paintClay(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, Radius.elliptical(r, r)),
      color,
      pressed: pressed,
      fill: fill,
    );
  }

  @override
  bool shouldRepaint(ClayPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.pressed != pressed ||
      old.fill != fill;
}

/// Fills [shape] flat with [color] and strokes a hairline around it.
void paintClay(
  Canvas canvas,
  RRect shape,
  Color? color, {
  bool dark = true,
  bool pressed = false,
  bool fill = true,
  bool lift = true,
}) {
  if (fill) {
    canvas.drawRRect(
      shape,
      Paint()
        ..color = pressed ? CurioTokens.base : (color ?? CurioTokens.surface),
    );
  }
  if (pressed) {
    canvas.drawRRect(
      shape.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = CurioTokens.border,
    );
  }
}
