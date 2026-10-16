import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
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
      if (mounted)
        setState(() {
          _message.clear();
          _error = false;
          _notice = 'Your message has been saved for the Curio team.';
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = true;
          _notice =
              'We couldn’t send this. Your message is still here — please retry.';
        });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: 'Help and feedback',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ExpansionTile(
          title: Text('How is progress saved?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Signed-in progress is saved on your device and synced to your family account. Check the sync status in Profile. Reconnect and tap it to retry if a sync is pending.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('When do reports arrive?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Weekly reports cover Monday through Sunday and become available after 8 AM the following Monday in your chosen time zone. Email delivery is optional. Your first report follows your first completed calendar week.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Can we play without an account?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Yes — choose “Continue as guest” on the welcome screen. Progress is kept on this device only. Create a family account later and Curio offers to bring that progress with you.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Can I play again?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Yes. Each daily game earns XP once a day, and you can replay it any time just for fun. Many games also offer a practice round with a different puzzle when you finish. The Frostlands story earns its XP once.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Tell us what could be better.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (SupabaseConfig.isConfigured &&
            Supabase.instance.client.auth.currentUser != null) ...[
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
        ] else
          const Text(
            'Sign in with a family account to send feedback to the Curio team.',
          ),
        if (_notice != null) ...[
          const SizedBox(height: 16),
          AuthNotice(_notice!, error: _error),
        ],
        const SizedBox(height: 24),
        TextButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Curio'),
          child: const Text('Open-source licenses'),
        ),
      ],
    ),
  );
}
