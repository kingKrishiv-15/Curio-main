import 'package:flutter/material.dart';
import '../../../core/models/family_settings.dart';
import '../../../core/services/family_service.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../core/widgets/curio_gloss.dart';
import '../../auth/presentation/auth_layout.dart';

class FamilySettingsPage extends StatefulWidget {
  const FamilySettingsPage({super.key});
  @override
  State<FamilySettingsPage> createState() => _FamilySettingsPageState();
}

class _FamilySettingsPageState extends State<FamilySettingsPage> {
  final _service = FamilyService();
  bool _loading = true, _saving = false, _reminders = false, _email = false;

  /// Only true once real settings arrived — saving defaults over settings we
  /// failed to load would wipe the family's choices (and consent).
  bool _loaded = false;
  int _goal = 3, _hour = 18;
  String _timezone = 'UTC';
  String? _consent, _error, _saved;
  static const zones = FamilySettings.commonTimezones;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.loadSettings();
      if (mounted)
        setState(() {
          _goal = s.dailyGoal;
          _hour = s.reminderHour;
          _reminders = s.remindersEnabled;
          _email = s.weeklyEmailEnabled;
          _timezone = s.timezone;
          _consent = s.consentVersion;
          _loaded = true;
        });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Settings could not be loaded. Please retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = null;
    });
    try {
      await _service.saveSettings(
        FamilySettings(
          dailyGoal: _goal,
          remindersEnabled: _reminders,
          reminderHour: _hour,
          timezone: _timezone,
          weeklyEmailEnabled: _email,
          consentVersion: _consent,
        ),
      );
      if (mounted) {
        CurioScope.of(context).setDailyGoal(_goal);
        setState(() => _saved = 'Your family preferences are saved.');
      }
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not save your changes. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: 'Family preferences',
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'A rhythm that works for you.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a small daily goal and decide how you’d like to hear from Curio.',
              ),
              const SizedBox(height: 24),
              CurioGloss(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily learning goal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_goal ${_goal == 1 ? 'activity' : 'activities'} a day',
                    ),
                    Slider(
                      value: _goal.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_goal ${_goal == 1 ? 'activity' : 'activities'}',
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _goal = v.round()),
                    ),
                    const Text(
                      'A goal is an invitation, never a screen-time limit.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CurioGloss(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Learning reminders'),
                      subtitle: const Text(
                        'A gentle reminder in your Curio inbox.',
                      ),
                      value: _reminders && !_service.isDemo,
                      onChanged: _saving || _service.isDemo
                          ? null
                          : (v) => setState(() => _reminders = v),
                    ),
                    if (_reminders && !_service.isDemo)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminder time'),
                        subtitle: Text(
                          TimeOfDay(hour: _hour, minute: 0).format(context),
                        ),
                        trailing: const Icon(Icons.schedule),
                        onTap: _saving
                            ? null
                            : () async {
                                final value = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: _hour,
                                    minute: 0,
                                  ),
                                  helpText:
                                      'Reminders are sent at the selected hour',
                                );
                                if (value == null || !mounted) return;
                                setState(() => _hour = value.hour);
                                if (value.minute != 0 && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Reminders go out on the hour, so it’s set for ${TimeOfDay(hour: value.hour, minute: 0).format(context)}.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Weekly parent email'),
                      subtitle: const Text(
                        'Last week’s practice, delivered Monday after 8 AM. Turn off anytime.',
                      ),
                      value: _email && !_service.isDemo,
                      onChanged: _saving || _service.isDemo
                          ? null
                          : (v) => setState(() => _email = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _timezone,
                      decoration: const InputDecoration(
                        labelText: 'Your time zone',
                      ),
                      isExpanded: true,
                      items: {...zones, _timezone}
                          .map(
                            (z) => DropdownMenuItem(
                              value: z,
                              child: Text(z.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _timezone = v!),
                    ),
                  ],
                ),
              ),
              if (_service.isDemo) ...[
                const SizedBox(height: 20),
                const AuthNotice(
                  'Your daily goal is saved on this device. Reminders and the weekly email need a family account — create one from Profile.',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
                AuthNotice(_error!, error: true),
              ],
              if (_saved != null) ...[
                const SizedBox(height: 20),
                AuthNotice(_saved!),
              ],
              const SizedBox(height: 24),
              if (!_loaded) ...[
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reload settings'),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                onPressed: _saving || !_loaded ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save preferences'),
              ),
            ],
          ),
  );
}
