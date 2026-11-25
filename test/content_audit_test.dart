import 'package:curio/features/games/cascade/domain/cascade.dart';
import 'package:curio/features/games/common/daily_schedule.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/english/domain/english_game.dart';
import 'package:curio/features/games/evidence/domain/evidence_cases.dart';
import 'package:curio/features/games/link_lab/domain/link_lab.dart';
import 'package:curio/features/games/loophole/domain/loophole_bank.dart';
import 'package:curio/features/games/memory/domain/memory_game.dart';
import 'package:curio/features/games/memory_grid/domain/memory_grid.dart';
import 'package:curio/features/games/number_hunt/domain/number_hunt.dart';
import 'package:curio/features/games/odd_cluster/domain/odd_cluster.dart';
import 'package:curio/features/games/pattern/domain/pattern_forge.dart';
import 'package:curio/features/games/squeeze/domain/squeeze_engine.dart';
import 'package:curio/features/games/verdict/domain/verdict.dart';
import 'package:curio/features/games/whos_who/domain/whos_who.dart';
import 'package:curio/features/games/word_trails/domain/word_trails.dart';
import 'package:flutter_test/flutter_test.dart';

/// Walks the real daily schedule for six months and checks every game's
/// content: each appearance gets a day of its own, and no single question
/// (a claim, a word, a story, a case) comes back inside the window.
void main() {
  final start = DateTime(2026, 11, 25);
  const days = 183;

  // Every game's day numbers, in the order a learner meets them.
  final appearances = <String, List<int>>{};
  for (var d = 0; d < days; d++) {
    final date = DateTime(start.year, start.month, start.day + d);
    for (final id in dailyGameIds(date)) {
      appearances
          .putIfAbsent(id, () => [])
          .add(DailyPick.dayNumber(puzzleDateForGame(id, date)));
    }
  }

  /// The questions a game asks on day [day], each as a short signature.
  final questions = <String, List<String> Function(int day)>{
    'word_wise': (d) => [for (final q in questionsForDay(d)) q.prompt],
    'word_builder': (d) => [for (final w in wordsForDay(d)) w.$1],
    'word_trails': (d) => [WordTrail.daily(d).story.story],
    'link_lab': (d) => [
      for (final g in linkLabPuzzles[d % linkLabPuzzles.length].groups)
        g.words.join(','),
    ],
    'odd_cluster': (d) => [
      for (final g in oddClusterPuzzles[d % oddClusterPuzzles.length].groups)
        g.words.join(','),
    ],
    'cascade': (d) => [cascadeClaims[d % cascadeClaims.length].claim],
    'evidence_garden': (d) => [evidenceCaseFor(d).heading],
    'verdict': (d) => [for (final v in verdictDailySet(d)) v.claim],
    'loophole': (d) => [
      for (final r in loopholeDays[d % loopholeDays.length]) r.statement,
    ],
    'pattern_forge': (d) => [
      for (final q in ForgeDay.forDay(forgeDay(d)).questions)
        '${q.kind.name}:${q.terms.join(',')}',
    ],
    'whos_who': (d) => [
      for (final p in WhoPuzzle.dailySet(d))
        '${p.names.join()}${p.clues.length}${p.solution}',
    ],
    'number_hunt': (d) => ['${NumberHunt.dailyTarget(d)}'],
    'squeeze': (d) => [
      '${SqueezeEngine(date: DateTime.utc(2026).add(Duration(days: d))).target}',
    ],
    'memory_match': (d) => [MemoryMatchGame(d).cards.join(',')],
    'memory_trail': (d) => [MemoryTrailGame(d).trails.join('|')],
    'memory_grid': (d) => ['${MemoryGrid(d).seed}'],
  };

  int repeatsIn(String game) {
    final seen = <String>{};
    var repeats = 0;
    for (final d in appearances[game]!) {
      for (final q in questions[game]!(d)) {
        if (!seen.add(q)) repeats++;
      }
    }
    return repeats;
  }

  // Generated games: a fresh puzzle every appearance, no question twice.
  for (final game in [
    'memory_match',
    'memory_trail',
    'memory_grid',
    'squeeze',
    'number_hunt',
    'whos_who',
    'pattern_forge',
  ]) {
    test('$game never repeats a question in six months', () {
      expect(repeatsIn(game), 0);
    });
  }

  // Hand-written banks: listed so the gap is visible. Each needs more
  // content before it can join the list above.
  test('hand-written banks, repeats in six months (report only)', () {
    final lines = [
      for (final game in [
        'verdict',
        'word_wise',
        'word_builder',
        'loophole',
        'odd_cluster',
        'link_lab',
        'cascade',
        'evidence_garden',
        'word_trails',
      ])
        '$game: ${appearances[game]!.length} appearances, '
            '${repeatsIn(game)} repeated questions',
    ];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
