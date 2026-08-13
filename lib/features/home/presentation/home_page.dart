import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/link_lab/presentation/link_lab_page.dart';
import '../../games/signal_grid/presentation/signal_grid_page.dart';
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
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          Row(
            children: [
              const CurioBrand(compact: true),
              const Spacer(),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Badge(
                  child: Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 5),
              IconButton.filledTonal(
                tooltip: 'Parent dashboard',
                onPressed: () => openPage(context, const ParentDashboardPage()),
                icon: const Icon(Icons.family_restroom_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const MascotBadge(size: 66),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: CurioColors.navyMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${state.childName}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: state.dailyGoalCompleted / 3,
                color: CurioColors.coral,
                child: Text(
                  '${state.dailyGoalCompleted}/3',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '${state.streak} days',
                label: 'learning streak',
                color: CurioColors.orange,
                background: CurioColors.orangeSoft,
              ),
              const SizedBox(width: 10),
              StatPill(
                icon: Icons.bolt_rounded,
                value: '${state.totalXp} XP',
                label: 'total progress',
                color: CurioColors.tealDark,
                background: CurioColors.tealSoft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DailyQuestCard(
            completed: state.completedToday('squeeze'),
            onTap: () => openPage(context, const SqueezePage()),
          ),
          const SizedBox(height: 26),
          SectionHeading(
            'Today’s brain breaks',
            subtitle: 'Short, focused, and new every day',
            trailing: TextButton(
              onPressed: onExplore,
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 560
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _QuickGameCard(
                      title: 'Link Lab',
                      subtitle: 'Find four hidden knowledge groups',
                      icon: Icons.hub_rounded,
                      color: CurioColors.coral,
                      meta: '3–5 min · Reasoning',
                      completed: state.completedToday('link_lab'),
                      onTap: () => openPage(context, const LinkLabPage()),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickGameCard(
                      title: 'Signal Grid',
                      subtitle: 'Balance sparks and waves with logic',
                      icon: Icons.grid_4x4_rounded,
                      color: CurioColors.teal,
                      meta: '4–6 min · Logic',
                      completed: state.completedToday('signal_grid'),
                      onTap: () => openPage(context, const SignalGridPage()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const SectionHeading(
            'Your learning path',
            subtitle: 'A personalised recommendation from your activity',
          ),
          const SizedBox(height: 12),
          CurioCard(
            onTap: () => openPage(context, const SkillQuestPage()),
            child: Row(
              children: [
                ProgressRing(
                  value: state.skills['Number sense'] ?? 0,
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: CurioColors.tealDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CurioEyebrow(
                        'Recommended next',
                        color: CurioColors.tealDark,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Strengthen number sense',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You’re close to your next mastery milestone.',
                        style: TextStyle(
                          color: CurioColors.navyMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: CurioColors.navyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CurioColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35165C72),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -35,
                child: Icon(
                  Icons.blur_circular_rounded,
                  size: 190,
                  color: Colors.white.withValues(alpha: .07),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                        colors: [Color(0x24FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: Text(
                            completed ? 'COMPLETED' : "TODAY'S QUEST",
                            style: const TextStyle(
                              color: CurioColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '+80 XP',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 21),
                    const Text(
                      'Squeeze the\nsecret number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seven guesses. Smart clues. One hidden number.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 9,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .9),
                            ),
                          ),
                          child: Text(
                            completed ? 'Play again' : 'Start challenge',
                            style: const TextStyle(
                              color: CurioColors.coralDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: .65),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '2–4 min',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .72),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickGameCard extends StatelessWidget {
  const _QuickGameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.meta,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String meta;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CurioCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              completed ? Icons.check_rounded : icon,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CurioColors.navyMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  completed ? 'Completed today' : meta,
                  style: TextStyle(
                    color: completed ? CurioColors.green : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: CurioColors.navyMuted),
        ],
      ),
    );
  }
}
