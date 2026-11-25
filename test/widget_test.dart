import 'package:curio/app/curio_app.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/daily_game_session.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
import 'package:curio/features/shell/presentation/main_shell.dart';
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

  testWidgets('Games lists only today’s lineup and opens a daily run', (
    tester,
  ) async {
    final date = DateTime(2026);
    final state = CurioState(now: () => date);
    addTearDown(state.dispose);
    final dailyIds = state.todayGameIds;
    expect(dailyIds, contains('squeeze'));
    await tester.pumpWidget(
      CurioScope(
        notifier: state,
        child: MaterialApp(theme: CurioTheme.light, home: const MainShell()),
      ),
    );

    await tester.tap(find.byKey(const Key('nav_Games')));
    await tester.pumpAndSettle();
    for (final game in gameCatalog) {
      expect(
        find.byKey(Key('game_row_${game.id}')),
        dailyIds.contains(game.id) ? findsOneWidget : findsNothing,
      );
    }
    final squeeze = find.byKey(const Key('game_row_squeeze'));
    await tester.scrollUntilVisible(squeeze, 200);
    await tester.tap(squeeze);
    await tester.pumpAndSettle();
    final session = tester.widget<DailyGameSession>(
      find.byType(DailyGameSession),
    );
    expect(session.date, date);
    expect(session.practice, isFalse);

    final input = find.byKey(const Key('squeezeInput'));
    await tester.ensureVisible(input);
    final target = SqueezeEngine(
      date: puzzleDateForGame('squeeze', date),
    ).target;
    await tester.enterText(input, '$target');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.totalXp, gameById('squeeze').xp);
    expect(state.gamesCompletedToday, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'Home shows the calendar, the daily challenge, then today’s games as a grid at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const CurioApp());
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.getBottomLeft(find.text('This week')).dy,
          lessThan(tester.getTopLeft(find.text('Today’s games')).dy),
        );
        final set = todaysSet();
        final anchor = find.byKey(Key('game_row_${set.anchor.id}'));
        expect(anchor, findsOneWidget);
        expect(find.text(set.anchor.title), findsOneWidget);
        final challengeWidth = tester.getRect(anchor).width;
        final page = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        double? cardWidth;
        for (final game in set.others) {
          final card = find.byKey(Key('game_row_${game.id}'));
          await tester.scrollUntilVisible(card, 200, scrollable: page.first);
          expect(card, findsOneWidget);
          final width = tester.getRect(card).width;
          // Listing cards share one width, two or three to a row.
          expect(width, closeTo(cardWidth ?? width, .5));
          expect(width, lessThan(challengeWidth * .6));
          cardWidth = width;
        }
        expect(set.others.length + 1, dailyGameCount);
        expect(find.byKey(const Key('nav_Games')), findsOneWidget);
        expect(find.byKey(const Key('nav_Discover')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
