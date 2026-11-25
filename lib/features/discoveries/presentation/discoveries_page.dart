import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_emblem.dart';
import '../domain/discovery.dart';

/// Discover, laid out like Airbnb's Wishlists: a big title, a summary of
/// the collection, then every idea collected as a pastel picture card.
class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({this.onHome, super.key});

  final VoidCallback? onHome;

  static Color _tint(Discovery discovery) => switch (discovery.category) {
    'Maths' || 'Patterns' => CurioTokens.tintMaths,
    'Thinking' => CurioTokens.tintThinking,
    _ => CurioTokens.tintLogic,
  };

  void _open(BuildContext context, Discovery discovery) {
    final tint = _tint(discovery);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            CurioTokens.s24,
            0,
            CurioTokens.s24,
            CurioTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IdeaPicture(discovery: discovery, tint: tint, height: 160),
              const SizedBox(height: CurioTokens.s16),
              CurioChip(discovery.category, tint: tint),
              const SizedBox(height: CurioTokens.s12),
              Text(discovery.title, style: CurioTokens.title),
              const SizedBox(height: CurioTokens.s12),
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
      // Scrolls under the floating navigation; the list clears it below.
      extendBehindBottom: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          CurioTokens.s24,
          CurioTokens.s16,
          CurioTokens.s24,
          MediaQuery.paddingOf(context).bottom + CurioTokens.s24,
        ),
        children: [
          const CurioTabHeader(),
          const SizedBox(height: CurioTokens.s24),
          Semantics(
            header: true,
            child: const Text('Discover', style: CurioTokens.display),
          ),
          const SizedBox(height: CurioTokens.s8),
          const Text(
            'Surprising ideas you collect by playing.',
            style: CurioType.meta,
          ),
          const SizedBox(height: CurioTokens.s24),
          CurioClay(
            raised: true,
            padding: const EdgeInsets.all(CurioTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: ProgressRing(
                        value: total == 0 ? 0 : collected.length / total,
                        color: CurioTokens.accent,
                        size: 56,
                        child: const Icon(
                          Icons.collections_bookmark_outlined,
                          color: CurioTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: CurioTokens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your collection', style: CurioType.cardTitle),
                          Text(
                            '${collected.length} of $total ideas collected',
                            key: const Key('discover_summary'),
                            style: CurioType.meta,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (empty) ...[
                  const SizedBox(height: CurioTokens.s16),
                  const Text(
                    'Nothing here yet. Finish a game to collect your first idea.',
                    style: CurioTokens.body,
                  ),
                  if (onHome != null) ...[
                    const SizedBox(height: CurioTokens.s16),
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
            const SizedBox(height: CurioTokens.s32),
            SectionHeading(
              'Collected',
              subtitle: 'Tap one to read it again',
              trailing: CurioChip(
                '${collected.length}',
                icon: Icons.auto_awesome_rounded,
                iconColor: CurioTokens.tintMaths,
                tint: CurioTokens.tintMaths,
              ),
            ),
            const SizedBox(height: CurioTokens.s16),
            CurioGrid(
              children: [
                for (final discovery in collected)
                  CurioPressable(
                    key: Key('discovery_${discovery.id}'),
                    onTap: () => _open(context, discovery),
                    semanticLabel:
                        '${discovery.title}, ${discovery.category}. Open',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IdeaPicture(
                          discovery: discovery,
                          tint: _tint(discovery),
                        ),
                        const SizedBox(height: CurioTokens.s12),
                        Text(
                          discovery.title,
                          style: CurioType.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(discovery.category, style: CurioType.meta),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// An idea's picture: its icon as a little 3D toy on its pale colour,
/// square in the grid or a wide banner in the sheet.
class _IdeaPicture extends StatelessWidget {
  const _IdeaPicture({required this.discovery, required this.tint, this.height});

  final Discovery discovery;
  final Color tint;

  /// A fixed height for the sheet's banner; the grid uses a square.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final picture = DecoratedBox(
      decoration: BoxDecoration(
        color: CurioTokens.wash(tint, .16),
        borderRadius: CurioTokens.cardShape,
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .62,
          heightFactor: .62,
          child: FittedBox(
            child: GameEmblem(icon: discovery.icon, color: tint, size: 160),
          ),
        ),
      ),
    );
    final height = this.height;
    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: picture);
    }
    return AspectRatio(aspectRatio: 1, child: picture);
  }
}
