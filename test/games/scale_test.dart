import 'dart:math';

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/scale/domain/scale.dart';
import 'package:curio/features/games/scale/presentation/scale_page.dart';
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

/// As in game_pages_test, plus [motion] to leave animations on.
Widget play(
  Widget page,
  CurioState state, {
  bool dark = false,
  double text = 1,
  bool motion = false,
}) => CurioScope(
  notifier: state,
  child: MaterialApp(
    theme: dark ? CurioTheme.dark : CurioTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: !motion,
        textScaler: TextScaler.linear(text),
      ),
      child: child!,
    ),
    home: page,
  ),
);

/// Scrolls the page's list (which only builds what's near the screen) until
/// [finder] exists.
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

Key keyFor(ScaleSide side) => Key('scale_${side.name}');

ScaleSide wrongFor(ScaleSide side) =>
    side == ScaleSide.left ? ScaleSide.right : ScaleSide.left;

// ─────────────── An independent reader for what the pans show ───────────────

final _readers = <(RegExp, Rational Function(Match m))>[
  (
    RegExp(r'^(\d+)/(\d+) of (\d+)$'),
    (m) => Rational(_n(m, 1), _n(m, 2)) * Rational(_n(m, 3)),
  ),
  (
    RegExp(r'^(\d+)% of (\d+)$'),
    (m) => Rational(_n(m, 1), 100) * Rational(_n(m, 2)),
  ),
  (RegExp(r'^(\d+) × (\d+)$'), (m) => Rational(_n(m, 1) * _n(m, 2))),
  (RegExp(r'^(\d+)²$'), (m) => Rational(_n(m, 1) * _n(m, 1))),
  (RegExp(r'^(\d+) − (\d+)$'), (m) => Rational(_n(m, 1) - _n(m, 2))),
  (RegExp(r'^(\d+) ÷ (\d+)$'), (m) => Rational(_n(m, 1), _n(m, 2))),
  (RegExp(r'^(\d+)/(\d+)$'), (m) => Rational(_n(m, 1), _n(m, 2))),
  (RegExp(r'^(\d+)%$'), (m) => Rational(_n(m, 1), 100)),
  (
    RegExp(r'^(\d+)\.(\d+)$'),
    (m) => Rational(int.parse('${m[1]}${m[2]}'), pow(10, m[2]!.length).toInt()),
  ),
  (RegExp(r'^(\d+)$'), (m) => Rational(_n(m, 1))),
];

int _n(Match m, int group) => int.parse(m[group]!);

Rational read(String text) {
  for (final (pattern, value) in _readers) {
    final m = pattern.firstMatch(text);
    if (m != null) return value(m);
  }
  fail('Unreadable amount: "$text"');
}

/// Each kind looks the way the rules say it should.
void expectWellFormed(Quantity q) {
  final label = q.label;
  switch (q.kind) {
    case QuantityKind.fraction:
      final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(label);
      expect(m, isNotNull, reason: label);
      expect(_n(m!, 2), inInclusiveRange(2, 12), reason: label);
      expect(_n(m, 1), inInclusiveRange(1, _n(m, 2) - 1), reason: 'proper');
    case QuantityKind.decimal:
      expect(label, matches(RegExp(r'^0\.\d{1,2}$')));
      expect(label.endsWith('0'), isFalse, reason: '$label is written short');
    case QuantityKind.percent:
      final m = RegExp(r'^(\d+)%$').firstMatch(label);
      expect(m, isNotNull, reason: label);
      expect(_n(m!, 1) % 5, 0, reason: label);
      expect(_n(m, 1), inInclusiveRange(5, 95));
    case QuantityKind.whole:
      expect(label, matches(RegExp(r'^\d+$')));
    case QuantityKind.expression:
      expect(
        label,
        matches(RegExp(r'^(\d+ [×−÷] \d+|\d+²|\d+/\d+ of \d+|\d+% of \d+)$')),
      );
      expect(q.value.isWhole, isTrue, reason: '$label has a whole answer');
      final division = RegExp(r'^(\d+) ÷ (\d+)$').firstMatch(label);
      if (division != null) {
        expect(_n(division, 1) % _n(division, 2), 0, reason: label);
      }
  }
}

