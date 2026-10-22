import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/curio_colors.dart';
import '../theme/curio_colors_light.dart';

/// Curio's mark: a "C" for Curio, with a magnifying lens resting on its
/// tip — the curious look-closer that every game asks for. Drawn flat and
/// calm: an even, round-capped mint stroke, a gold lens ring with a short
/// handle reaching into the C's opening, and a clean gap where the C passes
/// behind the lens, so it reads as depth without gloss or shadows.
///
/// All geometry lives in a 1×1 unit square so the widget, the launcher icons
/// and the SVG exported by `tool/generate_brand_assets.dart` are drawn from
/// exactly the same numbers.
abstract final class CurioMarkGeometry {
  // The "C": one even stroke opening to the right.
  static const center = Offset(.452, .52);
  static const radius = .25;
  static const weight = .122;

  /// From the lower tip, clockwise round the left, to the upper tip (which
  /// slips behind the lens).
  static const startAngle = 38 * math.pi / 180;
  static const sweep = 274 * math.pi / 180;

  // The lens: a ring over the C's upper tip, handle angled down-right.
  static const lensCenter = Offset(.667, .295);
  static const lensRadius = .1;
  static const lensWeight = .048;
  static const handleAngle = 45 * math.pi / 180;
  static const handleLength = .12;
  static const handleWeight = .054;

  /// Clear space between the lens ring and the C where they cross.
  static const gap = .028;

  static Offset _onC(double angle, double r) =>
      center + Offset(math.cos(angle), math.sin(angle)) * r;

  /// Outline of the "C" as points, lower tip → upper tip along the outer
  /// edge, then back along the inner edge. Shared by [cPath] and the SVG
  /// writer.
  static ({List<Offset> outer, List<Offset> inner, double cap}) cOutline() {
    const steps = 120;
    return (
      outer: [
        for (var i = 0; i <= steps; i++)
          _onC(startAngle + sweep * i / steps, radius + weight / 2),
      ],
      inner: [
        for (var i = 0; i <= steps; i++)
          _onC(startAngle + sweep * i / steps, radius - weight / 2),
      ],
      cap: weight / 2,
    );
  }

  /// The "C" in [box], round caps included, before the lens cuts into it.
  static Path cPath(Rect box) {
    final shape = cOutline();
    Offset p(Offset unit) => box.topLeft + unit * box.width;
    final cap = Radius.circular(shape.cap * box.width);
    final path = Path()
      ..moveTo(p(shape.outer.first).dx, p(shape.outer.first).dy);
    for (final point in shape.outer.skip(1)) {
      path.lineTo(p(point).dx, p(point).dy);
    }
    path.arcToPoint(p(shape.inner.last), radius: cap);
    for (final point in shape.inner.reversed.skip(1)) {
      path.lineTo(p(point).dx, p(point).dy);
    }
    path.arcToPoint(p(shape.outer.first), radius: cap);
    return path..close();
  }

  /// The circle cut out of the "C" around the lens.
  static double get cutRadius => lensRadius + lensWeight / 2 + gap;

  /// Where the handle starts (the ring's outer edge) and ends.
  static Offset get handleStart =>
      lensCenter +
      Offset(math.cos(handleAngle), math.sin(handleAngle)) *
          (lensRadius + lensWeight / 2);
  static Offset get handleEnd =>
      lensCenter +
      Offset(math.cos(handleAngle), math.sin(handleAngle)) *
          (lensRadius + lensWeight / 2 + handleLength);

  /// A four-point sparkle with gently concave sides — Nova's sparkle, used
  /// by the mascot and the landing art.
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

  /// The "C".
  final Color glyph;

  /// The lens.
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, Radius.circular(side * cornerRadius)),
        Paint()..shader = colors.tile.createShader(tile),
      );
    }

    final s = side * glyphScale;
    final glyph = Rect.fromCenter(center: tile.center, width: s, height: s);
    Offset unit(Offset u) => glyph.topLeft + u * s;
    final lens = unit(CurioMarkGeometry.lensCenter);

    // The "C", with a clean circle cut where it passes behind the lens.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        CurioMarkGeometry.cPath(glyph),
        Path()..addOval(
          Rect.fromCircle(
            center: lens,
            radius: CurioMarkGeometry.cutRadius * s,
          ),
        ),
      ),
      Paint()..color = colors.glyph,
    );

    // The lens: a hint of clear glass, the ring, a small glint, the handle.
    canvas.drawCircle(
      lens,
      CurioMarkGeometry.lensRadius * s,
      Paint()..color = Colors.white.withValues(alpha: .08),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.spark
      ..strokeWidth = CurioMarkGeometry.lensWeight * s;
    canvas.drawCircle(lens, CurioMarkGeometry.lensRadius * s, ring);
    canvas.drawArc(
      Rect.fromCircle(
        center: lens,
        radius: CurioMarkGeometry.lensRadius * s * .55,
      ),
      200 * math.pi / 180,
      62 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = CurioMarkGeometry.lensWeight * s * .42
        ..color = Colors.white.withValues(alpha: .6),
    );
    canvas.drawLine(
      unit(CurioMarkGeometry.handleStart),
      unit(CurioMarkGeometry.handleEnd),
      Paint()
        ..color = colors.spark
        ..strokeCap = StrokeCap.round
        ..strokeWidth = CurioMarkGeometry.handleWeight * s,
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
                        .withValues(alpha: dark ? .34 : .14),
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

/// "curio" set in Fraunces, with the dot of the i in the mark's gold — so
/// the wordmark works on its own, too.
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

  // "ı" (U+0131) is the dotless i — Fraunces ships it, so the gold dot can
  // take the dot's place instead of sitting on top of it.
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

  // Room above the x-height so the dot never clips at small sizes.
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
    canvas.drawCircle(center, fontSize * .085, Paint()..color = spark);
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
