import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../core/widgets/curio_logo.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../../theme/curio_tokens.dart';
import '../../family/presentation/family_inbox_page.dart';
import '../../games/common/daily_schedule.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_cards.dart';
import '../../games/presentation/game_row.dart';
import 'home_parts.dart';
import 'weekly_progress.dart';

/// Home, in the style of Airbnb: a white page, today at a glance in a
/// search-bar pill, a sticky row of categories, and games shown as
/// listings with big pastel pictures.
class HomePage extends StatefulWidget {
  const HomePage({this.onProfile, this.onGames, super.key});

  final VoidCallback? onProfile;

  /// Opens the Games tab, from the arrow beside "Today's games".
  final VoidCallback? onGames;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// The chosen category, or null for "All".
  LearningSection? _section;

  @override
  Widget build(BuildContext context) {
    final state = CurioScope.of(context);
    final date = state.today;
    final set = todaysSet(date: date, ids: state.dailySetIds);
    final today = [set.anchor, ...set.others];
    final section = _section;

    return CurioPage(
      backgroundColor: CurioTokens.base,
      // The page runs under the floating navigation, so no band shows
      // behind it; the last section clears it with bottom padding.
      extendBehindBottom: true,
      child: RefreshIndicator(
        onRefresh: state.refreshDailySet,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                CurioTokens.s24,
                CurioTokens.s16,
                CurioTokens.s24,
                CurioTokens.s24,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CurioTabHeader(
                      actions: [
                        CurioIconButton(
                          icon: Icons.mail_outline_rounded,
                          tooltip: 'Family messages',
                          onPressed: () =>
                              openPage(context, const FamilyInboxPage()),
                        ),
                        const SizedBox(width: CurioTokens.s8),
                        ExplorerAvatar(
                          name: state.childName,
                          size: 44,
                          onTap: widget.onProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: CurioTokens.s24),
                    WeeklyProgress(state: state),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedStrip(
                extent: CategoryStrip.extentFor(
                  MediaQuery.textScalerOf(context),
                ),
                child: CategoryStrip(
                  selected: section,
                  onSelected: (value) => setState(() => _section = value),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                CurioTokens.s24,
                CurioTokens.s24,
                CurioTokens.s24,
                MediaQuery.paddingOf(context).bottom + CurioTokens.s24,
              ),
              sliver: SliverList.list(
                children: section == null
                    ? _everything(context, state, set)
                    : _onlySection(context, state, today, section),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "All": the daily challenge, the rest of today's set and the story.
  List<Widget> _everything(
    BuildContext context,
    CurioState state,
    ({GameEntry anchor, List<GameEntry> others}) set,
  ) {
    final story = gameById('frostlands_night_1');
    return [
      SectionHeading('Daily challenge', trailing: XpChip(set.anchor.xp)),
      const SizedBox(height: CurioTokens.s16),
      GameCompactCard(
        key: Key('game_row_${set.anchor.id}'),
        game: set.anchor,
        done: state.completedToday(set.anchor.id),
        onPlay: () => openGame(context, set.anchor),
      ),
      const SizedBox(height: CurioTokens.s48),
      SectionHeading(
        'Today’s games',
        subtitle: 'One from every section, a few minutes each',
        onMore: widget.onGames,
      ),
      const SizedBox(height: CurioTokens.s16),
      CurioGrid(
        children: [
          for (final game in set.others)
            GameListingCard(
              key: Key('game_row_${game.id}'),
              game: game,
              label: game.section.title,
              labelIcon: sectionIcon(game.section),
              done: state.completedToday(game.id),
              onTap: () => openGame(context, game),
            ),
        ],
      ),
      const SizedBox(height: CurioTokens.s48),
      const SectionHeading(
        'Story time',
        subtitle: 'Read, choose, and see where it leads',
      ),
      const SizedBox(height: CurioTokens.s16),
      _StoryCard(
        game: story,
        done: state.completedActivities.contains(story.id),
      ),
    ];
  }

  /// One category: today's game from it, then its other games as practice
  /// rounds (which play any time and earn no XP).
  List<Widget> _onlySection(
    BuildContext context,
    CurioState state,
    List<GameEntry> today,
    LearningSection section,
  ) {
    final todays = [
      for (final game in today)
        if (game.section == section) game,
    ];
    final todayIds = state.todayGameIds.toSet();
    final more = [
      for (final id in sectionRotation[section] ?? const <String>[])
        if (!todayIds.contains(id)) findGame(id),
    ].whereType<GameEntry>().toList();

    return [
      SectionHeading(
        'Today in ${section.title}',
        subtitle: section.description,
      ),
      const SizedBox(height: CurioTokens.s16),
      if (todays.length == 1)
        GameCompactCard(
          key: Key('game_row_${todays.single.id}'),
          game: todays.single,
          done: state.completedToday(todays.single.id),
          onPlay: () => openGame(context, todays.single),
        )
      else
        CurioGrid(
          children: [
            for (final game in todays)
              GameListingCard(
                key: Key('game_row_${game.id}'),
                game: game,
                label: 'Today',
                labelIcon: Icons.today_rounded,
                done: state.completedToday(game.id),
                onTap: () => openGame(context, game),
              ),
          ],
        ),
      if (more.isNotEmpty) ...[
        const SizedBox(height: CurioTokens.s48),
        SectionHeading(
          'More ${section.title} games',
          subtitle: 'Practice rounds to play any time. They don’t earn XP.',
        ),
        const SizedBox(height: CurioTokens.s16),
        CurioGrid(
          children: [
            for (final game in more)
              GameListingCard(
                key: Key('home_practice_${game.id}'),
                game: game,
                label: 'Practice',
                labelIcon: Icons.replay_rounded,
                practice: true,
                onTap: () => openGame(context, game),
              ),
          ],
        ),
      ],
    ];
  }
}

/// The story as a wide listing: a night-sky picture, its name and a line.
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.game, required this.done});

  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final detail = done
        ? 'Revisit the story · ${game.duration}'
        : 'A choose-your-path adventure · ${game.duration}';
    return CurioPressable(
      onTap: () => openGame(context, game),
      semanticLabel: '${game.title}. $detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameTile(
            game: game,
            aspectRatio: 2,
            emblemScale: .74,
            label: 'Story',
            labelIcon: Icons.auto_stories_rounded,
            done: done,
          ),
          const SizedBox(height: CurioTokens.s12),
          Text(game.title, style: CurioType.cardTitle),
          Text(detail, style: CurioType.meta),
        ],
      ),
    );
  }
}

/// Keeps the category strip on screen while the page scrolls under it,
/// with a hairline beneath, as Airbnb's category bar does.
class _PinnedStrip extends SliverPersistentHeaderDelegate {
  const _PinnedStrip({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: CurioTokens.base,
    child: Column(
      children: [
        Expanded(
          child: Align(alignment: Alignment.bottomCenter, child: child),
        ),
        const Divider(height: 1),
      ],
    ),
  );

  @override
  bool shouldRebuild(_PinnedStrip oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}
