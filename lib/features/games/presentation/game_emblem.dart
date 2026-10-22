import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A little sculpted toy for each game. Built from vectors so it stays sharp
/// on a small phone, a tablet and the launcher-sized welcome illustrations.
/// The game's own symbol and colour carry its identity across every shelf.
class GameEmblem extends StatelessWidget {
  const GameEmblem({
    required this.icon,
    required this.color,
    this.size = 100,
    this.tilt = -.12,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size, tilt;

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(color, Colors.black, .48)!;
    final pale = Color.lerp(color, Colors.white, .86)!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: FittedBox(
          child: SizedBox.square(
            dimension: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 106,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: deep.withValues(alpha: .35),
                          blurRadius: 19,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: tilt + .28,
                  child: Transform.translate(
                    offset: const Offset(5, 7),
                    child: _plate(
                      LinearGradient(colors: [pale, color]),
                      Border.all(color: Colors.white.withValues(alpha: .4)),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: tilt,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: _plate(LinearGradient(colors: [deep, color])),
                      ),
                      _plate(
                        LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            pale,
                            Color.lerp(color, Colors.white, .58)!,
                          ],
                          stops: const [0, .58, 1],
                        ),
                        Border.all(
                          color: Colors.white.withValues(alpha: .9),
                          width: 1.5,
                        ),
                      ),
                      // The icon has a solid side wall, a shaded face and a
                      // soft contact shadow, like a moulded puzzle piece.
                      for (var depth = 6; depth > 0; depth--)
                        Transform.translate(
                          offset: Offset(1, depth.toDouble() - 1),
                          child: Icon(icon, size: 73, color: deep),
                        ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(color, Colors.white, .3)!,
                            color,
                            deep,
                          ],
                        ).createShader(rect),
                        child: Icon(icon, size: 73, color: Colors.white),
                      ),
                      Positioned(
                        top: 25,
                        left: 32,
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _plate(Gradient gradient, [Border? border]) => Container(
    width: 110,
    height: 110,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(29),
      gradient: gradient,
      border: border,
    ),
  );
}
