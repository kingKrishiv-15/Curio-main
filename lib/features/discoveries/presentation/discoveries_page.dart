import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../domain/discovery.dart';

/// Discover: the ideas a learner has collected, as a plain list. Nothing
/// is shown for ideas that are still locked.
class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({super.key});

  void _open(BuildContext context, Discovery discovery) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                discovery.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(discovery.fact, style: CurioTokens.body),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final collected = [
      for (final d in discoveries)
        if (state.collectedFacts.contains(d.id)) d,
    ];
    return CurioPage(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Discover',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            collected.isEmpty
                ? 'Nothing here yet. Finish a game and the idea behind it is saved here.'
                : '${collected.length} of ${discoveries.length} ideas collected',
            key: const Key('discover_summary'),
            style: CurioTokens.bodySmall,
          ),
          const SizedBox(height: 24),
          for (final discovery in collected)
            CurioRow(
              key: Key('discovery_${discovery.id}'),
              title: discovery.title,
              subtitle: discovery.category,
              onTap: () => _open(context, discovery),
            ),
        ],
      ),
    );
  }
}
