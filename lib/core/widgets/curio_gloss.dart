import 'dart:ui';
import 'package:flutter/material.dart';

/// Curio's take on Roots' layered glass: tinted body, inset highlight,
/// restrained reflection and a soft floating shadow.
class CurioGloss extends StatelessWidget {
  const CurioGloss({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
    this.tint,
    this.borderColor,
    this.blur = false,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Color? borderColor;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = tint == null
        ? (dark
              ? Theme.of(context).colorScheme.surface
              : const Color(0xFFF1EADD))
        : Color.alphaBlend(tint!, Theme.of(context).colorScheme.surface);
    final border = BorderRadius.circular(radius);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              base,
              Colors.white,
              tint != null ? .08 : (dark ? .16 : .8),
            )!.withValues(alpha: blur ? (dark ? .62 : .68) : .94),
            base.withValues(
              alpha: blur ? (dark ? .38 : .40) : (dark ? .78 : .82),
            ),
            Color.lerp(
              base,
              dark ? Colors.black : Colors.white,
              .12,
            )!.withValues(alpha: blur ? (dark ? .54 : .56) : .90),
          ],
          stops: const [0, .6, 1],
        ),
        border: Border.all(
          color:
              borderColor ?? Colors.white.withValues(alpha: dark ? .16 : .55),
          width: 1.2,
        ),
      ),
      child: CustomPaint(
        foregroundPainter: _GlassEdge(radius, dark),
        child: Padding(padding: padding, child: child),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .22 : .07),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? .06 : .3),
            blurRadius: 1,
            offset: const Offset(-.5, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border,
        child: blur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: surface,
              )
            : surface,
      ),
    );
  }
}

class _GlassEdge extends CustomPainter {
  const _GlassEdge(this.radius, this.dark);
  final double radius;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(3),
        Radius.circular((radius - 3).clamp(0, 999)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? .38 : .9),
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassEdge oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.dark != dark;
}
