import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fades and slides a child in once, staggered by [delay] — the public
/// sibling of Home's `_FadeSlideIn`, for screens outside Home.
class CurioFadeSlideIn extends StatefulWidget {
  const CurioFadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<CurioFadeSlideIn> createState() => _CurioFadeSlideInState();
}

class _CurioFadeSlideInState extends State<CurioFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _start = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// A slow, endless bob — for illustration pieces that should feel alive
/// without asking for attention.
class CurioFloat extends StatefulWidget {
  const CurioFloat({
    required this.child,
    this.distance = 6,
    this.period = const Duration(milliseconds: 3600),
    this.phase = 0,
    super.key,
  });

  final Widget child;
  final double distance;
  final Duration period;

  /// 0–1, so several floating pieces don't move in lockstep.
  final double phase;

  @override
  State<CurioFloat> createState() => _CurioFloatState();
}

class _CurioFloatState extends State<CurioFloat>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoop(_controller, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = (_controller.value + widget.phase) * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * widget.distance),
          child: child,
        );
      },
    );
  }
}

/// Runs [controller] on a loop only while the platform (or Curio's own
/// Accessibility setting) allows motion — a stopped ticker also saves the
/// battery for people who asked for less movement.
void syncLoop(
  AnimationController controller,
  BuildContext context, {
  bool reverse = false,
}) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.stop();
  } else if (!controller.isAnimating) {
    controller.repeat(reverse: reverse);
  }
}
