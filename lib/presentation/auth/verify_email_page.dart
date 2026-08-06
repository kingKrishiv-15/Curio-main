import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isChecking = false;
  bool _showNotYetVerified = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _showNotYetVerified = false;
    });

    final verified = await ref.read(authRepositoryProvider).isEmailVerified();

    if (!mounted) return;
    if (verified) {
      context.go('/onboarding/consent');
    } else {
      setState(() {
        _isChecking = false;
        _showNotYetVerified = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "We've sent you a confirmation link. Open it, then come back and tap the button below.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_showNotYetVerified) ...[
                    const SizedBox(height: 16),
                    Text(
                      "That email hasn't been confirmed yet.",
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("I've verified my email"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
