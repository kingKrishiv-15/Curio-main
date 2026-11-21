import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../game_catalog.dart';
import 'game_banner.dart';
import 'game_emblem.dart';
import 'game_row.dart';

class TodayGamesPage extends StatelessWidget {
  const TodayGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    return CurioPage(
      child: RefreshIndicator(
        onRefresh: state.refreshDailySet,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: const [
            CurioTabHeader(),
            SizedBox(height: 16),
            TodayGames(showDescriptions: true),
          ],
        ),
      ),
    );
  }
}

class TodayGames extends StatelessWidget {
  const TodayGames({this.showDescriptions = false, super.key});

  final bool showDescriptions;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final date = state.today;
    final set = todaysSet(date: date, ids: state.dailySetIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: const Text('Today’s games', style: CurioTokens.display),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              MaterialLocalizations.of(context).formatMediumDate(date),
              style: CurioTokens.bodySmall,
            ),
            Text(
              '${state.gamesCompletedToday} of ${set.others.length + 1} done',
              style: CurioTokens.label,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FeaturedGame(
          key: Key('game_row_${set.anchor.id}'),
          game: set.anchor,
          done: state.completedToday(set.anchor.id),
          showDescription: showDescriptions,
        ),
        const SizedBox(height: 12),
        for (final game in set.others) ...[
          if (game != set.others.first) const Divider(height: 1, indent: 64),
          _TodayGameRow(
            key: Key('game_row_${game.id}'),
            game: game,
            done: state.completedToday(game.id),
            showDescription: showDescriptions,
          ),
        ],
      ],
    );
  }
}

class _FeaturedGame extends StatelessWidget {
  const _FeaturedGame({
    required this.game,
    required this.done,
    required this.showDescription,
    super.key,
  });

  final GameEntry game;
  final bool done, showDescription;

  @override
  Widget build(BuildContext context) {
    final tint = sectionColor(context, game.section);
    return CurioCard(
      color: CurioTokens.wash(tint, .13),
      onTap: () => openGame(context, game),
      child: Row(
        children: [
          GameEmblem(
            icon: game.icon,
            color: gameColor(game.id, tint),
            size: 64,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily challenge • ${game.duration}',
                  style: CurioTokens.label,
                ),
                const SizedBox(height: 4),
                Text(game.title, style: CurioTokens.title),
                if (showDescription) ...[
                  const SizedBox(height: 4),
                  Text(game.tagline, style: CurioTokens.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const _DoneIcon()
          else
            const ExcludeSemantics(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: CurioTokens.accent,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: CurioTokens.onAccent,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayGameRow extends StatelessWidget {
  const _TodayGameRow({
    required this.game,
    required this.done,
    required this.showDescription,
    super.key,
  });

  final GameEntry game;
  final bool done, showDescription;

  @override
  Widget build(BuildContext context) {
    final tint = sectionColor(context, game.section);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => openGame(context, game),
        borderRadius: CurioTokens.cardShape,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: CurioTokens.wash(tint, .14),
                  borderRadius: CurioTokens.cardShape,
                ),
                child: GameEmblem(
                  icon: game.icon,
                  color: gameColor(game.id, tint),
                  size: 48,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: CurioTokens.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showDescription) ...[
                      Text(game.tagline, style: CurioTokens.bodySmall),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '${game.section.title} • ${game.duration}',
                      style: CurioTokens.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (done)
                const _DoneIcon()
              else
                const ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: CurioTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneIcon extends StatelessWidget {
  const _DoneIcon();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.check_circle_outline_rounded,
    color: CurioTokens.correct,
    semanticLabel: 'Done today',
  );
}
