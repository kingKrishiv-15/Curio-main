import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'auth_messages.dart';
import 'widgets/auth_fields.dart';

/// Shown by the [AuthGate] after a password-reset code (or link) checks out.
/// The parent is already signed in at this point; this just makes the new
/// password stick before they carry on.
class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({
    required this.authService,
    required this.onDone,
    super.key,
  });

  final AuthService authService;
  final VoidCallback onDone;

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.updatePassword(_password.text);
      TextInput.finishAutofillContext();
      if (mounted) widget.onDone();
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
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CurioEyebrow('Almost there'),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  'Choose a new password',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(height: 1.05),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your code checked out. Pick something memorable — you’ll use it next time you sign in.',
                style: TextStyle(color: muted, height: 1.55),
              ),
              const SizedBox(height: 26),
              PasswordField(
                controller: _password,
                label: 'New password',
                isNew: true,
                enabled: !_loading,
                onSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthNotice(_error!, error: true),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('update_password_save'),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save and continue'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : widget.authService.signOut,
                child: const Text('Cancel and sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
