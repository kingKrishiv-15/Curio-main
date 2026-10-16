import 'dart:io';
import 'dart:math';

import 'package:curio/core/services/progress_store.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/widgets/parental_gate.dart';
import 'package:curio/features/discoveries/domain/discovery.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/common/game_rewards.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/signal_grid/domain/signal_grid.dart';
import 'package:curio/features/skills/presentation/skill_quest_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements ProgressStore {
  _MemoryStore(this.snapshot);
  ProgressSnapshot snapshot;
  @override
  Future<ProgressSnapshot> load() async => snapshot;
  @override
  Future<void> save(ProgressSnapshot value) async => snapshot = value;
}

String _day(DateTime d) => CurioState.dailyActivityId('x', d).substring(2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rewards', () {
    test('the client reward table matches the server migration exactly', () {
      // Every migration, in order, so later ones override earlier rows.
      final files =
          Directory('supabase/migrations')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.sql'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      final sql = files.map((f) => f.readAsStringSync()).join('\n');
      final rows = RegExp(
        r"\('([a-z_0-9]+)', (\d+), '([A-Za-z ]+)', '([a-z_]+)', (true|false)\)",
      ).allMatches(sql);
      final server = {
        for (final m in rows)
          m.group(1)!: (
            int.parse(m.group(2)!),
            m.group(3)!,
            m.group(4)!,
            m.group(5) == 'true',
          ),
      };
      expect(server.keys.toSet(), gameRewards.keys.toSet());
      for (final MapEntry(key: id, value: r) in gameRewards.entries) {
        expect(server[id], (r.xp, r.skill, r.factId, r.dated), reason: id);
      }
    });

    test('every reward has a catalog entry, a real skill and a real fact', () {
      final facts = discoveries.map((d) => d.id).toSet();
      for (final MapEntry(key: id, value: r) in gameRewards.entries) {
        expect(gameCatalog.map((g) => g.id), contains(id));
        expect(learningSkills, contains(r.skill));
        expect(facts, contains(r.factId), reason: id);
      }
      for (final fact in CurioState.streakDiscoveries.values) {
        expect(facts, contains(fact));
      }
      final earnable = {
        ...gameRewards.values.map((r) => r.factId),
        ...CurioState.streakDiscoveries.values,
      };
      expect(
        facts.difference(earnable),
        isEmpty,
        reason: 'every discovery can actually be unlocked',
      );
    });

    test('today’s picks rotate and lead with the featured game', () {
      final a = todaysPicks(date: DateTime(2026, 10, 8));
      final b = todaysPicks(date: DateTime(2026, 10, 9));
      expect(a.length, 5);
      expect(a.first, featuredGame(date: DateTime(2026, 10, 8)));
      expect(a.map((g) => g.id), isNot(b.map((g) => g.id)));
      expect(a.every((g) => g.isDaily), isTrue);
    });
  });

  group('Streaks', () {
    test(
      'load recomputes a lapsed streak instead of trusting the stored one',
      () async {
        final old = DateTime.now().subtract(const Duration(days: 10));
        final state = CurioState(
          store: _MemoryStore(
            ProgressSnapshot(
              childName: 'Ana',
              totalXp: 100,
              streak: 9, // stale
              completedActivities: {'squeeze_${_day(old)}'},
              collectedFacts: const {},
              skills: const {},
            ),
          ),
        );
        await state.hydrate();
        expect(state.streak, 0);
        state.dispose();
      },
    );

    test('longest streak and streak discoveries', () {
      final days = {
        for (final d in ['20261001', '20261002', '20261003', '20261005'])
          'squeeze_$d',
        'frostlands_night_1',
      };
      expect(CurioState.calculateLongestStreak(days), 3);

      final state = CurioState();
      state.completedActivities.clear();
      state.collectedFacts.clear();
      final now = DateTime.now();
      for (var i = 2; i >= 1; i--) {
        state.completedActivities.add(
          CurioState.dailyActivityId(
            'bridge',
            DateTime(now.year, now.month, now.day - i),
          ),
        );
      }
      state.completeActivity(
        id: CurioState.dailyActivityId('bridge'),
        xp: 80,
        skill: 'Number sense',
      );
      expect(state.streak, 3);
      expect(state.collectedFacts, contains('octopus_hearts'));
      expect(state.collectedFacts, isNot(contains('shortest_war')));
      state.dispose();
    });
  });

  group('Signal Grid', () {
    test('every board follows the rules', () {
      expect(SignalPuzzle.allBoards, isNotEmpty);
      for (final board in SignalPuzzle.allBoards) {
        expect(SignalPuzzle.violations(board), isEmpty);
      }
    });

    test('each daily puzzle has exactly one solution', () {
      for (var day = 0; day < 60; day++) {
        final p = SignalPuzzle.forDay(day);
        final fits = SignalPuzzle.allBoards.where(
          (b) => p.givens.every((i) => b[i] == p.solution[i]),
        );
        expect(fits.length, 1, reason: 'day $day');
        expect(p.givens.length, lessThan(16));
      }
    });

    test('a broken row is reported', () {
      final board = List<bool?>.of(SignalPuzzle.allBoards.first);
      board[0] = !board[0]!;
      expect(SignalPuzzle.violations(board), contains(0));
    });
  });

  test('Skill Quest recommends a game for the weakest skill', () {
    final state = CurioState()
      ..skills.addAll({
        'Number sense': .8,
        'Patterns': .6,
        'Evidence': .1,
        'Reasoning': .5,
      });
    final (skill, game) = SkillQuestPage.recommendation(state);
    expect(skill, 'Evidence');
    expect(game.skill, 'Evidence');
    expect(SkillQuestPage.levelFor(1), 5);
    expect(SkillQuestPage.levelFor(0), 1);
    state.dispose();
  });

  testWidgets('Parental gate lets the right answer through only', (
    tester,
  ) async {
    ParentalGate.reset();
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: CurioTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await ParentalGate.check(context, random: Random(1)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final question = find.textContaining('What is');
    final match = RegExp(
      r'(\d+) × (\d+)',
    ).firstMatch(tester.widget<Text>(question).data!)!;
    final answer = int.parse(match.group(1)!) * int.parse(match.group(2)!);
    await tester.tap(find.byKey(Key('gate_$answer')));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    // Recently passed: no second question.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('What is'), findsNothing);
    expect(result, isTrue);
    ParentalGate.reset();
  });

  test('DailyPick shifts backwards for practice without going negative', () {
    expect(DailyPick.index(10, shift: -25), inInclusiveRange(0, 9));
  });
}
