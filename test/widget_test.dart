import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curio/app/curio_app.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/link_lab/presentation/link_lab_page.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
import 'package:curio/features/learn/presentation/learn_hub_page.dart';

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

  test('Daily activity ids include the full date', () {
    expect(
      CurioState.dailyActivityId('squeeze', DateTime(2026, 8, 13)),
      'squeeze_20260813',
    );
  });

  testWidgets('Curio opens learning modes from bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const CurioApp());

    expect(find.textContaining('Explorer!'), findsOneWidget);
    expect(find.text("TODAY'S QUEST"), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Games'));
    await tester.pumpAndSettle();

    expect(find.text('Ways to learn'), findsOneWidget);
    expect(find.text('Link Lab'), findsOneWidget);
    expect(find.text('Signal Grid'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pattern Forge'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(LearnHubPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Pattern Forge'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Evidence Detective'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(LearnHubPage),
            matching: find.byType(Scrollable),
          )
          .first,
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
    await tester.tap(find.widgetWithText(NavigationDestination, 'Games'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Evidence Detective'),
      320,
      scrollable: find
          .descendant(
            of: find.byType(LearnHubPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Evidence Detective'));
    await tester.pumpAndSettle();

    expect(find.text('CASE 001 · THE GARDEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Link Lab accepts a complete connection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Games'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link Lab').first);
    await tester.pumpAndSettle();

    for (final word in ['MERCURY', 'VENUS', 'EARTH', 'MARS']) {
      await tester.ensureVisible(find.byKey(Key('link_$word')));
      await tester.tap(find.byKey(Key('link_$word')));
    }
    await tester.scrollUntilVisible(
      find.text('Check connection'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(LinkLabPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Check connection'));
    await tester.pumpAndSettle();

    expect(find.text('ROCKY PLANETS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Core shell renders at desktop width', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.pumpAndSettle();

    expect(find.text('Daily momentum'), findsOneWidget);
    expect(find.text('Today’s brain breaks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signal Grid completes a valid daily puzzle', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.tap(find.widgetWithText(NavigationDestination, 'Games'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signal Grid').first);
    await tester.pumpAndSettle();

    const tapsByCell = <int, int>{
      1: 2,
      2: 1,
      4: 1,
      6: 2,
      7: 1,
      8: 2,
      9: 1,
      11: 2,
      13: 1,
      14: 2,
    };
    for (final entry in tapsByCell.entries) {
      final cell = find.byKey(Key('signal_${entry.key}'));
      for (var tap = 0; tap < entry.value; tap++) {
        await tester.tap(cell);
      }
    }
    await tester.ensureVisible(find.text('Check my grid'));
    await tester.tap(find.text('Check my grid'));
    await tester.pumpAndSettle();

    expect(find.text('Grid harmonised.'), findsOneWidget);
    expect(find.text('+100 XP earned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
