import 'dart:async';

import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/services/guest_session.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/auth/presentation/auth_gate.dart';
import 'package:curio/features/auth/presentation/landing_page.dart';
import 'package:curio/features/games/bridge/presentation/bridge_page.dart';
import 'package:curio/features/games/cascade/domain/cascade.dart';
import 'package:curio/features/games/cascade/presentation/cascade_page.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/loophole/domain/loophole_bank.dart';
import 'package:curio/features/games/loophole/presentation/loophole_page.dart';
import 'package:curio/features/games/odd_cluster/domain/odd_cluster.dart';
import 'package:curio/features/games/odd_cluster/presentation/odd_cluster_page.dart';
import 'package:curio/features/games/sequence/domain/sequence.dart';
import 'package:curio/features/games/sequence/presentation/sequence_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final day = DateTime(2026, 10, 8);

Future<void> phone(
  WidgetTester tester, [
  Size size = const Size(390, 844),
]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

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

/// Scrolls the page's list (which only builds what's near the screen) until
/// [finder] exists, then taps it.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    try {
      await tester.scrollUntilVisible(finder, 250, scrollable: list);
    } catch (_) {
      await tester.scrollUntilVisible(finder, -250, scrollable: list);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class NoSessionAuth extends AuthService {
  NoSessionAuth()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final changes = StreamController<AuthState>.broadcast();
  @override
  Session? get currentSession => null;
  @override
  Stream<AuthState> get authChanges => changes.stream;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Odd Cluster: solve all four groups and earn the day', (
    tester,
  ) async {
    await phone(tester);
    final state = CurioState();
    await tester.pumpWidget(play(OddClusterPage(date: day), state));
    final puzzle =
        oddClusterPuzzles[DailyPick.dayNumber(day) % oddClusterPuzzles.length];
    for (final group in puzzle.groups) {
      for (final word in group.words) {
        await tap(tester, find.byKey(Key('cluster_$word')));
      }
      await tap(tester, find.byKey(const Key('cluster_submit')));
    }
    await reveal(tester, find.text('Flawless!'));
    expect(find.text('Flawless!'), findsOneWidget);
    expect(state.completedToday('odd_cluster'), isTrue);
    expect(state.collectedFacts, contains('giant_rings'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sequence: three right answers finish the day', (tester) async {
    await phone(tester);
    final state = CurioState();
    await tester.pumpWidget(play(SequencePage(date: day), state));
    final d = DailyPick.dayNumber(day);
    for (var i = 0; i < 3; i++) {
      final round = SequenceRound(
        sequenceBank[(d * 3 + i) % sequenceBank.length],
      );
      await tester.enterText(
        find.byKey(const Key('sequence_input')),
        '${round.target}',
      );
      await tap(tester, find.byKey(const Key('sequence_guess')));
      expect(find.textContaining('Cracked it'), findsOneWidget);
      if (i < 2) await tap(tester, find.text('Next sequence'));
    }
    await reveal(tester, find.text('300 / 300'));
    expect(find.text('300 / 300'), findsOneWidget);
    expect(state.completedToday('sequence'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cascade: the true chain scores 100', (tester) async {
    await phone(tester);
    final state = CurioState();
    await tester.pumpWidget(play(CascadePage(date: day), state));
    final claim =
        cascadeClaims[DailyPick.dayNumber(day) % cascadeClaims.length];
    expect(find.text(claim.claim), findsOneWidget);
    for (final tile in claim.chain) {
      await tap(tester, find.text(tile.text));
    }
    await tap(tester, find.byKey(const Key('cascade_submit')));
    await reveal(tester, find.text('100 / 100'));
    expect(find.text('100 / 100'), findsOneWidget);
    await reveal(tester, find.text('The real chain'));
    expect(find.text('The real chain'), findsOneWidget);
    expect(state.completedToday('cascade'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bridge: hints can carry you over every bridge', (tester) async {
    await phone(tester);
    final state = CurioState();
    await tester.pumpWidget(play(BridgePage(date: day), state));
    for (var bridge = 0; bridge < 3; bridge++) {
      // Each hint places one tile; the button disappears once it's built.
      for (var hints = 0; hints < 5; hints++) {
        try {
          await tap(tester, find.byKey(const Key('bridge_hint')));
        } catch (_) {
          break;
        }
      }
      if (bridge < 2) await tap(tester, find.text('Next bridge'));
    }
    await reveal(tester, find.text('All bridges built.'));
    expect(find.text('All bridges built.'), findsOneWidget);
    expect(state.completedToday('bridge'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loophole works offline without an account', (tester) async {
    await phone(tester);
    final state = CurioState();
    await tester.pumpWidget(play(const LoopholePage(), state));
    await tester.pumpAndSettle();
    final rounds = loopholeDays[DailyPick.index(loopholeDays.length)];
    for (var r = 0; r < rounds.length; r++) {
      await tap(tester, find.text(rounds[r].tokens[rounds[r].target]).first);
      // After the last statement the result card sits above it.
      await reveal(tester, find.text(rounds[r].explanation));
      expect(find.text(rounds[r].explanation), findsOneWidget);
      if (r < rounds.length - 1) await tap(tester, find.text('Next statement'));
    }
    await reveal(tester, find.text('6 / 6'));
    expect(find.text('6 / 6'), findsOneWidget);
    expect(state.completedToday('loophole'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Practice rounds never earn XP twice', (tester) async {
    await phone(tester);
    final state = CurioState();
    final xpBefore = state.totalXp;
    await tester.pumpWidget(play(CascadePage(date: day), state));
    final claim =
        cascadeClaims[DailyPick.dayNumber(day) % cascadeClaims.length];
    for (final tile in claim.chain) {
      await tap(tester, find.text(tile.text));
    }
    await tap(tester, find.byKey(const Key('cascade_submit')));
    expect(state.totalXp, xpBefore + 90);
    await tap(tester, find.byKey(const Key('game_practice')));
    await reveal(tester, find.text('PRACTICE'));
    expect(find.text('PRACTICE'), findsOneWidget);
    expect(state.totalXp, xpBefore + 90);
  });

  testWidgets(
    'A saved guest session returns to welcome and keeps old progress',
    (tester) async {
      await phone(tester);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('curio_guest_active', true);
      await LocalProgressStore().save(
        LocalProgressStore.fresh.copyWith(childName: 'Maya'),
      );
      final auth = NoSessionAuth();
      await tester.pumpWidget(
        MaterialApp(
          theme: CurioTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: AuthGate(authService: auth),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LandingPage), findsOneWidget);
      expect(find.byKey(const Key('landing_guest')), findsNothing);
      expect((await LocalProgressStore().load()).childName, 'Maya');
      await tester.pumpWidget(const SizedBox());
      await auth.changes.close();
    },
  );

  for (final size in [
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('New games fit $size dark=$dark with large text', (
        tester,
      ) async {
        await phone(tester, size);
        final pages = <Widget>[
          OddClusterPage(date: day),
          SequencePage(date: day),
          CascadePage(date: day),
          BridgePage(date: day),
          const LoopholePage(),
        ];
        for (final page in pages) {
          await tester.pumpWidget(
            play(page, CurioState(), dark: dark, text: 1.6),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} at $size',
          );
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
