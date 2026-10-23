import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../navigation/open_page.dart';
import '../services/auth_service.dart';

/// Parent areas require the current account's password on every entry.
/// No arithmetic challenge or cached unlock can bypass verification.
abstract final class ParentalGate {
  static Future<bool> check(
    BuildContext context, {
    AuthService? authService,
  }) async {
    final auth =
        authService ?? (SupabaseConfig.isConfigured ? AuthService() : null);
    if (auth?.currentSession == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Parent access'),
          content: const Text(
            'Sign in to your family account to open parent reports and settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (_) => _PasswordDialog(auth: auth!),
        ) ==
        true;
  }

  static Future<void> open(
    BuildContext context,
    Widget page, {
    AuthService? authService,
  }) async {
    if (await check(context, authService: authService) && context.mounted) {
      await openPage(context, page);
    }
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.auth});
  final AuthService auth;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  late final String _parentId;
  bool _busy = false, _hidden = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parentId = widget.auth.currentSession!.user.id;
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your account password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.verifyParentPassword(_password.text);
      if (!mounted) return;
      if (widget.auth.currentSession?.user.id != _parentId) {
        throw const AuthException('The signed-in account changed.');
      }
      _password.clear();
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            error is AuthException && error.code == 'invalid_credentials'
            ? 'That password didn’t match. Please try again.'
            : error is AuthException && error.statusCode == '429'
            ? 'Too many attempts. Please wait before trying again.'
            : 'We couldn’t verify your password. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      scrollable: true,
      title: const Text('Parent access'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your account password to open parent reports and family settings.',
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('parent_password'),
            controller: _password,
            enabled: !_busy,
            autofocus: true,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: 'Account password',
              errorText: _error,
              errorMaxLines: 4,
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: _busy
                    ? null
                    : () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Need a new password? Use “Forgot password?” on the sign-in screen.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('parent_unlock'),
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unlock'),
        ),
      ],
    ),
  );
}
