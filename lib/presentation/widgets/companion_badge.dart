import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The child's ongoing companion (a dragon, currently only met properly in
/// the Frostlands story world) shown here as a compact icon-scale badge for
/// the Home dashboard's "companion stage" indicator.
///
/// Restyled deliberately away from a plush-toy look: an angular, sharp-edged
/// silhouette with a single glowing eye rather than big soft cartoon
/// features - meant to read as "something a 12-13 year old thinks looks
/// cool," not younger-skewing cute. The full Frostlands scene later gets a
/// more detailed version of this same silhouette language (see the sprint
/// brief's request for two dragon visual directions) - this badge is the
/// compact, everywhere-else version of that same character.
class CompanionBadge extends StatelessWidget {
  const CompanionBadge({
    super.key,
    required this.stage,
    this.maxStage = 5,
    this.size = 96,
    this.silhouetteColor = const Color(0xFF15121F),
    this.glowColor = const Color(0xFF7C3AED),
  });

  final int stage;
  final int maxStage;
  final double size;
  final Color silhouetteColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompanionPainter(
          progress: (stage / maxStage).clamp(0, 1),
          silhouetteColor: silhouetteColor,
          glowColor: glowColor,
        ),
      ),
    );
  }
}

class _CompanionPainter extends CustomPainter {
  _CompanionPainter({required this.progress, required this.silhouetteColor, required this.glowColor});

  final double progress;
  final Color silhouetteColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Stage progress ring
    final ringRect = Rect.fromCircle(center: center, radius: radius - 4);
    final trackPaint = Paint()
      ..color = silhouetteColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, 0, 2 * math.pi, false, trackPaint);

    final progressPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);

    // Dragon head silhouette, scaled to fit inside the ring.
    final scale = size.width / 120;
    canvas.save();
    canvas.translate(center.dx - 60 * scale, center.dy - 50 * scale);
    canvas.scale(scale);

    final headPath = Path()
      ..moveTo(10, 55)
      ..lineTo(25, 30)
      ..lineTo(30, 8)
      ..lineTo(38, 32)
      ..lineTo(44, 15)
      ..lineTo(50, 34)
      ..lineTo(65, 28)
      ..lineTo(95, 32)
      ..lineTo(112, 42)
      ..lineTo(100, 50)
      ..lineTo(78, 48)
      ..lineTo(75, 55)
      ..lineTo(55, 62)
      ..lineTo(35, 68)
      ..lineTo(20, 72)
      ..lineTo(8, 68)
      ..close();

    canvas.drawPath(headPath, Paint()..color = silhouetteColor);

    // Glowing eye.
    const eyeCenter = Offset(72, 40);
    canvas.drawCircle(
      eyeCenter,
      9,
      Paint()
        ..color = glowColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(eyeCenter, 3.2, Paint()..color = glowColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompanionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.silhouetteColor != silhouetteColor ||
        oldDelegate.glowColor != glowColor;
  }
}
