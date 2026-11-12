import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_row.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Home, top to bottom: today's anchor game (the one raised block), a
/// one-line streak strip, then the rest of today's set as plain rows.
class HomePage extends StatelessWidget {
  const HomePage({this.onProfile, super.key});

  /// Switches to the Profile tab (the avatar).
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final today = state.today;
    final set = todaysSet(date: today);
    return CurioPage(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_weekdays[today.weekday - 1]} ${today.day} ${_months[today.month - 1]}',
                  key: const Key('home_date'),
                  style: CurioTokens.label,
                ),
              ),
              IconButton(
                tooltip: 'Family messages',
                onPressed: () => openPage(context, const FamilyInboxPage()),
                icon: const Icon(Icons.mail_outline_rounded),
              ),
              const SizedBox(width: 4),
              ExplorerAvatar(name: state.childName, size: 40, onTap: onProfile),
            ],
          ),
          const SizedBox(height: 16),
          _Anchor(game: set.anchor, done: state.completedToday(set.anchor.id)),
          const SizedBox(height: 24),
          Semantics(
            label: '${state.streak} day streak. ${state.totalXp} XP in total.',
            excludeSemantics: true,
            child: Row(
              key: const Key('home_streak'),
              children: [
                Expanded(
                  child: Text(
                    state.streak == 1
                        ? '1 day streak'
                        : '${state.streak} day streak',
                    style: CurioTokens.bodySmall.copyWith(
                      color: CurioTokens.textPrimary,
                    ),
                  ),
                ),
                Text('${state.totalXp} XP', style: CurioTokens.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: Text(
              'Also today',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          for (final game in set.others)
            GameRow(game: game, done: state.completedToday(game.id)),
        ],
      ),
    );
  }
}

/// Today's anchor game: the only raised element on Home, the largest
/// type, and the only full-width primary button.
class _Anchor extends StatelessWidget {
  const _Anchor({required this.game, required this.done});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) => CurioClay(
    key: const Key('home_anchor'),
    raised: true,
    color: CurioTokens.surfaceRaised,
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          done ? 'Done for today' : 'Today',
          style: CurioTokens.label.copyWith(
            color: sectionColor(context, game.section),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(game.title, style: CurioTokens.display),
        ),
        const SizedBox(height: 8),
        Text(game.tagline, style: CurioTokens.body),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('home_play'),
          onPressed: () => openGame(context, game),
          child: Text(done ? 'Play again for practice' : 'Play'),
        ),
      ],
    ),
  );
}
