import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curio/app/curio_app.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';

void main() {
  test('Squeeze narrows its candidate range', () {
    final engine = SqueezeEngine(target: 64);

    expect(engine.guess(50), contains('too low'));
    expect(engine.minimum, 51);
    expect(engine.maximum, 100);

    expect(engine.guess(75), contains('too high'));
    expect(engine.minimum, 51);
    expect(engine.maximum, 74);

    expect(engine.guess(64), contains('found it'));
    expect(engine.solved, isTrue);
  });

  testWidgets('Curio opens learning modes from bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const CurioApp());

    expect(find.textContaining('Explorer!'), findsOneWidget);
    expect(find.text("TODAY'S QUEST"), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Learn'));
    await tester.pumpAndSettle();

    expect(find.text('Ways to learn'), findsOneWidget);
    expect(find.text('Pattern Forge'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Evidence Detective'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Evidence Detective'), findsOneWidget);
  });

  testWidgets('Evidence Detective renders on a phone-sized viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Learn'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Evidence Detective'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.dragFrom(const Offset(195, 620), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evidence Detective'));
    await tester.pumpAndSettle();

    expect(find.text('CASE 001 · THE GARDEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
