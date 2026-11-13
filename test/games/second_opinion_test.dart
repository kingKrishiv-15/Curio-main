import 'dart:convert';
import 'dart:io';

import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/second_opinion/data/demo_puzzle.dart';
import 'package:curio/features/games/second_opinion/data/second_opinion_gateways.dart';
import 'package:curio/features/games/second_opinion/domain/second_opinion.dart';
import 'package:curio/features/games/second_opinion/presentation/second_opinion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _flaws = {
  'fabricated',
  'confident_guess',
  'out_of_date',
  'scope_drift',
  'cherry_picked',
};

/// The content rules, checked again in Dart so `flutter test` guards them
/// (tool/second_opinion/build.js enforces the same rules when it builds).
void _checkDay(Map<String, dynamic> day, String label) {
  final public = day['public'] as Map<String, dynamic>;
  final answer = day['answer'] as Map<String, dynamic>;
  final words = (public['brief'] as String).trim().split(RegExp(r'\s+')).length;
  expect(words, inInclusiveRange(150, 250), reason: '$label brief length');
  final claims = [for (final c in public['claims'] as List) c['id'] as String];
  expect(claims.length, 8, reason: label);
  expect(
    [for (final p in public['probes'] as List) p['id']],
    [for (final p in Probe.values) p.id],
    reason: '$label has the six fixed probes',
  );
  final flawed = answer['flawed'] as Map<String, dynamic>;
  expect(flawed.length, 3, reason: '$label has exactly three flawed claims');
  expect(claims, containsAll(flawed.keys), reason: label);
  final types = [for (final f in flawed.values) f['type'] as String];
  expect(types.every(_flaws.contains), isTrue, reason: label);
  expect(types.toSet().length, greaterThan(1), reason: '$label varies types');
  final exposes = answer['exposes'] as Map<String, dynamic>;
  expect(exposes.length, inInclusiveRange(1, 2), reason: '$label probes');
  expect((answer['replies'] as Map).keys.toSet(), {
    for (final p in Probe.values) p.id,
  }, reason: label);
  // Nothing about the answer may sit in the part the client receives.
  final leaked = jsonEncode(public);
  for (final key in ['flawed', 'exposes', 'replies', 'why']) {
    expect(leaked.contains('"$key"'), isFalse, reason: '$label leaks $key');
  }
  expect(jsonEncode(day).contains(RegExp('[–—]')), isFalse);
}

