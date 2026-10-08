import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/curio_colors.dart';
import '../theme/curio_colors_light.dart';

/// Curio's mark: a lowercase "c" drawn as one confident brush stroke — the
/// shape of a question still being asked — with a spark leaping from its
/// tip, the moment the answer arrives. The stroke starts fine and swells,
/// the way a thought gathers weight; the spark echoes the sparkle Nova
/// wears, so the logo and the mascot read as one family.
///
/// All geometry lives in a 1×1 unit square so the widget, the launcher icons
/// and the SVG exported by `tool/generate_brand_assets.dart` are drawn from
/// exactly the same numbers.
abstract final class CurioMarkGeometry {
  static const center = Offset(.465, .535);
  static const radius = .235;
  static const weight = .158;

  /// The "c" opens to the upper right, towards the spark.
  static const startAngle = 42 * math.pi / 180;
  static const sweep = 268 * math.pi / 180;

  static const sparkCenter = Offset(.735, .265);
  static const sparkRadius = .13;
  static const twinkleCenter = Offset(.845, .43);
  static const twinkleRadius = .032;

  static double _halfWidth(double t) {
    // A fine tail that swells to full weight over the first ~45% of the
    // stroke — calligraphic rather than mechanical.
    final eased = Curves.easeOutCubic.transform((t / .45).clamp(0, 1));
    return weight / 2 * (.28 + .72 * eased);
  }

  /// Outline of the tapered "c" as points, tail → head along the outer edge
  /// then back along the inner edge. Shared by [cPath] and the SVG writer.
  static ({List<Offset> outer, List<Offset> inner, double tail, double head})
  cOutline() {
    const steps = 120;
    final outer = <Offset>[];
    final inner = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngle + sweep * t;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final half = _halfWidth(t);
      outer.add(center + direction * (radius + half));
      inner.add(center + direction * (radius - half));
    }
    return (
      outer: outer,
      inner: inner,
      tail: _halfWidth(0),
      head: _halfWidth(1),
    );
  }

  static Path cPath(Rect box) {
    final shape = cOutline();
    Offset p(Offset unit) => box.topLeft + Offset(unit.dx, unit.dy) * box.width;
    final path = Path()
      ..moveTo(p(shape.outer.first).dx, p(shape.outer.first).dy);
    for (final point in shape.outer.skip(1)) {
      path.lineTo(p(point).dx, p(point).dy);
    }
    path.arcToPoint(
      p(shape.inner.last),
      radius: Radius.circular(shape.head * box.width),
    );
    for (final point in shape.inner.reversed.skip(1)) {
      path.lineTo(p(point).dx, p(point).dy);
    }
    path.arcToPoint(
      p(shape.outer.first),
      radius: Radius.circular(shape.tail * box.width),
    );
    return path..close();
  }

  /// A four-point sparkle with gently concave sides.
  static Path sparkPath(Offset center, double radius, {double pinch = .16}) {
    final k = radius * pinch;
    final c = center;
    return Path()
      ..moveTo(c.dx, c.dy - radius)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + radius, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + radius)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - radius, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - radius)
      ..close();
  }
}

/// The colours the mark is always drawn in. The mark keeps the same
/// evergreen tile in both modes — a logo that changes colour with the
/// theme stops being recognisable — so these live on both palettes with
/// identical values, per the "same field name on both classes" rule.
class CurioMarkColors {
  const CurioMarkColors({
    required this.tile,
    required this.glyph,
    required this.spark,
  });

  final Gradient tile;
  final Color glyph;
  final Color spark;

  static const brand = CurioMarkColors(
    tile: CurioColors.markGradient,
    glyph: CurioColors.markGlyph,
    spark: CurioColors.spark,
  );
}

/// Paints the mark into any square. Used by [CurioLogoMark] and by the
/// launcher-icon generator, so both stay pixel-identical.
class CurioMarkPainter extends CustomPainter {
  const CurioMarkPainter({
    this.colors = CurioMarkColors.brand,
    this.cornerRadius = .3,
    this.glyphScale = 1,
    this.drawTile = true,
  });

  final CurioMarkColors colors;

  /// Tile corner radius as a fraction of its side. 0 gives a full-bleed
  /// square (iOS masks icons itself).
  final double cornerRadius;

