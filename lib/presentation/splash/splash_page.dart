import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

/// Decides where a freshly-launched app should land. Phase 0 keeps this
/// simple - signed-in goes to the home placeholder, signed-out goes to
/// sign-in. Resuming onboarding mid-flow (e.g. verified email but never
/// finished adding a child) needs a profile/child existence query, which
/// isn't built until a later phase.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    final isSignedIn = ref.read(supabaseClientProvider).auth.currentSession != null;
    context.go(isSignedIn ? '/home' : '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
