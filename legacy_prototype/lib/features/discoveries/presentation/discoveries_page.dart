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
    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Text(
            'YOUR TREASURE SHELF',
            style: TextStyle(
              color: CurioColors.coral,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 5),
          Text('Discoveries', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            '${state.collectedFacts.length} of ${discoveries.length} curious facts collected',
            style: const TextStyle(color: CurioColors.navyMuted),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: state.collectedFacts.length / discoveries.length,
              minHeight: 10,
              backgroundColor: CurioColors.creamDeep,
              color: CurioColors.coral,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 210,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: discoveries.length,
            itemBuilder: (context, index) {
              final discovery = discoveries[index];
              final collected = state.collectedFacts.contains(discovery.id);
              return CurioCard(
                color: collected ? Colors.white : CurioColors.creamDeep,
                borderColor: collected
                    ? CurioColors.teal.withValues(alpha: .3)
                    : CurioColors.creamDeep,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: collected
                          ? CurioColors.tealSoft
                          : Colors.white54,
                      child: Icon(
                        collected ? discovery.icon : Icons.lock_rounded,
                        color: collected
                            ? CurioColors.tealDark
                            : CurioColors.navyMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      collected ? discovery.category.toUpperCase() : 'LOCKED',
                      style: const TextStyle(
                        color: CurioColors.coral,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collected ? discovery.title : 'Keep exploring',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
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
