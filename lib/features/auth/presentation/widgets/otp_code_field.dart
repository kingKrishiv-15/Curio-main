import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';

/// A row of digit boxes backed by one real, invisible text field — so
/// paste, iOS one-time-code autofill, hardware keyboards and screen
/// readers all behave exactly like a normal input.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.controller,
    required this.length,
    this.onSubmitted,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
    super.key,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    // Put the caret back after a wrong code clears the boxes.
    if (oldWidget.enabled != widget.enabled && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final length = code.length > widget.length
        ? code.length.clamp(6, 10)
        : widget.length.clamp(6, 10);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = length > 6 ? 4.0 : 8.0;
        final box = ((constraints.maxWidth - gap * (length - 1)) / length)
            .clamp(0.0, 56.0);
        final height = (box * 1.3).clamp(48.0, 65.0);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      _DigitBox(
                        key: ValueKey('otp_digit_$i'),
                        width: box,
                        height: height,
                        digit: i < code.length ? code[i] : null,
                        active:
                            _focus.hasFocus &&
                            widget.enabled &&
                            (i == code.length ||
                                (code.length == length && i == length - 1)),
                        hasError: widget.hasError,
                        enabled: widget.enabled,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    key: const Key('otp_input'),
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    expands: true,
                    maxLines: null,
                    showCursor: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      counterText: '',
                      labelText: 'Verification code, 6 to 10 digits',
                    ),
                    onSubmitted: (value) {
                      if (value.length >= 6 && value.length <= 10) {
                        widget.onSubmitted?.call(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.width,
    required this.height,
    required this.digit,
    required this.active,
    required this.hasError,
    required this.enabled,
    super.key,
  });

  final double width, height;
  final String? digit;
  final bool active, hasError, enabled;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final border = hasError
        ? danger
        : active
        ? coral
        : digit != null
        ? ink.withValues(alpha: .32)
        : outline;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? surface : surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(width * .28),
        border: Border.all(color: border, width: active || hasError ? 2 : 1.3),
        boxShadow: active
            ? [
                BoxShadow(
                  color: coral.withValues(alpha: .22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: digit != null
          ? Text(
              digit!,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: (width * .6).clamp(14.0, 28.0),
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            )
          : active
          ? _Caret(color: coral, height: height * .4)
          : null,
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret({required this.color, required this.height});
  final Color color;
  final double height;
  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoop(_blink, context, reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: 2,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return bar;
    return FadeTransition(opacity: _blink, child: bar);
  }
}
