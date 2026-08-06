import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Stands in for the real Home dashboard (a later phase). Confirms the
/// onboarding flow actually reached the end by showing the active child, if
/// one was just created in this session.
class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChild = ref.watch(activeChildProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          activeChild != null ? "You're set up, ${activeChild.displayName}!" : "You're signed in.",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
