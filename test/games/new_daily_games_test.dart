import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/crowns/domain/crowns.dart';
import 'package:curio/features/games/crowns/domain/crowns_boards.dart';
import 'package:curio/features/games/crowns/presentation/crowns_page.dart';
import 'package:curio/features/games/memory_grid/domain/memory_grid.dart';
import 'package:curio/features/games/memory_grid/presentation/memory_grid_page.dart';
import 'package:curio/features/games/word_trails/domain/word_trails.dart';
import 'package:curio/features/games/word_trails/presentation/word_trails_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final day = DateTime(2026, 10, 27);

Widget play(
  Widget page,
  CurioState state, {
  bool dark = false,
  double text = 1,
}) => CurioScope(
  notifier: state,
  child: MaterialApp(
    theme: dark ? CurioTheme.dark : CurioTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(text)),
      child: child!,
    ),
    home: page,
  ),
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<CurioState> open(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  bool dark = false,
  double text = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = CurioState(now: () => day);
  addTearDown(state.dispose);
  await tester.pumpWidget(play(page, state, dark: dark, text: text));
  await tester.pumpAndSettle();
  return state;
}

int get today => DailyPick.dayNumber(day);

void main() {
  group('Crowns', () {
    test('every board, in every orientation, has exactly one solution', () {
      for (final board in crownsBoards) {
        for (final mirror in [false, true]) {
          for (var turns = 0; turns < 4; turns++) {
            final b = board.transformed(turns: turns, mirror: mirror);
            expect(solveCrowns(b), [b.solution]);
            for (var k = 0; k < b.size; k++) {
              expect(b.regions, contains(k));
            }
          }
        }
      }
    });

    test('a day brings a 5×5 then a 6×6, and they change daily', () {
      final boards = dailyCrowns(today);
      expect(boards.map((b) => b.size), [5, 6]);
      expect(dailyCrowns(today + 1).first.regions, isNot(boards.first.regions));
    });

    test('clashes are found and hints place a right crown', () {
      final game = CrownsGame(dailyCrowns(today).first);
      game.toggleCrown((0, 0));
      game.toggleCrown((1, 1));
      expect(game.conflicts, {(0, 0), (1, 1)});
      expect(game.blocked((0, 3)), isTrue);
      game.clear();
      while (game.hint() != null) {}
      expect(game.solved, isTrue);
    });

    testWidgets('solving both boards earns the reward', (tester) async {
      final state = await open(tester, CrownsPage(date: day));
      final boards = dailyCrowns(today);
      for (final (i, board) in boards.indexed) {
        for (var r = 0; r < board.size; r++) {
          await tap(
            tester,
            find.byKey(Key('crowns_${r}_${board.solution[r]}')),
          );
        }
        if (i < boards.length - 1) {
          await tap(tester, find.byKey(const Key('crowns_next')));
        }
      }
      expect(state.completedToday('crowns'), isTrue);
    });
  });

  group('Memory Grid', () {
    test('rounds get gradually harder and stay possible', () {
      for (var i = 1; i < gridRounds.length; i++) {
        expect(
          gridRounds[i].cells,
          greaterThanOrEqualTo(gridRounds[i - 1].cells),
        );
        expect(gridRounds[i].flash, lessThan(gridRounds[i - 1].flash));
        expect(
          gridRounds[i].cells,
          lessThan(gridRounds[i].size * gridRounds[i].size),
        );
      }
    });

    test('a wrong pattern costs a heart and three end the run', () {
      final grid = MemoryGrid(today);
      for (var miss = 0; miss < MemoryGrid.lives; miss++) {
        final wrong = [
          for (var i = 0; i < 9; i++)
            if (!grid.pattern.contains(i)) i,
        ];
        GridResult? result;
        for (final square in wrong.take(grid.settings.cells)) {
          result = grid.toggle(square);
        }
        expect(result, GridResult.missed);
        if (!grid.over) grid.advance(matched: false);
      }
      expect(grid.over, isTrue);
      expect(grid.won, isFalse);
    });

    testWidgets('remembering every pattern earns the reward', (tester) async {
      final state = await open(tester, MemoryGridPage(date: day));
      final grid = MemoryGrid(today);
      await tap(tester, find.byKey(const Key('grid_start')));
      for (var round = 0; round < gridRounds.length; round++) {
        await tester.pump(gridRounds[round].flash);
        await tester.pumpAndSettle();
        for (final square in grid.pattern.toList()) {
          await tap(tester, find.byKey(Key('grid_$square')));
          grid.toggle(square);
        }
        grid.advance(matched: true);
        if (round < gridRounds.length - 1) {
          await tap(tester, find.byKey(const Key('grid_next')));
        }
      }
      expect(state.completedToday('memory_grid'), isTrue);
    });
  });

  group('Word Trails', () {
    test('every story fits the board and every word is traceable', () {
      for (final story in trailStories) {
        final letters = story.words.fold(0, (n, w) => n + w.answer.length);
        expect(letters, lessThanOrEqualTo(WordTrail.size * WordTrail.size));
        expect(story.words.where((w) => w.key).length, 1, reason: story.title);
        expect(
          RegExp(r'\{\d+\}').allMatches(story.story).length,
          story.words.length,
        );
        final trail = WordTrail(story);
        for (final (w, path) in trail.paths.indexed) {
          for (var i = 1; i < path.length; i++) {
            expect(WordTrail.touching(path[i - 1], path[i]), isTrue);
          }
          expect(trail.wordFor(path.reversed.toList()), w);
          expect(trail.choicesFor(w).toSet().length, 3);
        }
      }
    });

    testWidgets('tracing every word and its meaning earns the reward', (
      tester,
    ) async {
      final state = await open(tester, WordTrailsPage(date: day));
      final trail = WordTrail.daily(today);
      for (final (w, path) in trail.paths.indexed) {
        for (final square in path) {
          await tap(tester, find.byKey(Key('trail_$square')));
        }
        final right = trail.choicesFor(w).indexOf(trail.story.words[w].meaning);
        await tap(tester, find.byKey(Key('trail_choice_$right')));
      }
      expect(state.completedToday('word_trails'), isTrue);
    });
  });

  for (final dark in [false, true]) {
    testWidgets('all three fit a small phone at large text, dark=$dark', (
      tester,
    ) async {
      for (final page in [
        CrownsPage(date: day),
        MemoryGridPage(date: day),
        WordTrailsPage(date: day),
      ]) {
        await open(
          tester,
          page,
          size: const Size(320, 640),
          dark: dark,
          text: 1.8,
        );
        expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
