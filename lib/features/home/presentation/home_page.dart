import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_row.dart';
import '../../games/presentation/today_games.dart';
import 'weekly_progress.dart';

class HomePage extends StatelessWidget {
  const HomePage({this.onProfile, super.key});

  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final story = gameById('frostlands_night_1');

    return CurioPage(
      child: RefreshIndicator(
        onRefresh: state.refreshDailySet,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            CurioTabHeader(
              actions: [
                IconButton(
                  tooltip: 'Family messages',
                  onPressed: () => openPage(context, const FamilyInboxPage()),
                  icon: const Icon(Icons.mail_outline_rounded),
                ),
                const SizedBox(width: 8),
                ExplorerAvatar(
                  name: state.childName,
                  size: 48,
                  onTap: onProfile,
                ),
              ],
            ),
            const SizedBox(height: 16),
            WeeklyProgress(state: state),
            const SizedBox(height: 24),
            const TodayGames(),
            const SizedBox(height: 16),
            _StoryCard(
              game: story,
              done: state.completedActivities.contains(story.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.game, required this.done});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) => CurioCard(
    color: CurioTokens.wash(CurioTokens.tintLogic),
    onTap: () => openGame(context, game),
    child: Row(
      children: [
        const ExcludeSemantics(
          child: CurioIconTile(
            icon: Icons.auto_stories_rounded,
            color: CurioTokens.textPrimary,
            background: CurioTokens.surface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.title, style: CurioTokens.title),
              const SizedBox(height: 4),
              Text(
                done ? 'Revisit the story' : 'A choose-your-path adventure',
                style: CurioTokens.bodySmall,
              ),
            ],
          ),
        ),
        const ExcludeSemantics(child: Icon(Icons.chevron_right_rounded)),
      ],
    ),
  );
}
