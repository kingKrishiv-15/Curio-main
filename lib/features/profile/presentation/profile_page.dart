import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/parental_gate.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../../theme/curio_tokens.dart';
import '../../discoveries/domain/discovery.dart';
import '../../family/presentation/accessibility_page.dart';
import '../../family/presentation/help_page.dart';
import '../../family/presentation/privacy_page.dart';
import '../../parent/presentation/parent_dashboard_page.dart';
import '../../skills/presentation/skill_quest_page.dart';
import '../domain/badges.dart';
import 'badges_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _rename(BuildContext context, CurioState state) async {
    final name = await showTextPrompt(
      context,
      title: 'Learner name',
      initialText: state.childName,
      hint: 'What should we call you?',
      maxLength: 18,
      confirmLabel: 'Save name',
      validator: (value) =>
          value.trim().isEmpty ? 'Add a name of at least one letter.' : null,
    );
    if (name != null) state.renameChild(name);
  }

  Future<void> _signOut(BuildContext context, CurioState state) async {
    await state.retrySync();
    if (!context.mounted) return;
    void say(String message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (state.syncError != null) {
      say('Reconnect and sync before signing out, so no progress is lost.');
      return;
    }
    try {
      await AuthService().signOut();
    } catch (_) {
      if (context.mounted) say('Could not sign out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final collected = discoveries
        .where((d) => state.collectedFacts.contains(d.id))
        .length;
    final badges = computeBadges(
      activities: state.completedActivities,
      factsCollected: collected,
      discoveriesTotal: discoveries.length,
      totalXp: state.totalXp,
      longestStreak: state.longestStreak,
    );
    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const CurioTabHeader(),
          const SizedBox(height: 16),
          CurioClay(
            key: const Key('profile_identity'),
            raised: true,
            color: CurioTokens.wash(CurioTokens.tintThinking, .08),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExplorerAvatar(name: state.childName, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          state.childName,
                          style: CurioTokens.display,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('profile_rename'),
                      tooltip: 'Edit name',
                      onPressed: () => _rename(context, state),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Stage ${state.companionStage}',
                      style: CurioTokens.label.copyWith(
                        color: CurioTokens.textPrimary,
                      ),
                    ),
                    Text(
                      '${250 - state.xpIntoStage} XP to the next stage',
                      style: CurioTokens.label,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: CurioProgressBar(
                    value: state.xpIntoStage / 250,
                    color: CurioTokens.tintThinking,
                    height: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            key: const Key('profile_stats'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stat(
                  value: '${state.totalXp}',
                  label: 'Total XP',
                  icon: Icons.bolt_rounded,
                  tint: CurioTokens.tintMaths,
                ),
                const SizedBox(width: 8),
                _Stat(
                  value: '${state.streak}',
                  label: 'Day streak',
                  icon: Icons.local_fire_department_rounded,
                  tint: CurioTokens.accent,
                ),
                const SizedBox(width: 8),
                _Stat(
                  value: '$collected',
                  label: 'Ideas collected',
                  icon: Icons.collections_bookmark_rounded,
                  tint: CurioTokens.tintLogic,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BadgeShelf(badges: badges),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: const Text(
              'Learning and settings',
              style: CurioTokens.title,
            ),
          ),
          const SizedBox(height: 8),
          _ProfileLink(
            title: 'Skills',
            subtitle: 'See your learning progress',
            icon: Icons.route_rounded,
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
          _ProfileLink(
            title: 'Parent dashboard',
            subtitle: 'Progress and family controls',
            icon: Icons.groups_outlined,
            onTap: () =>
                ParentalGate.open(context, const ParentDashboardPage()),
          ),
          _ProfileLink(
            title: 'Accessibility',
            subtitle: 'Motion and reading size',
            icon: Icons.accessibility_new_rounded,
            onTap: () => openPage(context, const AccessibilityPage()),
          ),
          _ProfileLink(
            title: 'Help and feedback',
            icon: Icons.help_outline_rounded,
            onTap: () => openPage(context, const HelpPage()),
          ),
          _ProfileLink(
            title: 'Privacy and account',
            icon: Icons.lock_outline_rounded,
            onTap: () => ParentalGate.open(context, const PrivacyPage()),
          ),
          if (SupabaseConfig.isConfigured) ...[
            _ProfileLink(
              title: state.isSyncing
                  ? 'Syncing progress'
                  : state.syncError == null
                  ? 'Progress is backed up'
                  : 'Sync needs attention',
              icon: Icons.cloud_outlined,
              subtitle: state.syncError,
              onTap: state.retrySync,
            ),
            _ProfileLink(
              key: const Key('profile_sign_out'),
              title: 'Sign out',
              icon: Icons.logout_rounded,
              onTap: () => _signOut(context, state),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String value, label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: CurioClay(
        color: CurioTokens.wash(tint, .15),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: CurioTokens.textPrimary),
            const SizedBox(height: 4),
            Text(value, style: CurioTokens.title),
            Text(label, textAlign: TextAlign.center, style: CurioTokens.label),
          ],
        ),
      ),
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CurioRow(
    title: title,
    subtitle: subtitle,
    leading: ExcludeSemantics(
      child: CurioIconTile(icon: icon, color: CurioTokens.textSecondary),
    ),
    onTap: onTap,
  );
}
