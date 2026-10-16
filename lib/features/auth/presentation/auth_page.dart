import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'auth_messages.dart';
import 'email_code_request_page.dart';
import 'guest_sheet.dart';
import 'verify_code_page.dart';
import 'widgets/auth_fields.dart';

enum AuthMode { signIn, signUp }

/// Email + password sign-in and sign-up. Creating an account emails a
/// 6-digit code ([VerifyCodePage]); the [AuthGate] takes over the moment
/// Supabase reports a session, so this page never navigates "forward" on
/// success itself.
class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.authService,
    this.mode = AuthMode.signIn,
    super.key,
  });

  final AuthService authService;
  final AuthMode mode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Replaced (not reset) when switching modes: FormState.reset() would also
  // wipe the email the parent already typed.
  var _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late AuthMode _mode = widget.mode;
  bool _consent = false;
  bool _consentMissing = false;
  bool _loading = false;
  String? _message;
  bool _messageIsError = true;

  bool get _signUp => _mode == AuthMode.signUp;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode, {String? message, bool error = true}) {
    setState(() {
      _mode = mode;
      _message = message;
      _messageIsError = error;
      _consentMissing = false;
      _password.clear();
      _form = GlobalKey<FormState>();
    });
  }

  Future<void> _openVerify(CodePurpose purpose, {String? notice}) =>
      Navigator.of(context).push(
        authRoute(
          VerifyCodePage(
            authService: widget.authService,
            purpose: purpose,
            email: _email.text.trim(),
            notice: notice,
          ),
        ),
      );

  Future<void> _submit() async {
    if (_loading) return;
    final valid = _form.currentState!.validate();
    if (_signUp && !_consent) setState(() => _consentMissing = true);
    if (!valid || (_signUp && !_consent)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (_signUp) {
        final outcome = await widget.authService.createAccount(
          email: _email.text,
          password: _password.text,
        );
        TextInput.finishAutofillContext();
        if (!mounted) return;
        switch (outcome) {
          case SignUpOutcome.codeSent:
            await _openVerify(CodePurpose.signUp);
          case SignUpOutcome.alreadyRegistered:
            _switchMode(
              AuthMode.signIn,
              message:
                  'There’s already a Curio account for ${_email.text.trim()}. Sign in below — or reset your password if you’ve forgotten it.',
              error: false,
            );
          case SignUpOutcome.signedIn:
            break; // The gate moves on by itself.
        }
      } else {
        await widget.authService.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
        TextInput.finishAutofillContext();
      }
    } catch (error) {
      if (!mounted) return;
      if (isEmailNotConfirmed(error)) {
        // They signed up but never entered the code. Send a fresh one and
        // take them straight to it rather than showing a dead end.
        String? notice =
            'Your email isn’t confirmed yet, so we’ve sent a fresh code.';
        try {
          await widget.authService.sendCode(CodePurpose.signUp, _email.text);
        } catch (_) {
          notice =
              'Your email isn’t confirmed yet. Enter the code from our last email, or send a new one.';
        }
        if (mounted) await _openVerify(CodePurpose.signUp, notice: notice);
      } else {
        setState(() {
          _message = authErrorMessage(error);
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestCode(CodePurpose purpose) => Navigator.of(context).push(
    authRoute(
      EmailCodeRequestPage(
        authService: widget.authService,
        purpose: purpose,
        initialEmail: _email.text.trim(),
      ),
    ),
  );

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await widget.authService.signInWithGoogle();
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return AuthFrame(
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurioEyebrow(
                _signUp ? 'For parents & guardians' : 'Welcome back',
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  _signUp
                      ? 'Create your family account'
                      : 'Good to see you again.',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(height: 1.05),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _signUp
                    ? 'We’ll email you a 6-digit code to confirm it’s you, then you’ll set up your explorer. About a minute in all.'
                    : 'Sign in to pick up right where your explorer left off.',
                style: TextStyle(color: muted, height: 1.55),
              ),
              const SizedBox(height: 26),
              EmailField(controller: _email, enabled: !_loading),
              const SizedBox(height: 16),
              PasswordField(
                key: ValueKey(_mode),
                controller: _password,
                label: _signUp ? 'Create a password' : 'Password',
                isNew: _signUp,
                enabled: !_loading,
                onSubmitted: (_) => _submit(),
              ),
              if (!_signUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => _requestCode(CodePurpose.recovery),
                    child: const Text('Forgot password?'),
                  ),
                ),
              if (_signUp) ...[
                const SizedBox(height: 18),
                _ConsentRow(
                  value: _consent,
                  missing: _consentMissing,
                  enabled: !_loading,
                  onChanged: (v) => setState(() {
                    _consent = v;
                    if (v) _consentMissing = false;
                  }),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                AuthNotice(_message!, error: _messageIsError),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('auth_submit'),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_signUp ? 'Create account' : 'Sign in'),
              ),
              if (!_signUp) ...[
                const SizedBox(height: 18),
                const _OrDivider(),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _requestCode(CodePurpose.signIn),
                  icon: const Icon(Icons.pin_outlined, size: 20),
                  label: const Text('Email me a sign-in code'),
                ),
                if (SupabaseConfig.enableGoogleAuth) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _google,
                    icon: const Icon(Icons.account_circle_outlined, size: 20),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _signUp ? 'Already have an account?' : 'New to Curio?',
                    style: TextStyle(color: muted),
                  ),
                  TextButton(
                    key: const Key('auth_switch_mode'),
                    onPressed: _loading
                        ? null
                        : () => _switchMode(
                            _signUp ? AuthMode.signIn : AuthMode.signUp,
                          ),
                    child: Text(_signUp ? 'Sign in' : 'Create an account'),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  key: const Key('auth_guest'),
                  onPressed: _loading ? null : () => showGuestSheet(context),
                  child: const Text('Continue as guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatefulWidget {
  const _ConsentRow({
    required this.value,
    required this.missing,
    required this.enabled,
    required this.onChanged,
  });

  final bool value, missing, enabled;
  final ValueChanged<bool> onChanged;

  @override
  State<_ConsentRow> createState() => _ConsentRowState();
}

class _ConsentRowState extends State<_ConsentRow> {
  late final _link = TapGestureRecognizer()
    ..onTap = () => showPrivacySummary(context);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: const Key('auth_consent'),
              value: widget.value,
              isError: widget.missing,
              onChanged: widget.enabled
                  ? (v) => widget.onChanged(v ?? false)
                  : null,
              semanticLabel:
                  'I’m a parent or guardian and I agree to how Curio looks after my family’s data',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: ink, height: 1.45, fontSize: 13.5),
                    children: [
                      const TextSpan(
                        text:
                            'I’m a parent or guardian, and I agree to how Curio looks after my family’s data. ',
                      ),
                      TextSpan(
                        text: 'What we keep',
                        style: TextStyle(
                          color: coral,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: coral,
                        ),
                        recognizer: _link,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.missing)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 2),
            child: Text(
              'Please confirm you’re a parent or guardian to continue.',
              style: TextStyle(
                color: danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or', style: Theme.of(context).textTheme.bodySmall),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
