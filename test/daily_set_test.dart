import 'dart:async';
import 'dart:io';

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the server rotation in get_daily_set matches the client rotation', () {
    final sql = File(
      'supabase/migrations/202611210001_expand_daily_rotation.sql',
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
    expect(
      set.others.map((g) => g.id),
      todaysPicks(date: state.today).map((g) => g.id),
    );
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

  testWidgets('a signed-in app expires its old lineup at UTC midnight', (
    tester,
  ) async {
    var deviceTime = DateTime.utc(2026, 11, 20, 5);
    final serverDate = DateTime.utc(2026, 11, 13);
    final nextDay = DateTime.utc(2026, 11, 14);
    final nextRefresh = Completer<void>();
    var requests = 0;
    final state = CurioState(
      now: () => deviceTime,
      fetchDailySet: () async {
        if (++requests == 1) {
          return (
            date: serverDate,
            serverTime: serverDate.add(
              const Duration(hours: 23, minutes: 59, seconds: 59),
            ),
            games: dailyGameIds(serverDate, serverIds: [anchorGameId]),
          );
        }
        await nextRefresh.future;
        return (
          date: nextDay,
          serverTime: nextDay.add(const Duration(seconds: 1)),
          games: dailyGameIds(nextDay, serverIds: [anchorGameId]),
        );
      },
    );
    await state.refreshDailySet();
    state.startDailyClock();
    expect(state.todayGameIds.first, anchorGameId);

    deviceTime = deviceTime.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(requests, 2);
    expect(state.dailySetIds, isNull);
    expect(state.todayGameIds, dailyGameIds(nextDay));
    expect(state.todayGameIds.first, isNot(anchorGameId));

    nextRefresh.complete();
    await tester.pump();
    expect(
      state.todayGameIds,
      dailyGameIds(nextDay, serverIds: [anchorGameId]),
    );
    expect(state.today.isUtc, isTrue);
    state.dispose();
  });

  test('resuming the app refreshes the server plan', () async {
    var requests = 0;
    final day = DateTime.utc(2026, 11, 14, 10);
    final state = CurioState(
      fetchDailySet: () async {
        requests++;
        return (date: day, serverTime: day, games: dailyGameIds(day));
      },
    );
    addTearDown(state.dispose);
    state.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await state.refreshDailySet();
    expect(requests, 1);
    expect(state.todayGameIds, dailyGameIds(day));
  });
}
