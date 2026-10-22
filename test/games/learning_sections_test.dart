import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/services/minigame_service.dart';
import 'package:curio/features/games/loophole/domain/loophole_bank.dart';
import 'package:curio/features/games/loophole/presentation/loophole_page.dart';
import 'package:curio/features/home/presentation/home_page.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/english/domain/english_game.dart';
import 'package:curio/features/games/english/presentation/english_page.dart';
import 'package:curio/features/games/memory/domain/memory_game.dart';
import 'package:curio/features/games/memory/presentation/memory_page.dart';
import 'package:curio/features/learn/presentation/learn_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflinePuzzleService extends MinigameService {
  @override
  bool get isSignedIn => true;
  @override
  Future<DailyPuzzle?> fetchPuzzle(String type, DateTime date) async =>
      throw StateError('Offline');
}

final day = DateTime(2026, 10, 22);
final seed = DailyPick.dayNumber(day);

Widget play(
  Widget page,
  CurioState state, {
  bool dark = false,
  double text = 1,
}) => MaterialApp(
  theme: dark ? CurioTheme.dark : CurioTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(text)),
    child: child!,
  ),
  home: CurioScope(notifier: state, child: page),
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> solveMatch(WidgetTester tester, int seed) async {
  final game = MemoryMatchGame(seed);
  for (final symbol in game.cards.toSet()) {
    final pair = [
      for (var i = 0; i < game.cards.length; i++)
        if (game.cards[i] == symbol) i,
    ];
    for (final index in pair) {
      await tap(tester, find.byKey(Key('memory_card_$index')));
    }
  }
}

Future<void> solveWords(
  WidgetTester tester,
  int seed, {
  bool builder = false,
}) async {
  for (var r = 0; r < 5; r++) {
    if (builder) {
      final word = wordsForDay(seed)[r].$1;
      final letters = shuffledLetters(word, seed * 17 + r);
      final used = <int>{};
      for (final letter in word.split('')) {
        final index = [
          for (var i = 0; i < letters.length; i++)
            if (letters[i] == letter && !used.contains(i)) i,
        ].first;
        used.add(index);
        await tap(tester, find.byKey(Key('english_letter_$index')));
      }
      await tap(tester, find.byKey(const Key('english_check')));
    } else {
      await tap(tester, find.text(questionsForDay(seed)[r].answer));
    }
    await tap(tester, find.byKey(const Key('english_next')));
  }
}

