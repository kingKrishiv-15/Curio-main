import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';
import 'package:flutter/services.dart';
import '../../../core/services/family_service.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/text_prompt_dialog.dart';
import '../../auth/presentation/auth_layout.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _service = FamilyService();
  bool _busy = false;
  String? _error;
  Future<void> _export() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _service.exportData();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your account data'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(child: SelectableText(data)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: data));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account data copied.')),
                  );
                }
              },
              child: const Text('Copy JSON'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not export your account. Please reconnect and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final value = await showTextPrompt(
      context,
      title: 'Delete your family account?',
      message:
          'This permanently deletes your account, learner progress, reports, and notification preferences. This cannot be undone. Enter your password to confirm.',
      label: 'Account password',
      obscure: true,
      cancelLabel: 'Keep account',
      confirmLabel: 'Delete permanently',
      validator: (value) => value.isEmpty ? 'Enter your password.' : null,
    );
    if (value == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.deleteAccount(value);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Deletion failed. Check your password and connection, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = CurioTokens.textSecondary;
    final forest = CurioTokens.accent;
    final danger = CurioTokens.wrong;
    return CurioPage(
      title: 'Privacy and your data',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Your family, your choices.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'What Curio keeps, why it keeps it, and how to take it with you or delete it.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.lock_outline_rounded,
            title: 'What Curio keeps',
            body:
                'Your parent email, your explorer’s nickname, activity history, learning progress, family preferences and weekly reports. Only your signed-in account can see them. There’s no advertising or analytics SDK in Curio.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.mark_email_unread_outlined,
            title: 'Emails and reminders',
            body:
                'Both are optional and can be switched off in Family preferences. Emails are sent through an email provider only when you turn them on. Notifications are kept for 90 days; learning history and weekly reports stay until you delete your account.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.smartphone_rounded,
            title: 'On this device',
            body:
                'A copy of learning progress is kept here so nothing is lost if the connection drops. Signing out clears it after a final sync. Please use a parent or guardian’s email, a nickname is all your explorer needs.',
          ),
          if (!_service.isDemo) ...[
            const SizedBox(height: 24),
            const SectionHeading('Your data'),
            const SizedBox(height: 12),
            CurioCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    enabled: !_busy,
                    onTap: _export,
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    leading: CurioIconTile(
                      icon: Icons.download_rounded,
                      color: forest,
                      size: 38,
                      iconSize: 19,
                      radius: CurioTokens.radiusCard,
                    ),
                    title: const Text(
                      'Export my account data',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('A copy of everything, as JSON'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    enabled: !_busy,
                    onTap: _delete,
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    leading: CurioIconTile(
                      icon: Icons.delete_outline_rounded,
                      color: danger,
                      size: 38,
                      iconSize: 19,
                      radius: CurioTokens.radiusCard,
                    ),
                    title: Text(
                      'Delete family account',
                      style: TextStyle(
                        color: danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Permanently, with all progress'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthNotice(_error!, error: true),
          ],
        ],
      ),
    );
  }
}

/// A short, titled block of privacy information.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final muted = CurioTokens.textSecondary;
    return CurioCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurioIconTile(
            icon: icon,
            color: CurioTokens.accent,
            size: 38,
            iconSize: 19,
            radius: CurioTokens.radiusCard,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: muted, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
