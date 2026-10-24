import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_ui.dart';
import '../domain/badges.dart';

/// Each badge family's colour: first steps forest, streaks coral, exploring
/// blue, discoveries plum, XP gold.
Color badgeColor(BuildContext context, BadgeTone tone) => switch (tone) {
  BadgeTone.start => curioColor(
    context,
    CurioColors.forest,
    CurioColorsLight.forest,
  ),
  BadgeTone.streak => curioColor(
    context,
    CurioColors.coral,
    CurioColorsLight.coral,
  ),
  BadgeTone.explore => curioColor(
    context,
    CurioColors.blue,
    CurioColorsLight.blue,
  ),
  BadgeTone.discovery => curioColor(
    context,
    CurioColors.plum,
    CurioColorsLight.plum,
  ),
  BadgeTone.xp => curioColor(
    context,
    CurioColors.saffron,
    CurioColorsLight.saffron,
  ),
};

String _badgeSemantics(CurioBadge badge) => badge.earned
    ? '${badge.title}, earned'
    : '${badge.title}, ${badge.current} of ${badge.target} ${badge.unit}';

/// A round medal: puffed up in its family colour once earned; until then a
/// dent ringed by how far along it is.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({required this.badge, this.size = 52, super.key});

  final CurioBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = badgeColor(context, badge.tone);
    // Bright fills take dark glyphs (design.md §3).
    final onColor = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
    );
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final track = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );

    final Widget disc;
    if (badge.earned) {
      disc = CurioClay(
        radius: size / 2,
        color: color,
        child: Center(
          child: Icon(badge.icon, size: size * .46, color: onColor),
        ),
      );
    } else {
      disc = CustomPaint(
        painter: _ProgressRing(
          progress: badge.progress,
          color: color,
          track: track,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * .1),
          child: CurioClay(
            radius: size * .4,
            pressed: true,
            child: Center(
              child: Icon(
                badge.icon,
                size: size * .4,
                color: muted.withValues(alpha: .8),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: _badgeSemantics(badge),
      child: ExcludeSemantics(
        child: SizedBox.square(dimension: size, child: disc),
      ),
    );
  }
}

class _ProgressRing extends CustomPainter {
  const _ProgressRing({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * .065;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRing old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// The Profile page's trophy shelf: how many badges are earned, every medal,
/// and the badge that's closest to being earned. Tapping opens [showBadgesSheet].
class BadgeShelf extends StatelessWidget {
  const BadgeShelf({required this.badges, required this.onOpen, super.key});

  final List<CurioBadge> badges;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final link = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffronStrong,
    );
    final earned = badges.where((b) => b.earned).length;
    final next = nextBadge(badges);
    // Earned medals first, so the shelf fills up from the left.
    final ordered = [
      ...badges.where((b) => b.earned),
      ...badges.where((b) => !b.earned),
    ];

    return Semantics(
      button: true,
      label: [
        'Badges, $earned of ${badges.length} earned',
        if (next != null)
          'Next up: ${next.title}, ${next.current} of ${next.target} ${next.unit}',
        'Opens all badges',
      ].join('. '),
      excludeSemantics: true,
      onTap: onOpen,
      child: CurioCard(
        key: const Key('badge_shelf'),
        onTap: onOpen,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CurioIconTile(
                  icon: Icons.emoji_events_rounded,
                  color: gold,
                  size: 40,
                  iconSize: 22,
                  radius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Badges',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$earned of ${badges.length} earned',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    color: link,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: link, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in ordered) BadgeMedal(badge: b, size: 40),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 14),
              _NextUp(badge: next),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({required this.badge});

  final CurioBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = badgeColor(context, badge.tone);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return CurioClay(
      radius: 14,
      color: color.withValues(alpha: .08),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'NEXT UP  ',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                TextSpan(
                  text: badge.title,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' · ${badge.description}',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          _ProgressLine(badge: badge, color: color),
        ],
      ),
    );
  }
}

/// A progress bar with "3 / 7 days" beside it.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.badge, required this.color});

  final CurioBadge badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Row(
      children: [
        Expanded(
          child: CurioProgressBar(
            value: badge.progress,
            color: color,
            height: 7,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          badge.progressLabel,
          style: TextStyle(
            color: muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Every badge in a tall sheet: what's earned, then what's left, closest first.
Future<void> showBadgesSheet(BuildContext context, List<CurioBadge> badges) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .86,
      minChildSize: .5,
      maxChildSize: .95,
      builder: (context, controller) =>
          _BadgesSheet(badges: badges, controller: controller),
    ),
  );
}

class _BadgesSheet extends StatelessWidget {
  const _BadgesSheet({required this.badges, required this.controller});

  final List<CurioBadge> badges;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final earned = [
      for (final b in badges)
        if (b.earned) b,
    ];
    final toEarn = [
      for (final b in badges)
        if (!b.earned) b,
    ]..sort((a, b) => b.progress.compareTo(a.progress));

    return SafeArea(
      top: false,
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const CurioEyebrow('Badges'),
          const SizedBox(height: 8),
          Text(
            'A trail of brave thinking',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            earned.isEmpty
                ? 'Finish your first game to earn your first badge.'
                : '${earned.length} of ${badges.length} earned. Each one comes from something you really did.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 12),
          CurioProgressBar(value: earned.length / badges.length, height: 10),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: 22),
            SectionHeading('Earned', subtitle: '${earned.length} so far'),
            const SizedBox(height: 10),
            for (final b in earned) ...[
              _BadgeRow(badge: b),
              const SizedBox(height: 10),
            ],
          ],
          if (toEarn.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SectionHeading('Still to earn', subtitle: 'Closest first'),
            const SizedBox(height: 10),
            for (final b in toEarn) ...[
              _BadgeRow(badge: b),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.badge});

  final CurioBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = badgeColor(context, badge.tone);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final earnedInk = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );
    return Semantics(
      container: true,
      label:
          '${badge.title}. ${badge.description} '
          '${badge.earned ? 'Earned.' : '${badge.current} of ${badge.target} ${badge.unit}.'}',
      excludeSemantics: true,
      child: CurioCard(
        key: Key('badge_${badge.id}'),
        padding: const EdgeInsets.all(12),
        color: badge.earned ? color.withValues(alpha: .1) : null,
        child: Row(
          children: [
            BadgeMedal(badge: badge, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.description,
                    style: TextStyle(color: muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  if (badge.earned)
                    Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: earnedInk,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Earned',
                          style: TextStyle(
                            color: earnedInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  else
                    _ProgressLine(badge: badge, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
