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
      CurioColors.teal,
      CurioColors.coral,
      CurioColors.goldStrong,
      CurioColors.frost,
    ];

    return CurioPage(
      title: 'Skill Quest',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            'YOUR LEARNING MAP',
            style: TextStyle(
              color: CurioColors.coral,
              fontSize: 11,
              fontWeight: FontWeight.w900,
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
                borderColor: colors[index].withValues(alpha: .35),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors[index].withValues(alpha: .13),
                      foregroundColor: colors[index],
                      child: Icon(icons[index], size: 28),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: item.value,
                              minHeight: 9,
                              backgroundColor: CurioColors.creamDeep,
                              color: colors[index],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${(item.value * 100).round()}% mastery',
                            style: const TextStyle(
                              color: CurioColors.navyMuted,
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
            color: CurioColors.tealSoft,
            borderColor: CurioColors.teal,
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
