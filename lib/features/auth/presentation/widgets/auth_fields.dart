import 'package:flutter/material.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateEmail(String? value) =>
    _emailPattern.hasMatch((value ?? '').trim())
    ? null
    : 'Enter a valid email address, like you@example.com.';

/// Curio's password rules. Keep in sync with Supabase → Authentication →
/// Sign In / Providers → Email → minimum length 8, "Letters and digits".
({bool length, bool mix}) passwordChecks(String value) => (
  length: value.length >= 8,
  mix: RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value),
);

String? validateNewPassword(String? value) {
  final checks = passwordChecks(value ?? '');
  if (!checks.length) return 'Use at least 8 characters.';
  if (!checks.mix) return 'Include at least one letter and one number.';
  return null;
}

class EmailField extends StatelessWidget {
  const EmailField({
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled, autofocus;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    autofocus: autofocus,
    keyboardType: TextInputType.emailAddress,
    textInputAction: textInputAction,
    autofillHints: const [AutofillHints.email],
    autocorrect: false,
    enableSuggestions: false,
    decoration: const InputDecoration(
      labelText: 'Email address',
      hintText: 'you@example.com',
      prefixIcon: Icon(Icons.alternate_email_rounded),
    ),
    validator: validateEmail,
    onFieldSubmitted: onSubmitted,
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    this.label = 'Password',
    this.isNew = false,
    this.enabled = true,
    this.onSubmitted,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  /// New passwords get the live checklist and the "new password" autofill
  /// hint, so password managers offer to generate one.
  final bool isNew;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    if (widget.isNew) widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: _hidden,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: [
          widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
        ],
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _hidden ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _hidden = !_hidden),
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        validator:
            widget.validator ??
            (widget.isNew
                ? validateNewPassword
                : (v) => (v ?? '').isEmpty ? 'Enter your password.' : null),
        onFieldSubmitted: widget.onSubmitted,
      ),
      if (widget.isNew) ...[
        const SizedBox(height: 10),
        _PasswordChecklist(value: widget.controller.text),
      ],
    ],
  );
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final checks = passwordChecks(value);
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _Check(done: checks.length, label: '8+ characters'),
        _Check(done: checks.mix, label: 'A letter and a number'),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.label});
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? curioColor(context, CurioColors.success, CurioColorsLight.success)
        : curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return Semantics(
      label: '$label${done ? ', done' : ', not yet'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey(done),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The plain-language summary a parent agrees to when creating an account.
/// Bump `FamilySettings.currentConsentVersion` whenever this changes.
Future<void> showPrivacySummary(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => const _PrivacySummary(),
);

class _PrivacySummary extends StatelessWidget {
  const _PrivacySummary();

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    const items = [
      (
        Icons.alternate_email_rounded,
        'Your email address',
        'So you can sign in, and so we can send the emails you choose.',
      ),
      (
        Icons.face_outlined,
        'Your explorer’s nickname',
        'Never their full name, a photo, or where they are.',
      ),
      (
        Icons.extension_outlined,
        'Their learning progress',
        'Games finished, discoveries found, skill levels and streaks.',
      ),
      (
        Icons.tune_rounded,
        'Your family preferences',
        'Daily goals, reminder times and email choices.',
      ),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What Curio keeps',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Only what’s needed to run your family’s account.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            for (final (icon, title, body) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurioIconTile(
                      icon: icon,
                      color: curioColor(
                        context,
                        CurioColors.forest,
                        CurioColorsLight.forest,
                      ),
                      size: 40,
                      iconSize: 20,
                      radius: 13,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(body, style: TextStyle(color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'It’s all private to your account. You can export or permanently delete it anytime from Profile → Privacy.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
