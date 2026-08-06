import 'package:flutter/material.dart';

/// Wraps [child] with genuine press feedback (scale + opacity dip) instead
/// of relying on Material's default ripple - every tappable element in
/// Curio uses this. Respects the OS "reduce motion" setting: when enabled,
/// the scale/opacity animation is skipped and only the tap itself fires,
/// so the element still feels responsive without the motion.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scale = _pressed && !reduceMotion ? widget.pressedScale : 1.0;
    final opacity = _pressed ? 0.88 : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
