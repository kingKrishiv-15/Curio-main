import 'package:flutter/material.dart';

import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../theme/curio_tokens.dart';
import '../game_catalog.dart';
import 'game_banner.dart';
import 'game_emblem.dart';

/// Games shown the way Airbnb shows stays: a rounded picture in the
/// game's own pale colour with its 3D emblem, then a name and a quiet line.

/// The picture half of a listing: a rounded tile in the game's own pale
/// colour with its 3D emblem in the middle, an optional chip in the top
/// left corner and a tick in the top right once it is done.
class GameTile extends StatelessWidget {
  const GameTile({
    required this.game,
    this.aspectRatio = 1,
    this.emblemScale = .62,
    this.label,
    this.labelIcon,
    this.done = false,
    super.key,
  });

  final GameEntry game;
  final double aspectRatio, emblemScale;
  final String? label;
  final IconData? labelIcon;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final tint = sectionColor(context, game.section);
    final color = gameColor(game.id, tint);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CurioTokens.wash(color, .16),
          borderRadius: CurioTokens.cardShape,
        ),
        child: Stack(
          children: [
            Center(
              child: FractionallySizedBox(
                widthFactor: emblemScale,
                heightFactor: emblemScale,
                child: FittedBox(
                  child: GameEmblem(icon: game.icon, color: color, size: 160),
                ),
              ),
            ),
            if (label != null)
              Positioned(
                top: CurioTokens.s12,
                left: CurioTokens.s12,
                right: done
                    ? CurioTokens.s48 + CurioTokens.s4
                    : CurioTokens.s12,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CurioChip(label!, icon: labelIcon, iconColor: tint),
                ),
              ),
            if (done)
              const Positioned(
                top: CurioTokens.s12,
                right: CurioTokens.s12,
                child: DoneBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

/// An Airbnb listing card for a game: the tile, then its name and one
/// quiet line underneath. No box around it; whitespace does that job.
class GameListingCard extends StatelessWidget {
  const GameListingCard({
    required this.game,
    required this.onTap,
    this.label,
    this.labelIcon,
    this.done = false,
    this.practice = false,
    super.key,
  });

  final GameEntry game;
  final VoidCallback onTap;
  final String? label;
  final IconData? labelIcon;
  final bool done, practice;

  @override
  Widget build(BuildContext context) {
    final detail = done
        ? 'Done today'
        : practice
        ? '${game.duration} · Practice'
        : '${game.duration} · +${game.xp} XP';
    return CurioPressable(
      onTap: onTap,
      semanticLabel: '${game.title}, ${game.section.title}. $detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameTile(game: game, label: label, labelIcon: labelIcon, done: done),
          const SizedBox(height: CurioTokens.s12),
          Text(
            game.title,
            style: CurioType.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            detail,
            style: done
                ? CurioType.strong.copyWith(color: CurioTokens.correct)
                : CurioType.meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A game as one compact white row: a small picture, its name, a line of
/// detail and its tagline, and a round play button (a tick once done).
class GameCompactCard extends StatelessWidget {
  const GameCompactCard({
    required this.game,
    required this.done,
    required this.onPlay,
    this.detail,
    super.key,
  });

  final GameEntry game;
  final bool done;
  final VoidCallback onPlay;

  /// The line under the name. Defaults to the section and duration.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final meta = detail ?? '${game.section.title} · ${game.duration}';
    return CurioPressable(
      onTap: onPlay,
      semanticLabel: '${game.title}. $meta${done ? '. Done today' : ''}',
      child: CurioClay(
        padding: const EdgeInsets.all(CurioTokens.s12),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: GameTile(game: game, emblemScale: .7),
            ),
            const SizedBox(width: CurioTokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: CurioType.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(meta, style: CurioTokens.label),
                  const SizedBox(height: CurioTokens.s4),
                  Text(
                    game.tagline,
                    style: CurioType.meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: CurioTokens.s12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: done
                    ? CurioTokens.wash(CurioTokens.correct, .14)
                    : CurioTokens.accent,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  done ? Icons.check_rounded : Icons.play_arrow_rounded,
                  color: done ? CurioTokens.correct : CurioTokens.onAccent,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
