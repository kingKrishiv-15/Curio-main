import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curio/app/curio_app.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/evidence/domain/evidence_cases.dart';
import 'package:curio/features/games/link_lab/domain/link_lab.dart';
import 'package:curio/features/games/link_lab/presentation/link_lab_page.dart';
import 'package:curio/features/games/signal_grid/domain/signal_grid.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
import 'package:curio/features/learn/presentation/learn_hub_page.dart';

/// The Learn hub is a long list; scroll a game into the middle of the screen
/// (clear of the floating nav) before checking or tapping it.
Future<void> showInLearnHub(WidgetTester tester, String title) async {
  final finder = find.text(title);
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find
        .descendant(
          of: find.byType(LearnHubPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

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

    expect(find.text('Hello, Explorer!'), findsOneWidget);
    expect(find.text('Weekly growth'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_Games')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Ways to learn'), findsOneWidget);
    await showInLearnHub(tester, 'Link Lab');
    expect(find.text('Link Lab'), findsOneWidget);
    await showInLearnHub(tester, 'Signal Grid');
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
    await tester.tap(find.byKey(const Key('nav_Games')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
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
    await showInLearnHub(tester, 'Evidence Detective');
    await tester.tap(find.text('Evidence Detective'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final today = evidenceCaseFor(DailyPick.dayNumber());
    expect(find.text(today.heading), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Link Lab accepts a complete connection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.tap(find.byKey(const Key('nav_Games')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await showInLearnHub(tester, 'Link Lab');
    await tester.tap(find.text('Link Lab').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Solve today's puzzle, group by group, checking each one is revealed.
    final puzzle = LinkLabGame.forDay(linkLabDay(DailyPick.dayNumber())).puzzle;
    final list = find
        .descendant(
          of: find.byType(LinkLabPage),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final group in puzzle.groups) {
      for (final word in group.words) {
        await tester.scrollUntilVisible(
          find.byKey(Key('link_$word')),
          -250,
          scrollable: list,
        );
        await tester.ensureVisible(find.byKey(Key('link_$word')));
        await tester.pump();
        await tester.tap(find.byKey(Key('link_$word')));
        await tester.pump();
      }
      await tester.scrollUntilVisible(
        find.text('Check connection'),
        250,
        scrollable: list,
      );
      await tester.tap(find.text('Check connection'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.scrollUntilVisible(
        find.text(group.title.toUpperCase()),
        -250,
        scrollable: list,
      );
      expect(find.text(group.title.toUpperCase()), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('Flawless links!'),
      250,
      scrollable: list,
    );
    expect(find.text('Flawless links!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Core shell renders at desktop width', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Today’s goal'), findsOneWidget);
    expect(find.text('Today’s picks'), findsOneWidget);
    final tile = find.byKey(const Key('skill_tile_Evidence'));
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Explore by skill'), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('4 games'), findsWidgets);
    expect(find.text('Verdict'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signal Grid completes a valid daily puzzle', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CurioApp());
    await tester.tap(find.byKey(const Key('nav_Games')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await showInLearnHub(tester, 'Signal Grid');
    await tester.tap(find.text('Signal Grid').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // One tap makes a spark, two make a wave; givens are already placed.
    final puzzle = SignalPuzzle.forDay(DailyPick.dayNumber());
    final tapsByCell = <int, int>{
      for (var i = 0; i < 16; i++)
        if (!puzzle.givens.contains(i)) i: puzzle.solution[i] ? 1 : 2,
    };
    for (final entry in tapsByCell.entries) {
      final cell = find.byKey(Key('signal_${entry.key}'));
      for (var tap = 0; tap < entry.value; tap++) {
        await tester.tap(cell);
      }
    }
    await tester.ensureVisible(find.text('Check my grid'));
    await tester.tap(find.text('Check my grid'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Grid harmonised.'), findsOneWidget);
    expect(find.text('+100 XP earned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
