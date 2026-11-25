import 'dart:math';
import 'package:curio/theme/curio_tokens.dart';

import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_cards.dart';
import '../../games/presentation/game_emblem.dart';
import '../../games/presentation/game_row.dart';

class SkillQuestPage extends StatelessWidget {
  const SkillQuestPage({super.key});

  /// Levels 1 to 5 across 0 to 100% mastery (100% is level 5, not a phantom 6).
  static int levelFor(double mastery) => min(5, (mastery * 5).floor() + 1);

  /// The skill with the least mastery, and a game for it, preferring one
  /// not yet played today.
  static (String, GameEntry) recommendation(CurioState state) {
    final todays = state.todayGameIds.map(gameById).toList();
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
    final (weakest, next) = recommendation(state);
    return CurioPage(
      title: 'Skill Quest',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          CurioTokens.s24,
          CurioTokens.s8,
          CurioTokens.s24,
          CurioTokens.s32,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Every game moves a skill forward.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: CurioTokens.s8),
          const Text(
            'Mastery grows a little with every game finished.',
            style: CurioType.meta,
          ),
          const SizedBox(height: CurioTokens.s24),
          for (final skill in learningSkills) ...[
            _SkillCard(
              skill: skill,
              mastery: (state.skills[skill] ?? 0).clamp(0, 1).toDouble(),
              games: [
                for (final g in gameCatalog)
                  if (g.skill == skill) g.title,
              ],
            ),
            const SizedBox(height: CurioTokens.s12),
          ],
          const SizedBox(height: CurioTokens.s24),
          SectionHeading(
            'Recommended next',
            subtitle: '$weakest has the most room to grow',
          ),
          const SizedBox(height: CurioTokens.s16),
          GameCompactCard(
            key: Key('game_row_${next.id}'),
            game: next,
            done: state.completedToday(next.id),
            onPlay: () => openGame(context, next),
          ),
        ],
      ),
    );
  }
}

/// One skill: its 3D emblem, its level, a thin bar and the games that
/// train it, in a white card.
class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.mastery,
    required this.games,
  });

  final String skill;
  final double mastery;
  final List<String> games;

  @override
  Widget build(BuildContext context) {
    final color = skillColor(context, skill);
    final level = SkillQuestPage.levelFor(mastery);
    return Semantics(
      container: true,
      label:
          '$skill, level $level, ${(mastery * 100).round()}% mastery. '
          'Games: ${games.join(', ')}',
      excludeSemantics: true,
      child: CurioClay(
        padding: const EdgeInsets.all(CurioTokens.s16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: CurioTokens.wash(color, .14),
                borderRadius: CurioTokens.cardShape,
              ),
              child: GameEmblem(icon: skillIcon(skill), color: color, size: 56),
            ),
            const SizedBox(width: CurioTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(skill, style: CurioType.cardTitle)),
                      CurioChip('Lv $level', tint: color),
                    ],
                  ),
                  const SizedBox(height: CurioTokens.s8),
                  CurioProgressBar(value: mastery, color: color, height: 6),
                  const SizedBox(height: CurioTokens.s8),
                  Text(
                    '${(mastery * 100).round()}% mastery · ${games.join(', ')}',
                    style: CurioTokens.label,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
