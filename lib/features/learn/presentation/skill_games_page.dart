import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_card.dart';
import '../../skills/presentation/skill_quest_page.dart';

/// One skill's games, opened from Home's "Explore by skill" tiles: the
/// level reached so far, then every game that trains it, unplayed first.
class SkillGamesPage extends StatelessWidget {
  const SkillGamesPage({required this.skill, super.key});

  final String skill;

  static const _about = {
    'Number sense': 'Comparing, estimating and working with numbers.',
    'Patterns': 'Spotting rules, sequences and symmetry.',
    'Evidence': 'Telling strong clues from weak ones before deciding.',
    'Reasoning': 'Logic, deduction and sorting ideas into groups.',
  };

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final color = skillColor(context, skill);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final mastery = (state.skills[skill] ?? 0).clamp(0, 1).toDouble();
    bool done(GameEntry g) => g.isDaily
        ? state.completedToday(g.id)
        : state.completedActivities.contains(g.id);
    final games = [
      for (final g in gameCatalog)
        if (g.skill == skill) g,
    ]..sort((a, b) => (done(a) ? 1 : 0).compareTo(done(b) ? 1 : 0));

    return CurioPage(
      title: skill,
      maxWidth: 1040,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          CurioCard(
            color: color.withValues(alpha: .1),
            borderColor: color.withValues(alpha: .32),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CurioIconTile(
                  icon: skillIcon(skill),
                  color: color,
                  size: 52,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${SkillQuestPage.levelFor(mastery)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _about[skill] ?? '',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CurioProgressBar(
                              value: mastery,
                              color: color,
                              height: 7,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(mastery * 100).round()}% mastery',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeading(
            '${games.length} games',
            subtitle: 'A fresh puzzle in each daily game, every day',
          ),
          const SizedBox(height: 12),
          GameGrid(
            children: [for (final g in games) GameCard(game: g, done: done(g))],
          ),
        ],
      ),
    );
  }
}
