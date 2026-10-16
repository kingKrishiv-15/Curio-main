import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/whos_who/domain/whos_who.dart';
import 'package:curio/features/games/whos_who/presentation/whos_who_page.dart';
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
/// [finder] exists, then makes sure it's on screen.
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

Key cellKey(int child, int category) => Key('whos_who_cell_${child}_$category');

/// Picks [item] for one cell through its picker sheet.
Future<void> choose(
  WidgetTester tester,
  int child,
  int category,
  int item,
) async {
  await tap(tester, find.byKey(cellKey(child, category)));
  await tap(tester, find.byKey(Key('whos_who_option_$item')));
}

/// Fills the whole table with [puzzle]'s answer.
Future<void> fillAnswer(WidgetTester tester, WhoPuzzle puzzle) async {
  for (var child = 0; child < puzzle.size; child++) {
    for (var c = 0; c < puzzle.categories.length; c++) {
      await choose(tester, child, c, puzzle.solution[c][child]);
    }
  }
}

/// Taps the hint button until the puzzle is solved (it then disappears).
Future<void> hintToTheEnd(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    try {
      await tap(tester, find.byKey(const Key('whos_who_hint')));
    } catch (_) {
      return;
    }
  }
}

/// Grammar problems in a clue sentence, if any.
List<String> grammarProblems(String s) => [
  if (!RegExp(r'^[A-Z]').hasMatch(s)) 'starts lower case',
  if (!s.endsWith('.') || s.endsWith('..')) 'no single full stop',
  if (s.contains('  ')) 'double space',
  if (RegExp(r'\s[.,]').hasMatch(s)) 'space before punctuation',
  if (s.contains("'")) 'straight apostrophe',
  if (RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false).hasMatch(s))
    'doubled word',
  if (RegExp(
    r'\b(a|an) (apples|grapes|carrots|pretzels|popcorn|cheese)\b',
  ).hasMatch(s))
    'article on a plural',
  if (s.split(' ').length < 4) 'too short',
];

