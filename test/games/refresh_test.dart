import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/evidence/domain/evidence_cases.dart';
import 'package:curio/features/games/evidence/presentation/evidence_detective_page.dart';
import 'package:curio/features/games/link_lab/domain/link_lab.dart';
import 'package:curio/features/games/link_lab/presentation/link_lab_page.dart';
import 'package:curio/features/games/pattern/domain/pattern_forge.dart';
import 'package:curio/features/games/pattern/presentation/pattern_forge_page.dart';
import 'package:curio/features/games/sequence/domain/sequence.dart';
import 'package:curio/features/story/domain/frostlands.dart';
import 'package:curio/features/story/presentation/frostlands_story_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final day = DateTime(2026, 10, 8);
final dayNumber = DailyPick.dayNumber(day);

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

/// Scrolls the page's list until [finder] exists and is on screen.
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
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> solveLinkLab(WidgetTester tester, LinkLabGame game) async {
  for (final group in game.puzzle.groups) {
    for (final word in group.words) {
      await tap(tester, find.byKey(Key('link_$word')));
    }
    await tap(tester, find.byKey(const Key('link_submit')));
  }
}

Future<void> solveForge(WidgetTester tester, ForgeDay forge) async {
  for (var i = 0; i < 3; i++) {
    final q = forge.questions[i];
    final key = switch (q) {
      NextQuestion(:final options, :final answer) =>
        'forge_option_${options.indexOf(answer)}',
      RuleQuestion(:final answer) => 'forge_option_$answer',
      RepairQuestion(:final wrongIndex) => 'forge_number_$wrongIndex',
    };
    await tap(tester, find.byKey(Key(key)));
    if (i < 2) await tap(tester, find.byKey(const Key('forge_next')));
  }
}

Future<void> solveCase(WidgetTester tester, EvidenceCase c) async {
  for (var i = 0; i < c.clues.length; i++) {
    await tap(tester, find.byKey(Key('rank_${i}_${c.clues[i].rank.name}')));
  }
  await tap(tester, find.byKey(const Key('evidence_submit')));
}

