import 'package:flutter/material.dart';

/// A gentle, continuous vertical float + slight rotation - used to make the
/// companion illustration feel alive on Home rather than a static image.
/// When the OS "reduce motion" setting is on, the controller is never
/// started at all (not just visually skipped) - a permanently-repeating
/// ticker running in the background regardless of the setting would still
/// cost battery/CPU, and would hang `tester.pumpAndSettle()` in widget
/// tests, which waits for every active animation to finish.
class IdleFloat extends StatefulWidget {
  const IdleFloat({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.period = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final double amplitude;
  final Duration period;

  @override
  State<IdleFloat> createState() => _IdleFloatState();
}

class _IdleFloatState extends State<IdleFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final dy = -widget.amplitude * t;
        final angle = (t - 0.5) * 0.03; // a couple degrees of gentle sway
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: widget.child,
    );
  }
}
