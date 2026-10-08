import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'auth_messages.dart';
import 'widgets/otp_code_field.dart';
import 'widgets/welcome_art.dart';

/// Where a parent types the code Supabase emailed them. A correct code
/// creates a session; the [AuthGate] notices and moves on (to learner setup,
/// Home, or choosing a new password), so success needs no navigation here.
class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({
    required this.authService,
    required this.purpose,
    required this.email,
    this.notice,
    this.codeLength,
    super.key,
  });

  final AuthService authService;
  final CodePurpose purpose;
  final String email;

  /// Optional context shown above the boxes, e.g. why a code was re-sent.
  final String? notice;

  /// Defaults to [SupabaseConfig.otpLength].
  final int? codeLength;

  /// Supabase lets each address request one email per minute.
  static const resendCooldown = Duration(seconds: 60);

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _code = TextEditingController();
  Timer? _ticker;
  int _resendIn = VerifyCodePage.resendCooldown.inSeconds;
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _info;

  int get _length => widget.codeLength ?? SupabaseConfig.otpLength;

  @override
  void initState() {
    super.initState();
    _info = widget.notice;
    _startCooldown(VerifyCodePage.resendCooldown.inSeconds);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _ticker?.cancel();
    setState(() => _resendIn = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _verify([String? value]) async {
    final code = value ?? _code.text;
    if (_verifying || code.length != _length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.authService.verifyCode(
        widget.purpose,
        email: widget.email,
        code: code,
      );
    } catch (error) {
      if (!mounted) return;
      _code.clear();
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendIn > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.authService.sendCode(widget.purpose, widget.email);
      if (!mounted) return;
      _code.clear();
      setState(
        () =>
            _info = 'A new code is on its way. Only the newest code will work.',
      );
      _startCooldown(VerifyCodePage.resendCooldown.inSeconds);
    } catch (error) {
      if (!mounted) return;
      final wait = retryAfterSeconds(error);
      if (wait != null) {
        _startCooldown(wait);
      } else {
        setState(() => _error = authErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _title => switch (widget.purpose) {
    CodePurpose.signUp => 'Confirm your email',
    CodePurpose.signIn => 'Check your email',
    CodePurpose.recovery => 'Check your email',
  };

  String get _lead => switch (widget.purpose) {
    CodePurpose.signUp => 'Enter the $_length-digit code we sent to',
    CodePurpose.signIn => 'Enter the $_length-digit sign-in code we sent to',
    CodePurpose.recovery =>
      'If there’s a Curio account for this address, we’ve sent a $_length-digit code to',
  };

  String get _cta => switch (widget.purpose) {
    CodePurpose.signUp => 'Confirm and continue',
    CodePurpose.signIn => 'Sign in',
    CodePurpose.recovery => 'Continue',
  };

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final minutes = _resendIn ~/ 60;
    final seconds = (_resendIn % 60).toString().padLeft(2, '0');
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: InboxArt()),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              _title,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(height: 1.05),
            ),
          ),
          const SizedBox(height: 12),
          Text(_lead, style: TextStyle(color: muted, height: 1.55)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.email,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  height: 1.55,
                ),
              ),
              TextButton(
                onPressed: _verifying
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('Change'),
              ),
            ],
          ),
          if (_info != null) ...[
            const SizedBox(height: 10),
            AuthNotice(_info!),
          ],
          const SizedBox(height: 22),
          OtpCodeField(
            controller: _code,
            length: _length,
            hasError: _error != null,
            enabled: !_verifying,
            onCompleted: _verify,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            AuthNotice(_error!, error: true),
          ],
          const SizedBox(height: 22),
          ListenableBuilder(
            listenable: _code,
            builder: (context, _) => FilledButton(
              key: const Key('verify_submit'),
              onPressed: _verifying || _code.text.length != _length
                  ? null
                  : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_cta),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: _resendIn > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Didn’t get it? You can send a new code in $minutes:$seconds',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : TextButton.icon(
                    key: const Key('verify_resend'),
                    onPressed: _resending || _verifying ? null : _resend,
                    icon: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Send a new code'),
                  ),
          ),
          const SizedBox(height: 18),
          const _Tip(),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip();

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: curioColor(
          context,
          CurioColors.surfaceMuted,
          CurioColorsLight.surfaceMuted,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Emails can take a minute to arrive. Check your spam or promotions folder, and use the code from the newest email.',
              style: TextStyle(color: muted, fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
