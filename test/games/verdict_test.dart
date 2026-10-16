import 'dart:math' as math;

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/common/game_rewards.dart';
import 'package:curio/features/games/verdict/domain/verdict.dart';
import 'package:curio/features/games/verdict/presentation/verdict_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// [finder] exists, then makes sure it's on screen.
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

/// Scrolls from the top of the list to the bottom so every part of it is
/// laid out at least once (overflows only show up once built).
Future<void> scrollThrough(WidgetTester tester) async {
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  position.jumpTo(0);
  await tester.pump();
  while (position.pixels < position.maxScrollExtent) {
    position.jumpTo(math.min(position.pixels + 200, position.maxScrollExtent));
    await tester.pump();
  }
}

Verdict wrongFor(VerdictItem item) =>
    Verdict.values.firstWhere((v) => v != item.verdict);

/// Answers every claim in [items] (right unless [wrong] says otherwise) and
/// opens the result.
Future<void> playSet(
  WidgetTester tester,
  List<VerdictItem> items, {
  Set<int> wrong = const {},
  void Function(int round)? check,
}) async {
  for (var i = 0; i < items.length; i++) {
    await reveal(tester, find.text(items[i].claim));
    final pick = wrong.contains(i) ? wrongFor(items[i]) : items[i].verdict;
    await tap(tester, find.byKey(Key('verdict_${pick.name}')));
    check?.call(i);
    await tap(tester, find.byKey(const Key('verdict_next')));
  }
}