Widget _app(Widget page, CurioState state) => CurioScope(
  notifier: state,
  child: MaterialApp(theme: CurioTheme.dark, home: page),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    try {
      await tester.scrollUntilVisible(finder, 200, scrollable: list);
    } catch (_) {
      await tester.scrollUntilVisible(finder, -200, scrollable: list);
    }
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemoSecondOpinionGateway.reset();
  });

  group('Scoring', () {
    test('400 a hit, 150 off a false flag, probes and time on top', () {
      final s = scoreSecondOpinion(
        hits: 2,
        falseFlags: 1,
        goodProbes: 1,
        secondsLeft: 108,
      );
      expect((s.base, s.penalty, s.probes, s.time), (800, 150, 200, 108));
      expect(s.score, 958);
    });

    test('probe bonus is 200 for the first good probe, 100 for each more', () {
      int bonus(int good) => scoreSecondOpinion(
        hits: 0,
        falseFlags: 0,
        goodProbes: good,
        secondsLeft: 0,
      ).probes;
      expect([bonus(0), bonus(1), bonus(2), bonus(3)], [0, 200, 300, 400]);
    });

    test('time is capped at 300 and the total never goes below zero', () {
      expect(
        scoreSecondOpinion(
          hits: 3,
          falseFlags: 0,
          goodProbes: 2,
          secondsLeft: 999,
        ).score,
        1200 + 300 + 300,
      );
      expect(
        scoreSecondOpinion(
          hits: 0,
          falseFlags: 3,
          goodProbes: 0,
          secondsLeft: 0,
        ).score,
        0,
      );
    });
  });

  test('the share text is the agreed format and gives nothing away', () {
    final verdict = SecondOpinionVerdict.fromJson({
      'chosen': ['c1', 'c2', 'c4'],
      'flawed': {
        'c1': {'type': 'fabricated', 'probe': 'source', 'why': 'w'},
        'c2': {'type': 'out_of_date', 'probe': 'current', 'why': 'w'},
        'c3': {'type': 'cherry_picked', 'probe': 'counter', 'why': 'w'},
      },
      'probes': ['example', 'source'],
      'good_probes': 1,
      'seconds_left': 108,
      'score': 958,
      'breakdown': {'base': 800, 'penalty': 150, 'probes': 200, 'time': 108},
    });
    final share = secondOpinionShare(142, verdict);
    expect(
      share,
      'Second Opinion #142\n🟩🟩⬜  2/3   🔍 1 good probe   1:48 left',
    );
    expect(share.contains('c1'), isFalse);
    expect(
      verdict.lesson(verdict.flawed[2]),
      'You asked "Give me a specific example.". This claim was cherry-picked, '
      'and "What is the strongest argument against this?" would have exposed it.',
    );
  });

  group('Content', () {
    final days =
        (jsonDecode(
                  File(
                    'test/fixtures/second_opinion_days.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();

    test('there are at least 30 days and no topic repeats', () {
      expect(days.length, greaterThanOrEqualTo(30));
      final topics = [for (final d in days) d['public']['topic']];
      expect(topics.toSet().length, topics.length);
    });

    test('every day keeps the rules', () {
      for (var i = 0; i < days.length; i++) {
        _checkDay(days[i], 'day ${i + 1}');
      }
    });

    test('all five failure types are used across the set', () {
      final used = {
        for (final d in days)
          for (final f in (d['answer']['flawed'] as Map).values) f['type'],
      };
      expect(used, _flaws);
    });

    test('the demo puzzle keeps the same rules', () {
      _checkDay(
        jsonDecode(demoSecondOpinionJson) as Map<String, dynamic>,
        'demo',
      );
    });
  });

  test('Second Opinion is the anchor and the set is anchor plus one per '
      'section', () {
    final set = todaysSet(date: DateTime(2026, 11, 13));
    expect(set.anchor.id, anchorGameId);
    expect(set.others.map((g) => g.section), LearningSection.values);
    expect(set.others.length + 1, dailyGameCount);
    expect(set.others.map((g) => g.id), isNot(contains(anchorGameId)));
  });

  group('Demo gateway', () {
    test('the clock runs from the first open and never resets', () async {
      var now = DateTime(2026, 11, 13, 9);
      final gateway = DemoSecondOpinionGateway(now: () => now);
      expect((await gateway.open()).secondsLeft, 300);
      now = now.add(const Duration(seconds: 70));
      expect((await gateway.open()).secondsLeft, 230);
      now = now.add(const Duration(minutes: 10));
      expect((await gateway.open()).secondsLeft, 0);
    });

    test(
      'three probes at most, one submission, graded like the server',
      () async {
        var now = DateTime(2026, 11, 13, 9);
        final gateway = DemoSecondOpinionGateway(now: () => now);
        await gateway.open();
        await gateway.ask(Probe.example);
        await gateway.ask(Probe.source);
        await gateway.ask(Probe.scope);
        expect(() => gateway.ask(Probe.current), throwsStateError);
        now = now.add(const Duration(seconds: 192));
        final verdict = await gateway.submit({'c3', 'c5', 'c1'});
        expect(verdict.hits, 2);
        expect(verdict.goodProbes, 1);
        expect(verdict.secondsLeft, 108);
        expect(verdict.score, 800 - 150 + 200 + 108);
        final again = await gateway.submit({'c3', 'c5', 'c6'});
        expect(again.score, verdict.score, reason: 'one submission only');
      },
    );

    test('submitting after the clock runs out earns no time bonus', () async {
      var now = DateTime(2026, 11, 13, 9);
      final gateway = DemoSecondOpinionGateway(now: () => now);
      await gateway.open();
      now = now.add(const Duration(minutes: 6));
      final verdict = await gateway.submit({'c3', 'c5', 'c6'});
      expect(verdict.timeBonus, 0);
      expect(verdict.score, 1200);
    });
  });

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('a full round at $size: brief, probes, flags, debrief', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final state = CurioState();
      await tester.pumpWidget(
        _app(SecondOpinionPage(gateway: DemoSecondOpinionGateway()), state),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('so_brief')), findsOneWidget);
      expect(find.byKey(const Key('so_timer')), findsOneWidget);
      expect(find.textContaining('We asked an AI about'), findsOneWidget);

      for (final probe in [Probe.example, Probe.source, Probe.current]) {
        await _tap(tester, find.byKey(Key('so_probe_${probe.id}')));
        expect(find.byKey(Key('so_reply_${probe.id}')), findsOneWidget);
      }
      expect(
        find.byKey(const Key('so_probe_unsure')),
        findsNothing,
        reason: 'no fourth probe',
      );

      await _tap(tester, find.byKey(const Key('so_to_verdict')));
      expect(find.byKey(const Key('so_verdict')), findsOneWidget);
      expect(
        find.textContaining('The Great Wall of China is not one wall'),
        findsNothing,
        reason: 'the brief is gone in the verdict phase',
      );
      for (final id in ['c3', 'c5', 'c6']) {
        await _tap(tester, find.byKey(Key('so_claim_$id')));
      }
      await _tap(tester, find.byKey(const Key('so_submit')));

      expect(find.byKey(const Key('so_debrief')), findsOneWidget);
      expect(find.text('You caught all three'), findsOneWidget);
      expect(find.textContaining('Second Opinion #0'), findsOneWidget);
      expect(state.completedToday('second_opinion'), isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('so_flaw_c6')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Fabricated.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('a failed load says so and offers a retry', (tester) async {
    await tester.pumpWidget(
      _app(SecondOpinionPage(gateway: _Broken()), CurioState()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('so_error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Broken implements SecondOpinionGateway {
  @override
  Future<SecondOpinionSession> open() async =>
      throw const SecondOpinionUnavailable(
        'Today\'s Second Opinion has not been published yet.',
      );

  @override
  Future<String> ask(Probe probe) async => '';

  @override
  Future<SecondOpinionVerdict> submit(Set<String> claimIds) =>
      throw UnimplementedError();
}
