import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';

class SkillQuestPage extends StatelessWidget {
  const SkillQuestPage({super.key});

  /// Levels 1–5 across 0–100% mastery (100% is level 5, not a phantom 6).
  static int levelFor(double mastery) => min(5, (mastery * 5).floor() + 1);

  /// The skill with the least mastery, and a game for it — preferring one
  /// not yet played today.
  static (String, GameEntry) recommendation(CurioState state) {
    final weakest = learningSkills.reduce(
      (a, b) => (state.skills[a] ?? 0) <= (state.skills[b] ?? 0) ? a : b,
    );
    final options = dailyGames.where((g) => g.skill == weakest).toList();
    final fresh = options.where((g) => !state.completedToday(g.id));
    return (weakest, fresh.isNotEmpty ? fresh.first : options.first);
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final (weakest, next) = recommendation(state);
    return CurioPage(
      title: 'Skill Quest',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const CurioEyebrow('Your learning map'),
          const SizedBox(height: 6),
          Text(
            'Every game moves a skill forward.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 22),
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
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          SectionHeading(
            'Recommended next',
            subtitle: '$weakest has the most room to grow',
          ),
          const SizedBox(height: 10),
          GameCard(
            game: next,
            style: GameCardStyle.row,
            done: state.completedToday(next.id),
          ),
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
            radius: 23,
            backgroundColor: color.withValues(alpha: .13),
            foregroundColor: color,
            child: Icon(skillIcon(skill), size: 23),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 9),
                CurioProgressBar(value: mastery, color: color, height: 8),
                const SizedBox(height: 5),
                Text(
                  '${(mastery * 100).round()}% mastery · ${games.join(', ')}',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11.5,
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
