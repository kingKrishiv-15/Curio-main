import 'package:flutter/material.dart';

import '../../../core/models/family_settings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_motion.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';
import 'widgets/auth_fields.dart';
import 'widgets/welcome_art.dart';

/// Learner setup, right after a parent's email is confirmed: a nickname, a
/// gentle daily goal, reading comfort, how they'd like to hear from Curio,
/// then a welcome. Reading preferences stay on this device; the learner and
/// family choices are saved to their account. All can be changed in Profile.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.authService,
    required this.onComplete,
    super.key,
  });

  final AuthService authService;
  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = 5;

  final _name = TextEditingController();
  final _nameForm = GlobalKey<FormState>();
  int _step = 0;
  int _goal = 3;
  bool _reminders = true;
  int _hour = 18;
  bool _weeklyEmail = false;
  late String _timezone = FamilySettings.guessTimezone();
  late final bool _needsConsent = !widget.authService.hasRecordedConsent;
  bool _consent = false;
  bool _consentMissing = false;
  bool _saving = false;
  String? _error;
  bool _reduceMotion = false;
  double _readingScale = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reading = CurioThemeScope.maybeOf(context);
    if (reading != null) {
      _reduceMotion = reading.reduceMotion;
      _readingScale = reading.readingScale;
    }
  }

  Future<void> _setReading({bool? motion, double? scale}) async {
    final controller = CurioThemeScope.maybeOf(context);
    setState(() {
      if (motion != null) _reduceMotion = motion;
      if (scale != null) _readingScale = scale;
    });
    await controller?.setReading(motion: motion, scale: scale);
  }

  String get _learner =>
      _name.text.trim().isEmpty ? 'your explorer' : _name.text.trim();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _back() {
    if (_saving || _step == 0) return;
    setState(() {
      _step--;
      _error = null;
    });
  }

  Future<void> _continue() async {
    if (_saving) return;
    if (_step == 0 && !_nameForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    if (_needsConsent && !_consent) {
      setState(() => _consentMissing = true);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.authService.completeOnboarding(
        _name.text,
        settings: FamilySettings(
          dailyGoal: _goal,
          remindersEnabled: _reminders,
          reminderHour: _hour,
          timezone: _timezone,
          weeklyEmailEnabled: _weeklyEmail,
          consentVersion: FamilySettings.currentConsentVersion,
        ),
      );
      if (mounted) widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn’t save your setup just yet. Everything you chose is still here — please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final (eyebrow, title, subtitle) = switch (_step) {
      0 => (
        'Meet your explorer',
        'Who’s exploring with Curio?',
        'What should Nova call them? A nickname is perfect — there’s no need for a real name.',
      ),
      1 => (
        'A gentle rhythm',
        'How much play a day?',
        'Pick a daily goal for $_learner. There’s one daily game each in Maths, Memory, English and Logic. You can change the goal anytime.',
      ),
      2 => (
        'Made for your explorer',
        'Make it comfortable.',
        'Try a reading size and choose how much things move. These settings apply on this device and can be changed in Profile.',
      ),
      3 => (
        'Staying in the loop',
        'How should we keep you posted?',
        'Small nudges help a habit stick. Choose what works for your family.',
      ),
      _ => (
        'All set',
        'Welcome, $_learner!',
        'Their first quest is waiting. Here’s what we’ve set up — it’s all editable later in Profile.',
      ),
    };
    return PopScope(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthFrame(
        onBack: _step > 0 && !_saving ? _back : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepBar(step: _step, count: _steps),
            const SizedBox(height: 26),
            CurioFadeSlideIn(
              key: ValueKey(_step),
              offset: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CurioEyebrow(eyebrow),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(subtitle, style: TextStyle(color: muted, height: 1.55)),
                  const SizedBox(height: 26),
                  switch (_step) {
                    0 => _nameStep(),
                    1 => _goalStep(),
                    2 => _comfortStep(),
                    3 => _loopStep(),
                    _ => _readyStep(),
                  },
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              AuthNotice(_error!, error: true),
            ],
            const SizedBox(height: 26),
            FilledButton(
              key: const Key('onboarding_continue'),
              onPressed: _saving ? null : _continue,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_step == _steps - 1 ? 'Start exploring' : 'Continue'),
            ),
            const SizedBox(height: 8),
            if (_step > 0)
              TextButton(
                onPressed: _saving ? null : _back,
                child: const Text('Back'),
              )
            else
              TextButton(
                onPressed: _saving ? null : widget.authService.signOut,
                child: const Text('Use a different account'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nameStep() => Column(
    children: [
      const CurioFloat(distance: 4, child: MascotBadge(size: 104)),
      const SizedBox(height: 26),
      Form(
        key: _nameForm,
        child: TextFormField(
          controller: _name,
          maxLength: 18,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Explorer’s nickname',
            hintText: 'e.g. Alex',
            prefixIcon: Icon(Icons.face_outlined),
          ),
          validator: (value) => (value ?? '').trim().isEmpty
              ? 'Add a nickname to continue.'
              : null,
          onFieldSubmitted: (_) => _continue(),
        ),
      ),
    ],
  );

  Widget _goalStep() {
    const options = [
      (1, 'A quick spark', 'One game a day · about 5 minutes'),
      (2, 'A little adventure', 'Two games a day · about 10 minutes'),
      (3, 'A steady habit', 'Three games a day · about 15 minutes'),
      (4, 'The full set', 'One in each section · about 20 minutes'),
    ];
    return Column(
      children: [
        for (final (goal, title, detail) in options) ...[
          _ChoiceCard(
            key: Key('goal_$goal'),
            selected: _goal == goal,
            title: title,
            detail: detail,
            badge: goal == 3 ? 'Recommended' : null,
            leading: '$goal',
            onTap: () => setState(() => _goal = goal),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _comfortStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CurioClay(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CurioFloat(distance: 3, child: MascotBadge(size: 64)),
            const SizedBox(height: 16),
            Text(
              'A little wonder, every day.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Play, discover and grow at your own pace.'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      for (final (scale, title, detail) in const [
        (1.0, 'Standard', 'The usual reading size'),
        (1.2, 'Larger', 'A little more room for every word'),
        (1.4, 'Largest', 'Big, clear text throughout Curio'),
      ]) ...[
        _ChoiceCard(
          key: Key('reading_$scale'),
          selected: (_readingScale - scale).abs() < .01,
          title: title,
          detail: detail,
          leading: 'Aa',
          onTap: () => _setReading(scale: scale),
        ),
        const SizedBox(height: 12),
      ],
      SwitchListTile.adaptive(
        key: const Key('onboarding_reduce_motion'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Gentler motion'),
        subtitle: const Text(
          'Keep illustrations still and skip moving transitions. Your device’s reduced-motion setting is always respected.',
        ),
        value: _reduceMotion,
        onChanged: (value) => _setReading(motion: value),
      ),
    ],
  );

  Widget _loopStep() {
    return CurioClay(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
            title: const Text('Daily reminder'),
            subtitle: const Text('A gentle nudge in your Curio inbox.'),
          ),
          if (_reminders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Reminder time'),
              trailing: Text(
                TimeOfDay(hour: _hour, minute: 0).format(context),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _hour, minute: 0),
                  helpText: 'Reminders go out at the start of this hour',
                );
                if (picked != null && mounted) {
                  setState(() => _hour = picked.hour);
                }
              },
            ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _weeklyEmail,
            onChanged: (v) => setState(() => _weeklyEmail = v),
            title: const Text('Weekly report emails'),
            subtitle: const Text(
              'Games, practice days, XP, discoveries and skills. Mondays after 8 AM in your time zone.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _timezone,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Your time zone',
              prefixIcon: Icon(Icons.public_rounded),
            ),
            items: {...FamilySettings.commonTimezones, _timezone}
                .map(
                  (zone) => DropdownMenuItem(
                    value: zone,
                    child: Text(zone.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _timezone = v ?? _timezone),
          ),
        ],
      ),
    );
  }

  Widget _readyStep() {
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final summary = [
      (
        Icons.flag_rounded,
        'Daily goal',
        '$_goal ${_goal == 1 ? 'game' : 'games'} a day',
      ),
      (
        Icons.notifications_none_rounded,
        'Reminders',
        _reminders ? TimeOfDay(hour: _hour, minute: 0).format(context) : 'Off',
      ),
      (
        Icons.mark_email_read_outlined,
        'Weekly email',
        _weeklyEmail ? 'Mondays' : 'Off',
      ),
      (
        Icons.text_fields_rounded,
        'Reading size',
        '${(_readingScale * 100).round()}%',
      ),
      (
        Icons.animation_rounded,
        'Motion',
        _reduceMotion ? 'Gentler' : 'Playful',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: curioColor(
              context,
              CurioColors.forestSoft,
              CurioColorsLight.forestSoft,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const CurioFloat(distance: 4, child: MascotBadge(size: 92)),
              const SizedBox(height: 18),
              for (final (icon, label, value) in summary)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: forest),
                      const SizedBox(width: 12),
                      Expanded(child: Text(label)),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Four little adventures, refreshed daily.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final section in WelcomeSkill.all)
              Chip(
                avatar: Icon(
                  section.icon,
                  size: 18,
                  color: section.ink(context),
                ),
                label: Text(section.label),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'One game per section each day. Replay for practice; points are awarded once.',
        ),
        if (_needsConsent) ...[
          const SizedBox(height: 18),
          CheckboxListTile(
            key: const Key('onboarding_consent'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            isError: _consentMissing,
            onChanged: (v) => setState(() {
              _consent = v ?? false;
              if (_consent) _consentMissing = false;
            }),
            title: const Text(
              'I’m a parent or guardian, and I agree to how Curio looks after my family’s data.',
            ),
            subtitle: _consentMissing
                ? Text(
                    'Please confirm to finish setting up.',
                    style: TextStyle(
                      color: curioColor(
                        context,
                        CurioColors.danger,
                        CurioColorsLight.danger,
                      ),
                    ),
                  )
                : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showPrivacySummary(context),
              child: const Text('What we keep'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.count});
  final int step, count;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final idle = curioColor(
      context,
      CurioColors.outlineSoft,
      CurioColorsLight.outline,
    );
    return Semantics(
      label: 'Setup step ${step + 1} of $count',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${step + 1} OF $count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= step ? coral : idle,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.detail,
    required this.leading,
    required this.onTap,
    this.badge,
    super.key,
  });

  final bool selected;
  final String title, detail, leading;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
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
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(coral.withValues(alpha: .1), surface)
                  : surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? coral : outline,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? coral : coral.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    leading,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      // Coral is bright in both modes: dark ink on it (§7).
                      color: selected
                          ? curioColor(
                              context,
                              CurioColors.night,
                              CurioColorsLight.ink,
                            )
                          : coral,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: forest.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: forest,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? coral : outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
