import 'package:curio/features/games/common/game_rewards.dart';
import 'package:curio/features/profile/domain/badges.dart';
import 'package:flutter_test/flutter_test.dart';

CurioBadge _find(List<CurioBadge> badges, String id) =>
    badges.firstWhere((b) => b.id == id);

void main() {
  test(
    'a brand-new explorer has earned nothing and is nearest to first steps',
    () {
      final badges = computeBadges(
        activities: {},
        factsCollected: 0,
        discoveriesTotal: 18,
        totalXp: 0,
        longestStreak: 0,
      );
      expect(badges.where((b) => b.earned), isEmpty);
      expect(nextBadge(badges)?.id, 'first_steps');
    },
  );

  test('badges are worked out from the activity history', () {
    final badges = computeBadges(
      activities: {
        'squeeze_20261007',
        'loophole_20261008',
        'sequence_20261008',
        'odd_cluster_20261008',
        'frostlands_night_1',
      },
      factsCollected: 5,
      discoveriesTotal: 18,
      totalXp: 620,
      longestStreak: 2,
    );
    expect(_find(badges, 'first_steps').earned, isTrue);
    // Three different games on 8 October.
    expect(_find(badges, 'busy_brain').earned, isTrue);
    expect(_find(badges, 'rhythm').progressLabel, '2 / 3 days');
    // Number sense, Evidence, Patterns and Reasoning (Odd Cluster + story).
    expect(_find(badges, 'all_rounder').earned, isTrue);
    expect(_find(badges, 'story_time').earned, isTrue);
    expect(_find(badges, 'collector').earned, isTrue);
    expect(_find(badges, 'growing').earned, isTrue);
    expect(_find(badges, 'bright_spark').earned, isFalse);

    const dailyCount = 14;
    expect(
      _find(badges, 'try_everything').progressLabel,
      '4 / $dailyCount games',
    );
  });

  test('catalogue expansion keeps previously earned collection badges', () {
    final legacy = gameRewards.keys.where(
      (id) => ![
        'memory_match',
        'memory_trail',
        'word_wise',
        'word_builder',
      ].contains(id),
    );
    final badges = computeBadges(
      activities: {
        for (final id in legacy) gameRewards[id]!.dated ? '${id}_20261022' : id,
      },
      factsCollected: 18,
      discoveriesTotal: 22,
      totalXp: 2000,
      longestStreak: 14,
    );
    expect(_find(badges, 'all_rounder').earned, isTrue);
    expect(_find(badges, 'try_everything').earned, isTrue);
    expect(_find(badges, 'fact_keeper').earned, isTrue);
  });

  test('progress never runs past the target', () {
    final badges = computeBadges(
      activities: {'squeeze_20261008'},
      factsCollected: 40,
      discoveriesTotal: 18,
      totalXp: 99999,
      longestStreak: 30,
    );
    for (final b in badges) {
      expect(b.current, lessThanOrEqualTo(b.target), reason: b.id);
      expect(b.progress, inInclusiveRange(0, 1), reason: b.id);
    }
    expect(_find(badges, 'fact_keeper').earned, isTrue);
    expect(_find(badges, 'fortnight').earned, isTrue);
  });

  test('activityGame strips only a date suffix', () {
    expect(activityGame('odd_cluster_20261009'), 'odd_cluster');
    expect(activityGame('frostlands_night_1'), 'frostlands_night_1');
    expect(activityGame('link_lab'), 'link_lab');
  });
}
