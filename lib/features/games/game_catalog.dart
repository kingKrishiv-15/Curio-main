import 'package:flutter/material.dart';

import '../../core/theme/curio_colors.dart';
import '../../core/theme/curio_colors_light.dart';
import '../../core/widgets/curio_ui.dart';
import '../story/presentation/frostlands_story_page.dart';
import 'bridge/presentation/bridge_page.dart';
import 'cascade/presentation/cascade_page.dart';
import 'common/game_kit.dart';
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
    required this.open,
    this.isNew = false,
  });

  /// The activity id the reward table knows it by.
  final String id;
  final String title;
  final String tagline;
  final IconData icon;
  final String duration;
  final Widget Function() open;
  final bool isNew;

  GameReward get reward => gameRewards[id]!;
  String get skill => reward.skill;
  int get xp => reward.xp;
  bool get isDaily => reward.dated;
}

final gameCatalog = <GameEntry>[
  GameEntry(
    id: 'odd_cluster',
    title: 'Odd Cluster',
    tagline: 'Sixteen tiles, four hidden groups — and one of them is a trap.',
    icon: Icons.workspaces_rounded,
    duration: '3–5 min',
    open: OddClusterPage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'sequence',
    title: 'Sequence',
    tagline: 'Guess the next number early, or buy more clues first.',
    icon: Icons.format_list_numbered_rounded,
    duration: '3 min',
    open: SequencePage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'bridge',
    title: 'Bridge',
    tagline: 'Order every tile to turn one number into another.',
    icon: Icons.linear_scale_rounded,
    duration: '3–5 min',
    open: BridgePage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'cascade',
    title: 'Cascade',
    tagline: 'Chain five consequences — evidence over hunches.',
    icon: Icons.waterfall_chart_rounded,
    duration: '4 min',
    open: CascadePage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'scale',
    title: 'Tip the Scale',
    tagline: 'Which is more: 3/4 or 0.7? Weigh it up, or call it equal.',
    icon: Icons.balance_rounded,
    duration: '3 min',
    open: ScalePage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'verdict',
    title: 'Verdict',
    tagline: 'Does the evidence back the claim — or can’t it tell yet?',
    icon: Icons.gavel_rounded,
    duration: '3 min',
    open: VerdictPage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'mirror',
    title: 'Mirror',
    tagline: 'Paint the other half so the pattern reflects perfectly.',
    icon: Icons.flip_rounded,
    duration: '3–4 min',
    open: MirrorPage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'whos_who',
    title: 'Who’s Who',
    tagline: 'Match every child to their pet and favourite, using only the clues.',
    icon: Icons.groups_rounded,
    duration: '4–6 min',
    open: WhosWhoPage.new,
    isNew: true,
  ),
  GameEntry(
    id: 'loophole',
    title: 'Loophole',
    tagline: 'Find the one word making a true statement mislead.',
    icon: Icons.format_quote_rounded,
    duration: '2 min',
    open: LoopholePage.new,
  ),
  GameEntry(
    id: 'squeeze',
    title: 'Squeeze',
    tagline: 'Find the secret number before the range closes in.',
    icon: Icons.calculate_rounded,
    duration: '2–4 min',
    open: SqueezePage.new,
  ),
  GameEntry(
    id: 'link_lab',
    title: 'Link Lab',
    tagline: 'Sort sixteen clues into four knowledge groups.',
    icon: Icons.hub_outlined,
    duration: '3–5 min',
    open: LinkLabPage.new,
  ),
  GameEntry(
    id: 'signal_grid',
    title: 'Signal Grid',
    tagline: 'Balance the grid by deduction alone.',
    icon: Icons.grid_view_rounded,
    duration: '4–6 min',
    open: SignalGridPage.new,
  ),
  GameEntry(
    id: 'pattern_forge',
    title: 'Pattern Forge',
    tagline: 'Pick the next number, name the rule, fix the broken pattern.',
    icon: Icons.blur_on_rounded,
    duration: '3–5 min',
    open: PatternForgePage.new,
  ),
  GameEntry(
    id: 'evidence_garden',
    title: 'Evidence Detective',
    tagline: 'A new case each day: rank the clues before you jump to conclusions.',
    icon: Icons.manage_search_rounded,
    duration: '4–6 min',
    open: EvidenceDetectivePage.new,
  ),
  GameEntry(
    id: 'frostlands_night_1',
    title: 'Frostlands Story',
    tagline: 'Help Ash home — careful, brave or kind? Four endings to find.',
    icon: Icons.ac_unit_rounded,
    duration: '5 min',
    open: FrostlandsStoryPage.new,
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

/// A rotating handful of daily games for Home, so it isn't the whole list
/// in the same order every day. The first is today's featured quest.
List<GameEntry> todaysPicks({DateTime? date, int count = 5}) {
  final games = dailyGames;
  final start = DailyPick.index(games.length, date: date);
  return [
    for (var i = 0; i < count && i < games.length; i++)
      games[(start + i) % games.length],
  ];
}

GameEntry featuredGame({DateTime? date}) => todaysPicks(date: date).first;

/// The skill colours from design.md §3: number sense gold, patterns coral,
/// evidence blue, reasoning plum.
Color skillColor(BuildContext context, String skill) => switch (skill) {
  'Number sense' => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  'Patterns' => curioColor(context, CurioColors.coral, CurioColorsLight.coral),
  'Evidence' => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  _ => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
};

IconData skillIcon(String skill) => switch (skill) {
  'Number sense' => Icons.calculate_rounded,
  'Patterns' => Icons.blur_on_rounded,
  'Evidence' => Icons.manage_search_rounded,
  _ => Icons.psychology_rounded,
};
