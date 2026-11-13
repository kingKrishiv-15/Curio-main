import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/open_page.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
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

/// Profile: who is playing (the one raised block), one row of three
/// numbers, then everything else as plain rows.
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
    final earned = badges.where((b) => b.earned).length;

    return CurioPage(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [
          CurioClay(
            key: const Key('profile_identity'),
            raised: true,
            color: CurioTokens.surfaceRaised,
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                CurioProgressBar(value: state.xpIntoStage / 250),
                const SizedBox(height: 8),
                Text(
                  'Stage ${state.companionStage}. '
                  '${250 - state.xpIntoStage} XP to stage ${state.companionStage + 1}.',
                  style: CurioTokens.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            key: const Key('profile_stats'),
            children: [
              _Stat(value: '${state.totalXp}', label: 'Total XP'),
              _Stat(value: '${state.streak}', label: 'Day streak'),
              _Stat(value: '$collected', label: 'Ideas collected'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          CurioRow(
            title: 'Badges',
            subtitle: '$earned of ${badges.length} earned',
            onTap: () => showBadgesSheet(context, badges),
          ),
          CurioRow(
            title: 'Skills',
            subtitle: 'Which skills each game has moved',
            onTap: () => openPage(context, const SkillQuestPage()),
          ),
          CurioRow(
            title: 'Parent dashboard',
            subtitle: 'Progress and family controls',
            onTap: () =>
                ParentalGate.open(context, const ParentDashboardPage()),
          ),
          CurioRow(
            title: 'Accessibility',
            subtitle: 'Motion and reading size',
            onTap: () => openPage(context, const AccessibilityPage()),
          ),
          CurioRow(
            title: 'Help and feedback',
            onTap: () => openPage(context, const HelpPage()),
          ),
          CurioRow(
            title: 'Privacy and account',
            onTap: () => ParentalGate.open(context, const PrivacyPage()),
          ),
          if (SupabaseConfig.isConfigured) ...[
            CurioRow(
              title: state.isSyncing
                  ? 'Syncing progress'
                  : state.syncError == null
                  ? 'Progress is backed up'
                  : 'Sync needs attention',
              subtitle: state.syncError,
              onTap: state.retrySync,
            ),
            CurioRow(
              key: const Key('profile_sign_out'),
              title: 'Sign out',
              onTap: () => _signOut(context, state),
            ),
          ],
        ],
      ),
    );
  }
}

/// One number over its label. Three of these make Profile's single stat
/// row: plain text, no tiles.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: CurioTokens.title),
          const SizedBox(height: 4),
          Text(label, style: CurioTokens.label),
        ],
      ),
    ),
  );
}
