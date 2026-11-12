import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/common/daily_schedule.dart';
import 'auth_layout.dart';
import 'auth_page.dart';

/// Shown once before sign-up: what a day in Curio is, in three rows.
class IntroPage extends StatelessWidget {
  const IntroPage({required this.authService, super.key});

  final AuthService authService;

  static const _seenKey = 'curio_intro_seen';

  static Future<bool> hasBeenSeen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey, true);
    } catch (_) {
      // The intro simply shows again when storage is unavailable.
    }
  }

  Future<void> _finish(BuildContext context, AuthMode mode) async {
    await _markSeen();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      authRoute(AuthPage(authService: authService, mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'A daily set of $dailyGameCount',
        'One game from each of $sectionNames. It takes about fifteen minutes.',
      ),
      (
        'Each game leaves something behind',
        'Finish one and the idea behind it is saved to Discover.',
      ),
      (
        'Parents see the same numbers',
        'Days played, games finished and which skills are moving.',
      ),
    ];
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'How a day in Curio works',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 24),
          for (final (title, body) in rows)
            CurioRow(title: title, subtitle: body),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('intro_next'),
            onPressed: () => _finish(context, AuthMode.signUp),
            child: const Text('Create a family account'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _finish(context, AuthMode.signIn),
            child: const Text('I already have an account'),
          ),
          const SizedBox(height: CurioTokens.s8),
        ],
      ),
    );
  }
}
