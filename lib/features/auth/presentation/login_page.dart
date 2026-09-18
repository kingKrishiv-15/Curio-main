import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import 'auth_layout.dart';

enum _AuthView { signIn, signUp, reset, confirm }

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authService, super.key});
  final AuthService authService;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  _AuthView _view = _AuthView.signIn;
  bool _loading = false;
  bool _hidden = true;
  bool _error = false;
  String? _message;
  bool get _signup => _view == _AuthView.signUp;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _switch(_AuthView view) {
    setState(() {
      _view = view;
      _message = null;
      _error = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
      _error = false;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'We couldn’t connect. Please try again.';
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _run(() async {
      if (_view == _AuthView.reset) {
        await widget.authService.sendPasswordReset(_email.text);
        if (mounted) {
          setState(
            () => _message =
                'If an account exists for this email, a reset link is on its way. Check your inbox and spam folder.',
          );
        }
      } else if (_signup) {
        final response = await widget.authService.createAccount(
          email: _email.text,
          password: _password.text,
        );
        TextInput.finishAutofillContext();
        if (response.session == null && mounted) {
          setState(() => _view = _AuthView.confirm);
        }
      } else {
        await widget.authService.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
        TextInput.finishAutofillContext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirm = _view == _AuthView.confirm;
    final reset = _view == _AuthView.reset;
    final title = confirm
        ? 'Check your inbox.'
        : reset
        ? 'Let’s get you back in.'
        : _signup
        ? 'A curious start.'
        : 'Welcome back.';
    final subtitle = confirm
        ? 'We sent a confirmation link to ${_email.text.trim()}. Open it to continue to your learner setup.'
        : reset
        ? 'Enter your account email and we’ll send you a password reset link.'
        : _signup
        ? 'Create a parent account. Then we’ll get your young explorer ready.'
        : 'A new little discovery is waiting for you.';
    return AuthLayout(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!confirm && !reset) ...[
              SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                segments: const [
                  ButtonSegment(value: false, label: Text('Sign in')),
                  ButtonSegment(value: true, label: Text('Create account')),
                ],
                selected: {_signup},
                showSelectedIcon: false,
                onSelectionChanged: _loading
                    ? null
                    : (value) => _switch(
                        value.first ? _AuthView.signUp : _AuthView.signIn,
                      ),
              ),
              const SizedBox(height: 28),
            ],
            if (confirm) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.mark_email_read_outlined, size: 42),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(height: 1.1),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            if (!confirm)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: reset
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Parent’s email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter a valid email address.',
                      onFieldSubmitted: reset ? (_) => _submit() : null,
                    ),
                    if (!reset) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _password,
                        enabled: !_loading,
                        obscureText: _hidden,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          _signup
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: _signup
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: _signup ? 'At least 8 characters' : null,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _hidden
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(() => _hidden = !_hidden),
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => (v ?? '').isEmpty
                            ? 'Enter your password.'
                            : _signup && v!.length < 8
                            ? 'Use at least 8 characters.'
                            : null,
                        onFieldSubmitted: _signup ? null : (_) => _submit(),
                      ),
                      if (_signup) ...[
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _confirmation,
                          enabled: !_loading,
                          obscureText: _hidden,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                          ),
                          validator: (v) => v == _password.text
                              ? null
                              : 'The passwords don’t match.',
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ] else
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switch(_AuthView.reset),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              AuthNotice(_message!, error: _error),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _loading
                  ? null
                  : confirm
                  ? () => _run(() async {
                      await widget.authService.resendConfirmation(_email.text);
                      if (mounted) {
                        setState(
                          () => _message =
                              'A fresh confirmation link is on its way.',
                        );
                      }
                    })
                  : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        confirm
                            ? 'Resend confirmation email'
                            : reset
                            ? 'Send reset link'
                            : _signup
                            ? 'Create my account'
                            : 'Sign in',
                      ),
                    ),
            ),
            if (confirm || reset)
              TextButton(
                onPressed: _loading ? null : () => _switch(_AuthView.signIn),
                child: const Text('Back to sign in'),
              ),
            if (!confirm && !reset && SupabaseConfig.enableGoogleAuth) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _run(widget.authService.signInWithGoogle),
                child: const Text('Continue with Google'),
              ),
            ],
            if (!confirm && !reset) ...[
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For parents and guardians. One account to keep your learner’s progress together.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
