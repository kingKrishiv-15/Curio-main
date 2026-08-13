import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../domain/discovery.dart';

class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final progress = state.collectedFacts.length / discoveries.length;
    return CurioPage(
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 112),
        children: [
          PageIntro(
            eyebrow: 'Knowledge collection',
            title: 'Discoveries',
            subtitle:
                '${state.collectedFacts.length} of ${discoveries.length} curious facts uncovered',
            trailing: ProgressRing(
              value: progress,
              color: CurioColors.orange,
              child: Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CurioCard(
            color: CurioColors.navy,
            borderColor: CurioColors.navy,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: CurioColors.auroraGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.collections_bookmark_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your curiosity archive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every completed challenge can reveal a new idea worth remembering.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionHeading(
            'Collected cards',
            subtitle: 'Tap into the facts you’ve earned through play',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 218,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: discoveries.length,
            itemBuilder: (context, index) {
              final discovery = discoveries[index];
              final collected = state.collectedFacts.contains(discovery.id);
              return CurioCard(
                color: collected ? Colors.white : CurioColors.surfaceMuted,
                borderColor: collected
                    ? CurioColors.teal.withValues(alpha: .2)
                    : CurioColors.creamDeep,
                padding: const EdgeInsets.all(16),
                elevation: collected,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: collected
                                ? CurioColors.tealSoft
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            collected ? discovery.icon : Icons.lock_outline,
                            color: collected
                                ? CurioColors.tealDark
                                : CurioColors.navyMuted,
                          ),
                        ),
                        const Spacer(),
                        if (collected)
                          const Icon(
                            Icons.bookmark_added_rounded,
                            color: CurioColors.coral,
                            size: 19,
                          ),
                      ],
                    ),
                    const Spacer(),
                    CurioEyebrow(
                      collected ? discovery.category : 'Locked',
                      color: collected
                          ? CurioColors.coral
                          : CurioColors.navyMuted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      collected ? discovery.title : 'Keep exploring',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      collected
                          ? discovery.fact
                          : 'Complete another activity to reveal this discovery.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CurioColors.navyMuted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
