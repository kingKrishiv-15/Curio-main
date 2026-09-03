import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final forestStrong = curioColor(
      context,
      CurioColors.forestStrong,
      CurioColorsLight.forestStrong,
    );
    final forest = curioColor(context, CurioColors.forest, CurioColorsLight.forest);
    final saffron = curioColor(context, CurioColors.saffron, CurioColorsLight.saffron);
    final saffronStrong = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final saffronSoft = curioColor(
      context,
      CurioColors.saffronSoft,
      CurioColorsLight.saffronSoft,
    );
    final onDark = curioColor(context, CurioColors.onDark, CurioColorsLight.onDark);
    final teal = curioColor(context, CurioColors.teal, CurioColorsLight.teal);
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    return CurioPage(
      title: 'Parent dashboard',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          CurioCard(
            color: forestStrong,
            borderColor: forestStrong,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: forest,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: saffron,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.childName,
                        style: TextStyle(
                          color: onDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${state.totalXp} total XP · Stage ${state.companionStage}',
                        style: TextStyle(
                          color: onDark.withValues(alpha: .66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = <Widget>[
                _ParentStat(
                  value: '${state.activitiesCompleted}',
                  label: 'activities',
                  color: teal,
                ),
                _ParentStat(
                  value: '${state.streak}',
                  label: 'day streak',
                  color: coral,
                ),
                _ParentStat(
                  value: '${state.collectedFacts.length}',
                  label: 'discoveries',
                  color: saffronStrong,
                ),
              ];
              return Row(
                children: [
                  stats[0],
                  const SizedBox(width: 8),
                  stats[1],
                  const SizedBox(width: 8),
                  stats[2],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
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
                            child: CurioProgressBar(
                              value: entry.value,
                              height: 8,
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
          const SizedBox(height: 16),
          CurioCard(
            color: saffronSoft,
            borderColor: saffron.withValues(alpha: .3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurioIconTile(
                  icon: Icons.insights_rounded,
                  color: saffronStrong,
                  size: 40,
                  iconSize: 21,
                  radius: 12,
                ),
                const SizedBox(width: 11),
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
          const SizedBox(height: 16),
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
    final inkMuted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 21,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: inkMuted,
                fontSize: 9,
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
    final inkMuted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: curioColor(context, CurioColors.tealSoft, CurioColorsLight.tealSoft),
        foregroundColor: curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark),
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Text(
        value,
        style: TextStyle(
          color: inkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
