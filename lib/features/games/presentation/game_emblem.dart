import 'package:flutter/material.dart';

import '../../../theme/curio_tokens.dart';

/// A game's symbol in its section tint: flat, no tile, no gloss.
class GameEmblem extends StatelessWidget {
  const GameEmblem({
    required this.icon,
    required this.color,
    this.size = 100,
    this.tilt = 0,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size, tilt;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CurioTokens.wash(color),
          borderRadius: CurioTokens.cardShape,
        ),
        child: Icon(icon, color: color, size: size * .5),
      ),
    ),
  );
}
