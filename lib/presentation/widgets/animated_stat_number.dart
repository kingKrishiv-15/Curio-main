import 'package:flutter/material.dart';

/// Animates an integer stat (streak, XP, score) counting up from its
/// previous value to [value] whenever [value] changes, instead of snapping
/// instantly. Respects reduce-motion: jumps straight to the target value
/// with no tween when the OS setting is on.
class AnimatedStatNumber extends StatelessWidget {
  const AnimatedStatNumber({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Text('$prefix$value$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text('$prefix${animatedValue.round()}$suffix', style: style);
      },
    );
  }
}
