import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../games/common/game_rewards.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_banner.dart';
import '../domain/discovery.dart';

class DiscoveriesPage extends StatelessWidget {
  const DiscoveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final progress = state.collectedFacts.length / discoveries.length;
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final forestStrong = curioColor(
      context,
      CurioColors.forestStrong,
      CurioColorsLight.forestStrong,
    );
    final saffron = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffron,
    );
    final onDark = curioColor(
      context,
      CurioColors.onDark,
      CurioColorsLight.onDark,
    );
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final surfaceMuted = curioColor(
      context,
      CurioColors.surfaceMuted,
      CurioColorsLight.surfaceMuted,
    );
    final creamDeep = curioColor(
      context,
      CurioColors.creamDeep,
      CurioColorsLight.creamDeep,
    );
    final navyMuted = curioColor(
      context,
      CurioColors.navyMuted,
      CurioColorsLight.navyMuted,
    );
    return CurioPage(
      extendBehindBottom: true,
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 104),
        children: [
          PageIntro(
            eyebrow: 'Curiosity archive',
            title: 'Ideas worth keeping.',
            subtitle:
                '${state.collectedFacts.length} of ${discoveries.length} curious facts uncovered',
            trailing: ProgressRing(
              value: progress,
              color: coral,
              child: Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CurioCard(
            color: forestStrong,
            borderColor: forestStrong,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: saffron,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    color: forestStrong,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A cabinet of curious things',
                        style: TextStyle(
                          color: onDark,
                          fontSize: 17,
                          fontFamily: 'Fraunces',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every completed challenge can reveal a new idea worth remembering.',
                        style: TextStyle(
                          color: onDark.withValues(alpha: .65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionHeading(
            'Collected cards',
            subtitle:
                'Tap a card to read the whole fact, or to see how to unlock it',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680
                  ? 3
                  : constraints.maxWidth >= 350
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  // Grows with the reader's text size instead of clipping.
                  mainAxisExtent:
                      (columns == 1 ? 172 : 210) *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: discoveries.length,
                itemBuilder: (context, index) {
                  final discovery = discoveries[index];
                  final collected = state.collectedFacts.contains(discovery.id);
                  final tint = discoveryColor(context, discovery.id);
                  return CurioCard(
                    onTap: () => _showDiscovery(context, discovery, collected),
                    color: collected ? surface : surfaceMuted,
                    borderColor: collected
                        ? tint.withValues(alpha: .3)
                        : creamDeep,
                    padding: const EdgeInsets.all(13),
                    elevation: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: collected ? tint : surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                collected ? discovery.icon : Icons.lock_outline,
                                color: collected ? Colors.white : navyMuted,
                              ),
                            ),
                            const Spacer(),
                            if (collected)
                              Icon(
                                Icons.bookmark_added_rounded,
                                color: coral,
                                size: 19,
                              ),
                          ],
                        ),
                        const Spacer(),
                        CurioEyebrow(
                          collected ? discovery.category : 'Locked',
                          color: collected ? coral : navyMuted,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          collected ? discovery.title : 'Keep exploring',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          collected
                              ? discovery.fact
                              : _unlockHint(discovery.id),
                          maxLines: columns == 1 ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navyMuted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// How a locked discovery is earned: the game that awards it, or the streak.
String _unlockHint(String discoveryId) {
  for (final MapEntry(key: game, value: reward) in gameRewards.entries) {
    final title = findGame(game)?.title;
    if (reward.factId == discoveryId && title != null) {
      return 'Finish $title to reveal this discovery.';
    }
  }
  for (final MapEntry(key: days, value: fact)
      in CurioState.streakDiscoveries.entries) {
    if (fact == discoveryId) {
      return 'Practise $days days in a row to reveal this discovery.';
    }
  }
  return 'Keep exploring to reveal this discovery.';
}

GameEntry? _unlockingGame(String discoveryId) {
  for (final game in gameCatalog) {
    if (game.reward.factId == discoveryId) return game;
  }
  return null;
}

/// A discovery's colour: the solid colour of the game that unlocks it, or
/// brand green for the streak discoveries.
Color discoveryColor(BuildContext context, String discoveryId) {
  final game = _unlockingGame(discoveryId);
  return bannerFill(
    context,
    game == null
        ? CurioColorsLight.forest
        : gameColor(game.id, skillColor(context, game.skill)),
  );
}

void _showDiscovery(BuildContext context, Discovery discovery, bool collected) {
  final game = collected ? null : _unlockingGame(discovery.id);
  final accent = discoveryColor(context, discovery.id);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurioIconTile(
              icon: collected ? discovery.icon : Icons.lock_outline,
              color: collected ? Colors.white : accent,
              background: collected ? accent : accent.withValues(alpha: .14),
              size: 56,
              iconSize: 28,
              radius: 18,
            ),
            const SizedBox(height: 16),
            CurioEyebrow(collected ? discovery.category : 'Locked'),
            const SizedBox(height: 8),
            Text(
              collected ? discovery.title : 'Still a mystery',
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              collected ? discovery.fact : _unlockHint(discovery.id),
              style: const TextStyle(fontSize: 16, height: 1.55),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: game == null
                  ? FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Close'),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        openPage(context, game.open());
                      },
                      icon: Icon(game.icon, size: 18),
                      label: Text('Play ${game.title}'),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
