import 'dart:math' as math;
import 'package:curio/theme/curio_tokens.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../core/widgets/curio_ui.dart';
import '../domain/badges.dart';

/// Each badge family's colour: first steps forest, streaks coral, exploring
/// blue, discoveries plum, XP gold.
Color badgeColor(BuildContext context, BadgeTone tone) => switch (tone) {
  BadgeTone.start => CurioTokens.accent,
  BadgeTone.streak => CurioTokens.wrong,
  BadgeTone.explore => CurioTokens.tintLogic,
  BadgeTone.discovery => CurioTokens.tintThinking,
  BadgeTone.xp => CurioTokens.tintMaths,
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
    final onColor = CurioTokens.base;
    final muted = CurioTokens.textSecondary;
    final track = CurioTokens.border;

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

/// A progress bar with "3 / 7 days" beside it.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.badge, required this.color});

  final CurioBadge badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = CurioTokens.textSecondary;
    return Row(
      children: [
        Expanded(
          child: CurioProgressBar(
            value: badge.progress,
            color: color,
            height: 7,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          badge.progressLabel,
          style: TextStyle(
            color: muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class BadgeShelf extends StatelessWidget {
  const BadgeShelf({required this.badges, super.key});

  final List<CurioBadge> badges;

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((badge) => badge.earned).toList();
    final next = nextBadge(badges);
    final preview = [
      ...earned,
      ?next,
      ...badges.where((badge) => !badge.earned && badge != next),
    ].take(3);

    return CurioCard(
      key: const Key('badge_shelf'),
      onTap: () => showBadgesSheet(context, badges),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Badges', style: CurioType.cardTitle),
                    Text(
                      '${earned.length} of ${badges.length} earned',
                      style: CurioType.meta,
                    ),
                  ],
                ),
              ),
              const ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CurioTokens.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 32,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: CurioTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CurioTokens.s12),
          Wrap(
            spacing: CurioTokens.s8,
            runSpacing: CurioTokens.s8,
            children: [
              for (final badge in preview) BadgeMedal(badge: badge, size: 44),
            ],
          ),
        ],
      ),
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
    final muted = CurioTokens.textSecondary;
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Text('Badges', style: CurioTokens.display),
          const SizedBox(height: CurioTokens.s8),
          Text(
            earned.isEmpty
                ? 'Finish your first game to earn your first badge.'
                : '${earned.length} of ${badges.length} earned. Each one comes from something you really did.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: CurioTokens.s16),
          CurioProgressBar(value: earned.length / badges.length, height: 6),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeading('Earned', subtitle: '${earned.length} so far'),
            const SizedBox(height: 12),
            for (final b in earned) ...[
              _BadgeRow(badge: b),
              const SizedBox(height: 12),
            ],
          ],
          if (toEarn.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeading('Still to earn', subtitle: 'Closest first'),
            const SizedBox(height: 12),
            for (final b in toEarn) ...[
              _BadgeRow(badge: b),
              const SizedBox(height: 12),
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
    final muted = CurioTokens.textSecondary;
    final earnedInk = CurioTokens.accent;
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.title, style: CurioType.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(color: muted, fontSize: 13),
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
                        const SizedBox(width: 4),
                        Text(
                          'Earned',
                          style: TextStyle(
                            color: earnedInk,
                            fontSize: 13,
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
