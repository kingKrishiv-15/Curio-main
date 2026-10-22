import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../games/common/game_rewards.dart';

/// Which family a badge belongs to; the UI gives each family its colour.
enum BadgeTone { start, streak, explore, discovery, xp }

/// One achievement, with progress towards it, worked out from the explorer's
/// activity history. Nothing is stored separately, so a badge can never
/// drift out of sync with what the child actually did.
class CurioBadge {
  const CurioBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    required this.current,
    required this.target,
    required this.unit,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final BadgeTone tone;
  final int current;
  final int target;

  /// What [current] and [target] count ("days", "XP"…).
  final String unit;

  bool get earned => current >= target;
  double get progress => target <= 0 ? 1 : (current / target).clamp(0, 1);
  String get progressLabel => '$current / $target $unit';
}

final _datedId = RegExp(r'_([0-9]{8})$');

List<CurioBadge> computeBadges({
  required Set<String> activities,
  required int factsCollected,
  required int discoveriesTotal,
  required int totalXp,
  required int longestStreak,
  Map<String, GameReward> rewards = gameRewards,
}) {
  final games = activities.map(activityGame).toSet();
  final skillsPlayed = {
    for (final game in games)
      if (rewards[game] case final reward?) reward.skill,
  };
  final dailyGames = {
    for (final MapEntry(key: id, value: reward) in rewards.entries)
      if (reward.dated) id,
  };
  // Each daily game is recorded once per date, so the busiest date's count
  // is the most different games finished in a single day.
  final perDay = <String, int>{};
  for (final id in activities) {
    final day = _datedId.firstMatch(id)?.group(1);
    if (day != null) perDay[day] = (perDay[day] ?? 0) + 1;
  }
  final busiestDay = perDay.values.fold(0, (a, b) => a > b ? a : b);

  CurioBadge badge(
    String id,
    String title,
    String description,
    IconData icon,
    BadgeTone tone,
    int current,
    int target,
    String unit,
  ) => CurioBadge(
    id: id,
    title: title,
    description: description,
    icon: icon,
    tone: tone,
    current: current.clamp(0, target),
    target: target,
    unit: unit,
  );

  return [
    badge(
      'first_steps',
      'First steps',
      'Finish your very first game.',
      Icons.flag_rounded,
      BadgeTone.start,
      activities.length,
      1,
      'game',
    ),
    badge(
      'busy_brain',
      'Busy brain',
      'Finish 3 different games in one day.',
      Icons.bolt_rounded,
      BadgeTone.start,
      busiestDay,
      3,
      'in a day',
    ),
    badge(
      'rhythm',
      'Finding a rhythm',
      'Play 3 days in a row.',
      Icons.local_fire_department_rounded,
      BadgeTone.streak,
      longestStreak,
      3,
      'days',
    ),
    badge(
      'week',
      'Week of wonder',
      'Play 7 days in a row.',
      Icons.calendar_month_rounded,
      BadgeTone.streak,
      longestStreak,
      7,
      'days',
    ),
    badge(
      'fortnight',
      'Fortnight of focus',
      'Play 14 days in a row.',
      Icons.workspace_premium_rounded,
      BadgeTone.streak,
      longestStreak,
      14,
      'days',
    ),
    // Preserve the original milestone when new skills are added.
    badge(
      'all_rounder',
      'All-rounder',
      'Play games that train four different skills.',
      Icons.diversity_3_rounded,
      BadgeTone.explore,
      skillsPlayed.length,
      4,
      'skills',
    ),
    badge(
      'try_everything',
      'Try everything',
      'Play 14 different daily games.',
      Icons.explore_rounded,
      BadgeTone.explore,
      games.intersection(dailyGames).length,
      dailyGames.length < 14 ? dailyGames.length : 14,
      'games',
    ),
    badge(
      'story_time',
      'Story time',
      'Reach the end of the Frostlands story.',
      Icons.auto_stories_rounded,
      BadgeTone.explore,
      games.contains('frostlands_night_1') ? 1 : 0,
      1,
      'story',
    ),
    badge(
      'collector',
      'Curious collector',
      'Collect 5 discoveries.',
      Icons.collections_bookmark_rounded,
      BadgeTone.discovery,
      factsCollected,
      5,
      'found',
    ),
    badge(
      'fact_keeper',
      'Fact keeper',
      'Collect 18 discoveries.',
      Icons.menu_book_rounded,
      BadgeTone.discovery,
      factsCollected,
      discoveriesTotal < 18 ? discoveriesTotal : 18,
      'found',
    ),
    badge(
      'growing',
      'Growing explorer',
      'Earn 500 XP.',
      Icons.trending_up_rounded,
      BadgeTone.xp,
      totalXp,
      500,
      'XP',
    ),
    badge(
      'bright_spark',
      'Bright spark',
      'Earn 1,500 XP.',
      Icons.auto_awesome_rounded,
      BadgeTone.xp,
      totalXp,
      1500,
      'XP',
    ),
  ];
}

/// The unearned badge the explorer is closest to, or null once every badge
/// is earned. Ties go to the earlier (usually easier) badge.
CurioBadge? nextBadge(List<CurioBadge> badges) {
  CurioBadge? best;
  for (final badge in badges) {
    if (badge.earned) continue;
    if (best == null || badge.progress > best.progress) best = badge;
  }
  return best;
}
