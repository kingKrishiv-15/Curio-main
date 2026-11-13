import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/link_lab/domain/link_lab.dart';
import 'package:curio/features/games/link_lab/presentation/link_lab_page.dart';
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
        await reveal(tester, find.textContaining('No mistakes').last);
        expect(find.text('Flawless links!'), findsOneWidget);
        expect(state.completedToday('link_lab'), isTrue);
        expect(state.totalXp, xp + 90);

        await tap(tester, find.byKey(const Key('game_practice')));
        await reveal(tester, find.text('Practice'));
        await solveLinkLab(
          tester,
          LinkLabGame.forDay(linkLabDay(dayNumber, practice: 1)),
        );
        await reveal(tester, find.textContaining('No mistakes').last);
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
      expect(find.textContaining('1 mistake'), findsOneWidget);
      await tap(tester, find.byKey(const Key('link_hint')));
      expect(find.textContaining('1 hint'), findsOneWidget);
      expect(find.text('Your hints'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      await reveal(tester, find.text(careful.title));
      expect(find.text(careful.title), findsOneWidget);
      await reveal(tester, find.text('Your path'));
      expect(find.text('Careful 3, Brave 0, Kind 0'), findsOneWidget);
      await reveal(tester, find.textContaining('+50 XP'));
      expect(state.completedActivities, contains('frostlands_night_1'));
      expect(state.totalXp, xp + 50);

      await tap(tester, find.byKey(const Key('story_replay')));
      expect(find.textContaining('finished this story before'), findsOneWidget);
      await playStory(tester, 1);
      await reveal(tester, find.text(frostlandsEndings['brave']!.title));
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
        await check(const FrostlandsStoryPage(), () => playStory(tester, 2));
      });
    }
  }
}
