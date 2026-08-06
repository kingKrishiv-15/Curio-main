import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/curio_colors.dart';

/// Placeholder for a screen this UI sprint hasn't built yet - lets Home's
/// navigation be wired up and demoable now instead of blocking on every
/// destination existing first. Each of these gets replaced by its real
/// screen as the sprint reaches it (see the screen priority order).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title is being built this sprint.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: CurioColors.inkMuted),
        ),
      ),
    );
  }
}