void main() {
  test(
    'memory pairs are fair, mismatch input is locked, and every board can finish',
    () {
      for (var seed = -10; seed < 100; seed++) {
        final game = MemoryMatchGame(seed);
        expect(game.cards.toSet().length, 6);
        for (final symbol in game.cards.toSet()) {
          expect(game.cards.where((s) => s == symbol).length, 2);
        }
        final other = game.cards.indexWhere((s) => s != game.cards.first);
        game.flip(0);
        expect(game.flip(0), isFalse);
        game.flip(other);
        expect(game.needsReset, isTrue);
        expect(game.flip(2), isFalse);
        expect(game.moves, 1);
        game.hideUnmatched();
        for (final symbol in game.cards.toSet()) {
          for (var i = 0; i < game.cards.length; i++) {
            if (game.cards[i] == symbol) game.flip(i);
          }
        }
        expect(game.finished, isTrue);
        expect(game.moves, 7);
      }
    },
  );

  test(
    'memory trails teach recall, lock feedback, and include a recoverable wrong answer',
    () {
      final game = MemoryTrailGame(seed);
      expect(game.choose(game.trail.first), isFalse);
      game.startRecall();
      game.choose((game.trail.first + 1) % 12);
      expect(game.correct, isFalse);
      expect(game.choose(game.trail.first), isFalse);
      game.next();
      for (var round = 1; round < 5; round++) {
        expect(game.trail.length, round + 3);
        game.startRecall();
        for (final symbol in game.trail) {
          game.choose(symbol);
        }
        expect(game.correct, isTrue);
        game.next();
      }
      expect(game.score, 4);
      expect(game.round, 4);
    },
  );

  test(
    'English banks have unambiguous choices and solvable shuffled words',
    () {
      for (final q in wordQuestions) {
        expect(q.options.toSet().length, 4);
        expect(q.options.where((o) => o == q.answer).length, 1);
        expect(q.explanation, isNotEmpty);
      }
      for (var day = -20; day < 100; day++) {
        expect(questionsForDay(day).toSet().length, 5);
        expect(wordsForDay(day).toSet().length, 5);
        for (final word in wordsForDay(day)) {
          final letters = shuffledLetters(word.$1, day);
          expect(letters.join(), isNot(word.$1));
          expect(
            (List.of(letters)..sort()).join(),
            (word.$1.split('')..sort()).join(),
          );
        }
      }
      expect(MemoryMatchGame(1).cards, isNot(MemoryMatchGame(2).cards));
      expect(questionsForDay(1), isNot(questionsForDay(2)));
    },
  );

  testWidgets(
    'Memory Match finishes, persists its reward once, and practice earns nothing',
    (tester) async {
      final state = CurioState();
      addTearDown(state.dispose);
      await tester.pumpWidget(play(MemoryPage(date: day), state));
      await solveMatch(tester, seed);
      expect(find.text('Every pair found!'), findsOneWidget);
      expect(state.totalXp, 80);
      expect(state.collectedFacts, contains('memory_pairs'));
      await tap(tester, find.byKey(const Key('game_practice')));
      await solveMatch(tester, seed - 1);
      expect(state.totalXp, 80);
      expect(find.text('PRACTICE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Memory Trail completes all five rounds and allows mistakes', (
    tester,
  ) async {
    final state = CurioState();
    addTearDown(state.dispose);
    final trails = MemoryTrailGame(seed).trails;
    await tester.pumpWidget(play(MemoryPage(date: day, trail: true), state));
    for (var r = 0; r < 5; r++) {
      await tap(tester, find.byKey(const Key('trail_ready')));
      if (r == 0) {
        await tap(
          tester,
          find.byKey(Key('trail_symbol_${(trails[r].first + 1) % 12}')),
        );
      } else {
        for (final symbol in trails[r]) {
          await tap(tester, find.byKey(Key('trail_symbol_$symbol')));
        }
      }
      await tap(tester, find.byKey(const Key('trail_next')));
    }
    expect(find.text('4 / 5'), findsOneWidget);
    expect(state.totalXp, 80);
    expect(tester.takeException(), isNull);
  });

  for (final builder in [false, true]) {
    testWidgets(
      'English builder=$builder finishes and practice never adds XP',
      (tester) async {
        final state = CurioState();
        addTearDown(state.dispose);
        await tester.pumpWidget(
          play(EnglishPage(date: day, builder: builder), state),
        );
        await solveWords(tester, seed, builder: builder);
        expect(find.text('5 / 5'), findsOneWidget);
        expect(state.totalXp, 80);
        await tap(tester, find.byKey(const Key('game_practice')));
        await solveWords(tester, seed - 1, builder: builder);
        expect(state.totalXp, 80);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Signed-in Loophole falls back to playable local puzzles offline',
    (tester) async {
      final state = CurioState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        play(LoopholePage(date: day, service: _OfflinePuzzleService()), state),
      );
      await tester.pumpAndSettle();
      final rounds =
          loopholeDays[DailyPick.index(loopholeDays.length, date: day)];
      for (var i = 0; i < rounds.length; i++) {
        await tap(tester, find.text(rounds[i].tokens[rounds[i].target]));
        if (i < rounds.length - 1) {
          await tap(tester, find.text('Next statement'));
        }
      }
      expect(state.totalXp, 70);
      expect(find.text('6 / 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Word Builder supports undo, repeated letters, and revealing a difficult word',
    (tester) async {
      final state = CurioState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        play(EnglishPage(date: day, builder: true), state),
      );
      await tap(tester, find.byKey(const Key('english_letter_0')));
      await tap(tester, find.text('Undo'));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('english_check')))
            .onPressed,
        isNull,
      );
      await tap(tester, find.byKey(const Key('english_reveal')));
      expect(find.textContaining('A word to remember:'), findsOneWidget);
      expect(find.byKey(const Key('english_next')), findsOneWidget);
      expect(state.totalXp, 0);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Daily sections and new games fit $size dark=$dark at large text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final page in [
            MemoryPage(date: day),
            MemoryPage(date: day, trail: true),
            EnglishPage(date: day),
            EnglishPage(date: day, builder: true),
            const LearnHubPage(),
            HomePage(onExplore: () {}),
          ]) {
            final state = CurioState();
            await tester.pumpWidget(play(page, state, dark: dark, text: 1.8));
            await tester.pumpAndSettle();
            if (page is LearnHubPage) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -1800),
              );
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType}',
            );
            await tester.pumpWidget(const SizedBox());
            state.dispose();
          }
        },
      );
    }
  }
}
