import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/parental_gate.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../discoveries/domain/discovery.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../../family/presentation/accessibility_page.dart';
import '../../family/presentation/help_page.dart';
import '../../family/presentation/privacy_page.dart';
import '../domain/badges.dart';
import 'badges_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _rename(BuildContext context, CurioState state) async {
    final name = await showTextPrompt(
      context,
      title: 'Explorer name',
      initialText: state.childName,
      hint: 'What should we call you?',
      maxLength: 18,
      confirmLabel: 'Save name',
      validator: (value) =>
          value.trim().isEmpty ? 'Add a name of at least one letter.' : null,
    );
    if (name != null) state.renameChild(name);
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final badges = computeBadges(
      activities: state.completedActivities,
      factsCollected: discoveries
          .where((d) => state.collectedFacts.contains(d.id))
          .length,
      discoveriesTotal: discoveries.length,
      totalXp: state.totalXp,
      longestStreak: state.longestStreak,
    );
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final forestSoft = curioColor(
      context,
      CurioColors.forestSoft,
      CurioColorsLight.forestSoft,
    );
    // Text colour: the bright forest in dark mode, the deep one on light.
    final forestStrong = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );

    return CurioPage(
      extendBehindBottom: true,
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 25, 16, 104),
        children: [
          Center(child: ExplorerAvatar(name: state.childName, size: 84)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              state.childName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Curious Explorer · Stage ${state.companionStage}',
              style: TextStyle(color: inkMuted),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _rename(context, state),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit name'),
            ),
          ),
          const SizedBox(height: 16),
          CurioStatRow(
            tiles: [
              CurioStatTile(
                value: '${state.totalXp}',
                label: 'Total XP',
                tone: StatTone.coral,
              ),
              CurioStatTile(
                value: '${state.streak}',
                label: 'Day streak',
                tone: StatTone.gold,
                semanticLabel: '${state.streak} day streak',
              ),
              CurioStatTile(
                value: '${state.collectedFacts.length}',
                label: 'Discoveries',
                tone: StatTone.forest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CurioCard(
            color: forestSoft,
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
                  style: TextStyle(
                    color: forestStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 11),
                CurioProgressBar(
                  value: state.xpIntoStage / 250,
                  color: forest,
                  height: 10,
                ),
                const SizedBox(height: 7),
                Text(
                  '${250 - state.xpIntoStage} XP until stage ${state.companionStage + 1}',
                  style: TextStyle(color: inkMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BadgeShelf(
            badges: badges,
            onOpen: () => showBadgesSheet(context, badges),
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
                  icon: Icons.family_restroom_rounded,
                  title: 'Parent dashboard',
                  subtitle: 'Insights and family controls',
                  onTap: () =>
                      ParentalGate.open(context, const ParentDashboardPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CurioCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _ThemeToggleTile(),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accessibility',
                  subtitle: 'Motion, contrast and reading options',
                  onTap: () => openPage(context, const AccessibilityPage()),
                ),
                const Divider(height: 1, indent: 66),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and feedback',
                  subtitle: 'Get support or share an idea',
                  onTap: () => openPage(context, const HelpPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CurioCard(
            padding: EdgeInsets.zero,
            child: _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy and account',
              subtitle: 'Your data and your choices',
              onTap: () => ParentalGate.open(context, const PrivacyPage()),
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
                    onTap: () async {
                      await state.retrySync();
                      if (!context.mounted) return;
                      if (state.syncError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please reconnect and sync before signing out so your progress is safe.',
                            ),
                          ),
                        );
                        return;
                      }
                      try {
                        await AuthService().signOut();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not sign out. Please try again.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Curio · Learning should feel like discovery',
              style: TextStyle(color: inkMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// A "Dark mode" row with a switch, bound to the app-wide [ThemeController]
/// via [CurioThemeScope]. The one place the light/dark toggle lives.
class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    final controller = CurioThemeScope.of(context);
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final forestSoft = curioColor(
      context,
      CurioColors.forestSoft,
      CurioColorsLight.forestSoft,
    );
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = controller.isDark;
        return ListTile(
          onTap: controller.toggle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          leading: CurioIconTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: forest,
            background: forestSoft,
            size: 40,
            iconSize: 21,
            radius: 13,
          ),
          title: const Text(
            'Dark mode',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isDark
                ? 'On — easier on the eyes at night'
                : 'Off — bright and light',
            style: TextStyle(color: inkMuted, fontSize: 11),
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (_) => controller.toggle(),
          ),
        );
      },
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
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final forestSoft = curioColor(
      context,
      CurioColors.forestSoft,
      CurioColorsLight.forestSoft,
    );
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CurioIconTile(
        icon: icon,
        color: forest,
        background: forestSoft,
        size: 40,
        iconSize: 21,
        radius: 13,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: TextStyle(color: inkMuted, fontSize: 11)),
      trailing: Icon(Icons.chevron_right_rounded, color: inkMuted),
    );
  }
}
