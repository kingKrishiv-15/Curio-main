import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../navigation/open_page.dart';
import '../services/auth_service.dart';
import 'parent_code_dialog.dart';

/// Parent areas need a fresh one-time code, emailed to the signed-in
/// parent, on every entry (or the account password, for accounts that have
/// one). No arithmetic challenge or cached unlock can bypass verification.
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
    final parentId = auth!.currentSession!.user.id;
    void sameParent() {
      if (auth.currentSession?.user.id != parentId) {
        throw const AuthException('The signed-in account changed.');
      }
    }

    return showParentCodeDialog(
      context,
      auth: auth,
      title: 'Parent access',
      message:
          'To open parent reports and family settings, confirm it’s you with a code from your email.',
      confirmLabel: 'Unlock',
      confirmKey: const Key('parent_unlock'),
      onCode: (code) async {
        await auth.verifyParentCode(code);
        sameParent();
      },
      onPassword: (password) async {
        await auth.verifyParentPassword(password);
        sameParent();
      },
    );
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
