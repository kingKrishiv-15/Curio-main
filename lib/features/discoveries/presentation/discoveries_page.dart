import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../domain/discovery.dart';

class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final progress = state.collectedFacts.length / discoveries.length;
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final forestStrong = curioColor(
      context,
      CurioColors.forestStrong,
      CurioColorsLight.forestStrong,
    );
    final saffron = curioColor(context, CurioColors.saffron, CurioColorsLight.saffron);
    final onDark = curioColor(context, CurioColors.onDark, CurioColorsLight.onDark);
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final surfaceMuted = curioColor(
      context,
      CurioColors.surfaceMuted,
      CurioColorsLight.surfaceMuted,
    );
    final teal = curioColor(context, CurioColors.teal, CurioColorsLight.teal);
    final creamDeep = curioColor(context, CurioColors.creamDeep, CurioColorsLight.creamDeep);
    final tealSoft = curioColor(context, CurioColors.tealSoft, CurioColorsLight.tealSoft);
    final tealDark = curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark);
    final navyMuted = curioColor(context, CurioColors.navyMuted, CurioColorsLight.navyMuted);
    return CurioPage(
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
        children: [
          PageIntro(
            eyebrow: 'Curiosity archive',
            title: 'Ideas worth keeping.',
            subtitle:
                '${state.collectedFacts.length} of ${discoveries.length} curious facts uncovered',
            trailing: ProgressRing(
              value: progress,
              color: coral,
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
            color: forestStrong,
            borderColor: forestStrong,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: saffron,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    color: forestStrong,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A cabinet of curious things',
                        style: TextStyle(
                          color: onDark,
                          fontSize: 17,
                          fontFamily: 'Fraunces',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every completed challenge can reveal a new idea worth remembering.',
                        style: TextStyle(
                          color: onDark.withValues(alpha: .65),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680
                  ? 3
                  : constraints.maxWidth >= 350
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: columns == 1 ? 172 : 210,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: discoveries.length,
                itemBuilder: (context, index) {
                  final discovery = discoveries[index];
                  final collected = state.collectedFacts.contains(discovery.id);
                  return CurioCard(
                    color: collected ? surface : surfaceMuted,
                    borderColor: collected
                        ? teal.withValues(alpha: .2)
                        : creamDeep,
                    padding: const EdgeInsets.all(13),
                    elevation: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: collected ? tealSoft : surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Icon(
                                collected ? discovery.icon : Icons.lock_outline,
                                color: collected ? tealDark : navyMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (collected)
                              Icon(
                                Icons.bookmark_added_rounded,
                                color: coral,
                                size: 19,
                              ),
                          ],
                        ),
                        const Spacer(),
                        CurioEyebrow(
                          collected ? discovery.category : 'Locked',
                          color: collected ? coral : navyMuted,
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
                          maxLines: columns == 1 ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navyMuted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
