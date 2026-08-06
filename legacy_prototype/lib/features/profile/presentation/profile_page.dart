import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../parent/presentation/parent_dashboard_page.dart';

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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
        children: [
          const Center(child: MascotBadge(size: 100)),
          const SizedBox(height: 13),
          Center(
            child: Text(
              state.childName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Center(
            child: Text(
              'Curious Explorer · Stage ${state.companionStage}',
              style: const TextStyle(color: CurioColors.navyMuted),
            ),
          ),
          const SizedBox(height: 22),
          CurioCard(
            color: CurioColors.tealSoft,
            borderColor: CurioColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${state.xpIntoStage} / 250 XP',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      'Stage ${state.companionStage + 1}',
                      style: const TextStyle(
                        color: CurioColors.tealDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: state.xpIntoStage / 250,
                    minHeight: 11,
                    backgroundColor: Colors.white,
                    color: CurioColors.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ProfileTile(
            icon: Icons.edit_rounded,
            title: 'Change explorer name',
            onTap: () => _rename(context, state),
          ),
          _ProfileTile(
            icon: Icons.pets_rounded,
            title: 'Companion collection',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.emoji_events_rounded,
            title: 'Badges and milestones',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.family_restroom_rounded,
            title: 'Open parent dashboard',
            onTap: () => openPage(context, const ParentDashboardPage()),
          ),
          _ProfileTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.help_outline_rounded,
            title: 'Help and feedback',
            onTap: () {},
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Curio prototype · Local progress mode',
              style: TextStyle(color: CurioColors.navyMuted, fontSize: 11),
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
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: CurioColors.coralSoft,
        foregroundColor: CurioColors.coral,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
