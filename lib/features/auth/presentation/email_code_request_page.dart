import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'auth_messages.dart';
import 'verify_code_page.dart';
import 'widgets/auth_fields.dart';

/// Asks for an email, then sends a 6-digit code — to reset a forgotten
/// password ([CodePurpose.recovery]) or to sign in without one
/// ([CodePurpose.signIn]).
class EmailCodeRequestPage extends StatefulWidget {
  const EmailCodeRequestPage({
    required this.authService,
    required this.purpose,
    this.initialEmail = '',
    super.key,
  }) : assert(purpose != CodePurpose.signUp);

  final AuthService authService;
  final CodePurpose purpose;
  final String initialEmail;

  @override
  State<EmailCodeRequestPage> createState() => _EmailCodeRequestPageState();
}

class _EmailCodeRequestPageState extends State<EmailCodeRequestPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  String? _error;

  bool get _recovery => widget.purpose == CodePurpose.recovery;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.sendCode(widget.purpose, _email.text);
      if (!mounted) return;
      await Navigator.of(context).push(
        authRoute(
          VerifyCodePage(
            authService: widget.authService,
            purpose: widget.purpose,
            email: _email.text.trim(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
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
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurioEyebrow(_recovery ? 'Password help' : 'No password needed'),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                _recovery ? 'Forgot your password?' : 'Sign in with a code',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(height: 1.05),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _recovery
                  ? 'It happens. Enter your account email and we’ll send a 6-digit code so you can choose a new one.'
                  : 'Enter your account email and we’ll send a 6-digit code that signs you straight in.',
              style: TextStyle(color: muted, height: 1.55),
            ),
            const SizedBox(height: 26),
            EmailField(
              controller: _email,
              enabled: !_loading,
              autofocus: widget.initialEmail.isEmpty,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthNotice(_error!, error: true),
            ],
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('code_request_send'),
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_recovery ? 'Send reset code' : 'Email me a code'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).maybePop(),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