Future<void> playStory(WidgetTester tester, int choice) async {
  for (var i = 0; i < frostlandsScenes.length; i++) {
    await tap(tester, find.byKey(Key('story_choice_$choice')));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Link Lab bank', () {
    test('at least 8 puzzles of 4 groups × 4, 16 distinct tiles each', () {
      expect(linkLabPuzzles.length, greaterThanOrEqualTo(8));
      for (final puzzle in linkLabPuzzles) {
        expect(puzzle.groups.length, 4);
        expect(puzzle.words.toSet().length, 16, reason: puzzle.words.join(','));
        expect(puzzle.groups.map((g) => g.title).toSet().length, 4);
        for (final g in puzzle.groups) {
          expect(g.words.length, 4);
          expect(g.title, isNotEmpty);
          expect(g.why, isNotEmpty);
          for (final w in g.words) {
            expect(w, matches(RegExp(r'^[A-Z]{2,10}$')), reason: 'tile $w');
          }
        }
      }
    });

    test('the same day gives the same puzzle and board; days rotate', () {
      final a = LinkLabGame.forDay(dayNumber);
      final b = LinkLabGame.forDay(dayNumber);
      expect(a.puzzle, same(b.puzzle));
      expect(a.board, b.board);
      expect(a.board.toSet(), a.puzzle.words.toSet());
      expect(LinkLabGame.forDay(dayNumber + 1).puzzle, isNot(same(a.puzzle)));
      final seen = {
        for (var d = 0; d < linkLabPuzzles.length; d++)
          LinkLabGame.forDay(dayNumber + d).puzzle,
      };
      expect(seen.length, linkLabPuzzles.length, reason: 'all in rotation');
    });

    test('practice never replays today’s or tomorrow’s puzzle', () {
      for (var today = 270; today < 300; today++) {
        final daily = linkLabPuzzles[today % linkLabPuzzles.length];
        final tomorrow = linkLabPuzzles[(today + 1) % linkLabPuzzles.length];
        for (var round = 1; round <= 30; round++) {
          final p = LinkLabGame.forDay(linkLabDay(today, practice: round));
          expect(p.puzzle, isNot(same(daily)));
          expect(p.puzzle, isNot(same(tomorrow)));
        }
      }
    });

    test('gentle rules: honest mistakes, hints, share grid', () {
      final game = LinkLabGame(linkLabPuzzles.first, seed: 3);
      final g = game.puzzle.groups;
      final near = {...g[0].words.take(3), g[1].words.first};
      expect(game.guess(near), LinkVerdict.oneAway);
      expect(game.guess(near), LinkVerdict.repeat);
      for (var i = 0; i < 5; i++) {
        final mix = {
          g[0].words[i % 4],
          g[1].words[i % 4],
          g[2].words[0],
          g[3].words[i % 2],
        };
        game.guess(mix);
      }
      expect(game.mistakes, greaterThan(4), reason: 'never capped');
      final hint = game.hint()!;
      expect(hint.word, isNull);
      expect(game.hints, 1);
      for (final group in g) {
        expect(game.guess(group.words.toSet()), LinkVerdict.found);
      }
      expect(game.won, isTrue);
      final rows = game.shareGrid().split('\n');
      expect(rows.length, game.history.length);
      expect(rows.last, '🟪🟪🟪🟪');
      expect(game.shareGrid(), isNot(contains('MARS')));
    });
  });

  group('Pattern Forge generator', () {
    final generated = [for (var d = -30; d < 230; d++) ForgeDay.forDay(d)];

    test('three question types from three different rule families', () {
      for (final f in generated) {
        expect(f.questions.map((q) => q.kind).toList(), ForgeKind.values);
        expect(f.questions.map((q) => q.rule.kind).toSet().length, 3);
      }
      expect(
        generated.map((f) => f.questions.first.terms.join(',')).toSet().length,
        greaterThan(100),
        reason: 'days really differ',
      );
    });

    test('what comes next: unambiguous prefix, right answer exactly once', () {
      for (final f in generated) {
        final q = f.questions[0] as NextQuestion;
        expect(plausibleNextTerms(q.shown), {q.answer}, reason: '${q.shown}');
        expect(opensAt(q.terms), lessThanOrEqualTo(q.shown.length));
        expect(q.shown.length, greaterThanOrEqualTo(4));
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4, reason: 'distinct options');
        expect(q.options.where((o) => o == q.answer).length, 1);
        expect(q.options.every((o) => o >= 0), isTrue);
        expect(q.rule.fits(q.terms), isTrue);
      }
    });

    test('which rule: exactly one option makes the pattern', () {
      for (final f in generated) {
        final q = f.questions[1] as RuleQuestion;
        expect(q.options.length, 4);
        expect(q.options.map((o) => o.description).toSet().length, 4);
        final fitting = [
          for (final o in q.options)
            if (o.fits(q.shown)) o,
        ];
        expect(fitting, [q.rule], reason: '${q.shown} ${q.options}');
        expect(q.options[q.answer], q.rule);
      }
    });

    test('repair it: one wrong number, and no other single fix works', () {
      for (final f in generated) {
        final q = f.questions[2] as RepairQuestion;
        final changed = [
          for (var i = 0; i < q.shown.length; i++)
            if (q.shown[i] != q.terms[i]) i,
        ];
        expect(changed, [q.wrongIndex]);
        expect(followsPlausibleRule(q.shown), isFalse, reason: '${q.shown}');
        expect(followsPlausibleRule(q.terms), isTrue);
        // Independent brute force: every value at every position.
        final lo = q.shown.reduce((a, b) => a < b ? a : b);
        final hi = q.shown.reduce((a, b) => a > b ? a : b);
        final span = hi - lo;
        for (var i = 0; i < q.shown.length; i++) {
          for (var v = lo - 3 * span - 40; v <= hi + 3 * span + 40; v++) {
            if (v == q.shown[i]) continue;
            final fixed = List.of(q.shown)..[i] = v;
            final expected = i == q.wrongIndex && v == q.correctValue;
            expect(
              followsPlausibleRule(fixed),
              expected,
              reason: '${q.shown}: [$i] = $v',
            );
          }
        }
      }
    });

    test('practice steps back a day, never forward', () {
      expect(forgeDay(300), 300);
      expect(forgeDay(300, practice: 1), 299);
      expect(forgeDay(300, practice: 5), 295);
    });
  });

  group('Evidence cases', () {
    test('at least 7 cases, 3 explained clues each, every label used', () {
      expect(evidenceCases.length, greaterThanOrEqualTo(7));
      final ranks = <EvidenceRank>{};
      for (var i = 0; i < evidenceCases.length; i++) {
        final c = evidenceCases[i];
        expect(c.number, i + 1);
        expect(
          c.heading,
          startsWith('CASE ${(i + 1).toString().padLeft(3, '0')} · '),
        );
        expect(c.question, isNotEmpty);
        expect(c.summary, isNotEmpty);
        expect(c.clues.length, 3);
        for (final clue in c.clues) {
          expect(clue.title, isNotEmpty);
          expect(clue.detail, isNotEmpty);
          expect(clue.why, isNotEmpty);
          ranks.add(clue.rank);
        }
      }
      expect(ranks, EvidenceRank.values.toSet());
      expect(
        evidenceCases
            .map((c) => c.clues.map((k) => k.rank).toSet().length)
            .toSet()
            .length,
        greaterThan(1),
        reason: 'not always one of each',
      );
      expect(evidenceCases[3].heading, 'CASE 004 · THE LIBRARY BOOK');
    });

    test(
      'rotates daily, repeats per date, practice skips today and tomorrow',
      () {
        expect(evidenceCaseFor(dayNumber), same(evidenceCaseFor(dayNumber)));
        final seen = {
          for (var d = 0; d < evidenceCases.length; d++)
            evidenceCaseFor(dayNumber + d),
        };
        expect(seen.length, evidenceCases.length);
        for (var today = 270; today < 290; today++) {
          for (var round = 1; round <= 20; round++) {
            final p = evidenceCaseFor(today, practice: round);
            expect(p, isNot(same(evidenceCaseFor(today))));
            expect(p, isNot(same(evidenceCaseFor(today + 1))));
          }
        }
      },
    );

    test('scores each right ranking', () {
      final c = evidenceCases.first;
      expect(c.score({for (var i = 0; i < 3; i++) i: c.clues[i].rank}), 3);
      expect(c.score({0: c.clues[0].rank}), 1);
      expect(c.score({}), 0);
    });
  });

  group('Frostlands', () {
    test('every path reaches an ending, with at least 3 different endings', () {
      expect(frostlandsScenes.length, 3);
      for (final scene in frostlandsScenes) {
        expect(
          scene.choices.map((c) => c.trait).toSet(),
          StoryTrait.values.toSet(),
        );
        expect(scene.choices.every((c) => c.outcome.isNotEmpty), isTrue);
      }
      final endings = <String>{};
      for (final a in StoryTrait.values) {
        for (final b in StoryTrait.values) {
          for (final c in StoryTrait.values) {
            final ending = frostlandsEnding([a, b, c]);
            expect(ending.body, isNotEmpty);
            endings.add(ending.title);
          }
        }
      }
      expect(endings.length, greaterThanOrEqualTo(3));
      expect(
        frostlandsEnding([
          StoryTrait.kind,
          StoryTrait.kind,
          StoryTrait.brave,
        ]).title,
        frostlandsEndings['kind']!.title,
      );
      expect(
        frostlandsEnding([
          StoryTrait.careful,
          StoryTrait.brave,
          StoryTrait.kind,
        ]).title,
        frostlandsEndings['balanced']!.title,
      );
    });
  });

  group('Playthroughs', () {
    testWidgets(
      'Link Lab: solve the day, honest share, then practice for no XP',
      (tester) async {
        await phone(tester);
        final state = CurioState();
        final xp = state.totalXp;
        await tester.pumpWidget(play(LinkLabPage(date: day), state));
        await solveLinkLab(tester, LinkLabGame.forDay(linkLabDay(dayNumber)));
        await reveal(tester, find.text('No mistakes').last);
        expect(find.text('Flawless links!'), findsOneWidget);
        expect(state.completedToday('link_lab'), isTrue);
        expect(state.totalXp, xp + 90);

        await tap(tester, find.byKey(const Key('game_practice')));
        await reveal(tester, find.text('PRACTICE'));
        await solveLinkLab(
          tester,
          LinkLabGame.forDay(linkLabDay(dayNumber, practice: 1)),
        );
        await reveal(tester, find.text('No mistakes').last);
        expect(state.totalXp, xp + 90, reason: 'practice earns nothing');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Link Lab: a wrong guess is counted and hints are free', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(play(LinkLabPage(date: day), CurioState()));
      final game = LinkLabGame.forDay(linkLabDay(dayNumber));
      final g = game.puzzle.groups;
      for (final w in [
        g[0].words[0],
        g[0].words[1],
        g[1].words[0],
        g[1].words[1],
      ]) {
        await tap(tester, find.byKey(Key('link_$w')));
      }
      await tap(tester, find.byKey(const Key('link_submit')));
      expect(find.text('1 mistake'), findsOneWidget);
      await tap(tester, find.byKey(const Key('link_hint')));
      expect(find.text('1 hint'), findsOneWidget);
      expect(find.text('Your hints'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pattern Forge: three right answers, then practice for no XP', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      final xp = state.totalXp;
      await tester.pumpWidget(play(PatternForgePage(date: day), state));
      await solveForge(tester, ForgeDay.forDay(forgeDay(dayNumber)));
      await reveal(tester, find.text('3 / 3'));
      expect(find.text('Master forger!'), findsOneWidget);
      expect(state.completedToday('pattern_forge'), isTrue);
      expect(state.totalXp, xp + 60);

      await tap(tester, find.byKey(const Key('game_practice')));
      await reveal(tester, find.text('PRACTICE'));
      await solveForge(
        tester,
        ForgeDay.forDay(forgeDay(dayNumber, practice: 1)),
      );
      await reveal(tester, find.text('3 / 3'));
      expect(state.totalXp, xp + 60);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pattern Forge: a wrong repair tap shows the right fix', (
      tester,
    ) async {
      await phone(tester);
      await tester.pumpWidget(play(PatternForgePage(date: day), CurioState()));
      final forge = ForgeDay.forDay(forgeDay(dayNumber));
      final next = forge.questions[0] as NextQuestion;
      final wrong = next.options.indexWhere((o) => o != next.answer);
      await tap(tester, find.byKey(Key('forge_option_$wrong')));
      expect(find.textContaining('Not quite'), findsOneWidget);
      await tap(tester, find.byKey(const Key('forge_next')));
      await tap(tester, find.byKey(const Key('forge_option_0')));
      await tap(tester, find.byKey(const Key('forge_next')));
      final repair = forge.questions[2] as RepairQuestion;
      final other = repair.wrongIndex == 0 ? 1 : 0;
      await tap(tester, find.byKey(Key('forge_number_$other')));
      expect(
        find.textContaining('should be ${repair.correctValue}'),
        findsWidgets,
      );
      await reveal(tester, find.byKey(const Key('game_practice')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Evidence Detective: rank the day’s clues, then practice', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      final xp = state.totalXp;
      await tester.pumpWidget(play(EvidenceDetectivePage(date: day), state));
      final today = evidenceCaseFor(dayNumber);
      expect(find.text(today.heading), findsOneWidget);
      await solveCase(tester, today);
      await reveal(tester, find.text('3 / 3'));
      expect(find.text('Case cracked!'), findsOneWidget);
      expect(state.completedToday('evidence_garden'), isTrue);
      expect(state.totalXp, xp + 70);

      await tap(tester, find.byKey(const Key('game_practice')));
      final practice = evidenceCaseFor(dayNumber, practice: 1);
      await reveal(tester, find.text('PRACTICE'));
      expect(find.text(practice.heading), findsOneWidget);
      await solveCase(tester, practice);
      await reveal(tester, find.text('3 / 3'));
      expect(state.totalXp, xp + 70);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Evidence Detective: a replay says the XP was already earned', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      state.completedActivities.add(
        CurioState.dailyActivityId('evidence_garden'),
      );
      final xp = state.totalXp;
      await tester.pumpWidget(play(EvidenceDetectivePage(date: day), state));
      await solveCase(tester, evidenceCaseFor(dayNumber));
      await reveal(tester, find.textContaining('already earned'));
      expect(find.textContaining('already earned'), findsOneWidget);
      expect(state.totalXp, xp);
    });

    testWidgets('Frostlands: choices change the ending, XP once ever', (
      tester,
    ) async {
      await phone(tester);
      final state = CurioState();
      final xp = state.totalXp;
      await tester.pumpWidget(play(const FrostlandsStoryPage(), state));
      await playStory(tester, 0);
      final careful = frostlandsEndings['careful']!;
      expect(find.text(careful.title), findsOneWidget);
      await reveal(tester, find.text('Your path'));
      expect(find.text('Careful 3 · Brave 0 · Kind 0'), findsOneWidget);
      await reveal(tester, find.textContaining('+50 XP'));
      expect(state.completedActivities, contains('frostlands_night_1'));
      expect(state.totalXp, xp + 50);

      await tap(tester, find.byKey(const Key('story_replay')));
      expect(find.textContaining('finished this story before'), findsOneWidget);
      await playStory(tester, 1);
      expect(find.text(frostlandsEndings['brave']!.title), findsOneWidget);
      await reveal(tester, find.textContaining('already earned'));
      expect(find.textContaining('already earned'), findsOneWidget);
      expect(state.totalXp, xp + 50);
      expect(tester.takeException(), isNull);
    });
  });

  for (final size in [
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Refreshed games fit $size dark=$dark with large text', (
        tester,
      ) async {
        await phone(tester, size);
        Future<void> check(Widget page, Future<void> Function() finish) async {
          await tester.pumpWidget(
            play(page, CurioState(), dark: dark, text: 1.6),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} start',
          );
          await finish();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} end',
          );
          await tester.pumpWidget(const SizedBox());
        }

        await check(
          LinkLabPage(date: day),
          () => solveLinkLab(tester, LinkLabGame.forDay(linkLabDay(dayNumber))),
        );
        await check(
          PatternForgePage(date: day),
          () => solveForge(tester, ForgeDay.forDay(forgeDay(dayNumber))),
        );
        await check(
          EvidenceDetectivePage(date: day),
          () => solveCase(tester, evidenceCaseFor(dayNumber)),
        );
        await check(const FrostlandsStoryPage(), () => playStory(tester, 2));
      });
    }
  }
}
