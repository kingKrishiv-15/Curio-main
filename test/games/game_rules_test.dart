import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:curio/features/discoveries/domain/discovery.dart';
import 'package:curio/features/games/bridge/domain/bridge.dart';
import 'package:curio/features/games/cascade/domain/cascade.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/loophole/domain/loophole_bank.dart';
import 'package:curio/features/games/loophole/domain/loophole_local.dart';
import 'package:curio/features/games/odd_cluster/domain/odd_cluster.dart';
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

  group('Odd Cluster', () {
    test('every puzzle has 16 distinct tiles in four tiered groups', () {
      for (final puzzle in oddClusterPuzzles) {
        expect(puzzle.groups.length, 4);
        expect(puzzle.words.toSet().length, 16, reason: puzzle.words.join(','));
        expect(puzzle.groups.map((g) => g.tier).toSet(), {0, 1, 2, 3});
        for (final g in puzzle.groups) {
          expect(g.words.length, 4);
          expect(g.explanation, isNotEmpty);
        }
      }
    });

    test('the number puzzle: each rule fits exactly its own four tiles', () {
      final puzzle = oddClusterPuzzles.firstWhere(
        (p) => p.groups.any((g) => g.title == 'Palindromes in binary'),
      );
      final board = puzzle.words.map(int.parse).toList();
      bool prime(int n) =>
          n > 1 &&
          [for (var d = 2; d * d <= n; d++) d].every((d) => n % d != 0);
      bool square(int n) => pow(sqrt(n).round(), 2) == n;
      bool cube(int n) => pow(pow(n, 1 / 3).round(), 3) == n;
      bool binaryPalindrome(int n) {
        final b = n.toRadixString(2);
        return b == b.split('').reversed.join();
      }

      final rules = {
        'Prime numbers': prime,
        'Square numbers': square,
        'Cube numbers': cube,
        'Palindromes in binary': binaryPalindrome,
      };
      for (final MapEntry(key: title, value: rule) in rules.entries) {
        final group = puzzle.groups.firstWhere((g) => g.title == title);
        expect(
          board.where(rule).toSet(),
          group.words.map(int.parse).toSet(),
          reason: '$title must match only its own tiles',
        );
      }
    });

    test('one away, repeats, four strikes and a win', () {
      final puzzle = oddClusterPuzzles.first;
      final easy = puzzle.groups[0].words;
      final other = puzzle.groups[1].words;

      final game = OddClusterGame(puzzle, seed: 1);
      final nearMiss = {...easy.take(3), other.first};
      expect(game.guess(nearMiss), ClusterVerdict.oneAway);
      expect(game.guess(nearMiss), ClusterVerdict.repeat);
      expect(game.mistakes, 1, reason: 'a repeat costs nothing');
      expect(game.guess(easy.toSet()), ClusterVerdict.found);
      expect(game.board.length, 12);

      final loser = OddClusterGame(puzzle);
      final mixes = [
        {easy[0], easy[1], other[0], other[1]},
        {easy[0], easy[2], other[0], other[2]},
        {easy[0], easy[3], other[0], other[3]},
        {easy[1], easy[2], other[1], other[2]},
      ];
      for (final mix in mixes) {
        expect(loser.guess(mix), ClusterVerdict.wrong);
      }
      expect(loser.lost, isTrue);
      expect(loser.revealed.length, 4);

      final winner = OddClusterGame(puzzle);
      for (final g in puzzle.groups) {
        winner.guess(g.words.toSet());
      }
      expect(winner.won, isTrue);
      expect(winner.shareGrid().split('\n').length, 4);
      expect(winner.shareGrid(), isNot(contains('PENGUIN')));
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

  group('Loophole offline', () {
    test('matches the statements seeded on the server', () {
      final sql = File('supabase/seed_loophole.sql').readAsStringSync();
      final json = RegExp(
        r'\$json\$(.*)\$json\$',
        dotAll: true,
      ).firstMatch(sql)!.group(1)!;
      final days = jsonDecode(json) as List;
      expect(loopholeDays.length, days.length);
      for (var d = 0; d < days.length; d++) {
        final public = days[d]['public']['rounds'] as List;
        final answer = days[d]['answer']['rounds'] as List;
        for (var r = 0; r < public.length; r++) {
          final local = loopholeDays[d][r];
          expect(local.statement, public[r]['statement']);
          expect(local.tokens, List<String>.from(public[r]['tokens']));
          expect(local.target, answer[r]['target']);
          expect(local.explanation, answer[r]['explanation']);
          expect(local.target, lessThan(local.tokens.length));
        }
      }
    });

    test('scores like the server: 2 first try, 1 second, 0 missed', () {
      final game = LoopholeLocalGame(loopholeDays.first);
      final rounds = loopholeDays.first;
      int wrong(int r) => rounds[r].target == 0 ? 1 : 0;

      expect(game.submit(round: 0, tokenIndex: rounds[0].target)['marks'], [2]);
      final first = game.submit(round: 1, tokenIndex: wrong(1));
      expect(first['round_over'], isFalse);
      expect(
        first.containsKey('target'),
        isFalse,
        reason: 'no answer before the round ends',
      );
      expect(game.submit(round: 1, tokenIndex: rounds[1].target)['marks'], [
        2,
        1,
      ]);
      game.submit(round: 2, tokenIndex: wrong(2));
      final last = game.submit(round: 2, tokenIndex: wrong(2));
      expect(last['finished'], isTrue);
      expect(last['score'], 3);
      expect(last['marks'], [2, 1, 0]);
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
