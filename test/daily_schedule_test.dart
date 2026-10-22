import 'package:curio/core/models/family_settings.dart';
import 'package:curio/core/services/guest_session.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/common/daily_game_session.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/common/game_rewards.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every date has exactly one game per section, including date boundaries',
    () {
      final start = DateTime(2025, 12, 1);
      for (var d = 0; d < 800; d++) {
        final date = DateTime(start.year, start.month, start.day + d);
        final picks = todaysPicks(date: date);
        expect(picks.length, 3);
        expect(picks.map((g) => g.section).toList(), LearningSection.values);
        expect(picks.map((g) => g.id).toSet().length, 3);
        expect(
          todaysPicks(date: DateTime(date.year, date.month, date.day, 23, 59)),
          picks,
        );
        final tomorrow = todaysPicks(
          date: DateTime(date.year, date.month, date.day + 1),
        );
        for (var i = 0; i < 3; i++) {
          expect(picks[i].id, isNot(tomorrow[i].id));
        }
      }
    },
  );

  test('every daily game rotates in and advances its own puzzle bank', () {
    final date = DateTime(2026, 10, 22);
    final seen = <String>{};
    for (final section in LearningSection.values) {
      final length = sectionRotation[section]!.length;
      for (var i = 0; i < length; i++) {
        final today = DateTime(date.year, date.month, date.day + i);
        final nextAppearance = DateTime(
          today.year,
          today.month,
          today.day + length,
        );
        final id = scheduledGameId(section, today);
        seen.add(id);
        expect(scheduledGameId(section, nextAppearance), id);
        expect(
          calendarDayNumber(puzzleDateForGame(id, nextAppearance)),
          calendarDayNumber(puzzleDateForGame(id, today)) + 1,
        );
      }
    }
    expect(seen, dailyGames.map((g) => g.id).toSet());
    expect(gameCatalog.map((g) => g.id).toSet().length, gameCatalog.length);
    for (final g in gameCatalog) {
      expect(g.section, isA<LearningSection>());
    }
  });

  test('fresh learners have no fabricated points, skills or streaks', () {
    final state = CurioState();
    expect(state.totalXp, 0);
    expect(state.streak, 0);
    expect(state.collectedFacts, isEmpty);
    expect(state.skills.values.every((v) => v == 0), isTrue);
    state.dispose();
  });

  test(
    'daily progress counts sections, restores from disk, and resets tomorrow',
    () async {
      SharedPreferences.setMockInitialValues({});
      var day = DateTime(2026, 10, 22);
      final store = LocalProgressStore();
      final state = CurioState(store: store, isGuest: true, now: () => day);
      await state.hydrate();
      void finish(String game) {
        final r = gameRewards[game]!;
        state.completeActivity(
          id: CurioState.dailyActivityId(game, day),
          xp: r.xp,
          skill: r.skill,
          factId: r.factId,
        );
      }

      for (final game in todaysPicks(date: day)) {
        finish(game.id);
      }
      final xp = state.totalXp;
      for (final game in todaysPicks(date: day)) {
        finish(game.id);
      }
      expect(state.totalXp, xp, reason: 'replays never earn twice');
      expect(state.dailyGoalCompleted, 3);
      expect(state.todayXp, xp);
      await state.flush();
      final restored = CurioState(store: store, isGuest: true, now: () => day);
      await restored.hydrate();
      expect(restored.totalXp, xp);
      expect(restored.dailyGoalCompleted, 3);
      day = DateTime(2026, 10, 23);
      expect(restored.dailyGoalCompleted, 0);
      expect(restored.todayXp, 0);
      expect(restored.totalXp, xp);
      state.dispose();
      restored.dispose();
    },
  );

  test('old five-game preferences are capped to the three available slots', () {
    expect(FamilySettings.fromJson({'daily_goal': 5}).dailyGoal, 3);
    final state = CurioState()..setDailyGoal(5);
    expect(state.dailyGoal, 3);
    state.setDailyGoal(0);
    expect(state.dailyGoal, 1);
    state.dispose();
  });

  testWidgets('a run opened before midnight is rewarded for its start date', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 22, 23, 59);
    final state = CurioState(now: () => DateTime(2026, 10, 23));
    await tester.pumpWidget(
      MaterialApp(
        home: CurioScope(
          notifier: state,
          child: DailyGameSession(
            gameId: 'memory_match',
            date: start,
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => awardDaily(context, 'memory_match'),
                child: const Text('finish'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('finish'));
    expect(state.completedActivities, {'memory_match_20261022'});
    expect(state.todayXp, 0);
    expect(state.totalXp, 80);
    await tester.tap(find.text('finish'));
    expect(state.totalXp, 80);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('an open app refreshes its daily plan at midnight', (
    tester,
  ) async {
    var day = DateTime(2026, 10, 22, 23, 59, 59);
    final state = CurioState(now: () => day);
    final before = todaysPicks(date: day).map((g) => g.id).join(',');
    await tester.pumpWidget(
      MaterialApp(
        home: CurioScope(
          notifier: state,
          child: Builder(
            builder: (context) => Text(
              todaysPicks(
                date: CurioScope.of(context).today,
              ).map((g) => g.id).join(','),
            ),
          ),
        ),
      ),
    );
    state.startDailyClock();
    day = DateTime(2026, 10, 23);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(before), findsNothing);
    expect(
      find.text(todaysPicks(date: day).map((g) => g.id).join(',')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
