import 'dart:io';

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the server rotation in get_daily_set matches the client rotation', () {
    final sql = File(
      'supabase/migrations/202611130002_daily_set.sql',
    ).readAsStringSync();
    List<String> pool(String name) {
      const open = 'text[] := array[';
      final start = sql.indexOf('v_$name $open') + 'v_$name $open'.length;
      final list = sql.substring(start, sql.indexOf(']', start));
      return [
        for (final item in list.split(',')) item.trim().replaceAll("'", ''),
      ];
    }

    for (final section in LearningSection.values) {
      expect(
        pool(section.name),
        sectionRotation[section],
        reason: section.name,
      );
    }
    expect(sql.contains("'$anchorGameId'"), isTrue);
    expect(sql.contains("date '2026-01-01'"), isTrue, reason: 'same day zero');
    expect(calendarDayNumber(DateTime(2026)), 0);
  });

  test('the server date wins over the device clock', () {
    final state = CurioState(now: () => DateTime(2026, 11, 20, 9, 30));
    expect(state.today.day, 20);
    state.adoptDailySet(
      serverDate: DateTime(2026, 11, 13),
      games: ['second_opinion', 'bridge', 'crowns', 'verdict'],
    );
    expect(
      (state.today.year, state.today.month, state.today.day),
      (2026, 11, 13),
    );
    final set = todaysSet(date: state.today, ids: state.dailySetIds);
    expect(set.anchor.id, 'second_opinion');
    expect(set.others.map((g) => g.id), ['bridge', 'crowns', 'verdict']);
    state.dispose();
  });

  test('an unknown game from the server falls back to the device rotation', () {
    final date = DateTime(2026, 11, 13);
    final set = todaysSet(date: date, ids: ['second_opinion', 'not_a_game']);
    expect(
      set.others.map((g) => g.id),
      todaysPicks(date: date).map((g) => g.id),
    );
  });
}