void main() {
  group('Solver', () {
    test('counts every assignment when there are no clues', () {
      expect(countSolutions(3, const []), 36);
      expect(countSolutions(4, const []), 576);
    });

    test('each kind of clue keeps the right share', () {
      expect(countSolutions(3, const [WhoClue.has(0, 0, 0)]), 12);
      expect(countSolutions(3, const [WhoClue.hasNot(0, 0, 0)]), 24);
      expect(countSolutions(3, const [WhoClue.linked(0, 0, 1, 2)]), 12);
      expect(countSolutions(3, const [WhoClue.linkedNot(1, 2, 0, 0)]), 24);
      expect(countSolutions(4, const [WhoClue.has(1, 1, 3)]), 144);
    });

    test('contradictions have no solution', () {
      expect(
        countSolutions(3, const [
          WhoClue.has(0, 0, 0),
          WhoClue.hasNot(0, 0, 0),
        ]),
        0,
      );
      expect(
        countSolutions(3, const [WhoClue.has(0, 0, 0), WhoClue.has(1, 0, 0)]),
        0,
      );
    });

    test('a hand-made puzzle has exactly one answer', () {
      // Child 0 has pet 0; pet 0's owner has colour 1; child 1 doesn't have
      // pet 1; colour 0 goes with pet 1.
      const clues = [
        WhoClue.has(0, 0, 0),
        WhoClue.linked(0, 0, 1, 1),
        WhoClue.hasNot(1, 0, 1),
        WhoClue.linked(1, 0, 0, 1),
      ];
      final answers = solveWho(3, clues);
      expect(answers.length, 1);
      expect(answers.single.items, [
        [0, 2, 1],
        [1, 2, 0],
      ]);
      expect(countSolutions(3, clues.sublist(0, 3)), greaterThan(1));
      expect(solvableByDeduction(3, clues), isTrue);
    });

    test('deduction alone cannot finish an under-clued puzzle', () {
      expect(solvableByDeduction(3, const [WhoClue.has(0, 0, 0)]), isFalse);
    });
  });

  group('Generated puzzles', () {
    void checkPuzzle(WhoPuzzle p, String where) {
      final range = WhoPuzzle.clueRange(p.size);
      expect(
        p.clues.length,
        inInclusiveRange(range.min, range.max),
        reason: where,
      );
      expect(
        p.clues.where((c) => c.kind == WhoClueKind.has).length,
        lessThanOrEqualTo(WhoPuzzle.maxPlainPositives),
        reason: where,
      );
      // Exactly one answer, and it's the stored one.
      final answers = solveWho(p.size, p.clues);
      expect(answers.length, 1, reason: where);
      expect(answers.single.items, p.solution, reason: where);
      final truth = WhoAssignment(p.solution);
      for (final clue in p.clues) {
        expect(clue.holds(truth), isTrue, reason: '$where: $clue');
        final without = [...p.clues]..remove(clue);
        expect(
          countSolutions(p.size, without, stopAt: 2),
          greaterThan(1),
          reason: '$where: $clue is redundant',
        );
      }
      expect(solvableByDeduction(p.size, p.clues), isTrue, reason: where);
      // Children: from the pool, all different initials.
      expect(p.names.every(whoNames.contains), isTrue, reason: where);
      expect(p.names.map((n) => n[0]).toSet().length, p.size, reason: where);
      // Items: distinct, from the right pool, one per child.
      for (var c = 0; c < p.categories.length; c++) {
        expect(p.items[c].toSet().length, p.size, reason: where);
        expect(p.items[c].every(p.categories[c].pool.contains), isTrue);
        expect(p.solution[c].toSet(), {for (var i = 0; i < p.size; i++) i});
      }
      // Sentences read properly and name what the clue is about.
      for (final clue in p.clues) {
        final s = p.sentence(clue);
        expect(grammarProblems(s), isEmpty, reason: '$where: "$s"');
        expect(s, contains(p.items[clue.category][clue.item]), reason: s);
        if (clue.isLinked) {
          expect(s, startsWith('The child '), reason: s);
          expect(s, contains(p.items[clue.otherCategory][clue.otherItem]));
        } else {
          expect(s, startsWith(p.names[clue.child]), reason: s);
        }
      }
    }

    test('320 days: both puzzles are unique, true, lean and well written', () {
      final seconds = <WhoCategory>{};
      for (var seed = 0; seed < 320; seed++) {
        final set = WhoPuzzle.dailySet(seed);
        expect(set.length, 2);
        expect(set[0].size, 3);
        expect(set[0].categories, [WhoCategory.pet, WhoCategory.colour]);
        expect(set[1].size, 4);
        expect(set[1].categories.first, WhoCategory.pet);
        expect(
          set[1].categories.last,
          isIn([WhoCategory.snack, WhoCategory.hobby]),
        );
        seconds.add(set[1].categories.last);
        expect(
          set[0].names.toSet().intersection(set[1].names.toSet()),
          isEmpty,
          reason: 'seed $seed: each puzzle has its own children',
        );
        checkPuzzle(set[0], 'seed $seed puzzle 1');
        checkPuzzle(set[1], 'seed $seed puzzle 2');
      }
      expect(seconds, {WhoCategory.snack, WhoCategory.hobby});
    });

    test('practice seeds are just as good', () {
      for (var shift = 1; shift <= 40; shift++) {
        for (final p in WhoPuzzle.dailySet(281 * 1000 + shift)) {
          checkPuzzle(p, 'practice $shift');
        }
      }
    });

    test('the same seed always gives the same puzzles', () {
      for (final seed in [0, 7, 281, 12345]) {
        final a = WhoPuzzle.dailySet(seed), b = WhoPuzzle.dailySet(seed);
        for (var i = 0; i < 2; i++) {
          expect(a[i].names, b[i].names);
          expect(a[i].items, b[i].items);
          expect(a[i].solution, b[i].solution);
          expect(a[i].clueTexts, b[i].clueTexts);
        }
      }
      expect(
        WhoPuzzle.dailySet(1)[1].clueTexts,
        isNot(WhoPuzzle.dailySet(2)[1].clueTexts),
      );
    });

    test('clue sentences for every kind and category', () {
      const p = WhoPuzzle(
        names: ['Ana', 'Ben'],
        categories: [WhoCategory.pet, WhoCategory.hobby],
        items: [
          ['cat', 'fish'],
          ['chess', 'piano'],
        ],
        solution: [
          [0, 1],
          [0, 1],
        ],
        clues: [],
      );
      expect(p.sentence(const WhoClue.has(0, 0, 0)), 'Ana has the cat.');
      expect(
        p.sentence(const WhoClue.hasNot(1, 0, 0)),
        'Ben doesn’t have the cat.',
      );
      expect(p.sentence(const WhoClue.has(0, 1, 0)), 'Ana’s hobby is chess.');
      expect(
        p.sentence(const WhoClue.linked(1, 0, 0, 0)),
        'The child who loves chess has the cat.',
      );
      expect(
        p.sentence(const WhoClue.linked(0, 1, 1, 1)),
        'The child with the fish loves piano.',
      );
      // A "not" link always ends on the pet, whichever way it was stored.
      expect(
        p.sentence(const WhoClue.linkedNot(0, 0, 1, 1)),
        'The child who loves piano doesn’t have the cat.',
      );
      expect(
        WhoCategory.colour.statement('Chen', 'red', positive: false),
        'Chen’s favourite colour isn’t red.',
      );
      expect(
        '${WhoCategory.colour.subject('red')} '
            '${WhoCategory.pet.predicate('parrot', positive: false)}.',
        'The child whose favourite colour is red doesn’t have the parrot.',
      );
      expect(
        WhoCategory.snack.statement('Dev', 'popcorn', positive: true),
        'Dev’s favourite snack is popcorn.',
      );
    });
  });

  group('A round', () {
    WhoPuzzle puzzle() => WhoPuzzle.dailySet(281).first;

    test('choosing moves an item from whoever had it', () {
      final round = WhoRound(puzzle());
      const a = (child: 0, category: 0), b = (child: 1, category: 0);
      expect(round.choose(a, 2), isTrue);
      expect(round.choose(b, 2), isTrue);
      expect(round.pickAt(a), isNull);
      expect(round.pickAt(b), 2);
      expect(round.ownerOf(0, 2), 1);
      expect(round.choose(b, null), isTrue);
      expect(round.emptyCount, 6);
    });

    test('checks count blanks for free and charge for mistakes', () {
      final p = puzzle();
      final round = WhoRound(p);
      round.choose((child: 0, category: 0), p.solution[0][0]);
      final early = round.check();
      expect(early.empty, 5);
      expect(round.points, 100, reason: 'a check with blanks is free');

      // Fill the answer, then swap two children's pets.
      for (final cell in round.cells) {
        round.choose(cell, p.solution[cell.category][cell.child]);
      }
      round.choose((child: 0, category: 0), p.solution[0][1]);
      round.choose((child: 1, category: 0), p.solution[0][0]);
      final result = round.check();
      expect((result.right, result.total, result.solved), (4, 6, false));
      expect(round.wrong, {(child: 0, category: 0), (child: 1, category: 0)});
      expect(round.points, 85);

      round.choose((child: 0, category: 0), p.solution[0][0]);
      expect(round.wrong, isEmpty, reason: 'changed cells lose their ✕');
      expect(round.emptyCount, 1);
      round.choose((child: 1, category: 0), p.solution[0][1]);
      expect(round.check().solved, isTrue);
      expect(round.solved, isTrue);
      expect(round.points, 85);
    });

    test('hints fill one right cell, lock it and finish the puzzle', () {
      final p = puzzle();
      final round = WhoRound(p);
      final first = round.hint()!;
      expect(round.isRight(first), isTrue);
      expect(round.hinted, {first});
      expect(round.points, 75);
      // A hinted cell and its item can't be changed.
      expect(round.choose(first, null), isFalse);
      final other = (child: (first.child + 1) % 3, category: first.category);
      expect(round.canChoose(other, round.pickAt(first)!), isFalse);

      var hints = 1;
      while (!round.solved) {
        expect(round.hint(), isNotNull);
        hints++;
      }
      expect(hints, 6);
      expect(round.points, WhoRound.minPoints);
    });

    test('a hint fixes a cell marked wrong first', () {
      final p = puzzle();
      final round = WhoRound(p);
      for (final cell in round.cells) {
        round.choose(cell, p.solution[cell.category][cell.child]);
      }
      // Swap two children's colours: both cells get a ✕.
      round.choose((child: 2, category: 1), p.solution[1][0]);
      round.choose((child: 0, category: 1), p.solution[1][2]);
      expect(round.check().right, 4);
      expect(round.wrong, {(child: 0, category: 1), (child: 2, category: 1)});
      expect(round.hint(), (child: 0, category: 1));
      expect(round.wrong, isEmpty);
      expect(round.pickAt((child: 2, category: 1)), isNull);
      expect(round.solved, isFalse, reason: 'the other cell is now blank');
      expect(round.hint(), (child: 2, category: 1));
      expect(round.solved, isTrue);
      expect(round.points, 100 - 15 - 2 * 25);
    });

    test('scores never drop below the minimum', () {
      final round = WhoRound(puzzle())
        ..hints = 3
        ..wrongChecks = 4;
      expect(round.points, WhoRound.minPoints);
    });
  });

  group('Page', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('fill both puzzles, score 200 and earn the day', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      final xp = state.totalXp;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(play(WhosWhoPage(date: day), state));
      final puzzles = WhoPuzzle.dailySet(DailyPick.dayNumber(day));

      // Clues are on screen and each cell is a real, labelled button.
      expect(find.text(puzzles[0].clueTexts.first), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(cellKey(0, 0))),
        matchesSemantics(
          label: '${puzzles[0].names[0]}’s pet: not chosen',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();

      // Crossing off a clue.
      await tap(tester, find.byKey(const Key('whos_who_clue_0')));
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      await fillAnswer(tester, puzzles[0]);
      await tap(tester, find.byKey(const Key('whos_who_check')));
      expect(find.textContaining('Spot on'), findsOneWidget);
      await tap(tester, find.byKey(const Key('whos_who_next')));

      expect(find.text(puzzles[1].clueTexts.first), findsOneWidget);
      await fillAnswer(tester, puzzles[1]);
      await tap(tester, find.byKey(const Key('whos_who_check')));

      await reveal(tester, find.text('200 / 200'));
      expect(find.text('200 / 200'), findsOneWidget);
      expect(find.textContaining('🟩🟩'), findsOneWidget);
      expect(state.completedToday('whos_who'), isTrue);
      expect(state.totalXp, xp + 100);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wrong check marks cells with ✕ without the answer', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(play(WhosWhoPage(date: day), CurioState()));
      final p = WhoPuzzle.dailySet(DailyPick.dayNumber(day)).first;
      await fillAnswer(tester, p);
      // Give child 0 child 1's pet — it moves, leaving child 1 blank.
      await choose(tester, 0, 0, p.solution[0][1]);
      await tap(tester, find.byKey(const Key('whos_who_check')));
      expect(find.text('One cell still needs a choice.'), findsOneWidget);
      await choose(tester, 1, 0, p.solution[0][0]);
      await tap(tester, find.byKey(const Key('whos_who_check')));
      expect(find.textContaining('4 of 6 right'), findsOneWidget);
      expect(find.byKey(const Key('whos_who_wrong_0_0')), findsOneWidget);
      expect(find.byKey(const Key('whos_who_wrong_1_0')), findsOneWidget);
      expect(find.text('Worth 85'), findsOneWidget);

      // The picker shows who has what and still lets it move.
      await tap(tester, find.byKey(cellKey(2, 0)));
      expect(find.textContaining('(${p.names[0]})'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a practice round never earns XP again', (tester) async {
      await phone(tester);
      final state = CurioState();
      final xp = state.totalXp;
      await tester.pumpWidget(play(WhosWhoPage(date: day), state));
      await hintToTheEnd(tester);
      await tap(tester, find.byKey(const Key('whos_who_next')));
      await hintToTheEnd(tester);
      await reveal(tester, find.text('40 / 200'));
      expect(state.totalXp, xp + 100);

      await tap(tester, find.byKey(const Key('game_practice')));
      await reveal(tester, find.text('PRACTICE'));
      expect(find.text('PRACTICE'), findsOneWidget);
      await hintToTheEnd(tester);
      await tap(tester, find.byKey(const Key('whos_who_next')));
      await hintToTheEnd(tester);
      await reveal(tester, find.text('40 / 200'));
      expect(find.textContaining('XP earned'), findsNothing);
      expect(state.totalXp, xp + 100);
      expect(tester.takeException(), isNull);
    });

    for (final size in [
      const Size(375, 667),
      const Size(812, 375),
      const Size(1280, 900),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('fits $size dark=$dark with large text', (tester) async {
          await phone(tester, size);
          // A replay of a finished day: GameResultCard's "+100 XP earned" row
          // is shared code that doesn't wrap yet (see report), so this run
          // checks the page with the card's "already earned" line instead.
          final state = CurioState()
            ..completedActivities.add(CurioState.dailyActivityId('whos_who'));
          await tester.pumpWidget(
            play(WhosWhoPage(date: day), state, dark: dark, text: 1.6),
          );
          await tester.pumpAndSettle();
          final p = WhoPuzzle.dailySet(DailyPick.dayNumber(day)).first;

          // Picker open, a ✕ cell, a hinted cell, then both puzzles solved.
          await tap(tester, find.byKey(cellKey(0, 0)));
          expect(tester.takeException(), isNull);
          await tap(tester, find.byKey(const Key('whos_who_option_0')));
          await choose(tester, 1, 1, (p.solution[1][1] + 1) % 3);
          for (final cell in WhoRound(p).cells) {
            if (cell == (child: 0, category: 0) ||
                cell == (child: 1, category: 1)) {
              continue;
            }
            await choose(
              tester,
              cell.child,
              cell.category,
              p.solution[cell.category][cell.child],
            );
          }
          await tap(tester, find.byKey(const Key('whos_who_check')));
          await tap(tester, find.byKey(const Key('whos_who_hint')));
          await tap(tester, find.byKey(const Key('whos_who_clue_1')));
          expect(tester.takeException(), isNull);

          await hintToTheEnd(tester);
          await tap(tester, find.byKey(const Key('whos_who_next')));
          await hintToTheEnd(tester);
          await reveal(tester, find.byKey(const Key('game_practice')));
          expect(state.completedToday('whos_who'), isTrue);
          expect(tester.takeException(), isNull, reason: '$size dark=$dark');
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