Set<String> ids(List<VerdictItem> items) => {for (final i in items) i.id};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Verdict bank', () {
    test('is big, balanced and a whole number of days', () {
      expect(verdictBank.length, greaterThanOrEqualTo(36));
      expect(verdictBank.length % VerdictRules.roundsPerDay, 0);
      for (final verdict in Verdict.values) {
        expect(
          verdictBank.where((i) => i.verdict == verdict).length,
          greaterThanOrEqualTo(11),
          reason: verdict.name,
        );
      }
    });

    test('ids and claims are unique', () {
      expect(ids(verdictBank).length, verdictBank.length);
      expect(
        verdictBank.map((i) => i.claim).toSet().length,
        verdictBank.length,
      );
    });

    test('every item fits its limits and has an explanation and tag', () {
      for (final item in verdictBank) {
        expect(item.id, matches(RegExp(r'^[a-z0-9_]+$')));
        expect(
          item.claim.length,
          inInclusiveRange(10, VerdictRules.maxClaim),
          reason: item.id,
        );
        expect(
          item.evidence.length,
          inInclusiveRange(10, VerdictRules.maxEvidence),
          reason: item.id,
        );
        expect(
          item.explanation.length,
          inInclusiveRange(20, VerdictRules.maxExplanation),
          reason: item.id,
        );
        expect(item.tool.label.trim(), isNotEmpty, reason: item.id);
      }
    });

    test('copy is tidy: curly quotes, full stops, British spelling', () {
      final american = RegExp(
        r'\b(color|favorite|center|meters?|liters?|gray|mom|cookies?|candy|soccer|math|practiced)\b',
        caseSensitive: false,
      );
      for (final item in verdictBank) {
        for (final text in [item.claim, item.evidence, item.explanation]) {
          expect(text, isNot(contains("'")), reason: '${item.id}: use ’');
          expect(text, isNot(contains('"')), reason: '${item.id}: use “ ”');
          expect(text, isNot(matches(american)), reason: item.id);
          expect(text, matches(RegExp(r'[.!)]$')), reason: item.id);
          expect(text, isNot(contains('  ')), reason: item.id);
        }
      }
    });

    test('each tool fits its verdict', () {
      const backing = {
        ThinkingTool.fairTest,
        ThinkingTool.enoughToTell,
        ThinkingTool.measured,
      };
      final allowed = {
        Verdict.supports: backing,
        Verdict.against: {...backing, ThinkingTool.counterExample},
        Verdict.cantTell: {
          ThinkingTool.tooFew,
          ThinkingTool.noComparison,
          ThinkingTool.together,
          ThinkingTool.offTopic,
          ThinkingTool.opinion,
          ThinkingTool.oneStory,
          ThinkingTool.notYet,
        },
      };
      final absolute = RegExp(
        r'\b(always|never|every|nobody|only|anything|all)\b',
        caseSensitive: false,
      );
      for (final item in verdictBank) {
        expect(allowed[item.verdict], contains(item.tool), reason: item.id);
        if (item.tool == ThinkingTool.counterExample) {
          expect(item.claim, matches(absolute), reason: item.id);
        }
        if (item.tool == ThinkingTool.notYet) {
          expect(item.claim, contains('will'), reason: item.id);
        }
      }
      // The game's discovery is correlation, so it must come up often.
      expect(
        verdictBank.where((i) => i.tool == ThinkingTool.together).length,
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('Verdict daily deal', () {
    test('the first 120 days: five distinct claims, all three verdicts', () {
      for (var d = 0; d < 120; d++) {
        final set = verdictDailySet(d);
        expect(set.length, VerdictRules.roundsPerDay, reason: 'day $d');
        expect(ids(set).length, VerdictRules.roundsPerDay, reason: 'day $d');
        expect(
          set.map((i) => i.verdict).toSet(),
          Verdict.values.toSet(),
          reason: 'day $d',
        );
      }
    });

    test('is the same for a day every time, and moves on the next', () {
      for (var d = -20; d < 400; d++) {
        expect(ids(verdictDailySet(d)), ids(verdictDailySet(d)));
        expect(
          ids(verdictDailySet(d)).intersection(ids(verdictDailySet(d + 1))),
          isEmpty,
          reason: 'day $d and the next share a claim',
        );
      }
    });

    test('each cycle shows the whole bank once before repeating', () {
      final days = verdictCycleDays;
      for (var cycle = -2; cycle < 20; cycle++) {
        final seen = [
          for (var d = cycle * days; d < (cycle + 1) * days; d++)
            ...verdictDailySet(d).map((i) => i.id),
        ];
        expect(seen.length, verdictBank.length, reason: 'cycle $cycle');
        expect(seen.toSet(), ids(verdictBank), reason: 'cycle $cycle');
      }
    });

    test('practice replays past days, never today or tomorrow', () {
      for (final d in [0, 1, 8, 9, 100, 280, 281, 282, 289]) {
        final avoid = {
          ...ids(verdictDailySet(d)),
          ...ids(verdictDailySet(d + 1)),
        };
        final seen = <String>{};
        for (var round = 1; round <= 10; round++) {
          final set = verdictPracticeSet(d, round);
          expect(ids(set).length, VerdictRules.roundsPerDay);
          expect(set.map((i) => i.verdict).toSet(), Verdict.values.toSet());
          expect(ids(set).intersection(avoid), isEmpty, reason: 'day $d');
          expect(seen.add(ids(set).join(',')), isTrue, reason: 'repeat');
        }
        // Mid-cycle, yesterday shares nothing with today or tomorrow, so
        // practice simply starts there.
        final inCycle = d % verdictCycleDays;
        if (inCycle != 0 && inCycle != verdictCycleDays - 1) {
          expect(ids(verdictPracticeSet(d, 1)), ids(verdictDailySet(d - 1)));
        }
      }
    });
  });

  group('Verdict rounds', () {
    test('one verdict per claim, scored and shared without spoilers', () {
      final items = verdictDailySet(0);
      final game = VerdictGame(items);
      expect(game.next, throwsStateError, reason: 'answer first');
      expect(game.answer(items[0].verdict), isTrue);
      expect(() => game.answer(items[0].verdict), throwsStateError);
      for (var i = 1; i < items.length; i++) {
        game.next();
        expect(
          game.answer(i == 1 ? wrongFor(items[i]) : items[i].verdict),
          i != 1,
        );
      }
      expect(game.allAnswered, isTrue);
      expect(game.isLast, isTrue);
      expect(game.next, throwsStateError);
      expect(game.score, 4);
      expect(game.shareGrid, '🟩🟥🟩🟩🟩');
    });
  });

  testWidgets('Verdict: five right verdicts earn the day', (tester) async {
    await phone(tester);
    final state = CurioState();
    final xpBefore = state.totalXp;
    await tester.pumpWidget(play(VerdictPage(date: day), state));
    final items = verdictDailySet(DailyPick.dayNumber(day));
    await playSet(
      tester,
      items,
      check: (i) {
        expect(find.text(items[i].explanation), findsOneWidget);
        expect(find.text(items[i].tool.label), findsOneWidget);
        expect(find.text('Your verdict — right!'), findsOneWidget);
        expect(state.completedToday('verdict'), i == items.length - 1);
      },
    );
    await reveal(tester, find.text('5 / 5'));
    expect(find.text('5 / 5'), findsOneWidget);
    expect(state.completedToday('verdict'), isTrue);
    expect(state.totalXp, xpBefore + gameRewards['verdict']!.xp);
    expect(state.collectedFacts, contains('correlation'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verdict: a wrong pick shows the right verdict in words', (
    tester,
  ) async {
    await phone(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(play(VerdictPage(date: day), CurioState()));
    final items = verdictDailySet(DailyPick.dayNumber(day));
    for (final verdict in Verdict.values) {
      await reveal(tester, find.byKey(Key('verdict_${verdict.name}')));
      expect(
        tester.getSemantics(find.byKey(Key('verdict_${verdict.name}'))),
        isSemantics(
          label: verdict.label,
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    }
    await playSet(
      tester,
      items,
      wrong: {0},
      check: (i) {
        if (i != 0) return;
        expect(find.text('Your verdict — not this time'), findsOneWidget);
        expect(find.text('The right verdict'), findsOneWidget);
        expect(find.textContaining('Not quite'), findsOneWidget);
        expect(
          tester.getSemantics(
            find.byKey(Key('verdict_${items[0].verdict.name}')),
          ),
          isSemantics(isButton: true, isEnabled: false),
        );
      },
    );
    await reveal(tester, find.text('4 / 5'));
    expect(find.text('4 / 5'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Verdict practice: no extra XP, never tomorrow’s claims', (
    tester,
  ) async {
    await phone(tester);
    final state = CurioState();
    final xpBefore = state.totalXp;
    final xp = gameRewards['verdict']!.xp;
    await tester.pumpWidget(play(VerdictPage(date: day), state));
    final d = DailyPick.dayNumber(day);
    await playSet(tester, verdictDailySet(d));
    expect(state.totalXp, xpBefore + xp);

    final tomorrow = verdictDailySet(d + 1);
    for (var round = 1; round <= 2; round++) {
      await tap(tester, find.byKey(const Key('game_practice')));
      await reveal(tester, find.text('PRACTICE'));
      expect(find.text('PRACTICE'), findsOneWidget);
      final practice = verdictPracticeSet(d, round);
      expect(ids(practice).intersection(ids(tomorrow)), isEmpty);
      await playSet(
        tester,
        practice,
        check: (_) {
          for (final item in tomorrow) {
            expect(find.text(item.claim), findsNothing);
          }
        },
      );
      await reveal(tester, find.text('5 / 5'));
      expect(find.textContaining('XP earned'), findsNothing);
      expect(state.totalXp, xpBefore + xp, reason: 'practice $round');
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Verdict fits $size dark=$dark with large text', (
        tester,
      ) async {
        await phone(tester, size);
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(details.toString());
        addTearDown(() => FlutterError.onError = previous);
        await tester.pumpWidget(
          play(VerdictPage(date: day), CurioState(), dark: dark, text: 1.6),
        );
        await tester.pumpAndSettle();
        await scrollThrough(tester);
        final items = verdictDailySet(DailyPick.dayNumber(day));
        for (var i = 0; i < items.length; i++) {
          await reveal(tester, find.text(items[i].claim));
          final pick = i == 0 ? wrongFor(items[i]) : items[i].verdict;
          await tap(tester, find.byKey(Key('verdict_${pick.name}')));
          await scrollThrough(tester);
          await tap(tester, find.byKey(const Key('verdict_next')));
        }
        await scrollThrough(tester);
        expect(find.text('4 / 5'), findsOneWidget);

        await tester.tap(find.byTooltip('How to play'));
        await tester.pumpAndSettle();
        expect(find.text('Got it'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        FlutterError.onError = previous;
        expect(errors, isEmpty, reason: 'Verdict at $size dark=$dark');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
