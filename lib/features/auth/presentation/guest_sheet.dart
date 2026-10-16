import 'package:flutter/material.dart';

import '../../../core/services/guest_session.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';

/// "Continue as guest": try Curio without an account. Says plainly where
/// progress lives, asks for an optional nickname, then hands over to the
/// [AuthGate], which notices [GuestSession] and opens the app.
Future<void> showGuestSheet(BuildContext context, {GuestSession? session}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GuestSheet(session: session ?? GuestSession.instance),
    );

class _GuestSheet extends StatefulWidget {
  const _GuestSheet({required this.session});
  final GuestSession session;

  @override
  State<_GuestSheet> createState() => _GuestSheetState();
}

class _GuestSheetState extends State<_GuestSheet> {
  final _name = TextEditingController();
  bool _starting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.session.start(name: _name.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'This device couldn’t save guest progress. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    final saffron = curioColor(context, CurioColors.saffron, CurioColorsLight.saffron);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Play as a guest', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Jump straight into the games — no email needed.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: saffron.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_iphone_rounded, color: saffron, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Progress is saved on this device only. Create a family account any time to see it on other devices and unlock the parent emails.',
                        style: TextStyle(color: muted, height: 1.45, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('guest_name'),
                controller: _name,
                maxLength: 18,
                enabled: !_starting,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _start(),
                decoration: const InputDecoration(
                  labelText: 'Explorer’s nickname (optional)',
                  hintText: 'e.g. Alex',
                  prefixIcon: Icon(Icons.face_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: curioColor(context, CurioColors.danger, CurioColorsLight.danger),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('guest_start'),
                onPressed: _starting ? null : _start,
                child: _starting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start exploring'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
