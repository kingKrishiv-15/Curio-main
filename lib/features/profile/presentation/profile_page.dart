import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showMilestones(BuildContext context, CurioState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CurioEyebrow('Milestones'),
              const SizedBox(height: 10),
              Text(
                'A trail of brave thinking',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              CurioStatusStrip(
                icon: Icons.bolt_rounded,
                title: '${state.totalXp} XP collected',
                body: 'Every completed quest adds to your explorer story.',
                color: CurioColors.coral,
              ),
              const SizedBox(height: 10),
              CurioStatusStrip(
                icon: Icons.auto_stories_rounded,
                title: '${state.collectedFacts.length} discoveries saved',
                body: 'Curious facts are archived as you learn.',
                color: CurioColors.forest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccessibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accessibility',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Curio respects your device text scale and screen-reader settings. Controls use clear labels, strong contrast, and generous touch targets.',
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.fromLTRB(16, 25, 16, 104),
        children: [
          const Center(child: CurioEyebrow('Explorer profile')),
          const SizedBox(height: 14),
          Center(
            child: Text(
              state.childName,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          Center(
            child: Text(
              'Curious Explorer · Stage ${state.companionStage}',
              style: const TextStyle(color: CurioColors.inkMuted),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () => _rename(context, state),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('EDIT NAME'),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final stats = <Widget>[
                StatPill(
                  icon: Icons.bolt_rounded,
                  value: '${state.totalXp}',
                  label: 'total XP',
                  color: CurioColors.coral,
                  background: CurioColors.coralSoft,
                ),
                StatPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '${state.streak}',
                  label: 'day streak',
                  color: CurioColors.orange,
                  background: CurioColors.orangeSoft,
                ),
                StatPill(
                  icon: Icons.auto_stories_rounded,
                  value: '${state.collectedFacts.length}',
                  label: 'discoveries',
                  color: CurioColors.tealDark,
                  background: CurioColors.tealSoft,
                ),
              ];
              if (!compact) {
                return Row(
                  children: [
                    stats[0],
                    const SizedBox(width: 10),
                    stats[1],
                    const SizedBox(width: 10),
                    stats[2],
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [stats[0], const SizedBox(width: 10), stats[1]],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [stats[2], const Spacer()]),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          CurioCard(
            color: CurioColors.forestSoft,
            borderColor: CurioColors.forest.withValues(alpha: .18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Companion growth',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${state.xpIntoStage} / 250 XP',
                  style: const TextStyle(
                    color: CurioColors.forestStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 11),
                LinearProgressIndicator(
                  value: state.xpIntoStage / 250,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: CurioColors.surface,
                  color: CurioColors.forest,
                ),
                const SizedBox(height: 7),
                Text(
                  '${250 - state.xpIntoStage} XP until stage ${state.companionStage + 1}',
                  style: const TextStyle(
                    color: CurioColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
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
                  onTap: () => _showMilestones(context, state),
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
                  onTap: () => _showAccessibility(context),
                ),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and feedback',
                  subtitle: 'Get support or share an idea',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Curio',
                    applicationVersion: '1.0',
                    applicationLegalese:
                        'Thoughtful daily games for curious young minds.',
                  ),
                ),
              ],
            ),
          ),
          if (SupabaseConfig.isConfigured) ...[
            const SizedBox(height: 16),
            CurioCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileTile(
                    icon: state.syncError == null
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    title: state.isSyncing
                        ? 'Syncing progress…'
                        : state.syncError == null
                        ? 'Progress is backed up'
                        : 'Cloud sync needs attention',
                    subtitle:
                        state.syncError ?? 'Connected securely to Supabase',
                    onTap: state.retrySync,
                  ),
                  const Divider(height: 1, indent: 66),
                  _ProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'Your cloud progress stays safely stored',
                    onTap: AuthService().signOut,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Curio · Learning should feel like discovery',
              style: TextStyle(color: CurioColors.inkMuted, fontSize: 10),
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
          color: CurioColors.forestSoft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: CurioColors.forest, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: CurioColors.inkMuted, fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: CurioColors.inkMuted,
      ),
    );
  }
}
