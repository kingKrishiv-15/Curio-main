import 'package:flutter/material.dart';

import '../../core/theme/curio_colors.dart';
import '../../core/theme/curio_colors_light.dart';
import '../../core/widgets/curio_ui.dart';
import '../story/presentation/frostlands_story_page.dart';
import 'bridge/presentation/bridge_page.dart';
import 'cascade/presentation/cascade_page.dart';
import 'common/daily_game_session.dart';
import 'common/daily_schedule.dart';
import 'memory/presentation/memory_page.dart';
import 'english/presentation/english_page.dart';
import 'common/game_rewards.dart';
import 'evidence/presentation/evidence_detective_page.dart';
import 'link_lab/presentation/link_lab_page.dart';
import 'loophole/presentation/loophole_page.dart';
import 'mirror/presentation/mirror_page.dart';
import 'odd_cluster/presentation/odd_cluster_page.dart';
import 'pattern/presentation/pattern_forge_page.dart';
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
    this.isNew = false,
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

  final bool isNew;

  GameReward get reward => gameRewards[id]!;
  String get skill => reward.skill;
  int get xp => reward.xp;
  bool get isDaily => reward.dated;
}

final gameCatalog = <GameEntry>[
  GameEntry(
    id: 'memory_match',
    title: 'Memory Match',
    tagline: 'Turn over two cards. Remember where each picture is hiding.',
    icon: Icons.style_rounded,
    duration: '3 min',
    builder: (date) => MemoryPage(date: date),
  ),
  GameEntry(
    id: 'memory_trail',
    title: 'Memory Trail',
    tagline: 'Study a trail of pictures, then remember their order.',
    icon: Icons.route_rounded,
    duration: '3 min',
    builder: (date) => MemoryPage(date: date, trail: true),
  ),
  GameEntry(
    id: 'word_wise',
    title: 'Word Wise',
    tagline:
        'Find the right word, explore its meaning and finish the sentence.',
    icon: Icons.menu_book_rounded,
    duration: '3 min',
    builder: (date) => EnglishPage(date: date),
  ),
  GameEntry(
    id: 'word_builder',
    title: 'Word Builder',
    tagline: 'Use the clue and put the letters in order to build a word.',
    icon: Icons.abc_rounded,
    duration: '3 min',
    builder: (date) => EnglishPage(date: date, builder: true),
  ),
  GameEntry(
    id: 'odd_cluster',
    title: 'Odd Cluster',
    tagline: 'Sixteen tiles, four hidden groups — and one of them is a trap.',
    icon: Icons.workspaces_rounded,
    duration: '3–5 min',
    builder: (date) => OddClusterPage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'sequence',
    title: 'Sequence',
    tagline: 'Guess the next number early, or buy more clues first.',
    icon: Icons.format_list_numbered_rounded,
    duration: '3 min',
    builder: (date) => SequencePage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'bridge',
    title: 'Bridge',
    tagline: 'Order every tile to turn one number into another.',
    icon: Icons.linear_scale_rounded,
    duration: '3–5 min',
    builder: (date) => BridgePage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'cascade',
    title: 'Cascade',
    tagline: 'Chain five consequences — evidence over hunches.',
    icon: Icons.waterfall_chart_rounded,
    duration: '4 min',
    builder: (date) => CascadePage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'scale',
    title: 'Tip the Scale',
    tagline: 'Which is more: 3/4 or 0.7? Weigh it up, or call it equal.',
    icon: Icons.balance_rounded,
    duration: '3 min',
    builder: (date) => ScalePage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'verdict',
    title: 'Verdict',
    tagline: 'Does the evidence back the claim — or can’t it tell yet?',
    icon: Icons.gavel_rounded,
    duration: '3 min',
    builder: (date) => VerdictPage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'mirror',
    title: 'Mirror',
    tagline: 'Paint the other half so the pattern reflects perfectly.',
    icon: Icons.flip_rounded,
    duration: '3–4 min',
    builder: (date) => MirrorPage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'whos_who',
    title: 'Who’s Who',
    tagline:
        'Match every child to their pet and favourite, using only the clues.',
    icon: Icons.groups_rounded,
    duration: '4–6 min',
    builder: (date) => WhosWhoPage(date: date),
    isNew: true,
  ),
  GameEntry(
    id: 'loophole',
    title: 'Loophole',
    tagline: 'Find the one word making a true statement mislead.',
    icon: Icons.format_quote_rounded,
    duration: '2 min',
    builder: (date) => LoopholePage(date: date),
  ),
  GameEntry(
    id: 'squeeze',
    title: 'Squeeze',
    tagline: 'Find the secret number before the range closes in.',
    icon: Icons.calculate_rounded,
    duration: '2–4 min',
    builder: (date) => SqueezePage(date: date),
  ),
  GameEntry(
    id: 'link_lab',
    title: 'Link Lab',
    tagline: 'Sort sixteen clues into four knowledge groups.',
    icon: Icons.hub_outlined,
    duration: '3–5 min',
    builder: (date) => LinkLabPage(date: date),
  ),
  GameEntry(
    id: 'signal_grid',
    title: 'Signal Grid',
    tagline: 'Balance the grid by deduction alone.',
    icon: Icons.grid_view_rounded,
    duration: '4–6 min',
    builder: (date) => SignalGridPage(date: date),
  ),
  GameEntry(
    id: 'pattern_forge',
    title: 'Pattern Forge',
    tagline: 'Pick the next number, name the rule, fix the broken pattern.',
    icon: Icons.blur_on_rounded,
    duration: '3–5 min',
    builder: (date) => PatternForgePage(date: date),
  ),
  GameEntry(
    id: 'evidence_garden',
    title: 'Evidence Detective',
    tagline:
        'A new case each day: rank the clues before you jump to conclusions.',
    icon: Icons.manage_search_rounded,
    duration: '4–6 min',
    builder: (date) => EvidenceDetectivePage(date: date),
  ),
  GameEntry(
    id: 'frostlands_night_1',
    title: 'Frostlands Story',
    tagline: 'Help Ash home — careful, brave or kind? Four endings to find.',
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
List<GameEntry> todaysPicks({DateTime? date, int count = 3}) {
  final today = date ?? DateTime.now();
  return [
    for (final section in LearningSection.values.take(count.clamp(0, 3)))
      gameById(scheduledGameId(section, today)),
  ];
}

GameEntry featuredGame({DateTime? date}) => todaysPicks(date: date).first;

IconData sectionIcon(LearningSection section) => switch (section) {
  LearningSection.maths => Icons.calculate_rounded,
  LearningSection.memory => Icons.psychology_rounded,
  LearningSection.english => Icons.menu_book_rounded,
};

Color sectionColor(BuildContext context, LearningSection section) =>
    skillColor(context, switch (section) {
      LearningSection.maths => 'Number sense',
      LearningSection.memory => 'Patterns',
      LearningSection.english => 'Evidence',
    });

/// The skill colours from design.md §3: number sense gold, patterns coral,
/// evidence blue, reasoning plum.
Color skillColor(BuildContext context, String skill) => switch (skill) {
  'Number sense' => curioColor(
    context,
    CurioColors.saffron,
    CurioColorsLight.saffron,
  ),
  'Memory' ||
  'Patterns' => curioColor(context, CurioColors.coral, CurioColorsLight.coral),
  'English' ||
  'Evidence' => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  _ => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
};

IconData skillIcon(String skill) => switch (skill) {
  'Number sense' => Icons.calculate_rounded,
  'Patterns' => Icons.blur_on_rounded,
  'Memory' => Icons.psychology_rounded,
  'English' => Icons.menu_book_rounded,
  'Evidence' => Icons.manage_search_rounded,
  _ => Icons.psychology_rounded,
};
