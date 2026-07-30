import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return CurioPage(
      title: 'Parent dashboard',
      actions: [
        IconButton(
          onPressed: () {},
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          CurioCard(
            color: CurioColors.navy,
            borderColor: CurioColors.navy,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: CurioColors.teal,
                  child: Icon(
                    Icons.face_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.childName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${state.totalXp} total XP · Stage ${state.companionStage}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ParentStat(
                value: '${state.activitiesCompleted}',
                label: 'activities',
                color: CurioColors.teal,
              ),
              const SizedBox(width: 10),
              _ParentStat(
                value: '${state.streak}',
                label: 'day streak',
                color: CurioColors.coral,
              ),
              const SizedBox(width: 10),
              _ParentStat(
                value: '${state.collectedFacts.length}',
                label: 'discoveries',
                color: const Color(0xFFC78312),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const SectionHeading('Skill snapshot'),
          const SizedBox(height: 12),
          CurioCard(
            child: Column(
              children: state.skills.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 105,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: entry.value,
                                minHeight: 9,
                                backgroundColor: CurioColors.creamDeep,
                                color: CurioColors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(entry.value * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          CurioCard(
            color: CurioColors.goldSoft,
            borderColor: CurioColors.gold,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights_rounded, color: Color(0xFFC78312)),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week\'s insight',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Number sense is the strongest area. Encourage explanations—not just answers—during the next pattern activity.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeading('Family controls'),
          const SizedBox(height: 10),
          const _ControlTile(
            icon: Icons.schedule_rounded,
            title: 'Daily learning goal',
            value: '15 minutes',
          ),
          const _ControlTile(
            icon: Icons.notifications_outlined,
            title: 'Learning reminders',
            value: '6:00 PM',
          ),
          const _ControlTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy and consent',
            value: 'Review',
          ),
        ],
      ),
    );
  }
}

class _ParentStat extends StatelessWidget {
  const _ParentStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: CurioColors.navyMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: CurioColors.tealSoft,
        foregroundColor: CurioColors.tealDark,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: CurioColors.navyMuted)),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
