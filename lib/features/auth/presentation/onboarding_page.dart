import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/curio_ui.dart';
import 'auth_layout.dart';

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
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;
    if (_step == 1 && !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.authService.completeOnboarding(_name.text);
      if (mounted) widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn’t save your learner yet. Your choices are still here — please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Small steps. Big discoveries.',
      'Meet your young explorer.',
      'Let the wondering begin.',
    ];
    final descriptions = [
      'A few playful minutes can make room for a big new idea. Here’s how Curio works.',
      'What should Nova call them? A nickname is perfect.',
      'Your learner’s space is ready. Every adventure starts with a little curiosity.',
    ];
    return PopScope(
      canPop: _step == 0 && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving && _step > 0) setState(() => _step--);
      },
      child: AuthLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'YOUR CURIO JOURNEY',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(letterSpacing: 1.3),
                  ),
                ),
                Text('${_step + 1} of 3'),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_step + 1) / 3,
                minHeight: 5,
                semanticsLabel: 'Setup step ${_step + 1} of 3',
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              header: true,
              child: Text(
                titles[_step],
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(height: 1.1),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              descriptions[_step],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            if (_step == 0) ...[
              const _JourneyItem(
                icon: Icons.extension_outlined,
                title: 'Play with a purpose',
                subtitle: 'Build reasoning, number sense, and pattern skills.',
              ),
              const _JourneyItem(
                icon: Icons.auto_awesome_outlined,
                title: 'Follow their curiosity',
                subtitle: 'Find surprising facts and collect new discoveries.',
              ),
              const _JourneyItem(
                icon: Icons.eco_outlined,
                title: 'Watch confidence grow',
                subtitle:
                    'Keep track of their learning, one small win at a time.',
              ),
            ],
            if (_step == 1) ...[
              const Center(child: MascotBadge(size: 108)),
              const SizedBox(height: 28),
              Form(
                key: _form,
                child: TextFormField(
                  controller: _name,
                  maxLength: 18,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Learner’s nickname',
                    hintText: 'e.g. Alex',
                    prefixIcon: Icon(Icons.face_outlined),
                    helperText: 'You can change this later in Profile.',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Add a nickname to continue.'
                      : null,
                  onFieldSubmitted: (_) => _continue(),
                ),
              ),
            ],
            if (_step == 2)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const MascotBadge(size: 96),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, ${_name.text.trim()}!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your first quest is waiting.\nLet’s see what you can discover.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              AuthNotice(_error!, error: true),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _continue,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _step == 2
                          ? 'Start exploring'
                          : _step == 0
                          ? 'Let’s get started'
                          : 'Continue',
                    ),
            ),
            const SizedBox(height: 8),
            if (_step > 0)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _step--;
                        _error = null;
                      }),
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
}

class _JourneyItem extends StatelessWidget {
  const _JourneyItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
