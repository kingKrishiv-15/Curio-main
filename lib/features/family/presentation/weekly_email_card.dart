import 'package:flutter/material.dart';

import '../../../core/models/family_settings.dart';
import '../../../core/services/family_service.dart';
import '../../../core/widgets/curio_clay.dart';

/// An explicit opt-in, next to the reports it delivers. Existing families
/// keep their saved choice; the dashboard never subscribes them silently.
class WeeklyEmailCard extends StatefulWidget {
  const WeeklyEmailCard({this.service, super.key});
  final FamilyService? service;

  @override
  State<WeeklyEmailCard> createState() => _WeeklyEmailCardState();
}

class _WeeklyEmailCardState extends State<WeeklyEmailCard> {
  late final _service = widget.service ?? FamilyService();
  FamilySettings? _settings;
  bool _saving = false;
  bool? _enabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.loadSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _enabled = settings.weeklyEmailEnabled;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'We couldn’t load your email preference. Please retry.',
        );
      }
    }
  }

  Future<void> _toggle(bool value) async {
    if (_saving || _settings == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.setWeeklyEmailEnabled(value);
      if (mounted) setState(() => _enabled = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Your email preference wasn’t changed. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => CurioClay(
    padding: const EdgeInsets.all(20),
    radius: 26,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly report emails',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Every explorer’s completed games, practice days, XP, discoveries and skill progress — together in one weekly email.',
        ),
        const SizedBox(height: 8),
        if (_settings != null)
          Text(
            'Mondays after 8 AM · ${_settings!.timezone.replaceAll('_', ' ')}',
          ),
        if (_service.parentEmail case final email?) ...[
          const SizedBox(height: 4),
          Text('Sent to $email'),
        ],
        if (_service.isDemo)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Weekly email needs a signed-in family account.'),
          )
        else if (_settings == null && _error == null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          )
        else if (_settings != null)
          SwitchListTile.adaptive(
            key: const Key('weekly_email_toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Email me weekly reports'),
            subtitle: const Text('You can turn this off anytime.'),
            value: _enabled ?? false,
            onChanged: _saving ? null : _toggle,
          ),
        if (_saving) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          if (_settings == null)
            TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      ],
    ),
  );
}
