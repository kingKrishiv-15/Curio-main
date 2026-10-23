import 'package:flutter/material.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/game_catalog.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../family/presentation/family_settings_page.dart';
import '../../family/presentation/privacy_page.dart';
import '../../family/presentation/weekly_email_card.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});
  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  int _emailRevision = 0;

  Future<void> _preferences() async {
    await openPage(context, const FamilySettingsPage());
    if (mounted) setState(() => _emailRevision++);
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 6);
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
    return CurioPage(
      title: 'Parent dashboard',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CurioClay(
            padding: const EdgeInsets.all(20),
            radius: 26,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              children: [
                const MascotBadge(size: 68),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CurioEyebrow('Your explorer'),
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
          CurioClay(
            padding: const EdgeInsets.all(20),
            radius: 26,
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
          CurioClay(
            padding: const EdgeInsets.all(20),
            radius: 26,
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
                        CurioProgressBar(
                          value: skill.value,
                          color: skillColor(context, skill.key),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CurioClay(
            padding: const EdgeInsets.all(20),
            radius: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little encouragement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  _encouragement(state, skills),
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
          WeeklyEmailCard(key: ValueKey(_emailRevision)),
          const SizedBox(height: 16),
          CurioClay(
            radius: 26,
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
                  _preferences,
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

String _encouragement(CurioState state, List<MapEntry<String, double>> skills) {
  if (state.completedActivities.isEmpty) {
    return 'Your first completed activity will start the learning snapshot. Let your explorer choose what looks interesting.';
  }
  final (weakest, next) = SkillQuestPage.recommendation(state);
  final even = skills.first.value - skills.last.value < .01;
  final lead = even
      ? '${state.childName} has been practising evenly across their learning skills.'
      : '${skills.first.key} is currently ${state.childName}’s strongest area.';
  return '$lead To grow ${weakest.toLowerCase()}, try ${next.title} together — and ask them to explain their thinking out loud.';
}
