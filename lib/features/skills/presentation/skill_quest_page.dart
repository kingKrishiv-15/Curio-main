import 'dart:math';
import 'package:curio/theme/curio_tokens.dart';

import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_row.dart';

class SkillQuestPage extends StatelessWidget {
  const SkillQuestPage({super.key});

  /// Levels 1 to 5 across 0 to 100% mastery (100% is level 5, not a phantom 6).
  static int levelFor(double mastery) => min(5, (mastery * 5).floor() + 1);

  /// The skill with the least mastery, and a game for it, preferring one
  /// not yet played today.
  static (String, GameEntry) recommendation(CurioState state) {
    final todays = todaysPicks(date: state.today);
    final fresh = todays.where((g) => !state.completedToday(g.id)).toList();
    final options = fresh.isEmpty ? todays : fresh;
    options.sort(
      (a, b) =>
          (state.skills[a.skill] ?? 0).compareTo(state.skills[b.skill] ?? 0),
    );
    final next = options.first;
    return (next.skill, next);
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final inkMuted = CurioTokens.textSecondary;
    final (weakest, next) = recommendation(state);
    return CurioPage(
      title: 'Skill Quest',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Every game moves a skill forward.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          for (final skill in learningSkills) ...[
            _SkillCard(
              skill: skill,
              mastery: (state.skills[skill] ?? 0).clamp(0, 1).toDouble(),
              games: [
                for (final g in gameCatalog)
                  if (g.skill == skill) g.title,
              ],
              mutedColor: inkMuted,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          SectionHeading(
            'Recommended next',
            subtitle: '$weakest has the most room to grow',
          ),
          const SizedBox(height: 12),
          GameRow(game: next, done: state.completedToday(next.id)),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.mastery,
    required this.games,
    required this.mutedColor,
  });

  final String skill;
  final double mastery;
  final List<String> games;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final color = skillColor(context, skill);
    return CurioCard(
      elevation: false,
      borderColor: color.withValues(alpha: .35),
      child: Row(
        children: [
          CircleAvatar(
            radius: CurioTokens.radiusCard,
            backgroundColor: color.withValues(alpha: .13),
            foregroundColor: color,
            child: Icon(skillIcon(skill), size: 23),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      'Lv ${SkillQuestPage.levelFor(mastery)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CurioProgressBar(value: mastery, color: color, height: 8),
                const SizedBox(height: 4),
                Text(
                  '${(mastery * 100).round()}% mastery, ${games.join(', ')}',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
