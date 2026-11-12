import 'package:curio/app/curio_app.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
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

  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('Home shows one anchor and the rest of the set at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const CurioApp());
      await tester.pump(const Duration(seconds: 1));
      final set = todaysSet();
      expect(find.byKey(const Key('home_anchor')), findsOneWidget);
      expect(find.text(set.anchor.title), findsOneWidget);
      for (final game in set.others) {
        final row = find.byKey(Key('game_row_${game.id}'));
        await tester.scrollUntilVisible(
          row,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(row, findsOneWidget);
      }
      expect(set.others.length + 1, dailyGameCount);
      expect(find.byKey(const Key('nav_Games')), findsNothing);
      expect(find.byKey(const Key('nav_Discover')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
