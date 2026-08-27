import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';

class SkillQuestPage extends StatelessWidget {
  const SkillQuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final entries = state.skills.entries.toList();
    const icons = [
      Icons.calculate_rounded,
      Icons.blur_on_rounded,
      Icons.manage_search_rounded,
      Icons.psychology_rounded,
    ];
    const colors = [
      CurioColors.forest,
      CurioColors.coral,
      CurioColors.goldStrong,
      CurioColors.blue,
    ];

    return CurioPage(
      title: 'Skill Quest',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'YOUR LEARNING MAP',
            style: TextStyle(
              color: CurioColors.forest,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Every game moves a skill forward.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 22),
          ...List.generate(entries.length, (index) {
            final item = entries[index];
            final level = (item.value * 5).floor() + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CurioCard(
                elevation: false,
                borderColor: colors[index].withValues(alpha: .35),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: colors[index].withValues(alpha: .13),
                      foregroundColor: colors[index],
                      child: Icon(icons[index], size: 23),
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
                                  item.key,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                'Lv $level',
                                style: TextStyle(
                                  color: colors[index],
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          CurioProgressBar(
                            value: item.value,
                            color: colors[index],
                            height: 8,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${(item.value * 100).round()}% mastery',
                            style: const TextStyle(
                              color: CurioColors.inkMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          CurioCard(
            color: CurioColors.forestSoft,
            borderColor: CurioColors.forest.withValues(alpha: .25),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.explore_rounded, color: CurioColors.tealDark),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Recommended next: play Pattern Forge to strengthen pattern recognition and explanation skills.',
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
