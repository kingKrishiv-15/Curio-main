import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.updatePassword(_password.text);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update the password. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CurioColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CurioBrand(),
                    const SizedBox(height: 42),
                    const CurioEyebrow('Account recovery'),
                    const SizedBox(height: 12),
                    Text(
                      'Choose a new password.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Use at least eight characters and avoid a password you use elsewhere.',
                      style: TextStyle(
                        color: CurioColors.inkMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _password,
                      style: const TextStyle(
                        color: CurioColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: CurioColors.forestStrong,
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) >= 8
                          ? null
                          : 'Use at least 8 characters.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmation,
                      style: const TextStyle(
                        color: CurioColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: CurioColors.forestStrong,
                      obscureText: _hidden,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                      validator: (value) => value == _password.text
                          ? null
                          : 'The passwords do not match.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: CurioColors.coralStrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CurioColors.onDark,
                              ),
                            )
                          : const Text('Save new password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
