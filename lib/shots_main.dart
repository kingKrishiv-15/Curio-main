// TEMPORARY: screenshot driver for design review and store screenshots.
// Not part of the app; delete before release.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/auth_service.dart';
import 'core/state/curio_state.dart';
import 'core/theme/curio_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/about_curio_page.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/auth/presentation/intro_page.dart';
import 'features/auth/presentation/verify_code_page.dart';
import 'features/auth/presentation/landing_page.dart';
import 'features/auth/presentation/onboarding_page.dart';
import 'features/discoveries/presentation/discoveries_page.dart';
import 'features/family/presentation/accessibility_page.dart';
import 'features/family/presentation/change_email_page.dart';
import 'features/family/presentation/family_inbox_page.dart';
import 'features/family/presentation/family_settings_page.dart';
import 'features/family/presentation/privacy_page.dart';
import 'features/family/presentation/help_page.dart';
import 'features/games/common/game_rewards.dart';
import 'features/games/game_catalog.dart';
import 'features/games/presentation/today_games.dart';
import 'features/parent/presentation/parent_dashboard_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/skills/presentation/skill_quest_page.dart';

const step = Duration(seconds: 9);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = CurioState()..childName = 'Aarav';
  final now = DateTime.now();
  final ids = gameCatalog.map((g) => g.id).toList();
  void done(String id, DateTime day) {
    final r = gameRewards[id]!;
    state.completeActivity(
      id: CurioState.dailyActivityId(id, day),
      xp: r.xp,
      skill: r.skill,
      factId: r.factId,
    );
  }

  for (var d = 9; d >= 1; d--) {
    for (var k = 0; k < 3; k++) {
      done(
        ids[(d * 3 + k) % ids.length],
        DateTime(now.year, now.month, now.day - d),
      );
    }
  }
  for (final id in state.todayGameIds.take(2)) {
    done(id, now);
  }
  runApp(_Shots(state: state));
}

final _auth = AuthService(
  client: SupabaseClient('https://example.supabase.co', 'preview'),
);

class _Shots extends StatefulWidget {
  const _Shots({required this.state});
  final CurioState state;
  @override
  State<_Shots> createState() => _ShotsState();
}

class _ShotsState extends State<_Shots> {
  final _theme = ThemeController();
  int _i = 0;

  /// (pushed, page): pushed pages get a back button, as in the app.
  late final List<(bool, Widget Function())> _screens = [
    (false, () => const MainShell()),
    (false, () => const TodayGamesPage()),
    (false, () => const DiscoveriesPage()),
    (false, () => const ProfilePage()),
    (true, () => const SkillQuestPage()),
    (true, () => const ParentDashboardPage()),
    (true, () => const FamilySettingsPage()),
    (true, () => const HelpPage()),
    (true, () => gameById('sequence').open()),
    (true, () => gameById('crowns').open()),
    (false, () => LandingPage(authService: _auth)),
    (true, () => AuthPage(authService: _auth)),
    (false, () => OnboardingPage(authService: _auth, onComplete: () {})),
    (true, () => const AccessibilityPage()),
    (true, () => const PrivacyPage()),
    (true, () => const FamilyInboxPage()),
    (true, () => ChangeEmailPage(authService: _auth)),
    (false, () => IntroPage(authService: _auth)),
    (
      true,
      () => VerifyCodePage(
        authService: _auth,
        purpose: CodePurpose.signIn,
        email: 'parent@example.com',
      ),
    ),
    (true, () => const AboutCurioPage()),
    (true, () => gameById('frostlands_night_1').open()),
    (true, () => gameById('odd_cluster').open()),
    (true, () => gameById('word_trails').open()),
    (true, () => gameById('evidence_garden').open()),
    (true, () => gameById('bridge').open()),
    (true, () => gameById('number_hunt').open()),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('SHOT 0');
    Timer.periodic(step, (t) {
      if (_i + 1 >= _screens.length) return t.cancel();
      setState(() => _i++);
      debugPrint('SHOT $_i');
    });
  }

  @override
  Widget build(BuildContext context) {
    final (pushed, page) = _screens[_i];
    return KeyedSubtree(
      key: ValueKey(_i),
      child: CurioThemeScope(
        controller: _theme,
        child: CurioScope(
          notifier: widget.state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: CurioTheme.light,
            home: pushed ? _Pusher(page: page) : page(),
          ),
        ),
      ),
    );
  }
}

/// Opens [page] on top of a blank route so it shows its back button.
class _Pusher extends StatefulWidget {
  const _Pusher({required this.page});
  final Widget Function() page;
  @override
  State<_Pusher> createState() => _PusherState();
}

class _PusherState extends State<_Pusher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => widget.page(),
          transitionDuration: Duration.zero,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
