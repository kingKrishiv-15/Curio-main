import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../common/daily_schedule.dart';
import '../game_catalog.dart';
import 'game_card.dart';

/// Home, Games and section pages all render the very same daily plan.
class DailyPlan extends StatelessWidget {
  const DailyPlan({this.section, super.key});
  final LearningSection? section;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final game in todaysPicks(date: state.today))
          if (section == null || game.section == section) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CurioIconTile(
                    icon: sectionIcon(game.section),
                    color: sectionColor(context, game.section),
                    size: 48,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.section.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          game.section.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GameCard(game: game, done: state.completedToday(game.id)),
            const SizedBox(height: 24),
          ],
      ],
    );
  }
}

class DailyPointsCard extends StatelessWidget {
  const DailyPointsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final completed = state.sectionsCompleted().length;
    final available = todaysPicks(
      date: state.today,
    ).fold(0, (sum, g) => sum + g.xp);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label:
                '${state.totalXp} total XP. ${state.todayXp} XP earned today.',
            excludeSemantics: true,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 20,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your points',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${state.totalXp} XP',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '+${state.todayXp} XP',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            completed == 3
                ? 'All three sections complete. Wonderful work!'
                : '$completed of 3 sections complete · $available XP in today’s plan',
          ),
          const SizedBox(height: 8),
          CurioProgressBar(value: completed / 3),
          const SizedBox(height: 10),
          const Text('Earn XP once per daily game. Replays are for practice.'),
        ],
      ),
    );
  }
}
