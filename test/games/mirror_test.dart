import 'dart:math';

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/widgets/curio_ui.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/mirror/domain/mirror.dart';
import 'package:curio/features/games/mirror/presentation/mirror_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final day = DateTime(2026, 10, 8);

Future<void> phone(
  WidgetTester tester, [
  Size size = const Size(390, 844),
]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

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

/// Scrolls the page's list (which only builds what's near the screen) until
/// [finder] exists, then taps it.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    try {
      await tester.scrollUntilVisible(finder, 250, scrollable: list);
    } catch (_) {
      await tester.scrollUntilVisible(finder, -250, scrollable: list);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const n = MirrorPuzzle.boardSize;
int rowOf(int cell) => cell ~/ n;
int colOf(int cell) => cell % n;
int at(int row, int col) => row * n + col;

List<MirrorPuzzle> today() =>
    mirrorPuzzles(mirrorSeed(DailyPick.dayNumber(day)));

List<int> wrongSquares(MirrorPuzzle p) =>
    p.paintSide.where((c) => !p.target.contains(c)).toList();

/// Paints [puzzle]'s answer and checks it.
Future<void> solve(WidgetTester tester, MirrorPuzzle puzzle) async {
  for (final cell in puzzle.target) {
    await tap(tester, find.byKey(Key('mirror_cell_$cell')));
  }
  await tap(tester, find.byKey(const Key('mirror_check')));
  await reveal(tester, find.textContaining('Perfect reflection'));
  expect(find.textContaining('Perfect reflection'), findsOneWidget);
}

Future<void> playAll(WidgetTester tester, List<MirrorPuzzle> puzzles) async {
  for (var i = 0; i < puzzles.length; i++) {
    await solve(tester, puzzles[i]);
    if (i < puzzles.length - 1) {
      await tap(tester, find.byKey(const Key('mirror_next')));
    }
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Mirror reflection', () {
    test('reflecting twice brings every square home', () {
      for (final size in [4, 6, 8]) {
        for (final axis in MirrorAxis.values) {
          for (var cell = 0; cell < size * size; cell++) {
            final once = reflectCell(cell, axis, size: size);
            expect(once, inInclusiveRange(0, size * size - 1));
            expect(
              reflectCell(once, axis, size: size),
              cell,
              reason: '$axis on $size×$size, square $cell',
            );
          }
        }
      }
    });

    test('each mirror flips the way you would draw it', () {
      expect(reflectCell(at(0, 0), MirrorAxis.vertical), at(0, 5));
      expect(reflectCell(at(3, 2), MirrorAxis.vertical), at(3, 3));
      expect(reflectCell(at(0, 4), MirrorAxis.horizontal), at(5, 4));
      expect(reflectCell(at(2, 1), MirrorAxis.horizontal), at(3, 1));
      expect(reflectCell(at(1, 4), MirrorAxis.diagonal), at(4, 1));
      expect(reflectCell(at(0, 5), MirrorAxis.diagonal), at(5, 0));
      expect(reflectCell(at(3, 3), MirrorAxis.diagonal), at(3, 3));
    });

    test('the mirror swaps the sides; only diagonal squares stay put', () {
      for (final axis in MirrorAxis.values) {
        final pattern = [
          for (var c = 0; c < n * n; c++)
            if (onPatternSide(c, axis)) c,
        ];
        final paint = [
          for (var c = 0; c < n * n; c++)
            if (!onPatternSide(c, axis)) c,
        ];
        final diagonal = axis == MirrorAxis.diagonal;
        expect(pattern.length, diagonal ? 21 : 18);
        expect(paint.length, diagonal ? 15 : 18);
        for (final cell in paint) {
          expect(onMirrorLine(cell, axis), isFalse);
          expect(onPatternSide(reflectCell(cell, axis), axis), isTrue);
        }
        for (final cell in pattern) {
          final image = reflectCell(cell, axis);
          if (onMirrorLine(cell, axis)) {
            expect(image, cell);
          } else {
            expect(onPatternSide(image, axis), isFalse, reason: '$axis $cell');
          }
        }
      }
      expect(
        [
          for (var c = 0; c < n * n; c++)
            if (onMirrorLine(c, MirrorAxis.diagonal)) c,
        ],
        [0, 7, 14, 21, 28, 35],
      );
      // On an even board a straight mirror runs between squares.
      for (var c = 0; c < n * n; c++) {
        expect(onMirrorLine(c, MirrorAxis.vertical), isFalse);
        expect(onMirrorLine(c, MirrorAxis.horizontal), isFalse);
      }
    });

    test('every answer square mirrors a pattern square, for any pattern', () {
      final random = Random(42);
      for (var i = 0; i < 300; i++) {
        for (final axis in MirrorAxis.values) {
          final side = [
            for (var c = 0; c < n * n; c++)
              if (onPatternSide(c, axis)) c,
          ]..shuffle(random);
          final given = side.take(random.nextInt(side.length + 1)).toSet();
          final puzzle = MirrorPuzzle(axis: axis, given: given);
          for (final cell in puzzle.target) {
            expect(puzzle.isLocked(cell), isFalse);
            expect(given, contains(reflectCell(cell, axis)));
          }
          expect(
            puzzle.target.length,
            given.where((c) => !onMirrorLine(c, axis)).length,
          );
        }
      }
    });
  });

  group('Mirror generator', () {
    const seeds = 400;
    final puzzles = {
      for (final axis in MirrorAxis.values)
        axis: [
          for (var seed = 0; seed < seeds; seed++)
            MirrorPuzzle.generate(Random(seed), axis),
        ],
    };

    test('$seeds seeds: 30–50% filled, at least 5 squares, answers on the '
        'paint side', () {
      for (final MapEntry(key: axis, value: list) in puzzles.entries) {
        for (final (seed, p) in list.indexed) {
          final reason = '$axis seed $seed';
          expect(p.axis, axis);
          expect(p.size, MirrorPuzzle.boardSize);
          expect(
            p.given.length / p.patternSide.length,
            inInclusiveRange(.3, .5),
            reason: reason,
          );
          expect(p.given.length, greaterThanOrEqualTo(5), reason: reason);
          expect(p.target.length, greaterThanOrEqualTo(5), reason: reason);
          expect(
            p.given.every((c) => onPatternSide(c, axis)),
            isTrue,
            reason: reason,
          );
          expect(
            p.target.every((c) => !onPatternSide(c, axis)),
            isTrue,
            reason: reason,
          );
          expect(p.target.every(p.paintSide.contains), isTrue, reason: reason);
          for (final cell in p.target) {
            expect(p.given, contains(reflectCell(cell, axis)), reason: reason);
          }
          for (final cell in p.given) {
            if (onMirrorLine(cell, axis)) continue;
            expect(p.target, contains(reflectCell(cell, axis)), reason: reason);
          }
          expect(p.isWorthSolving, isTrue, reason: reason);
        }
      }
    });

    test('the same seed always makes the same puzzles', () {
      for (var seed = 0; seed < seeds; seed++) {
        for (final axis in MirrorAxis.values) {
          final again = MirrorPuzzle.generate(Random(seed), axis);
          expect(again.given, puzzles[axis]![seed].given);
          expect(again.target, puzzles[axis]![seed].target);
        }
        final a = mirrorPuzzles(seed), b = mirrorPuzzles(seed);
        for (var i = 0; i < 3; i++) {
          expect(a[i].given, b[i].given, reason: 'seed $seed puzzle $i');
        }
      }
    });

    test('no shortcut: sliding or spinning the pattern is never right', () {
      for (final MapEntry(key: axis, value: list) in puzzles.entries) {
        for (final (seed, p) in list.indexed) {
          final off = p.given.where((c) => !onMirrorLine(c, axis));
          final spun = {
            for (final c in off) at(n - 1 - rowOf(c), n - 1 - colOf(c)),
          };
          expect(spun, isNot(equals(p.target)), reason: '$axis seed $seed');
          if (axis == MirrorAxis.vertical) {
            final slid = {for (final c in off) at(rowOf(c), colOf(c) + n ~/ 2)};
            expect(slid, isNot(equals(p.target)), reason: 'seed $seed');
          }
          if (axis == MirrorAxis.horizontal) {
            final slid = {for (final c in off) at(rowOf(c) + n ~/ 2, colOf(c))};
            expect(slid, isNot(equals(p.target)), reason: 'seed $seed');
          }
        }
      }
    });

    test('no row or column of the pattern is all empty or all full', () {
      for (final MapEntry(key: axis, value: list) in puzzles.entries) {
        for (final (seed, p) in list.indexed) {
          for (var k = 0; k < n; k++) {
            for (final line in [
              [for (var j = 0; j < n; j++) at(k, j)],
              [for (var j = 0; j < n; j++) at(j, k)],
            ]) {
              final part = line
                  .where(
                    (c) => onPatternSide(c, axis) && !onMirrorLine(c, axis),
                  )
                  .toList();
              if (part.length < 3) continue;
              expect(
                part.where(p.given.contains).length,
                inExclusiveRange(0, part.length),
                reason: '$axis seed $seed line $line',
              );
            }
          }
        }
      }
    });

    test('plenty of different patterns', () {
      for (final MapEntry(key: axis, value: list) in puzzles.entries) {
        final distinct = {
          for (final p in list) (p.given.toList()..sort()).join(','),
        };
        expect(distinct.length, greaterThan(seeds * .9), reason: '$axis');
      }
    });

    test('a day is three mirrors in order; practice sets are different', () {
      for (var d = 0; d < 60; d++) {
        expect(mirrorSeed(d), d);
        final daily = mirrorPuzzles(mirrorSeed(d));
        expect(daily.map((p) => p.axis), MirrorAxis.values);
        for (var practice = 1; practice <= 3; practice++) {
          final seed = mirrorSeed(d, practice: practice);
          expect(seed, isNot(mirrorSeed(d)));
          final set = mirrorPuzzles(seed);
          expect(set.map((p) => p.axis), MirrorAxis.values);
          expect(
            [
              for (var i = 0; i < 3; i++)
                setEquals(set[i].given, daily[i].given),
            ],
            contains(false),
            reason: 'day $d practice $practice repeats the daily',
          );
        }
      }
    });
  });

  group('Mirror checking', () {
    MirrorPuzzle puzzle() => mirrorPuzzles(7).first;

    /// Misses [check] − 1 times, then paints the answer.
    MirrorRound solvedOn(int check) {
      final round = MirrorRound(puzzle());
      final wrong = wrongSquares(round.puzzle);
      for (var miss = 0; miss < check - 1; miss++) {
        round.toggle(wrong[miss]);
        expect(round.check().correct, isFalse);
        round.toggle(wrong[miss]);
      }
      round.puzzle.target.forEach(round.toggle);
      expect(round.check().correct, isTrue);
      return round;
    }

    test('100 on the first check, 60 on the second, 30 on the third', () {
      for (final (check, points, mark) in [
        (1, 100, '🟩'),
        (2, 60, '🟨'),
        (3, 30, '🟧'),
      ]) {
        final round = solvedOn(check);
        expect(round.solved, isTrue);
        expect(round.revealed, isFalse);
        expect(round.over, isTrue);
        expect(round.checks, check);
        expect(round.points, points);
        expect(round.worth, points);
        expect(round.shareMark, mark);
        expect(round.markedExtra, isEmpty);
        expect(round.markedMissing, isEmpty);
        expect(
          round.toggle(round.puzzle.paintSide.first),
          isFalse,
          reason: 'a finished board is locked',
        );
        expect(round.check, throwsStateError);
      }
    });

    test('a third miss reveals the answer for 0 points', () {
      final round = MirrorRound(puzzle());
      final wrong = wrongSquares(round.puzzle);
      for (var miss = 0; miss < 3; miss++) {
        expect(round.over, isFalse);
        expect(round.worth, MirrorRound.checkPoints[miss]);
        expect(round.checksLeft, 3 - miss);
        round.toggle(wrong[miss]);
        expect(round.check().correct, isFalse);
      }
      expect(round.revealed, isTrue);
      expect(round.solved, isFalse);
      expect(round.over, isTrue);
      expect(round.points, 0);
      expect(round.shareMark, '⬛');
      expect(round.canCheck, isFalse);
      expect(round.markedMissing, round.puzzle.target);
      expect(round.markedExtra, wrong.take(3).toSet());
      expect(round.toggle(round.puzzle.paintSide.first), isFalse);
      expect(round.check, throwsStateError);
    });

    test('a check counts right, extra and missing squares', () {
      final round = MirrorRound(puzzle());
      final target = round.puzzle.target.toList();
      final wrong = wrongSquares(round.puzzle).first;
      round
        ..toggle(target[0])
        ..toggle(target[1])
        ..toggle(wrong);
      final result = round.check();
      expect(result.total, target.length);
      expect(result.right, 2);
      expect(result.extra, {wrong});
      expect(result.missing, target.skip(2).toSet());
      expect(result.correct, isFalse);
      expect(round.checksLeft, 2);
      expect(round.worth, 60);
    });

    test('pattern squares are locked; paint squares toggle', () {
      final round = MirrorRound(puzzle());
      for (final cell in round.puzzle.patternSide) {
        expect(round.toggle(cell), isFalse);
      }
      expect(round.painted, isEmpty);
      final cell = round.puzzle.paintSide.first;
      expect(round.toggle(cell), isTrue);
      expect(round.painted, {cell});
      expect(round.toggle(cell), isTrue);
      expect(round.painted, isEmpty);
    });

    test('marks only come from a check, and clear as they are fixed', () {
      final round = MirrorRound(puzzle());
      final target = round.puzzle.target.toList();
      final wrong = wrongSquares(round.puzzle);
      round.toggle(wrong[0]);
      expect(round.markedExtra, isEmpty);
      expect(round.markedMissing, isEmpty);
      round.check();
      expect(round.markedExtra, {wrong[0]});
      expect(round.markedMissing, target.toSet());
      round
        ..toggle(wrong[0])
        ..toggle(target[0]);
      expect(round.markedExtra, isEmpty);
      expect(round.markedMissing, target.skip(1).toSet());
      round.toggle(wrong[1]);
      expect(round.markedExtra, isEmpty, reason: 'new paint waits for a check');
    });

    test('Check waits for a painted board that has changed', () {
      final round = MirrorRound(puzzle());
      expect(round.canCheck, isFalse);
      final wrong = wrongSquares(round.puzzle).first;
      round.toggle(wrong);
      expect(round.canCheck, isTrue);
      round.check();
      expect(round.canCheck, isFalse, reason: 'same painting as last time');
      final cell = round.puzzle.target.first;
      round.toggle(cell);
      expect(round.canCheck, isTrue);
      round.toggle(cell);
      expect(round.canCheck, isFalse, reason: 'back to what was checked');
      round.clear();
      expect(round.painted, isEmpty);
      expect(round.canCheck, isFalse);
    });
  });

  testWidgets('Mirror: three perfect reflections finish the day', (
    tester,
  ) async {
    await phone(tester);
    final state = CurioState();
    final xpBefore = state.totalXp;
    await tester.pumpWidget(play(MirrorPage(date: day), state));
    await playAll(tester, today());
    await reveal(tester, find.text('300 / 300'));
    expect(find.text('300 / 300'), findsOneWidget);
    expect(find.text('Mirror master!'), findsOneWidget);
    expect(find.text('+80 XP earned'), findsOneWidget);
    expect(state.completedToday('mirror'), isTrue);
    expect(state.totalXp, xpBefore + 80);
    expect(state.collectedFacts, contains('mirror_symmetry'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mirror: marks appear only after a check; three misses reveal '
      'the answer', (tester) async {
    await phone(tester);
    await tester.pumpWidget(play(MirrorPage(date: day), CurioState()));
    final puzzle = today().first;
    final target = puzzle.target.toList();
    final wrong = wrongSquares(puzzle);
    PrimaryButton check() =>
        tester.widget<PrimaryButton>(find.byKey(const Key('mirror_check')));

    await reveal(tester, find.byKey(const Key('mirror_check')));
    expect(check().onPressed, isNull, reason: 'nothing painted yet');
    await tap(tester, find.byKey(Key('mirror_cell_${target[0]}')));
    await tap(tester, find.byKey(Key('mirror_cell_${wrong[0]}')));
    expect(find.byKey(Key('mirror_extra_${wrong[0]}')), findsNothing);
    for (final cell in target) {
      expect(find.byKey(Key('mirror_missing_$cell')), findsNothing);
    }

    await tap(tester, find.byKey(const Key('mirror_check')));
    final verdict = '1 of ${target.length} squares right';
    await reveal(tester, find.textContaining(verdict));
    expect(find.textContaining(verdict), findsOneWidget);
    expect(find.byKey(Key('mirror_extra_${wrong[0]}')), findsOneWidget);
    expect(find.byKey(Key('mirror_missing_${target[0]}')), findsNothing);
    for (final cell in target.skip(1)) {
      expect(find.byKey(Key('mirror_missing_$cell')), findsOneWidget);
    }
    expect(find.text('Missing'), findsOneWidget, reason: 'the legend');
    await reveal(tester, find.byKey(const Key('mirror_check')));
    expect(check().onPressed, isNull, reason: 'nothing changed since');

    for (final miss in [wrong[1], wrong[2]]) {
      await tap(tester, find.byKey(Key('mirror_cell_$miss')));
      await tap(tester, find.byKey(const Key('mirror_check')));
    }
    await reveal(tester, find.textContaining('Here’s the true reflection'));
    expect(find.textContaining('Here’s the true reflection'), findsOneWidget);
    for (final cell in target.skip(1)) {
      expect(find.byKey(Key('mirror_missing_$cell')), findsOneWidget);
    }
    for (final miss in wrong.take(3)) {
      expect(find.byKey(Key('mirror_extra_$miss')), findsOneWidget);
    }
    expect(find.byKey(const Key('mirror_check')), findsNothing);
    await reveal(tester, find.text('No points'));
    expect(find.text('No points'), findsOneWidget);
    await tap(tester, find.byKey(const Key('mirror_next')));
    await reveal(tester, find.text('PUZZLE 2 OF 3'));
    expect(find.text('PUZZLE 2 OF 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mirror squares read out row, column and state', (tester) async {
    final semantics = tester.ensureSemantics();
    await phone(tester);
    await tester.pumpWidget(play(MirrorPage(date: day), CurioState()));
    final puzzle = today().first;
    String where(int c) => 'Row ${rowOf(c) + 1}, column ${colOf(c) + 1}';
    final given = puzzle.given.first;
    final blank = puzzle.patternSide.firstWhere(
      (c) => !puzzle.given.contains(c),
    );
    final paint = puzzle.target.first;

    expect(
      tester.getSemantics(
        find.bySemanticsLabel('${where(given)}, filled, locked'),
      ),
      isSemantics(isButton: true, hasTapAction: false),
    );
    expect(
      find.bySemanticsLabel('${where(blank)}, empty, locked'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('${where(paint)}, empty')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    await tap(tester, find.byKey(Key('mirror_cell_$paint')));
    expect(find.bySemanticsLabel('${where(paint)}, filled'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Mirror: a practice round earns no extra XP', (tester) async {
    await phone(tester);
    final state = CurioState();
    final xpBefore = state.totalXp;
    await tester.pumpWidget(play(MirrorPage(date: day), state));
    await playAll(tester, today());
    expect(state.totalXp, xpBefore + 80);

    await tap(tester, find.byKey(const Key('game_practice')));
    await reveal(tester, find.text('PRACTICE'));
    expect(find.text('PRACTICE'), findsOneWidget);
    await playAll(
      tester,
      mirrorPuzzles(mirrorSeed(DailyPick.dayNumber(day), practice: 1)),
    );
    await reveal(tester, find.text('300 / 300'));
    expect(find.text('300 / 300'), findsOneWidget);
    expect(find.text('+80 XP earned'), findsNothing);
    expect(state.totalXp, xpBefore + 80);
    expect(state.completedActivities.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mirror: the glint loops only while motion is allowed', (
    tester,
  ) async {
    await phone(tester);
    final state = CurioState();
    Widget page({required bool reduce}) => CurioScope(
      notifier: state,
      child: MaterialApp(
        theme: CurioTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: MirrorPage(date: day),
      ),
    );
    await tester.pumpWidget(page(reduce: false));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(page(reduce: true));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Mirror fits $size dark=$dark with large text', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(
          play(MirrorPage(date: day), CurioState(), dark: dark, text: 1.6),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await reveal(tester, find.byKey(const Key('mirror_board')));
        final board = tester.getSize(find.byKey(const Key('mirror_board')));
        expect(board.width, board.height);
        expect(board.width, lessThanOrEqualTo(430));

        await tester.tap(find.byTooltip('How to play'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // With large text the sheet scrolls; "Got it" may start below it.
        await tester.ensureVisible(find.text('Got it'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        expect(find.text('Got it'), findsNothing);

        // One miss first, so the marks, legend and longer notice are laid
        // out too, then every puzzle through to the result card.
        final puzzles = today();
        final wrong = wrongSquares(puzzles.first).first;
        await tap(tester, find.byKey(Key('mirror_cell_$wrong')));
        await tap(tester, find.byKey(const Key('mirror_check')));
        expect(tester.takeException(), isNull);
        await tap(tester, find.byKey(Key('mirror_cell_$wrong')));
        await playAll(tester, puzzles.take(2).toList());
        await tap(tester, find.byKey(const Key('mirror_next')));
        for (final cell in puzzles.last.target) {
          await tap(tester, find.byKey(Key('mirror_cell_$cell')));
        }
        expect(tester.takeException(), isNull, reason: 'every puzzle state');

        await tap(tester, find.byKey(const Key('mirror_check')));
        await reveal(tester, find.text('260 / 300'));
        expect(find.text('260 / 300'), findsOneWidget);
        final resultError = tester.takeException();
        expect(resultError, isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
