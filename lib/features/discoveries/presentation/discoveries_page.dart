import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/game_catalog.dart';
import '../domain/discovery.dart';

class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({this.onHome, super.key});

  final VoidCallback? onHome;

  Color _tint(Discovery discovery) => switch (discovery.category) {
    'Maths' || 'Patterns' => CurioTokens.tintMaths,
    'Thinking' => CurioTokens.tintThinking,
    _ => CurioTokens.tintLogic,
  };

  Widget _icon(Discovery discovery) => ExcludeSemantics(
    child: CurioIconTile(
      icon: discovery.icon,
      color: CurioTokens.textPrimary,
      background: CurioTokens.wash(_tint(discovery), .23),
    ),
  );

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
              _icon(discovery),
              const SizedBox(height: 12),
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
    final collected = discoveries
        .where((idea) => state.collectedFacts.contains(idea.id))
        .toList();
    final availableIds = {
      for (final game in gameCatalog) game.reward.factId,
      ...CurioState.streakDiscoveries.values,
      for (final idea in collected) idea.id,
    };
    final total = discoveries
        .where((idea) => availableIds.contains(idea.id))
        .length;
    final empty = collected.isEmpty;

    return CurioPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const CurioTabHeader(),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: const Text('Discover', style: CurioTokens.display),
          ),
          const SizedBox(height: 16),
          CurioClay(
            raised: true,
            color: CurioTokens.wash(CurioTokens.tintMaths, .12),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 4),
                    ExcludeSemantics(
                      child: ProgressRing(
                        value: collected.length / total,
                        color: CurioTokens.textSecondary,
                        size: 60,
                        child: const Icon(
                          Icons.collections_bookmark_outlined,
                          color: CurioTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your collection',
                            style: CurioTokens.title,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${collected.length} of $total ideas collected',
                            key: const Key('discover_summary'),
                            style: CurioTokens.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (empty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Nothing here yet. Finish a game to collect your first idea.',
                    style: CurioTokens.body,
                  ),
                  if (onHome != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onHome,
                      child: const Text('Play today’s games'),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (!empty) ...[
            const SizedBox(height: 24),
            for (final discovery in collected) ...[
              CurioCard(
                key: Key('discovery_${discovery.id}'),
                onTap: () => _open(context, discovery),
                child: Row(
                  children: [
                    _icon(discovery),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(discovery.title, style: CurioTokens.title),
                          const SizedBox(height: 4),
                          Text(
                            discovery.category,
                            style: CurioTokens.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const ExcludeSemantics(
                      child: Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}
