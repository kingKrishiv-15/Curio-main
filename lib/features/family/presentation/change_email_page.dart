import 'dart:async';

import 'package:curio/theme/curio_tokens.dart';
import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../auth/presentation/auth_layout.dart';
import '../../auth/presentation/auth_messages.dart';
import '../../auth/presentation/widgets/auth_fields.dart';
import '../../auth/presentation/widgets/otp_code_field.dart';

enum _Step { enterEmail, newCode, currentCode, done }

/// Moves the family account to a new email, confirmed with codes.
///
/// Supabase emails a code to the new address and, with "Secure email
/// change" switched on, a second code to the current one. The account only
/// moves once every code is in, so a lost phone can't be used to hijack it.
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({this.authService, super.key});

  /// For tests; defaults to one backed by the initialised Supabase client.
  final AuthService? authService;

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  static final _codePattern = RegExp(r'^\d{6,10}$');
  late final AuthService _auth = widget.authService ?? AuthService();
  late final String _current = _auth.currentEmail ?? '';
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  _Step _step = _Step.enterEmail;
  Timer? _ticker;
  int _resendIn = 0;
  bool _busy = false;
  String? _error, _info;

  String get _newEmail => _email.text.trim();

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _ticker?.cancel();
    setState(() => _resendIn = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final wait = retryAfterSeconds(error);
      if (wait != null) _startCooldown(wait);
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    if (!_form.currentState!.validate()) return;
    if (_newEmail.toLowerCase() == _current.toLowerCase()) {
      setState(() => _error = 'That’s already your account email.');
      return;
    }
    await _run(() async {
      await _auth.requestEmailChange(_newEmail);
      if (!mounted) return;
      _code.clear();
      setState(() => _step = _Step.newCode);
      _startCooldown();
    });
  }

  Future<void> _verify([String? _]) async {
    final code = _code.text.trim();
    if (!_codePattern.hasMatch(code)) return;
    final toCurrent = _step == _Step.currentCode;
    await _run(() async {
      final done = await _auth.verifyEmailChange(
        email: toCurrent ? _current : _newEmail,
        code: code,
        newEmail: _newEmail,
      );
      if (!mounted) return;
      _code.clear();
      if (done) {
        _ticker?.cancel();
        setState(() => _step = _Step.done);
      } else if (!toCurrent) {
        setState(() {
          _step = _Step.currentCode;
          _info = 'New address confirmed. One more step.';
        });
      } else {
        setState(
          () => _error =
              'Both codes are in, but the change hasn’t finished yet. Please try again in a moment.',
        );
      }
    });
  }

  Future<void> _resend() => _run(() async {
    await _auth.resendEmailChange(_newEmail);
    if (!mounted) return;
    _code.clear();
    _info = 'New codes are on their way. Only the newest code will work.';
    _startCooldown();
  });

  @override
  Widget build(BuildContext context) {
    final muted = CurioTokens.textSecondary;
    final heading = Theme.of(context).textTheme.headlineMedium;
    final strong = TextStyle(
      color: CurioTokens.textPrimary,
      fontWeight: FontWeight.w800,
    );
    final children = switch (_step) {
      _Step.enterEmail => <Widget>[
        Text('Change your account email', style: heading),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(color: muted, height: 1.55),
            children: [
              const TextSpan(text: 'You sign in with '),
              TextSpan(text: _current, style: strong),
              const TextSpan(
                text:
                    '. We’ll email a code to your new address, and one to this address too, to make sure it’s really you.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: EmailField(
            key: const Key('change_email_input'),
            controller: _email,
            enabled: !_busy,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _request(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('change_email_send'),
          onPressed: _busy || _resendIn > 0 ? null : _request,
          child: _busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send codes'),
        ),
      ],
      _Step.newCode || _Step.currentCode => <Widget>[
        Text(
          _step == _Step.newCode
              ? 'Check your new inbox'
              : 'Now check your current inbox',
          style: heading,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(color: muted, height: 1.55),
            children: [
              const TextSpan(text: 'Enter the code we sent to '),
              TextSpan(
                text: _step == _Step.newCode ? _newEmail : _current,
                style: strong,
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        if (_info != null) ...[const SizedBox(height: 12), AuthNotice(_info!)],
        const SizedBox(height: 22),
        OtpCodeField(
          key: ValueKey(_step),
          controller: _code,
          length: SupabaseConfig.otpLength,
          hasError: _error != null,
          enabled: !_busy,
          onSubmitted: _verify,
        ),
        const SizedBox(height: 22),
        ListenableBuilder(
          listenable: _code,
          builder: (context, _) => FilledButton(
            key: const Key('change_email_verify'),
            onPressed: _busy || !_codePattern.hasMatch(_code.text.trim())
                ? null
                : _verify,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: _resendIn > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Didn’t get it? Send new codes in ${_resendIn ~/ 60}:${(_resendIn % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : TextButton.icon(
                  onPressed: _busy ? null : _resend,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Send new codes'),
                ),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _step = _Step.enterEmail;
                  _error = null;
                  _info = null;
                }),
          child: const Text('Use a different email'),
        ),
      ],
      _Step.done => <Widget>[
        Text('Email changed', style: heading),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(color: muted, height: 1.55),
            children: [
              const TextSpan(text: 'From now on, sign in with '),
              TextSpan(text: _newEmail, style: strong),
              const TextSpan(text: '. Weekly reports go there too.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    };
    return CurioPage(
      title: 'Account email',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ...children,
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthNotice(_error!, error: true),
          ],
        ],
      ),
    );
  }
}
