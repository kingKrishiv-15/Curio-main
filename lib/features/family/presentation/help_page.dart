import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../auth/presentation/auth_layout.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _message = TextEditingController();
  bool _sending = false;
  String? _notice;
  bool _error = false;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().length < 10) {
      setState(() {
        _error = true;
        _notice =
            'Please add at least 10 characters so we can understand the issue.';
      });
      return;
    }
    setState(() => _sending = true);
    try {
      final client = Supabase.instance.client;
      await client.from('support_requests').insert({
        'parent_id': client.auth.currentUser!.id,
        'message': _message.text.trim(),
      });
      if (mounted) {
        setState(() {
          _message.clear();
          _error = false;
          _notice = 'Your message has been saved for the Curio team.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _notice =
              'We couldn’t send this. Your message is still here — please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _faqs = [
    (
      Icons.cloud_sync_outlined,
      'How is progress saved?',
      'Signed-in progress is saved on your device and synced to your family account. Check the sync status in Profile. Reconnect and tap it to retry if a sync is pending.',
    ),
    (
      Icons.insights_rounded,
      'When do reports arrive?',
      'Weekly reports cover Monday through Sunday and become available after 8 AM the following Monday in your chosen time zone. Email delivery is optional. Your first report follows your first completed calendar week.',
    ),
    (
      Icons.person_outline_rounded,
      'Can we play without an account?',
      'Yes — choose “Continue as guest” on the welcome screen. Progress is kept on this device only. Create a family account later and Curio offers to bring that progress with you.',
    ),
    (
      Icons.replay_rounded,
      'Can I play again?',
      'Yes. Each daily game earns XP once a day, and you can replay it any time just for fun. Many games also offer a practice round with a different puzzle when you finish. The Frostlands story earns its XP once.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final signedIn =
        SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentUser != null;
    return CurioPage(
      title: 'Help and feedback',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'How can we help?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Quick answers first, and a direct line to the Curio team.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          const SectionHeading('Common questions'),
          const SizedBox(height: 10),
          CurioCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64),
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
                    childrenPadding: const EdgeInsets.fromLTRB(64, 0, 18, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    leading: CurioIconTile(
                      icon: _faqs[i].$1,
                      color: forest,
                      size: 38,
                      iconSize: 19,
                      radius: 12,
                    ),
                    title: Text(
                      _faqs[i].$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      Text(
                        _faqs[i].$3,
                        style: TextStyle(color: muted, height: 1.55),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeading('Send feedback'),
          const SizedBox(height: 10),
          CurioCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us what could be better.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  signedIn
                      ? 'Ideas, bugs, a game your explorer loved — it all helps.'
                      : 'Sign in with a family account to send feedback to the Curio team.',
                  style: TextStyle(color: muted, height: 1.45),
                ),
                if (signedIn) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _message,
                    enabled: !_sending,
                    maxLines: 5,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'Your feedback',
                      hintText:
                          'Please avoid including a child’s full name or other sensitive information.',
                    ),
                  ),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(_sending ? 'Sending…' : 'Send feedback'),
                  ),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 14),
                  AuthNotice(_notice!, error: _error),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'Curio'),
              child: const Text('Open-source licenses'),
            ),
          ),
        ],
      ),
    );
  }
}
