import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _rename(BuildContext context, CurioState state) {
    final controller = TextEditingController(text: state.childName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Explorer name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 18,
          decoration: const InputDecoration(
            hintText: 'What should we call you?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              state.renameChild(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save name'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return CurioPage(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 112),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const MascotBadge(size: 104),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: IconButton.filled(
                    tooltip: 'Change explorer name',
                    onPressed: () => _rename(context, state),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    style: IconButton.styleFrom(
                      backgroundColor: CurioColors.coral,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              state.childName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Center(
            child: Text(
              'Curious Explorer · Companion stage ${state.companionStage}',
              style: const TextStyle(color: CurioColors.navyMuted),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              StatPill(
                icon: Icons.bolt_rounded,
                value: '${state.totalXp}',
                label: 'total XP',
                color: CurioColors.coral,
                background: CurioColors.coralSoft,
              ),
              const SizedBox(width: 10),
              StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '${state.streak}',
                label: 'day streak',
                color: CurioColors.orange,
                background: CurioColors.orangeSoft,
              ),
              const SizedBox(width: 10),
              StatPill(
                icon: Icons.auto_stories_rounded,
                value: '${state.collectedFacts.length}',
                label: 'discoveries',
                color: CurioColors.tealDark,
                background: CurioColors.tealSoft,
              ),
            ],
          ),
          const SizedBox(height: 22),
          CurioCard(
            color: CurioColors.coralSoft,
            borderColor: CurioColors.coral.withValues(alpha: .2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Companion growth',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${state.xpIntoStage} / 250 XP',
                      style: const TextStyle(
                        color: CurioColors.coralDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                LinearProgressIndicator(
                  value: state.xpIntoStage / 250,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: Colors.white,
                  color: CurioColors.coral,
                ),
                const SizedBox(height: 7),
                Text(
                  '${250 - state.xpIntoStage} XP until stage ${state.companionStage + 1}',
                  style: const TextStyle(
                    color: CurioColors.navyMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeading('Your space'),
          const SizedBox(height: 10),
          CurioCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.route_rounded,
                  title: 'Skills and mastery',
                  subtitle: 'See your learning map',
                  onTap: () => openPage(context, const SkillQuestPage()),
                ),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.emoji_events_outlined,
                  title: 'Badges and milestones',
                  subtitle: 'View achievements',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.family_restroom_rounded,
                  title: 'Parent dashboard',
                  subtitle: 'Insights and family controls',
                  onTap: () => openPage(context, const ParentDashboardPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CurioCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessibility',
                  subtitle: 'Motion, contrast and reading options',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and feedback',
                  subtitle: 'Get support or share an idea',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Curio 1.0 · Learning should feel like discovery',
              style: TextStyle(color: CurioColors.navyMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CurioColors.surfaceMuted,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: CurioColors.coral, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: CurioColors.navyMuted, fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: CurioColors.navyMuted,
      ),
    );
  }
}
