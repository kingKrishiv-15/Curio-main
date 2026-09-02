import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';

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
  final _confirmPassword = TextEditingController();
  bool _creatingAccount = false;
  bool _loading = false;
  bool _hidePassword = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Something went wrong. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      if (_creatingAccount) {
        final response = await widget.authService.createAccount(
          email: _email.text,
          password: _password.text,
        );
        if (response.session == null && mounted) {
          setState(
            () => _message =
                'Check your email to confirm your account, then return to Curio.',
          );
        }
      } else {
        await widget.authService.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    await _run(() async {
      await widget.authService.sendPasswordReset(_email.text);
      if (mounted) setState(() => _message = 'Password reset email sent.');
    });
  }

  Future<void> _resendConfirmation() async {
    if (!_email.text.contains('@')) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    await _run(() async {
      await widget.authService.resendConfirmation(_email.text);
      if (mounted) {
        setState(() => _message = 'A new confirmation email is on its way.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      maxWidth: 460,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const MascotBadge(size: 56),
                const SizedBox(width: 14),
                const Expanded(child: CurioBrand()),
              ],
            ),
            const SizedBox(height: 36),
            const CurioEyebrow('Family sign in'),
            const SizedBox(height: 12),
            Text(
              _creatingAccount
                  ? 'Create your family account.'
                  : 'Welcome back, curious minds.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'A parent account keeps every child’s progress private and available across devices.',
              style: TextStyle(color: CurioColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: 26),
            GlassCard(
              radius: CurioRadius.hero,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (SupabaseConfig.enableGoogleAuth) ...[
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _run(widget.authService.signInWithGoogle),
                      child: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          style: const TextStyle(
                            color: CurioColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: CurioColors.forestStrong,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) =>
                              value != null && value.contains('@')
                              ? null
                              : 'Enter a valid email address.',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          style: const TextStyle(
                            color: CurioColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: CurioColors.forestStrong,
                          obscureText: _hidePassword,
                          autofillHints: [
                            _creatingAccount
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) >= 8
                              ? null
                              : 'Use at least 8 characters.',
                        ),
                        if (_creatingAccount) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPassword,
                            style: const TextStyle(
                              color: CurioColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: CurioColors.forestStrong,
                            obscureText: _hidePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                            validator: (value) => value == _password.text
                                ? null
                                : 'The passwords do not match.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: CurioColors.coralStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CurioColors.night,
                            ),
                          )
                        : Text(_creatingAccount ? 'Create account' : 'Sign in'),
                  ),
                  if (!_creatingAccount)
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  if (_creatingAccount)
                    TextButton(
                      onPressed: _loading ? null : _resendConfirmation,
                      child: const Text('Resend confirmation email'),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                            _creatingAccount = !_creatingAccount;
                            _message = null;
                          }),
                    child: Text(
                      _creatingAccount
                          ? 'Already have an account? Sign in'
                          : 'New to Curio? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
