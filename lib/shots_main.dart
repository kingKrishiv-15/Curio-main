// TEMPORARY: store screenshot driver. Delete after use.
import 'dart:async';

import 'package:flutter/material.dart';

import 'core/state/curio_state.dart';
import 'core/theme/curio_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/discoveries/presentation/discoveries_page.dart';
import 'features/games/common/game_rewards.dart';
import 'features/games/game_catalog.dart';
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
  runApp(_Shots(state: state));
}

class _Shots extends StatefulWidget {
  const _Shots({required this.state});
  final CurioState state;
  @override
  State<_Shots> createState() => _ShotsState();
}

class _ShotsState extends State<_Shots> {
  final _theme = ThemeController();
  int _i = 0;
  late final List<Widget Function()> _screens = [
    () => const MainShell(),
    () => gameCatalog.firstWhere((g) => g.id == 'crowns').open(),
    () => gameCatalog.firstWhere((g) => g.id == 'frostlands_night_1').open(),
    () => gameCatalog.firstWhere((g) => g.id == 'sequence').open(),
    () => const SkillQuestPage(),
    () => const Scaffold(body: DiscoveriesPage()),
    () => const ParentDashboardPage(),
    () => const Scaffold(body: ProfilePage()),
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
    return CurioThemeScope(
      controller: _theme,
      child: CurioScope(
        notifier: widget.state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: CurioTheme.light,
          home: KeyedSubtree(key: ValueKey(_i), child: _screens[_i]()),
        ),
      ),
    );
  }
}