  /// Shrinks the glyph towards the centre, for icon safe zones.
  final double glyphScale;
  final bool drawTile;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final tile = Rect.fromLTWH(
      (size.width - side) / 2,
      (size.height - side) / 2,
      side,
      side,
    );
    if (drawTile) {
      final rrect = RRect.fromRectAndRadius(
        tile,
        Radius.circular(side * cornerRadius),
      );
      canvas.drawRRect(rrect, Paint()..shader = colors.tile.createShader(tile));
      // A soft top-left sheen, the same light direction as CurioGloss.
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawCircle(
        tile.topLeft + Offset(side * .18, side * .1),
        side * .72,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: .2),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: tile.topLeft + Offset(side * .18, side * .1),
                  radius: side * .72,
                ),
              ),
      );
      canvas.restore();
    }

    final glyphSide = side * glyphScale;
    final glyph = Rect.fromCenter(
      center: tile.center,
      width: glyphSide,
      height: glyphSide,
    );
    Offset unit(Offset u) => glyph.topLeft + u * glyphSide;

    // A whisper of shadow under the stroke gives it a little lift off the
    // tile without adding a second colour.
    final shadow = Paint()
      ..color = const Color(0xFF062A1F).withValues(alpha: .28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glyphSide * .012);
    canvas.drawPath(
      CurioMarkGeometry.cPath(glyph.shift(Offset(0, glyphSide * .014))),
      shadow,
    );
    canvas.drawPath(
      CurioMarkGeometry.cPath(glyph),
      Paint()..color = colors.glyph,
    );

    final sparkPaint = Paint()..color = colors.spark;
    canvas.drawPath(
      CurioMarkGeometry.sparkPath(
        unit(CurioMarkGeometry.sparkCenter),
        CurioMarkGeometry.sparkRadius * glyphSide,
      ),
      sparkPaint,
    );
    canvas.drawCircle(
      unit(CurioMarkGeometry.twinkleCenter),
      CurioMarkGeometry.twinkleRadius * glyphSide,
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(CurioMarkPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.glyphScale != glyphScale ||
      oldDelegate.drawTile != drawTile;
}

/// The square app mark on its evergreen tile.
class CurioLogoMark extends StatelessWidget {
  const CurioLogoMark({this.size = 34, this.shadow = true, super.key});

  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: shadow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(size * .3),
                boxShadow: [
                  BoxShadow(
                    color: (dark ? Colors.black : const Color(0xFF1F6B50))
                        .withValues(alpha: dark ? .34 : .22),
                    blurRadius: size * .38,
                    offset: Offset(0, size * .14),
                    spreadRadius: -size * .06,
                  ),
                ],
              )
            : null,
        child: CustomPaint(painter: const CurioMarkPainter()),
      ),
    );
  }
}

/// "curio" set in Fraunces, with the tittle of the i replaced by the same
/// spark the mark carries — so the wordmark works on its own, too.
class CurioWordmark extends StatelessWidget {
  const CurioWordmark({this.fontSize = 29, this.color, super.key});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink =
        color ??
        (Theme.of(context).brightness == Brightness.dark
            ? CurioColors.ink
            : CurioColorsLight.ink);
    final spark = Theme.of(context).brightness == Brightness.dark
        ? CurioColors.spark
        : CurioColorsLight.spark;
    final painter = _WordmarkPainter(
      fontSize: fontSize,
      ink: ink,
      spark: spark,
    );
    return ExcludeSemantics(
      child: CustomPaint(size: painter.measure(), painter: painter),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter({
    required this.fontSize,
    required this.ink,
    required this.spark,
  });

  final double fontSize;
  final Color ink;
  final Color spark;

  // "ı" (U+0131) is the dotless i — Fraunces ships it, so the spark can take
  // the dot's place instead of sitting on top of it.
  static const _text = 'curıo';

  late final TextPainter _text$ = TextPainter(
    text: TextSpan(
      text: _text,
      style: TextStyle(
        fontFamily: 'Fraunces',
        color: ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: -fontSize * .045,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout();

  // Room above the x-height so the spark never clips at small sizes.
  double get _headroom => fontSize * .06;

  Size measure() =>
      Size(_text$.width + fontSize * .04, _text$.height + _headroom);

  @override
  void paint(Canvas canvas, Size size) {
    _text$.paint(canvas, Offset(0, _headroom));
    final left = _text$.getOffsetForCaret(
      const TextPosition(offset: 3),
      Rect.zero,
    );
    final right = _text$.getOffsetForCaret(
      const TextPosition(offset: 4),
      Rect.zero,
    );
    final baseline = _text$.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final center = Offset(
      (left.dx + right.dx) / 2 + fontSize * .004,
      _headroom + baseline - fontSize * .655,
    );
    canvas.drawPath(
      CurioMarkGeometry.sparkPath(center, fontSize * .16, pinch: .15),
      Paint()..color = spark,
    );
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.fontSize != fontSize ||
      oldDelegate.ink != ink ||
      oldDelegate.spark != spark;
}

/// Mark + wordmark lockup.
class CurioLogo extends StatelessWidget {
  const CurioLogo({this.markSize = 34, this.vertical = false, super.key});

  final double markSize;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final mark = CurioLogoMark(size: markSize);
    final word = CurioWordmark(fontSize: markSize * (vertical ? .78 : .86));
    return Semantics(
      label: 'Curio',
      image: true,
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                SizedBox(height: markSize * .28),
                word,
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                SizedBox(width: markSize * .3),
                word,
              ],
            ),
    );
  }
}
