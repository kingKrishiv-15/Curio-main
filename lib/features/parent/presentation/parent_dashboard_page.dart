import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/game_catalog.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
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
        padding: const EdgeInsets.fromLTRB(
          CurioTokens.s24,
          CurioTokens.s8,
          CurioTokens.s24,
          CurioTokens.s32,
        ),
        children: [
          CurioClay(
            raised: true,
            padding: const EdgeInsets.all(CurioTokens.s16),
            child: Row(
              children: [
                ExplorerAvatar(name: state.childName, size: 64),
                const SizedBox(width: CurioTokens.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(state.childName, style: CurioTokens.title),
                      ),
                      Text(
                        '${state.totalXp} XP · Stage ${state.companionStage}',
                        style: CurioType.meta,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CurioTokens.s32),
          const SectionHeading('The last 7 days'),
          const SizedBox(height: CurioTokens.s16),
          CurioClay(
            padding: const EdgeInsets.symmetric(vertical: CurioTokens.s16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Stat('${recent.length}', 'activities'),
                  const VerticalDivider(width: 1),
                  _Stat('$practiceDays', 'practice days'),
                  const VerticalDivider(width: 1),
                  _Stat('${state.streak}', 'day streak'),
                ],
              ),
            ),
          ),
          const SizedBox(height: CurioTokens.s32),
          const SectionHeading('Skill snapshot'),
          const SizedBox(height: CurioTokens.s16),
          CurioClay(
            padding: const EdgeInsets.all(CurioTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final skill in skills) ...[
                  if (skill != skills.first)
                    const SizedBox(height: CurioTokens.s16),
                  Row(
                    children: [
                      Expanded(child: Text(skill.key, style: CurioType.strong)),
                      Text(
                        '${(skill.value * 100).round()}%',
                        style: CurioType.meta,
                      ),
                    ],
                  ),
                  const SizedBox(height: CurioTokens.s8),
                  CurioProgressBar(
                    value: skill.value,
                    color: skillColor(context, skill.key),
                    height: 6,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: CurioTokens.s16),
          CurioClay(
            color: CurioTokens.wash(CurioTokens.tintMaths, .1),
            padding: const EdgeInsets.all(CurioTokens.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: CurioTokens.tintMaths,
                  ),
                ),
                const SizedBox(width: CurioTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little encouragement',
                        style: CurioType.cardTitle,
                      ),
                      const SizedBox(height: CurioTokens.s4),
                      Text(
                        _encouragement(state, skills),
                        style: CurioTokens.bodySmall.copyWith(
                          color: CurioTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CurioTokens.s32),
          const SectionHeading('Your family space'),
          const SizedBox(height: CurioTokens.s16),
          WeeklyEmailCard(key: ValueKey(_emailRevision)),
          const SizedBox(height: CurioTokens.s16),
          CurioListGroup(
            children: [
              CurioListRow(
                icon: Icons.insights_outlined,
                title: 'Weekly reports',
                subtitle: 'Your learning story, week by week',
                onTap: () =>
                    openPage(context, const FamilyInboxPage(reportsOnly: true)),
              ),
              CurioListRow(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Reminders and report updates',
                onTap: () => openPage(context, const FamilyInboxPage()),
              ),
              CurioListRow(
                icon: Icons.tune_rounded,
                title: 'Family preferences',
                subtitle:
                    '${state.dailyGoal} activities a day, reminders, email',
                onTap: _preferences,
              ),
              CurioListRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy and account',
                subtitle: 'Review, export, or delete your data',
                onTap: () => openPage(context, const PrivacyPage()),
              ),
            ],
          ),
          const SizedBox(height: CurioTokens.s16),
          const Text(
            'Mastery reflects completed practice, not a formal assessment.',
            style: CurioTokens.label,
          ),
        ],
      ),
    );
  }
}

/// One number in the seven-day card: bold value, its name underneath.
class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CurioTokens.s8),
        child: Column(
          children: [
            Text(value, style: CurioTokens.display),
            Text(label, textAlign: TextAlign.center, style: CurioTokens.label),
          ],
        ),
      ),
    ),
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
  return '$lead To grow ${weakest.toLowerCase()}, try ${next.title} together, and ask them to explain their thinking out loud.';
}
