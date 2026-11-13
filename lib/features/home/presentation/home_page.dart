import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../games/common/daily_schedule.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_row.dart';

/// Home puts the games first: today's anchor game, then the three rotating
/// games as small icon tiles. Streak, points and messages sit underneath.
/// Each game shows its icon, its name and its section, and nothing more.
class HomePage extends StatelessWidget {
  const HomePage({this.onProfile, super.key});

  /// Switches to the Profile tab (the avatar).
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final set = todaysSet(date: state.today, ids: state.dailySetIds);
    final done = state.gamesCompletedToday.clamp(0, dailyGameCount);
    return CurioPage(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CurioLogo(markSize: 28),
                ),
              ),
              ExplorerAvatar(name: state.childName, size: 40, onTap: onProfile),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Today’s games',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Text(
                '$done of $dailyGameCount done',
                key: const Key('home_progress'),
                style: CurioTokens.label,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Anchor(game: set.anchor, done: state.completedToday(set.anchor.id)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < set.others.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _GameTile(
                      game: set.others[i],
                      done: state.completedToday(set.others[i].id),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          CurioRow(
            key: const Key('home_streak'),
            title: state.streak == 1
                ? '1 day streak'
                : '${state.streak} day streak',
            trailing: Text('${state.totalXp} XP', style: CurioTokens.bodySmall),
          ),
          CurioRow(
            title: 'Family messages',
            onTap: () => openPage(context, const FamilyInboxPage()),
          ),
        ],
      ),
    );
  }
}

/// A game's icon on its section tint.
class _GameIcon extends StatelessWidget {
  const _GameIcon({required this.game});

  final GameEntry game;
  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final tint = sectionColor(context, game.section);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CurioTokens.wash(tint, .18),
            borderRadius: CurioTokens.cardShape,
          ),
          child: Icon(game.icon, color: tint, size: size * .5),
        ),
      ),
    );
  }
}

/// Today's anchor game: the only raised element on Home and the only
/// full-width primary button.
class _Anchor extends StatelessWidget {
  const _Anchor({required this.game, required this.done});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) => CurioClay(
    key: const Key('home_anchor'),
    raised: true,
    color: CurioTokens.surface,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _GameIcon(game: game),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(game.title, style: CurioTokens.title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done
                        ? 'Done for today'
                        : '${game.section.title}, ${game.duration}',
                    style: CurioTokens.label,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('home_play'),
          onPressed: () => openGame(context, game),
          child: Text(done ? 'Play again' : 'Play'),
        ),
      ],
    ),
  );
}

/// One of the three rotating games: icon, name, section. Tapping opens it.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.done});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${game.title}, ${game.section.title}${done ? ', done today' : ''}',
    excludeSemantics: true,
    child: CurioClay(
      color: CurioTokens.surface,
      child: InkWell(
        key: Key('game_row_${game.id}'),
        onTap: () => openGame(context, game),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Column(
            children: [
              _GameIcon(game: game),
              const SizedBox(height: 12),
              Text(
                game.title,
                textAlign: TextAlign.center,
                style: CurioTokens.label.copyWith(
                  color: CurioTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              done
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: CurioTokens.correct,
                    )
                  : Text(
                      game.section.title,
                      textAlign: TextAlign.center,
                      style: CurioTokens.label,
                    ),
            ],
          ),
        ),
      ),
    ),
  );
}
