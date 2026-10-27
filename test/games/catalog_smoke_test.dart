import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/signal_grid/domain/signal_grid.dart';
import 'package:curio/features/games/signal_grid/presentation/signal_grid_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every game in the catalog opens the way the app opens it — inside its
/// daily session — and scrolls end to end without an error, in both themes,
/// on a roomy phone and on a small one at large text.
void main() {
  final day = DateTime(2026, 10, 27);
  for (final (size, text) in [
    (const Size(390, 844), 1.0),
    (const Size(320, 640), 1.8),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('every game opens at $size, text=$text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final game in gameCatalog) {
          final state = CurioState(now: () => day);
          await tester.pumpWidget(
            CurioScope(
              notifier: state,
              child: MaterialApp(
                theme: dark ? CurioTheme.dark : CurioTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(text),
                  ),
                  child: child!,
                ),
                home: game.open(date: day),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await tester.drag(list.first, const Offset(0, -4000));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: game.id);
          await tester.pumpWidget(const SizedBox());
          state.dispose();
        }
      });
    }
  }

  testWidgets('Signal Grid can be solved by tapping and earns the reward', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = CurioState(now: () => day);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      CurioScope(
        notifier: state,
        child: MaterialApp(
          theme: CurioTheme.light,
          home: SignalGridPage(date: day),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final puzzle = SignalPuzzle.forDay(DailyPick.dayNumber(day));
    for (var i = 0; i < 16; i++) {
      if (puzzle.givens.contains(i)) continue;
      // Empty → spark → wave.
      final taps = puzzle.solution[i] ? 1 : 2;
      for (var t = 0; t < taps; t++) {
        await tester.ensureVisible(find.byKey(Key('signal_$i')));
        await tester.tap(find.byKey(Key('signal_$i')));
        await tester.pumpAndSettle();
      }
    }
    final check = find.text('Check my grid');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(state.completedToday('signal_grid'), isTrue);
  });
}
