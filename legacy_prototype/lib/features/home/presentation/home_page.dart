import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/squeeze/presentation/squeeze_page.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.onExplore, super.key});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Row(
            children: [
              const MascotBadge(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        color: CurioColors.navyMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${state.childName}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Parent dashboard',
                onPressed: () => openPage(context, const ParentDashboardPage()),
                icon: const Icon(Icons.family_restroom_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '${state.streak}',
                label: 'day streak',
                color: const Color(0xFFC78312),
                background: CurioColors.goldSoft,
              ),
              const SizedBox(width: 10),
              StatPill(
                icon: Icons.pets_rounded,
                value: 'Stage ${state.companionStage}',
                label: 'companion',
                color: CurioColors.green,
                background: CurioColors.greenSoft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          CurioCard(
            onTap: () => openPage(context, const SqueezePage()),
            color: CurioColors.navy,
            borderColor: CurioColors.navy,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -28,
                  child: Icon(
                    Icons.bubble_chart_rounded,
                    size: 128,
                    color: Colors.white.withValues(alpha: .07),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.today_rounded, color: CurioColors.gold),
                        SizedBox(width: 8),
                        Text(
                          'TODAY\'S QUEST',
                          style: TextStyle(
                            color: CurioColors.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Can you squeeze the\nsecret number?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seven guesses. Clever clues. One hidden number.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Text(
                          'PLAY NOW',
                          style: TextStyle(
                            color: CurioColors.teal,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: .8,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: CurioColors.teal,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeading('Continue your journey'),
          const SizedBox(height: 12),
          CurioCard(
            onTap: () => openPage(context, const SkillQuestPage()),
            color: CurioColors.tealSoft,
            borderColor: CurioColors.teal.withValues(alpha: .35),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: CurioColors.teal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number Sense · Level 3',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: const LinearProgressIndicator(
                          value: .62,
                          minHeight: 9,
                          color: CurioColors.teal,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '62% to the next level',
                        style: TextStyle(
                          color: CurioColors.tealDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeading('Ways to learn'),
          const SizedBox(height: 12),
          ModeTile(
            title: 'Explore all modes',
            subtitle: 'Maths, mysteries, stories and thinking games',
            icon: Icons.explore_rounded,
            color: CurioColors.coral,
            onTap: onExplore,
          ),
        ],
      ),
    );
  }
}
