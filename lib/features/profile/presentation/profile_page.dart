import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
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
    final links = <Widget>[
      CurioListRow(
        title: 'Skills',
        subtitle: 'See your learning progress',
        icon: Icons.route_outlined,
        onTap: () => openPage(context, const SkillQuestPage()),
      ),
      CurioListRow(
        title: 'Parent dashboard',
        subtitle: 'Progress and family controls',
        icon: Icons.groups_outlined,
        onTap: () => ParentalGate.open(context, const ParentDashboardPage()),
      ),
      CurioListRow(
        title: 'Accessibility',
        subtitle: 'Motion and reading size',
        icon: Icons.accessibility_new_rounded,
        onTap: () => openPage(context, const AccessibilityPage()),
      ),
      CurioListRow(
        title: 'Help and feedback',
        icon: Icons.help_outline_rounded,
        onTap: () => openPage(context, const HelpPage()),
      ),
      CurioListRow(
        title: 'Privacy and account',
        icon: Icons.lock_outline_rounded,
        onTap: () => ParentalGate.open(context, const PrivacyPage()),
      ),
    ];
    return CurioPage(
      // Scrolls under the floating navigation; the list clears it below.
      extendBehindBottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          CurioTokens.s24,
          CurioTokens.s16,
          CurioTokens.s24,
          MediaQuery.paddingOf(context).bottom + CurioTokens.s24,
        ),
        children: [
          const CurioTabHeader(),
          const SizedBox(height: CurioTokens.s24),
          Semantics(
            header: true,
            child: const Text('Profile', style: CurioTokens.display),
          ),
          const SizedBox(height: CurioTokens.s24),
          CurioClay(
            key: const Key('profile_identity'),
            raised: true,
            padding: const EdgeInsets.all(CurioTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExplorerAvatar(name: state.childName, size: 64),
                    const SizedBox(width: CurioTokens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              state.childName,
                              style: CurioTokens.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Stage ${state.companionStage} explorer',
                            style: CurioType.meta,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: CurioTokens.s8),
                    CurioIconButton(
                      key: const Key('profile_rename'),
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit name',
                      onPressed: () => _rename(context, state),
                    ),
                  ],
                ),
                const SizedBox(height: CurioTokens.s16),
                const Divider(height: 1),
                const SizedBox(height: CurioTokens.s16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stage ${state.companionStage}',
                      style: CurioType.strong,
                    ),
                    const SizedBox(width: CurioTokens.s12),
                    // Wraps rather than overflowing at large text sizes.
                    Expanded(
                      child: Text(
                        '${250 - state.xpIntoStage} XP to the next stage',
                        textAlign: TextAlign.end,
                        style: CurioType.meta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CurioTokens.s8),
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
          const SizedBox(height: CurioTokens.s16),
          CurioClay(
            key: const Key('profile_stats'),
            padding: const EdgeInsets.symmetric(vertical: CurioTokens.s16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Stat(
                    value: '${state.totalXp}',
                    label: 'Total XP',
                    icon: Icons.bolt_rounded,
                    tint: CurioTokens.tintMaths,
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
                    value: '${state.streak}',
                    label: 'Day streak',
                    icon: Icons.local_fire_department_rounded,
                    tint: CurioTokens.accent,
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
                    value: '$collected',
                    label: 'Ideas collected',
                    icon: Icons.collections_bookmark_rounded,
                    tint: CurioTokens.tintLogic,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CurioTokens.s16),
          BadgeShelf(badges: badges),
          const SizedBox(height: CurioTokens.s32),
          const SectionHeading('Learning and settings'),
          const SizedBox(height: CurioTokens.s12),
          CurioListGroup(children: links),
          if (SupabaseConfig.isConfigured) ...[
            const SizedBox(height: CurioTokens.s24),
            const SectionHeading('Account'),
            const SizedBox(height: CurioTokens.s12),
            CurioListGroup(
              children: [
                CurioListRow(
                  title: state.isSyncing
                      ? 'Syncing progress'
                      : state.syncError == null
                      ? 'Progress is backed up'
                      : 'Sync needs attention',
                  icon: Icons.cloud_outlined,
                  subtitle: state.syncError,
                  onTap: state.retrySync,
                ),
                CurioListRow(
                  key: const Key('profile_sign_out'),
                  title: 'Sign out',
                  icon: Icons.logout_rounded,
                  onTap: () => _signOut(context, state),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the three numbers in the stats card: an icon in its colour, the
/// value in bold, its name underneath.
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CurioTokens.s8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(height: CurioTokens.s4),
            Text(value, style: CurioTokens.title),
            Text(label, textAlign: TextAlign.center, style: CurioTokens.label),
          ],
        ),
      ),
    ),
  );
}
