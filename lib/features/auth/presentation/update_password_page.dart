import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
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
    final inkColor = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final forestStrongColor = curioColor(
      context,
      CurioColors.forestStrong,
      CurioColorsLight.forestStrong,
    );
    return CurioPage(
      maxWidth: 460,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                MascotBadge(size: 56),
                SizedBox(width: 14),
                Expanded(child: CurioBrand()),
              ],
            ),
            const SizedBox(height: 36),
            const CurioEyebrow('Account recovery'),
            const SizedBox(height: 12),
            Text(
              'Choose a new password.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Use at least eight characters and avoid a password you use elsewhere.',
              style: TextStyle(
                color: curioColor(
                  context,
                  CurioColors.inkMuted,
                  CurioColorsLight.inkMuted,
                ),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            GlassCard(
              radius: CurioRadius.hero,
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _password,
                      style: TextStyle(
                        color: inkColor,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: forestStrongColor,
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
                      style: TextStyle(
                        color: inkColor,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: forestStrongColor,
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
                        style: TextStyle(
                          color: curioColor(
                            context,
                            CurioColors.coralStrong,
                            CurioColorsLight.coralStrong,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: curioColor(
                                  context,
                                  CurioColors.night,
                                  CurioColorsLight.night,
                                ),
                              ),
                            )
                          : const Text('Save new password'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
