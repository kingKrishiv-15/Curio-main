import 'package:flutter/material.dart';

import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../game_catalog.dart';
import 'game_cards.dart';
import 'game_row.dart';

/// The Games tab: today's lineup, one compact row per game with its
/// tagline, so a parent can see at a glance what each one asks for.
class TodayGamesPage extends StatelessWidget {
  const TodayGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final date = state.today;
    final set = todaysSet(date: date, ids: state.dailySetIds);
    final done = state.gamesCompletedToday;
    final total = state.todayGameIds.length;

    return CurioPage(
      // Scrolls under the floating navigation; the list clears it below.
      extendBehindBottom: true,
      child: RefreshIndicator(
        onRefresh: state.refreshDailySet,
        // Six cards at most, so the whole list is built at once and every
        // game is always there for screen readers and tests.
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            CurioTokens.s24,
            CurioTokens.s16,
            CurioTokens.s24,
            MediaQuery.paddingOf(context).bottom + CurioTokens.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CurioTabHeader(),
              const SizedBox(height: CurioTokens.s24),
              Semantics(
                header: true,
                child: const Text('Today’s games', style: CurioTokens.display),
              ),
              const SizedBox(height: CurioTokens.s8),
              Wrap(
                spacing: CurioTokens.s8,
                runSpacing: CurioTokens.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    MaterialLocalizations.of(context).formatMediumDate(date),
                    style: CurioType.meta,
                  ),
                  CurioChip(
                    done >= total ? 'All $total done' : '$done of $total done',
                    icon: done >= total
                        ? Icons.check_rounded
                        : Icons.local_fire_department_rounded,
                    iconColor: done >= total
                        ? CurioTokens.correct
                        : CurioTokens.accent,
                    tint: done >= total
                        ? CurioTokens.correct
                        : CurioTokens.accent,
                  ),
                ],
              ),
              const SizedBox(height: CurioTokens.s32),
              SectionHeading(
                'Daily challenge',
                trailing: XpChip(set.anchor.xp),
              ),
              const SizedBox(height: CurioTokens.s16),
              GameCompactCard(
                key: Key('game_row_${set.anchor.id}'),
                game: set.anchor,
                done: state.completedToday(set.anchor.id),
                onPlay: () => openGame(context, set.anchor),
              ),
              const SizedBox(height: CurioTokens.s32),
              const SectionHeading(
                'One from every section',
                subtitle: 'A few minutes each. Every one earns XP today.',
              ),
              const SizedBox(height: CurioTokens.s16),
              for (final game in set.others) ...[
                if (game != set.others.first)
                  const SizedBox(height: CurioTokens.s12),
                GameCompactCard(
                  key: Key('game_row_${game.id}'),
                  game: game,
                  done: state.completedToday(game.id),
                  detail:
                      '${game.section.title} · ${game.duration} · '
                      '+${game.xp} XP',
                  onPlay: () => openGame(context, game),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
