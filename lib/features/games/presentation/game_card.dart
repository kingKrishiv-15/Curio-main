import 'package:flutter/material.dart';

import '../../../core/navigation/open_page.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../game_catalog.dart';
import 'game_banner.dart';
import 'game_emblem.dart';
import 'game_preview.dart';

/// How a [GameCard] is laid out.
enum GameCardStyle {
  /// Art on top, details below — for grids and the Home shelf.
  tile,

  /// Art on the left, details on the right — for lists.
  row,

  /// Big art and a play button — for today's featured quest.
  hero,

  /// Big art with a round play button on its lower edge — Home's carousel.
  spotlight,
}

/// The one card every screen uses to show a game: vivid art with a preview
/// of how it plays, then the title, a one-line promise, and the facts a
/// parent or child wants before tapping — skill, time, XP — plus whether
/// it's new, today's quest, or already done today.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.game,
    this.style = GameCardStyle.tile,
    this.done = false,
    this.featured = false,
    this.onTap,
    super.key,
  });

  final GameEntry game;
  final GameCardStyle style;

  /// Finished today (daily games) or ever (the story).
  final bool done;

  /// Today's featured quest.
  final bool featured;

  /// Defaults to opening the game.
  final VoidCallback? onTap;

  void _open(BuildContext context) => onTap != null
      ? onTap!()
      : openPage(context, game.open(date: CurioScope.of(context).today));

  String get _semanticLabel => [
    game.title,
    if (featured) 'today’s quest',
    if (game.isNew) 'new',
    game.tagline,
    '${game.section.title}, ${game.duration}',
    done ? 'done ${game.isDaily ? 'today' : ''}, XP earned' : '${game.xp} XP',
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    // Buttons and borders take the banner's own colour, so each card reads
    // as one piece; the skill chip keeps the skill's colour.
    final color = gameColor(game.id, skillColor(context, game.skill));
    final radius = switch (style) {
      GameCardStyle.hero => 28.0,
      _ => 24.0,
    };
    final content = switch (style) {
      GameCardStyle.tile => _tile(context, color),
      GameCardStyle.row => _row(context, color),
      GameCardStyle.hero => _hero(context, color),
      GameCardStyle.spotlight => _spotlight(context, color),
    };
    return Semantics(
      button: true,
      label: _semanticLabel,
      excludeSemantics: true,
      // excludeSemantics drops the InkWell's action, so restate it here.
      onTap: () => _open(context),
      child: CurioClay(
        radius: radius,
        padding: EdgeInsets.zero,
        outline: featured ? color.withValues(alpha: .7) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('game_card_${game.id}'),
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(radius),
            splashColor: color.withValues(alpha: .12),
            highlightColor: color.withValues(alpha: .05),
            child: content,
          ),
        ),
      ),
    );
  }

  // Art on top. Laid out with spaceBetween (not Expanded) so the card works
  // both in rows of equal height and on its own.
  Widget _tile(BuildContext context, Color color) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameArt(game: game, height: 104, done: done, featured: featured),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
              child: _Details(game: game, done: done, taglineLines: 2),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
          child: _PlayPill(done: done, color: color),
        ),
      ],
    ),
  );

  Widget _row(BuildContext context, Color color) => Padding(
    padding: const EdgeInsets.all(8),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: SizedBox(
              width: 104,
              child: GameArt(
                game: game,
                height: 112,
                done: done,
                featured: featured,
                compactBadges: true,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: _Details(game: game, done: done, taglineLines: 3),
            ),
          ),
          Center(
            child: _ArrowButton(color: color, done: done),
          ),
          const SizedBox(width: 6),
        ],
      ),
    ),
  );

  // The play button hangs half over the art; the card itself is the tap
  // target, so the button is only a signpost.
  Widget _spotlight(BuildContext context, Color color) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GameArt(
                    game: game,
                    height: 122,
                    done: done,
                    featured: featured,
                  ),
                  Positioned(
                    right: 12,
                    bottom: -21,
                    child: _PlayCircle(color: color, done: done),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 56, 0),
                child: Text(
                  game.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  game.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: _Meta(game: game, done: done),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, Color color) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameArt(game: game, height: 156, done: done, featured: featured),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurioEyebrow(
                  featured ? 'Today’s featured quest' : game.section.title,
                  color: curioColor(
                    context,
                    color,
                    Color.lerp(color, Colors.black, .3)!,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  game.tagline,
                  style: TextStyle(color: muted, height: 1.45, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _Meta(game: game, done: done),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _open(context),
                    icon: Icon(
                      done ? Icons.replay_rounded : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(done ? 'Play again' : 'Play today’s quest'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A sculpted game emblem and a glimpse of its puzzle, on a lit colour stage.
class GameArt extends StatelessWidget {
  const GameArt({
    required this.game,
    required this.height,
    this.done = false,
    this.featured = false,
    this.compactBadges = false,
    this.badges = true,
    super.key,
  });

  final GameEntry game;
  final double height;
  final bool done, featured;

  /// Icon-only badges, for narrow art.
  final bool compactBadges;

  /// DONE / QUEST / NEW. Off where they'd mean nothing, like the signed-out
  /// landing page.
  final bool badges;

  @override
  Widget build(BuildContext context) {
    final color = gameColor(game.id, skillColor(context, game.skill));
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, .24)!,
              bannerFill(context, color),
              Color.lerp(color, Colors.black, .3)!,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Puffed up like the clay card around it.
            Positioned.fill(
              child: CustomPaint(
                painter: ClayPainter(
                  color: color,
                  radius: 18,
                  dark: Theme.of(context).brightness == Brightness.dark,
                  fill: false,
                  lift: false,
                ),
              ),
            ),
            Positioned(
              right: -height * .3,
              top: -height * .65,
              child: Container(
                width: height * 1.7,
                height: height * 1.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                    width: height * .18,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, badges ? 22 : 4, 8, 4),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final emblem = GameEmblem(
                      icon: game.icon,
                      color: color,
                      size: box.maxHeight * 1.12,
                    );
                    if (box.maxWidth < 210) return Center(child: emblem);
                    return Row(
                      children: [
                        Expanded(flex: 4, child: Center(child: emblem)),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                            child: GamePreview(gameId: game.id, color: color),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (badges)
              Positioned(
                left: 8,
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (done)
                      _Badge(
                        icon: Icons.check_rounded,
                        label: compactBadges ? null : 'DONE',
                        foreground: curioColor(
                          context,
                          CurioColors.forestStrong,
                          CurioColorsLight.forestStrong,
                        ),
                      ),
                    const Spacer(),
                    if (featured)
                      _Badge(
                        icon: Icons.star_rounded,
                        label: compactBadges ? null : 'QUEST',
                        background: CurioColors.spark,
                        foreground: CurioColorsLight.ink,
                      )
                    else if (game.isNew && !done)
                      _Badge(
                        label: 'NEW',
                        foreground: Color.lerp(color, Colors.black, .5)!,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.foreground,
    this.label,
    this.icon,
    this.background = Colors.white,
  });

  final String? label;
  final IconData? icon;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: label == null ? 4 : 8,
      vertical: 3,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 13, color: foreground),
        if (icon != null && label != null) const SizedBox(width: 3),
        if (label != null)
          Text(
            label!,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: foreground,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
      ],
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.game,
    required this.done,
    required this.taglineLines,
  });

  final GameEntry game;
  final bool done;
  final int taglineLines;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          game.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19),
        ),
        const SizedBox(height: 4),
        Text(
          game.tagline,
          maxLines: taglineLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        _Meta(game: game, done: done),
      ],
    );
  }
}

/// Skill · time · reward, wrapping onto new lines when space is short.
class _Meta extends StatelessWidget {
  const _Meta({required this.game, required this.done});
  final GameEntry game;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = skillColor(context, game.skill);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final success = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.forestStrong,
    );
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffronStrong,
    );
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sectionIcon(game.section), size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  game.section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // Skill hues are bright: darken them for text on light cards.
                    color: curioColor(
                      context,
                      color,
                      Color.lerp(color, Colors.black, .35)!,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        _MetaItem(
          icon: Icons.schedule_rounded,
          label: game.duration,
          color: muted,
        ),
        done
            ? _MetaItem(
                icon: Icons.check_circle_rounded,
                label: 'XP earned',
                color: success,
              )
            : _MetaItem(
                icon: Icons.bolt_rounded,
                label: '+${game.xp} XP',
                color: gold,
              ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.done, required this.color});
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          done ? Icons.replay_rounded : Icons.play_arrow_rounded,
          size: 18,
          color: ink,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            done ? 'Practice again' : 'Play today’s game',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
    return CurioClay(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 9),
      color: color.withValues(alpha: done ? .1 : .24),
      child: label,
    );
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle({required this.color, required this.done});
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 46,
    child: CurioClay(
      radius: 23,
      outline: color,
      child: Icon(
        done ? Icons.replay_rounded : Icons.play_arrow_rounded,
        color: curioColor(context, color, Color.lerp(color, Colors.black, .3)!),
        size: 25,
      ),
    ),
  );
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.color, required this.done});
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 38,
    child: CurioClay(
      radius: 19,
      color: color.withValues(alpha: done ? .1 : .18),
      child: Icon(
        done ? Icons.replay_rounded : Icons.play_arrow_rounded,
        color: curioColor(
          context,
          color,
          Color.lerp(color, Colors.black, .35)!,
        ),
        size: 20,
      ),
    ),
  );
}

/// Lays [cards] out in rows of [columns] with equal heights per row, so a
/// grid stays tidy at any text size (no fixed heights to overflow).
class GameGrid extends StatelessWidget {
  const GameGrid({required this.children, this.spacing = 12, super.key});
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 980
          ? 4
          : width >= 700
          ? 3
          : width >= 330
          ? 2
          : 1;
      return Column(
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + columns; i++) ...[
                    if (i > start) SizedBox(width: spacing),
                    Expanded(
                      child: i < children.length
                          ? children[i]
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
