import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../game_catalog.dart';

/// Pins a run to the date and eligibility it had when opened.
void openGame(BuildContext context, GameEntry game) {
  final state = CurioScope.of(context);
  openPage(
    context,
    game.open(
      date: state.today,
      practice: game.isDaily && !state.todayGameIds.contains(game.id),
    ),
  );
}

/// A game in a list: its name, one short line, its section tint on the
/// left edge and a chevron (a tick once today's round is done).
class GameRow extends StatelessWidget {
  const GameRow({required this.game, this.done = false, super.key});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) => CurioRow(
    key: Key('game_row_${game.id}'),
    title: game.title,
    subtitle: game.tagline,
    tint: sectionColor(context, game.section),
    trailing: done
        ? const Icon(
            Icons.check_rounded,
            color: CurioTokens.correct,
            semanticLabel: 'Done today',
          )
        : null,
    onTap: () => openGame(context, game),
  );
}
