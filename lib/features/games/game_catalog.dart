import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';

import '../story/presentation/frostlands_story_page.dart';
import 'bridge/presentation/bridge_page.dart';
import 'cascade/presentation/cascade_page.dart';
import 'crowns/presentation/crowns_page.dart';
import 'common/daily_game_session.dart';
import 'common/daily_schedule.dart';
import 'common/game_rewards.dart';
import 'link_lab/presentation/link_lab_page.dart';
import 'mirror/presentation/mirror_page.dart';
import 'scale/presentation/scale_page.dart';
import 'sequence/presentation/sequence_page.dart';
import 'signal_grid/presentation/signal_grid_page.dart';
import 'squeeze/presentation/squeeze_page.dart';
import 'verdict/presentation/verdict_page.dart';
import 'whos_who/presentation/whos_who_page.dart';

/// Every activity in Curio, in one place. Home, the Learn tab and Skill
/// Quest all read from here, so a game has one name, one skill, one
/// duration and one XP value everywhere (XP and skill come from
/// [gameRewards], which mirrors the server's reward table).
class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.duration,
    required this.builder,
  });

  /// The activity id the reward table knows it by.
  final String id;
  final String title;
  final String tagline;
  final IconData icon;
  final String duration;
  final Widget Function(DateTime date) builder;
  LearningSection get section => sectionForGame(id);

  Widget open({DateTime? date}) {
    final started = date ?? DateTime.now();
    return DailyGameSession(
      gameId: id,
      date: started,
      child: builder(isDaily ? puzzleDateForGame(id, started) : started),
    );
  }

  GameReward get reward => gameRewards[id]!;
  String get skill => reward.skill;
  int get xp => reward.xp;
  bool get isDaily => reward.dated;
}

final gameCatalog = <GameEntry>[
  GameEntry(
    id: 'crowns',
    title: 'Crowns',
    tagline: 'One crown in every row, column and colour, and none touching.',
    icon: Icons.workspace_premium_rounded,
    duration: '3 to 5 min',
    builder: (date) => CrownsPage(date: date),
  ),
  GameEntry(
    id: 'sequence',
    title: 'Sequence',
    tagline: 'Guess the next number early, or buy more clues first.',
    icon: Icons.format_list_numbered_rounded,
    duration: '3 min',
    builder: (date) => SequencePage(date: date),
  ),
  GameEntry(
    id: 'bridge',
    title: 'Bridge',
    tagline: 'Order every tile to turn one number into another.',
    icon: Icons.linear_scale_rounded,
    duration: '3 to 5 min',
    builder: (date) => BridgePage(date: date),
  ),
  GameEntry(
    id: 'cascade',
    title: 'Cascade',
    tagline: 'Chain five consequences, evidence over hunches.',
    icon: Icons.waterfall_chart_rounded,
    duration: '4 min',
    builder: (date) => CascadePage(date: date),
  ),
  GameEntry(
    id: 'scale',
    title: 'Tip the Scale',
    tagline: 'Which is more: 3/4 or 0.7? Weigh it up, or call it equal.',
    icon: Icons.balance_rounded,
    duration: '3 min',
    builder: (date) => ScalePage(date: date),
  ),
  GameEntry(
    id: 'verdict',
    title: 'Verdict',
    tagline: 'Does the evidence back the claim, or can’t it tell yet?',
    icon: Icons.gavel_rounded,
    duration: '3 min',
    builder: (date) => VerdictPage(date: date),
  ),
  GameEntry(
    id: 'mirror',
    title: 'Mirror',
    tagline: 'Paint the other half so the pattern reflects perfectly.',
    icon: Icons.flip_rounded,
    duration: '3 to 4 min',
    builder: (date) => MirrorPage(date: date),
  ),
  GameEntry(
    id: 'whos_who',
    title: 'Who’s Who',
    tagline:
        'Match every child to their pet and favourite, using only the clues.',
    icon: Icons.groups_rounded,
    duration: '4 to 6 min',
    builder: (date) => WhosWhoPage(date: date),
  ),
  GameEntry(
    id: 'squeeze',
    title: 'Squeeze',
    tagline: 'Find the secret number before the range closes in.',
    icon: Icons.calculate_rounded,
    duration: '2 to 4 min',
    builder: (date) => SqueezePage(date: date),
  ),
  GameEntry(
    id: 'link_lab',
    title: 'Link Lab',
    tagline: 'Sort sixteen clues into four knowledge groups.',
    icon: Icons.hub_outlined,
    duration: '3 to 5 min',
    builder: (date) => LinkLabPage(date: date),
  ),
  GameEntry(
    id: 'signal_grid',
    title: 'Signal Grid',
    tagline: 'Balance the grid by deduction alone.',
    icon: Icons.grid_view_rounded,
    duration: '4 to 6 min',
    builder: (date) => SignalGridPage(date: date),
  ),
  GameEntry(
    id: 'frostlands_night_1',
    title: 'Frostlands Story',
    tagline: 'Help Ash home, careful, brave or kind? Four endings to find.',
    icon: Icons.ac_unit_rounded,
    duration: '5 min',
    builder: (_) => const FrostlandsStoryPage(),
  ),
];

GameEntry gameById(String id) => gameCatalog.firstWhere((g) => g.id == id);

/// Like [gameById], but null for an id the catalog doesn't list.
GameEntry? findGame(String id) {
  for (final g in gameCatalog) {
    if (g.id == id) return g;
  }
  return null;
}

List<GameEntry> get dailyGames => [
  for (final g in gameCatalog)
    if (g.isDaily) g,
];

/// Exactly one game per section; this is the shared daily plan for all screens.
List<GameEntry> todaysPicks({DateTime? date, int count = 4}) {
  final today = date ?? DateTime.now();
  return [
    for (final section in LearningSection.values.take(
      count.clamp(0, LearningSection.values.length),
    ))
      gameById(scheduledGameId(section, today)),
  ];
}

GameEntry featuredGame({DateTime? date}) => todaysPicks(date: date).first;

IconData sectionIcon(LearningSection section) => switch (section) {
  LearningSection.maths => Icons.calculate_rounded,
  LearningSection.logic => Icons.extension_rounded,
  LearningSection.thinking => Icons.psychology_rounded,
};

Color sectionColor(BuildContext context, LearningSection section) =>
    switch (section) {
      LearningSection.maths => CurioTokens.tintMaths,
      LearningSection.logic => CurioTokens.tintLogic,
      LearningSection.thinking => CurioTokens.tintThinking,
    };

/// The skill colours from design.md §3: number sense gold, patterns coral,
/// evidence blue, reasoning plum.
Color skillColor(BuildContext context, String skill) => switch (skill) {
  'Number sense' => CurioTokens.tintMaths,
  'Memory' || 'Patterns' => CurioTokens.wrong,
  'English' || 'Evidence' => CurioTokens.tintLogic,
  _ => CurioTokens.tintThinking,
};

IconData skillIcon(String skill) => switch (skill) {
  'Number sense' => Icons.calculate_rounded,
  'Patterns' => Icons.blur_on_rounded,
  'Memory' => Icons.psychology_rounded,
  'English' => Icons.menu_book_rounded,
  'Evidence' => Icons.manage_search_rounded,
  _ => Icons.psychology_rounded,
};

/// Today's set as Home shows it: one anchor game and the rest.
({GameEntry anchor, List<GameEntry> others}) todaysSet({DateTime? date}) {
  final picks = todaysPicks(date: date);
  return (anchor: picks.first, others: picks.sublist(1));
}
