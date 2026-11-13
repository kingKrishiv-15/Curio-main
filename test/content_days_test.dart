import 'dart:math';

import 'package:curio/features/games/bridge/domain/bridge.dart';
import 'package:curio/features/games/crowns/domain/crowns.dart';
import 'package:curio/features/games/mirror/domain/mirror.dart';
import 'package:curio/features/games/scale/domain/scale.dart';
import 'package:curio/features/games/sequence/domain/sequence.dart';
import 'package:curio/features/games/signal_grid/domain/signal_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each surviving game must offer at least 90 different days before it
/// repeats. A "day" here is one appearance of the game in the rotation.
void main() {
  const days = 90;

  void distinct(String game, String Function(int day) signature) {
    test('$game has $days distinct days', () {
      expect({for (var d = 0; d < days; d++) signature(d)}.length, days);
    });
  }

  distinct(
    'Sequence',
    (d) => sequenceRulesForDay(d).map((r) => r.terms.join(',')).join('|'),
  );
  test('every generated Sequence rule opens unambiguously', () {
    for (var d = 0; d < 400; d++) {
      for (final rule in sequenceRulesForDay(d)) {
        final opens = opensAt(rule.terms);
        expect(opens, isNotNull, reason: '${rule.name} ${rule.terms}');
        expect(opens!, lessThan(rule.terms.length - 1), reason: rule.name);
      }
    }
  });
  distinct('Bridge', (d) {
    final p = BridgePuzzle.generate(Random(d * 10));
    return '${p.start}>${p.target}:${p.tiles.map((t) => '${t.kind.name}${t.operand}').join()}';
  });
  distinct(
    'Tip the Scale',
    (d) => ScaleGame.forDay(d).rounds.map((r) => r.explanation).join('|'),
  );
  distinct(
    'Mirror',
    (d) => mirrorPuzzles(
      d,
    ).map((p) => '${p.axis.name}${p.size}${p.given}').join('|'),
  );
  distinct(
    'Crowns',
    (d) => dailyCrowns(d).map((b) => b.regions.join()).join('|'),
  );
  distinct('Signal Grid', (d) {
    final p = SignalPuzzle.forDay(d);
    return '${p.solution}${p.givens.toList()..sort()}';
  });
}
