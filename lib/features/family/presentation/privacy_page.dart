import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/family_service.dart';
import '../../../core/widgets/curio_ui.dart';
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
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account data copied.')),
                  );
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
      if (mounted)
        setState(
          () => _error =
              'Could not export your account. Please reconnect and try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your family account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your account, learner progress, reports, and notification preferences. This cannot be undone. Enter your password to confirm.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Account password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    final value = password.text;
    password.dispose();
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.deleteAccount(value);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Deletion failed. Check your password and connection, then try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: 'Privacy and your data',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your family, your choices.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        const Text(
          'Curio stores your parent email, learner nickname, activity history, learning progress, family preferences, and weekly reports. Your signed-in account controls access to this information. No advertising or analytics SDK is included.',
          style: TextStyle(height: 1.7),
        ),
        const SizedBox(height: 20),
        const Text(
          'Reminders and parent emails are optional and can be switched off in Family preferences. Email delivery uses an external email provider when enabled. Notifications are retained for 90 days. Learning history and weekly reports remain until you delete your account.',
          style: TextStyle(height: 1.7),
        ),
        const SizedBox(height: 20),
        const Text(
          'A copy of learning progress is stored on this device to recover from connection problems. Signing out clears that device copy after attempting sync. Only use a parent or guardian’s email; a learner nickname is enough.',
          style: TextStyle(height: 1.7),
        ),
        const SizedBox(height: 24),
        if (!_service.isDemo) ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export my account data'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete family account'),
          ),
        ],
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null) AuthNotice(_error!, error: true),
      ],
    ),
  );
}
