import 'dart:math';

import 'package:curio/features/discoveries/domain/discovery.dart';
import 'package:curio/features/games/bridge/domain/bridge.dart';
import 'package:curio/features/games/cascade/domain/cascade.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/sequence/domain/sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daily pick', () {
    test('is stable for a date and moves on the next day', () {
      final a = DailyPick.dayNumber(DateTime(2026, 10, 8, 1));
      final b = DailyPick.dayNumber(DateTime(2026, 10, 8, 23));
      expect(a, b);
      expect(DailyPick.dayNumber(DateTime(2026, 10, 9)), a + 1);
      expect(
        DailyPick.index(5, date: DateTime(2026, 10, 8)),
        inInclusiveRange(0, 4),
      );
    });
  });

  group('Sequence', () {
    test('the classic trap: 2, 4 could be add 2 or double', () {
      expect(plausibleNextTerms([2, 4]), {6, 8});
    });

    test('every sequence in the bank opens only once it is unambiguous', () {
      for (final rule in sequenceBank) {
        final k = opensAt(rule.terms);
        expect(k, isNotNull, reason: '${rule.name} is ambiguous');
        expect(k, lessThanOrEqualTo(5), reason: rule.name);
        // Room for every paid reveal plus one hidden number.
        expect(
          rule.terms.length,
          greaterThanOrEqualTo(k! + 4),
          reason: rule.name,
        );
        for (var j = k; j < rule.terms.length; j++) {
          expect(
            plausibleNextTerms(
              rule.terms.sublist(0, j),
            ).every((p) => p == rule.terms[j]),
            isTrue,
            reason: '${rule.name} at $j',
          );
        }
      }
    });

    test('rounds reward early commitment', () {
      final early = SequenceRound(sequenceBank.first);
      expect(early.guess(early.target), isTrue);
      expect(early.points, 100);

      final late = SequenceRound(sequenceBank.first)
        ..reveal()
        ..reveal();
      expect(late.guess(late.target + 1), isFalse);
      expect(late.guess(late.target), isTrue);
      expect(late.points, 100 - 60 - 20);

      final bust = SequenceRound(sequenceBank.first)
        ..reveal()
        ..reveal()
        ..reveal();
      expect(bust.canReveal, isFalse);
      bust.guess(-1);
      expect(bust.failed, isTrue);
      expect(bust.points, 0);
    });
  });

  group('Cascade', () {
    test('every claim has 5 links, 3 side effects and 4 myths', () {
      for (final claim in cascadeClaims) {
        expect(claim.chain.length, 5);
        expect(claim.chain.every((t) => t.kind == CascadeKind.link), isTrue);
        expect(
          claim.extras.where((t) => t.kind == CascadeKind.sideEffect).length,
          3,
        );
        expect(claim.extras.where((t) => t.kind == CascadeKind.myth).length, 4);
        expect(
          claim.tiles.map((t) => t.text).toSet().length,
          12,
          reason: claim.claim,
        );
        expect(claim.tiles.every((t) => t.note.isNotEmpty), isTrue);
      }
    });

    test('scores exact links and names every other kind of slot', () {
      final claim = cascadeClaims.first;
      final perfect = CascadeGame(claim);
      claim.chain.forEach(perfect.toggle);
      perfect.submit();
      expect(perfect.score, 100);

      final mixed = CascadeGame(claim);
      mixed
        ..toggle(claim.chain[1])
        ..toggle(claim.chain[0])
        ..toggle(
          claim.extras.firstWhere((t) => t.kind == CascadeKind.sideEffect),
        )
        ..toggle(claim.extras.firstWhere((t) => t.kind == CascadeKind.myth))
        ..toggle(claim.chain[4]);
      expect(mixed.submit(), [
        SlotVerdict.misplaced,
        SlotVerdict.misplaced,
        SlotVerdict.sideEffect,
        SlotVerdict.myth,
        SlotVerdict.exact,
      ]);
      expect(mixed.score, 20);
    });
  });

  group('Bridge', () {
    test(
      '300 generated puzzles are all solvable, clean and not pre-solved',
      () {
        for (var seed = 0; seed < 300; seed++) {
          final p = BridgePuzzle.generate(
            Random(seed),
            tileCount: seed.isEven ? 4 : 5,
          );
          expect(solves(p.start, p.target, p.solution), isTrue);
          expect(
            solves(p.start, p.target, p.tiles),
            isFalse,
            reason: 'seed $seed',
          );
          final values = runBridge(p.start, p.solution);
          expect(
            values.every(
              (v) => v != null && v >= 1 && v <= BridgePuzzle.maxValue,
            ),
            isTrue,
          );
          expect(p.solutions, inInclusiveRange(1, BridgePuzzle.maxSolutions));
          expect(p.solutions, solutionCount(p.start, p.target, p.tiles));
        }
      },
    );

    test('division only where it divides evenly, and order matters', () {
      expect(const BridgeOp(BridgeOpKind.divide, 3).apply(10), isNull);
      expect(
        runBridge(3, [
          const BridgeOp(BridgeOpKind.multiply, 2),
          const BridgeOp(BridgeOpKind.add, 4),
        ]).last,
        10,
      );
      expect(
        runBridge(3, [
          const BridgeOp(BridgeOpKind.add, 4),
          const BridgeOp(BridgeOpKind.multiply, 2),
        ]).last,
        14,
      );
    });

    test('hints always finish the bridge', () {
      final round = BridgeRound(BridgePuzzle.generate(Random(7)));
      while (round.hint()) {}
      expect(round.solved, isTrue);
      expect(round.points, greaterThanOrEqualTo(20));
    });
  });

  test('every game unlocks a discovery that exists', () {
    final ids = discoveries.map((d) => d.id).toSet();
    for (final id in [
      'sample_size',
      'giant_rings',
      'triangular_numbers',
      'traffic_evaporation',
      'order_matters',
    ]) {
      expect(ids, contains(id));
    }
    expect(ids.length, discoveries.length, reason: 'discovery ids are unique');
  });
}
