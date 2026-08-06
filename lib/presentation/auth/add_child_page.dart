import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/auth/repositories/auth_repository.dart';

/// Behavioral spec step 3 (add_child_profile RPC) and step 4 (the new child
/// becomes the active profile in local app state, via activeChildProvider).
///
/// Avatar picking is deliberately out of scope for Phase 0 - avatarKey is
/// sent as null. Age band is a free-form string in the schema (not locked
/// to an exact set yet - see the migration's `child.age_band` comment), so
/// this offers two sensible starting options rather than the domain layer
/// owning a fixed enum that content design hasn't settled on.
class AddChildPage extends ConsumerStatefulWidget {
  const AddChildPage({super.key});

  @override
  ConsumerState<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends ConsumerState<AddChildPage> {
  static const _ageBandOptions = ['8-10', '11-14'];
  static const _languageOptions = {'en': 'English', 'hi': 'Hindi'};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _ageBand = _ageBandOptions.first;
  String _language = _languageOptions.keys.first;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final child = await ref.read(addChildProfileProvider)(
        displayName: _nameController.text,
        ageBand: _ageBand,
        preferredLanguage: _language,
      );
      ref.read(activeChildProvider.notifier).state = child;
      if (mounted) context.go('/home');
    } on AuthFailure catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add your child')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Child's name"),
                      validator: (value) => (value == null || value.isEmpty) ? "Enter your child's name" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _ageBand,
                      decoration: const InputDecoration(labelText: 'Age band'),
                      items: [
                        for (final band in _ageBandOptions) DropdownMenuItem(value: band, child: Text(band)),
                      ],
                      onChanged: (value) => setState(() => _ageBand = value ?? _ageBand),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: const InputDecoration(labelText: 'Preferred language'),
                      items: [
                        for (final entry in _languageOptions.entries)
                          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                      ],
                      onChanged: (value) => setState(() => _language = value ?? _language),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Finish setup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
