import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/crowns/domain/crowns.dart';
import 'package:curio/features/games/crowns/domain/crowns_boards.dart';
import 'package:curio/features/games/crowns/presentation/crowns_page.dart';
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

Future<CurioState> open(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  bool dark = false,
  double text = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = CurioState(now: () => day);
  addTearDown(state.dispose);
  await tester.pumpWidget(play(page, state, dark: dark, text: text));
  await tester.pumpAndSettle();
  return state;
}

int get today => DailyPick.dayNumber(day);

void main() {
  group('Crowns', () {
    test('every board, in every orientation, has exactly one solution', () {
      for (final board in crownsBoards) {
        for (final mirror in [false, true]) {
          for (var turns = 0; turns < 4; turns++) {
            final b = board.transformed(turns: turns, mirror: mirror);
            expect(solveCrowns(b), [b.solution]);
            for (var k = 0; k < b.size; k++) {
              expect(b.regions, contains(k));
            }
          }
        }
      }
    });

    test('a day brings a 5×5 then a 6×6, and they change daily', () {
      final boards = dailyCrowns(today);
      expect(boards.map((b) => b.size), [5, 6]);
      expect(dailyCrowns(today + 1).first.regions, isNot(boards.first.regions));
    });

    test('clashes are found and hints place a right crown', () {
      final game = CrownsGame(dailyCrowns(today).first);
      game.toggleCrown((0, 0));
      game.toggleCrown((1, 1));
      expect(game.conflicts, {(0, 0), (1, 1)});
      expect(game.blocked((0, 3)), isTrue);
      game.clear();
      while (game.hint() != null) {}
      expect(game.solved, isTrue);
    });

    testWidgets('solving both boards earns the reward', (tester) async {
      final state = await open(tester, CrownsPage(date: day));
      final boards = dailyCrowns(today);
      for (final (i, board) in boards.indexed) {
        for (var r = 0; r < board.size; r++) {
          await tap(
            tester,
            find.byKey(Key('crowns_${r}_${board.solution[r]}')),
          );
        }
        if (i < boards.length - 1) {
          await tap(tester, find.byKey(const Key('crowns_next')));
        }
      }
      expect(state.completedToday('crowns'), isTrue);
    });
  });
}