/// The explanation names the right answer, and its two numbers really are
/// the two amounts written in one shared form.
void expectExplains(ScaleRound round) {
  final text = round.explanation;
  final m = RegExp(
    r'^(.+) · (.+) → (left is more|right is more|they’re equal)$',
  ).firstMatch(text);
  expect(m, isNotNull, reason: text);
  expect(
    {
      'left is more': ScaleSide.left,
      'right is more': ScaleSide.right,
      'they’re equal': ScaleSide.equal,
    }[m![3]],
    round.answer,
    reason: text,
  );
  String formOf(String working, Quantity q) {
    if (working == q.label) return working;
    expect(working, startsWith('${q.label} = '), reason: text);
    return working.substring(q.label.length + 3);
  }

  final left = formOf(m[1]!, round.left), right = formOf(m[2]!, round.right);
  expect(read(left), round.leftValue, reason: text);
  expect(read(right), round.rightValue, reason: text);

  // Same form: so the comparison is plain from the digits alone.
  final (int, int) compared;
  if (left.contains('/') || right.contains('/')) {
    final [ln, ld] = left.split('/');
    final [rn, rd] = right.split('/');
    expect(ld, rd, reason: 'common denominator in $text');
    compared = (int.parse(ln), int.parse(rn));
  } else {
    final lp = left.contains('.') ? left.split('.')[1].length : 0;
    final rp = right.contains('.') ? right.split('.')[1].length : 0;
    expect(lp, rp, reason: 'same decimal places in $text');
    compared = (
      int.parse(left.replaceAll('.', '')),
      int.parse(right.replaceAll('.', '')),
    );
  }
  final digitsSay = switch (compared.$1.compareTo(compared.$2)) {
    > 0 => ScaleSide.left,
    < 0 => ScaleSide.right,
    _ => ScaleSide.equal,
  };
  expect(digitsSay, round.answer, reason: text);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Rational', () {
    test('normalises to lowest terms with a positive denominator', () {
      final r = Rational(6, 8);
      expect((r.numerator, r.denominator), (3, 4));
      expect(Rational(2, -4), Rational(-1, 2));
      expect(Rational(-2, -4), Rational(1, 2));
      expect(Rational(0, 7), Rational.zero);
      expect(Rational(0, 7).denominator, 1);
      expect(Rational(12, 4).isWhole, isTrue);
      expect(Rational(6, 8).hashCode, Rational(3, 4).hashCode);
      expect(() => Rational(1, 0), throwsArgumentError);
    });

    test('compares exactly by cross-multiplying', () {
      expect(Rational(3, 4) > Rational(5, 8), isTrue);
      expect(Rational(1, 3) < Rational(35, 100), isTrue);
      expect(Rational(2, 5).compareTo(Rational(40, 100)), 0);
      expect(Rational(2, 3) >= Rational(4, 6), isTrue);
      expect(Rational(-1, 2) < Rational.zero, isTrue);
      // 0.1 + 0.2 really is 0.3 here.
      expect(Rational(1, 10) + Rational(2, 10), Rational(3, 10));
      final sorted = [Rational(7, 8), Rational(1, 3), Rational(1, 2)]..sort();
      expect(sorted, [Rational(1, 3), Rational(1, 2), Rational(7, 8)]);
    });

    test('does arithmetic', () {
      expect(Rational(1, 2) + Rational(1, 3), Rational(5, 6));
      expect(Rational(3, 4) - Rational(1, 4), Rational(1, 2));
      expect(Rational(2, 3) * Rational(3, 4), Rational(1, 2));
      expect(Rational(1, 2) / Rational(1, 4), Rational(2));
      expect(-Rational(1, 2), Rational(-1, 2));
      expect(Rational(-3, 5).abs(), Rational(3, 5));
      expect(() => Rational(1, 2) / Rational.zero, throwsArgumentError);
    });

    test('formats as fractions and exact decimals', () {
      expect(Rational(3, 4).toFractionString(), '3/4');
      expect(Rational(4, 2).toFractionString(), '2');
      expect(Rational(5, 8).toDecimalString(), '0.625');
      expect(Rational(3, 4).toDecimalString(places: 3), '0.750');
      expect(Rational(7).toDecimalString(), '7');
      expect(Rational(1, 20).toDecimalString(), '0.05');
      expect(Rational(-1, 4).toDecimalString(), '-0.25');
      expect(Rational(1, 3).decimalPlaces, isNull);
      expect(Rational(3, 8).decimalPlaces, 3);
      expect(Rational(7, 20).decimalPlaces, 2);
      expect(() => Rational(1, 3).toDecimalString(), throwsStateError);
    });

    test('writes two values in one shared form', () {
      expect(sharedForms(Rational(3, 4), Rational(5, 8)), ('0.750', '0.625'));
      expect(sharedForms(Rational(1, 3), Rational(1, 4)), ('4/12', '3/12'));
      expect(sharedForms(Rational(56), Rational(36)), ('56', '36'));
      expect(sharedForms(Rational(7, 20), Rational(1, 3)), ('21/60', '20/60'));
      expect(relativeGap(Rational(9), Rational(10)), Rational(1, 10));
      expect(relativeGap(Rational(1, 2), Rational(2, 4)), Rational.zero);
    });
  });

  group('Rounds', () {
    ScaleRound round(Quantity l, Quantity r) =>
        ScaleRound(left: l, right: r, tier: ScaleTier.warmUp);

    test('explanations show both values in a shared form', () {
      expect(
        round(Quantity.fraction(3, 4), Quantity.fraction(5, 8)).explanation,
        '3/4 = 0.750 · 5/8 = 0.625 → left is more',
      );
      expect(
        round(Quantity.fraction(1, 4), Quantity.fraction(1, 3)).explanation,
        '1/4 = 3/12 · 1/3 = 4/12 → right is more',
      );
      expect(
        round(Quantity.fraction(2, 5), Quantity.percent(40)).explanation,
        '2/5 = 0.4 · 40% = 0.4 → they’re equal',
      );
      expect(
        round(Quantity.fractionOf(3, 4, 8), Quantity.whole(6)).explanation,
        '3/4 of 8 = 6 · 6 → they’re equal',
      );
      expect(
        round(Quantity.decimal(40), Quantity.decimal(35)).explanation,
        '0.4 = 0.40 · 0.35 → left is more',
      );
      expect(
        round(Quantity.product(7, 8), Quantity.square(6)).explanation,
        '7 × 8 = 56 · 6² = 36 → left is more',
      );
      expect(
        round(Quantity.quotient(144, 12), Quantity.difference(100, 37)).answer,
        ScaleSide.right,
      );
      expect(
        round(
          Quantity.fraction(3, 4),
          Quantity.fraction(5, 8),
        ).spokenExplanation,
        'three quarters is 0.750, and five eighths is 0.625, so left is more.',
      );
      expect(() => Quantity.quotient(10, 3), throwsArgumentError);
    });

    test('a game records answers, scores and shares without spoilers', () {
      final game = ScaleGame.forDay(42);
      for (var i = 0; i < ScaleGame.roundCount; i++) {
        final answer = game.round.answer;
        final pick = i.isEven ? answer : wrongFor(answer);
        expect(game.answer(pick), i.isEven);
        expect(() => game.answer(pick), throwsStateError);
        expect(game.correctAt(i), i.isEven);
        if (!game.isLast) game.next();
      }
      expect(game.finished, isTrue);
      expect(game.score, 4);
      expect(game.shareGrid, '🟩🟥🟩🟥🟩🟥🟩🟥');
      expect(game.next, throwsStateError);
      expect(ScaleGame.forDay(42).next, throwsStateError);
    });

    test('days are stable, and practice never replays a daily set', () {
      List<String> labels(ScaleGame g) => [
        for (final r in g.rounds) ...[r.leftLabel, r.rightLabel],
      ];
      expect(labels(ScaleGame.forDay(5)), labels(ScaleGame.forDay(5)));
      expect(labels(ScaleGame.forDay(5)), isNot(labels(ScaleGame.forDay(6))));
      expect(
        labels(ScaleGame.forDay(5, practice: 1)),
        isNot(labels(ScaleGame.forDay(5))),
      );
      final dailySeeds = {for (var d = 0; d < 400; d++) scaleSeed(d)};
      for (var d = 0; d < 400; d++) {
        for (final p in [1, 2, 999, 1000, 5000]) {
          expect(dailySeeds, isNot(contains(scaleSeed(d, practice: p))));
        }
      }
    });
  });

  group('Generator, over 300 days and 100 practice sets', () {
    final sets = [
      for (var d = 0; d < 300; d++) ScaleGame.forDay(d).rounds,
      for (var p = 1; p <= 100; p++) ScaleGame.forDay(280, practice: p).rounds,
    ];

    test('eight rounds ramping warm-up → mixed forms → close calls', () {
      for (final rounds in sets) {
        expect(rounds.length, 8);
        for (var i = 0; i < 8; i++) {
          final r = rounds[i];
          final gap = relativeGap(r.leftValue, r.rightValue);
          if (i < 3) {
            expect(r.tier, ScaleTier.warmUp);
            expect(r.left.kind, r.right.kind, reason: '$r: same kind');
            expect(gap >= Rational(1, 4), isTrue, reason: '$r: clear gap');
          } else if (i < 6) {
            expect(r.tier, ScaleTier.mixed);
            expect(r.left.kind, isNot(r.right.kind), reason: '$r: mixed');
            if (r.answer != ScaleSide.equal) {
              expect(gap > Rational(1, 10), isTrue, reason: '$r: not close');
            }
          } else {
            expect(r.tier, ScaleTier.close);
            expect(gap <= Rational(1, 10), isTrue, reason: '$r: close call');
          }
        }
      }
    });

    test('one or two equal rounds, never in the warm-up', () {
      final counts = <int, int>{};
      final positions = <int, int>{};
      for (final rounds in sets) {
        final equal = [
          for (var i = 0; i < 8; i++)
            if (rounds[i].answer == ScaleSide.equal) i,
        ];
        expect(equal.length, inInclusiveRange(1, 2), reason: '$rounds');
        expect(equal.every((i) => i >= 3), isTrue);
        counts[equal.length] = (counts[equal.length] ?? 0) + 1;
        for (final i in equal) {
          positions[i] = (positions[i] ?? 0) + 1;
        }
      }
      expect(counts[1]!, greaterThan(sets.length ~/ 4));
      expect(counts[2]!, greaterThan(sets.length ~/ 4));
      for (var i = 3; i < 8; i++) {
        expect(positions[i] ?? 0, greaterThan(20), reason: 'round ${i + 1}');
      }
    });

    test('values are exact, in range, readable and never repeated', () {
      for (final rounds in sets) {
        final seen = <Rational>{};
        final labels = <String>{};
        final pairs = <String>{};
        for (final r in rounds) {
          expect(r.leftLabel, isNot(r.rightLabel));
          for (final q in [r.left, r.right]) {
            expectWellFormed(q);
            expect(read(q.label), q.value, reason: q.label);
            expect(q.value > Rational.zero, isTrue, reason: q.label);
            expect(q.value < Rational(1000), isTrue, reason: q.label);
            expect(labels.add(q.label), isTrue, reason: '${q.label} twice');
          }
          final values = {r.leftValue, r.rightValue};
          expect(seen.intersection(values), isEmpty, reason: '$r repeats');
          seen.addAll(values);
          final key = ([r.leftValue, r.rightValue]..sort()).join('|');
          expect(pairs.add(key), isTrue, reason: 'duplicate pair $r');
        }
      }
    });

    test(
      'every kind and every sum shows up; unreduced fractions now and then',
      () {
        final kinds = <QuantityKind>{};
        final forms = <String>{};
        var fractions = 0, unreduced = 0;
        for (final rounds in sets) {
          for (final r in rounds) {
            for (final q in [r.left, r.right]) {
              kinds.add(q.kind);
              if (q.kind == QuantityKind.fraction) {
                fractions++;
                if (q.label != q.value.toFractionString()) unreduced++;
              }
              for (final (name, pattern) in [
                ('×', ' × '),
                ('²', '²'),
                ('−', ' − '),
                ('÷', ' ÷ '),
                ('% of', '% of '),
              ]) {
                if (q.label.contains(pattern)) forms.add(name);
              }
              if (RegExp(r'^\d+/\d+ of ').hasMatch(q.label)) forms.add('of');
            }
          }
        }
        expect(kinds, QuantityKind.values.toSet());
        expect(forms, {'×', '²', '−', '÷', '% of', 'of'});
        expect(unreduced, greaterThan(20));
        expect(unreduced / fractions, lessThan(.3));
      },
    );

    test('the bigger side is left as often as right, every day', () {
      var left = 0, unequal = 0;
      final leftAt = List.filled(8, 0), unequalAt = List.filled(8, 0);
      for (final rounds in sets) {
        final answers = rounds.map((r) => r.answer).toList();
        final l = answers.where((a) => a == ScaleSide.left).length;
        final r = answers.where((a) => a == ScaleSide.right).length;
        expect((l - r).abs(), lessThanOrEqualTo(1), reason: '$answers');
        // No blind strategy beats half marks.
        for (final side in ScaleSide.values) {
          expect(answers.where((a) => a == side).length, lessThanOrEqualTo(4));
        }
        left += l;
        unequal += l + r;
        for (var i = 0; i < 8; i++) {
          if (answers[i] == ScaleSide.equal) continue;
          unequalAt[i]++;
          if (answers[i] == ScaleSide.left) leftAt[i]++;
        }
      }
      expect(left / unequal, inInclusiveRange(.45, .55));
      for (var i = 0; i < 8; i++) {
        expect(
          leftAt[i] / unequalAt[i],
          inInclusiveRange(.3, .7),
          reason: 'round ${i + 1}',
        );
      }
    });

    test('the explanation always agrees with the answer', () {
      for (final rounds in sets) {
        rounds.forEach(expectExplains);
      }
    });
  });

  group('Page', () {
    testWidgets('eight right answers finish the day and earn it once', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      final xpBefore = state.totalXp;
      await tester.pumpWidget(play(ScalePage(date: day), state));
      final rounds = ScaleGame.forDay(DailyPick.dayNumber(day)).rounds;
      for (var i = 0; i < rounds.length; i++) {
        await tap(tester, find.byKey(keyFor(rounds[i].answer)));
        await reveal(tester, find.byKey(const Key('scale_explanation')));
        Finder working(String text) => find.descendant(
          of: find.byKey(const Key('scale_explanation')),
          matching: find.text(text),
        );
        expect(working(rounds[i].leftWorking), findsOneWidget);
        expect(working(rounds[i].rightWorking), findsOneWidget);
        expect(working('→ ${rounds[i].verdict}'), findsOneWidget);
        await tap(tester, find.byKey(const Key('scale_next')));
      }
      await reveal(tester, find.text('8 / 8'));
      expect(find.text('8 / 8'), findsOneWidget);
      expect(find.text('Perfectly balanced!'), findsOneWidget);
      expect(state.completedToday('scale'), isTrue);
      expect(state.totalXp, xpBefore + 80);
      expect(state.collectedFacts, contains('equal_fractions'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wrong answer says so, then tips to the true side', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(play(ScalePage(date: day), CurioState()));
      final round = ScaleGame.forDay(DailyPick.dayNumber(day)).rounds.first;
      await tap(tester, find.byKey(keyFor(wrongFor(round.answer))));
      expect(find.textContaining('Not quite'), findsOneWidget);
      expect(find.textContaining('More', findRichText: true), findsOneWidget);
      expect(find.textContaining('Less', findRichText: true), findsOneWidget);
      expect(find.byKey(const Key('scale_equal')), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('a practice round earns no extra XP', (tester) async {
      await phone(tester);
      final state = CurioState();
      final xpBefore = state.totalXp;
      await tester.pumpWidget(play(ScalePage(date: day), state));
      final d = DailyPick.dayNumber(day);
      for (final round in ScaleGame.forDay(d).rounds) {
        await tap(tester, find.byKey(keyFor(round.answer)));
        await tap(tester, find.byKey(const Key('scale_next')));
      }
      expect(state.totalXp, xpBefore + 80);

      await tap(tester, find.byKey(const Key('game_practice')));
      await reveal(tester, find.text('PRACTICE'));
      expect(find.text('PRACTICE'), findsOneWidget);
      for (final round in ScaleGame.forDay(d, practice: 1).rounds) {
        await tap(tester, find.byKey(keyFor(round.answer)));
        await tap(tester, find.byKey(const Key('scale_next')));
      }
      await reveal(tester, find.text('8 / 8'));
      expect(find.textContaining('XP earned'), findsNothing);
      expect(state.totalXp, xpBefore + 80);
      expect(tester.takeException(), isNull);
    });

    double hang(WidgetTester tester, String side) => tester
        .widget<Transform>(find.byKey(ValueKey('scale_${side}_hang')))
        .transform
        .getTranslation()
        .y;

    testWidgets('reduce motion: no sway, and the tip lands at once', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(play(ScalePage(date: day), CurioState()));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'no sway');
      final round = ScaleGame.forDay(DailyPick.dayNumber(day)).rounds.first;
      await tester.tap(find.byKey(keyFor(round.answer)));
      await tester.pump();
      final first = hang(tester, 'left');
      await tester.pumpAndSettle();
      expect(hang(tester, 'left'), first);
      final heavy = round.answer == ScaleSide.left ? 'left' : 'right';
      final light = round.answer == ScaleSide.left ? 'right' : 'left';
      expect(hang(tester, heavy), greaterThan(0), reason: 'heavier side sinks');
      expect(hang(tester, light), lessThan(0));
    });

    testWidgets('with motion: sways while waiting, tips, then rests', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(
        play(ScalePage(date: day), CurioState(), motion: true),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'idle sway');
      final round = ScaleGame.forDay(DailyPick.dayNumber(day)).rounds.first;
      await tester.tap(find.byKey(keyFor(round.answer)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final early = hang(tester, 'left');
      await tester.pump(const Duration(seconds: 3));
      final rested = hang(tester, 'left');
      expect(early, isNot(rested), reason: 'it animates');
      expect(
        rested,
        round.answer == ScaleSide.left ? greaterThan(0) : lessThan(0),
      );
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'at rest');
      await tester.pumpWidget(const SizedBox());
    });

    for (final size in [
      const Size(375, 667),
      const Size(812, 375),
      const Size(1280, 900),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('fits $size dark=$dark with large text', (tester) async {
          await phone(tester, size);
          await tester.pumpWidget(
            play(ScalePage(date: day), CurioState(), dark: dark, text: 1.6),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'start');
          final rounds = ScaleGame.forDay(DailyPick.dayNumber(day)).rounds;
          for (var i = 0; i < rounds.length; i++) {
            final pick = i == 2
                ? ScaleSide.equal
                : i.isOdd
                ? wrongFor(rounds[i].answer)
                : rounds[i].answer;
            await tap(tester, find.byKey(keyFor(pick)));
            await reveal(tester, find.byKey(const Key('scale_next')));
            expect(tester.takeException(), isNull, reason: 'round ${i + 1}');
            await tap(tester, find.byKey(const Key('scale_next')));
          }
          await reveal(tester, find.textContaining('8.  '));
          expect(tester.takeException(), isNull, reason: 'result');
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
