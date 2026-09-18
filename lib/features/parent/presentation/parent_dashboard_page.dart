import 'package:flutter/material.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_gloss.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../family/presentation/family_settings_page.dart';
import '../../family/presentation/privacy_page.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final recent = state.completedActivities.where((id) {
      if (!RegExp(r'_[0-9]{8}$').hasMatch(id)) return false;
      final d = id.substring(id.length - 8);
      final date = DateTime(
        int.parse(d.substring(0, 4)),
        int.parse(d.substring(4, 6)),
        int.parse(d.substring(6, 8)),
      );
      return !date.isBefore(start) && !date.isAfter(now);
    }).toList();
    final practiceDays = recent
        .map((id) => id.substring(id.length - 8))
        .toSet()
        .length;
    final skills = state.skills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hasProgress = state.completedActivities.isNotEmpty;
    return CurioPage(
      title: 'Parent dashboard',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CurioGloss(
            tint: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              children: [
                const MascotBadge(size: 68),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CurioEyebrow('Growing, one discovery at a time'),
                      const SizedBox(height: 10),
                      Text(
                        state.childName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${state.totalXp} XP · Stage ${state.companionStage}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'The last 7 days',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          CurioGloss(
            child: Wrap(
              spacing: 32,
              runSpacing: 20,
              children: [
                _Stat('${recent.length}', 'activities'),
                _Stat('$practiceDays', 'practice days'),
                _Stat('${state.streak}', 'day streak'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Skill snapshot',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          CurioGloss(
            child: Column(
              children: [
                for (final skill in skills)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${skill.key} · ${(skill.value * 100).round()}%'),
                        const SizedBox(height: 8),
                        CurioProgressBar(value: skill.value),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CurioGloss(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little encouragement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  hasProgress
                      ? '${skills.first.key} is currently ${state.childName}’s strongest area. Try a ${skills.last.key.toLowerCase()} activity next, and ask them to explain their thinking.'
                      : 'Your first completed activity will start the learning snapshot. Let your explorer choose what looks interesting.',
                  style: const TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your family space',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          CurioGloss(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Link(
                  Icons.insights_outlined,
                  'Weekly reports',
                  'Your learning story, week by week',
                  () => openPage(
                    context,
                    const FamilyInboxPage(reportsOnly: true),
                  ),
                ),
                _Link(
                  Icons.notifications_outlined,
                  'Notifications',
                  'Reminders and report updates',
                  () => openPage(context, const FamilyInboxPage()),
                ),
                _Link(
                  Icons.tune_rounded,
                  'Family preferences',
                  '${state.dailyGoal} activities a day · reminders · email',
                  () => openPage(context, const FamilySettingsPage()),
                ),
                _Link(
                  Icons.privacy_tip_outlined,
                  'Privacy and account',
                  'Review, export, or delete your data',
                  () => openPage(context, const PrivacyPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mastery reflects completed practice, not a formal assessment.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      Text(label),
    ],
  );
}

class _Link extends StatelessWidget {
  const _Link(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
