import 'package:curio/app/curio_app.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/presentation/game_card.dart';
import 'package:curio/features/games/presentation/daily_plan.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
import 'package:curio/features/learn/presentation/learn_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Squeeze narrows its candidate range', () {
    final engine = SqueezeEngine(target: 64);
    expect(engine.guess(50), contains('too low'));
    expect(engine.minimum, 51);
    expect(engine.guess(75), contains('too high'));
    expect(engine.maximum, 74);
    expect(engine.guess(64), contains('found it'));
    expect(engine.solved, isTrue);
  });

  test('Daily activity ids include the full date', () {
    expect(
      CurioState.dailyActivityId('squeeze', DateTime(2026, 8, 13)),
      'squeeze_20260813',
    );
  });

  for (final size in [const Size(375, 667), const Size(1280, 900)]) {
    testWidgets('Home and Games share exactly three daily games at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const CurioApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Hello, Explorer!'), findsOneWidget);
      final picks = todaysPicks();
      await tester.scrollUntilVisible(
        find.byType(DailyPlan),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widgetList<GameCard>(find.byType(GameCard))
            .map((c) => c.game.id),
        picks.map((g) => g.id),
      );
      expect(find.text('Maths'), findsWidgets);
      expect(find.text('Memory'), findsWidgets);
      expect(find.text('English'), findsWidgets);
      await tester.tap(find.byKey(const Key('nav_Games')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Three little adventures'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(DailyPlan),
        300,
        scrollable: find
            .descendant(
              of: find.byType(LearnHubPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester
            .widgetList<GameCard>(find.byType(GameCard))
            .map((c) => c.game.id),
        picks.map((g) => g.id),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
