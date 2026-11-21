import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/number_hunt/domain/number_hunt.dart';
import 'package:curio/features/games/number_hunt/presentation/number_hunt_page.dart';
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

Future<void> enter(WidgetTester tester, int value) async {
  for (final digit in '$value'.split('')) {
    await tap(tester, find.byKey(Key('hunt_key_$digit')));
  }
  await tap(tester, find.byKey(const Key('hunt_guess')));
}

void main() {
  group('Number Hunt rules', () {
    test('daily numbers stay in range and change from day to day', () {
      final targets = [
        for (var d = -400; d < 400; d++) NumberHunt.dailyTarget(d),
      ];
      expect(targets.every((t) => t >= 1 && t <= 1000), isTrue);
      for (var i = 1; i < targets.length; i++) {
        expect(targets[i], isNot(targets[i - 1]));
      }
      expect(targets.toSet().length, greaterThan(500));
    });

    test('halving always finds any number within ten guesses', () {
      for (var target = 1; target <= 1000; target++) {
        final hunt = NumberHunt(target);
        while (!hunt.over) {
          hunt.guess((hunt.floor + hunt.ceiling) ~/ 2);
        }
        expect(hunt.found, isTrue, reason: '$target');
      }
    });

    test('clues narrow the window; ruled-out guesses are not counted', () {
      final hunt = NumberHunt(300);
      expect(hunt.guess(500), Clue.lower);
      expect((hunt.floor, hunt.ceiling), (1, 499));
      expect(hunt.guess(100), Clue.higher);
      expect((hunt.floor, hunt.ceiling), (101, 499));
      expect(hunt.guess(600), Clue.outside);
      expect(hunt.guesses, [500, 100]);
      expect(hunt.guess(300), Clue.found);
      expect(hunt.guess(1), Clue.finished);
    });

    test('ten misses end the hunt', () {
      final hunt = NumberHunt(1000);
      for (var g = 1; g <= 10; g++) {
        expect(hunt.over, isFalse);
        hunt.guess(g);
      }
      expect(hunt.over, isTrue);
      expect(hunt.found, isFalse);
    });

    test('heat grows as a guess gets closer', () {
      expect(Heat.of(500, 500), Heat.found);
      expect(Heat.of(510, 500), Heat.sizzling);
      expect(Heat.of(540, 500), Heat.hot);
      expect(Heat.of(400, 500), Heat.warm);
      expect(Heat.of(250, 500), Heat.cool);
      expect(Heat.of(1, 500), Heat.cold);
    });
  });

  testWidgets('halving on the number pad finds today’s number and earns XP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = CurioState(now: () => day);
    addTearDown(state.dispose);
    await tester.pumpWidget(play(NumberHuntPage(date: day), state));

    // Guess is disabled until something is typed; a leading zero is ignored.
    await tap(tester, find.byKey(const Key('hunt_key_0')));
    await tap(tester, find.byKey(const Key('hunt_guess')));
    expect(find.text('10 guesses left'), findsOneWidget);

    final target = NumberHunt.dailyTarget(DailyPick.dayNumber(day));
    var floor = 1, ceiling = 1000;
    while (find.byKey(const Key('hunt_guess')).evaluate().isNotEmpty) {
      final mid = (floor + ceiling) ~/ 2;
      await enter(tester, mid);
      if (mid < target) floor = mid + 1;
      if (mid > target) ceiling = mid - 1;
    }
    expect(state.completedToday('number_hunt'), isTrue);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Tracked down.'), findsOneWidget);
    expect(state.totalXp, 90);
  });

  for (final dark in [false, true]) {
    testWidgets('fits a small phone at large text, dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final state = CurioState(now: () => day);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        play(NumberHuntPage(date: day), state, dark: dark, text: 1.8),
      );
      await tester.pumpAndSettle();
      await enter(tester, 500);
      await enter(tester, 999);
      expect(tester.takeException(), isNull);
    });
  }
}
