import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_logo.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../../discoveries/domain/discovery.dart';
import '../../../games/game_catalog.dart';
import '../../../games/presentation/game_banner.dart';
import '../../../games/presentation/game_emblem.dart';

/// Illustrations for the signed-out journey. Every piece is decorative —
/// wrapped in [ExcludeSemantics] and fixed text scaling — because the words
/// next to it carry the meaning.

/// A skill as it appears across Curio: the same solid colour its games
/// and Home's skill tiles use.
class WelcomeSkill {
  const WelcomeSkill(this.label, this.icon, this.skill, this.gameId);
  final String label;
  final IconData icon;

  /// The learning skill it stands for (see `learningSkills`).
  final String skill;
  final String gameId;

  /// The fill colour (art, tiles).
  Color of(BuildContext context) =>
      gameColor(gameId, skillColor(context, skill));

  /// The same colour, deepened on light backgrounds so small text reads.
  Color ink(BuildContext context) {
    final solid = of(context);
    return curioColor(context, solid, Color.lerp(solid, Colors.black, .3)!);
  }

  static const all = [
    WelcomeSkill('Maths', Icons.calculate_rounded, 'Number sense', 'scale'),
    WelcomeSkill('Memory', Icons.style_rounded, 'Memory', 'memory_match'),
    WelcomeSkill('English', Icons.abc_rounded, 'Language', 'word_builder'),
    WelcomeSkill('Logic', Icons.extension_rounded, 'Reasoning', 'crowns'),
  ];
}

class _Decorative extends StatelessWidget {
  const _Decorative({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: MediaQuery.withNoTextScaling(child: child));
}

/// Curio's mark surrounded by the four daily sections. The toys bob gently
/// in place, leaving their labels stable and readable throughout the loop.
class OrbitHero extends StatefulWidget {
  const OrbitHero({this.size = 320, super.key});
  final double size;

  @override
  State<OrbitHero> createState() => _OrbitHeroState();
}

class _OrbitHeroState extends State<OrbitHero>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoop(_spin, context);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final still = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final spark = curioColor(
      context,
      CurioColors.spark,
      CurioColorsLight.spark,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final planet = s * .24;
    final orbit = s * .33;
    return _Decorative(
      child: SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, _) {
            final turn = still ? 0.0 : _spin.value * 2 * math.pi;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitPainter(
                      ring: ringColor,
                      arc: forest.withValues(alpha: dark ? .5 : .38),
                      spark: spark,
                      glow: (dark ? forest : spark).withValues(
                        alpha: dark ? .16 : .2,
                      ),
                      turn: turn,
                    ),
                  ),
                ),
                Center(
                  child: CurioFloat(
                    distance: 6,
                    child: Transform.rotate(
                      angle: -.06 + (still ? 0 : math.sin(turn) * .04),
                      child: CurioLogoMark(size: s * .35),
                    ),
                  ),
                ),
                for (var i = 0; i < WelcomeSkill.all.length; i++)
                  () {
                    final angle = [-2.4, -.75, .85, 2.45][i];
                    final bob = still ? 0.0 : math.sin(turn + i * 2) * s * .022;
                    final center = Offset(
                      s / 2 + math.cos(angle) * orbit,
                      s / 2 + math.sin(angle) * orbit + bob,
                    );
                    return Positioned(
                      left: (center.dx - planet * .9).clamp(
                        0.0,
                        s - planet * 1.8,
                      ),
                      top: center.dy - planet * .94,
                      width: planet * 1.8,
                      height: planet * 1.6,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _Planet(
                          key: ValueKey(
                            'welcome_section_${WelcomeSkill.all[i].label}',
                          ),
                          skill: WelcomeSkill.all[i],
                          size: planet,
                          tilt:
                              -.12 +
                              (still ? 0 : math.sin(turn + i * 2) * .065),
                        ),
                      ),
                    );
                  }(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Planet extends StatelessWidget {
  const _Planet({
    required this.skill,
    required this.size,
    required this.tilt,
    super.key,
  });
  final WelcomeSkill skill;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final color = skill.of(context);
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameEmblem(
          icon: skill.icon,
          color: color,
          size: size * 1.25,
          tilt: tilt,
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * .16,
            vertical: size * .04,
          ),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            skill.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: (size * .21).clamp(9, 12),
              fontWeight: FontWeight.w800,
              color: curioColor(context, CurioColors.ink, CurioColorsLight.ink),
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.ring,
    required this.arc,
    required this.spark,
    required this.glow,
    required this.turn,
  });

  final Color ring, arc, spark, glow;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.shortestSide;
    canvas.drawCircle(
      c,
      s * .36,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: s * .36)),
    );

    // Outer orbit: a fine dotted ring the skills travel along.
    final dots = Paint()..color = ring;
    const count = 72;
    for (var i = 0; i < count; i++) {
      final a = i / count * 2 * math.pi + turn * .25;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (s * .43),
        i.isEven ? 1.3 : .8,
        dots,
      );
    }

    // Inner orbit: the logo's "C", fading in round its sweep.
    final r = s * .27;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .018
      ..shader = SweepGradient(
        startAngle: CurioMarkGeometry.startAngle,
        endAngle: CurioMarkGeometry.startAngle + CurioMarkGeometry.sweep,
        colors: [arc.withValues(alpha: 0), arc],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      CurioMarkGeometry.startAngle,
      CurioMarkGeometry.sweep,
      false,
      arcPaint,
    );
    // A couple of far-off twinkles for depth.
    for (final (x, y, radius) in [(.1, .2, .022), (.9, .82, .018)]) {
      canvas.drawPath(
        CurioMarkGeometry.sparkPath(Offset(s * x, s * y), s * radius),
        Paint()..color = spark.withValues(alpha: .7),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.turn != turn ||
      old.ring != ring ||
      old.arc != arc ||
      old.spark != spark ||
      old.glow != glow;
}

/// A small fan of today's games, for the "Play" intro slide.
class GameFanArt extends StatelessWidget {
  const GameFanArt({this.height = 260, super.key});
  final double height;

  @override
  Widget build(BuildContext context) {
    // Mirrors Home's own game list (icons, skills, durations).
    final cards = [
      for (final id in const ['scale', 'memory_match', 'word_builder'])
        if (findGame(id) case final game?)
          (
            game.title,
            // "Numbers", not "Number sense": the card is narrow.
            '${game.skill == 'Number sense' ? 'Numbers' : game.skill} · '
                '${game.duration}',
            game.icon,
            gameColor(id, skillColor(context, game.skill)),
          ),
    ];
    final w = height * .48;
    // Left and right first so the centre card sits on top of both.
    const order = [0, 2, 1];
    return _Decorative(
      child: SizedBox(
        height: height,
        width: height * 1.5,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final i in order)
              Transform.translate(
                offset: Offset(
                  (i - 1) * w * 1.02,
                  (i - 1).abs() * height * .06,
                ),
                child: Transform.rotate(
                  angle: (i - 1) * .12,
                  child: CurioFloat(
                    distance: 5,
                    phase: i / 3,
                    child: _GameCard(
                      width: w,
                      title: cards[i].$1,
                      meta: cards[i].$2,
                      icon: cards[i].$3,
                      color: bannerFill(context, cards[i].$4),
                      raised: i == 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.width,
    required this.title,
    required this.meta,
    required this.icon,
    required this.color,
    this.raised = false,
  });

  final double width;
  final String title, meta;
  final IconData icon;
  final Color color;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Container(
      width: width,
      padding: EdgeInsets.all(width * .07),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(width * .16),
        border: Border.all(
          color: curioColor(
            context,
            CurioColors.outlineSoft,
            CurioColorsLight.outlineSoft,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: raised ? .22 : .12),
            blurRadius: raised ? 28 : 18,
            offset: Offset(0, raised ? 16 : 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(width * .11),
            child: Container(
              height: width * .82,
              color: color,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -width * .14,
                    bottom: -width * .16,
                    child: Icon(
                      icon,
                      size: width * .78,
                      color: Colors.white.withValues(alpha: .22),
                    ),
                  ),
                  Center(
                    child: Icon(icon, size: width * .34, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: width * .08),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: width * .12,
              fontWeight: FontWeight.w600,
              color: ink,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            maxLines: 1,
            style: TextStyle(
              fontSize: width * .075,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collected discoveries and a streak, for the "Discover" intro slide.
class DiscoveryArt extends StatelessWidget {
  const DiscoveryArt({this.height = 260, super.key});
  final double height;

  @override
  Widget build(BuildContext context) {
    final w = height * .86;
    final spark = curioColor(
      context,
      CurioColors.spark,
      CurioColorsLight.spark,
    );
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    // Sized by the front card (not a fixed height) so it never clips.
    return _Decorative(
      child: SizedBox(
        width: w * 1.26,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Transform.rotate(
                angle: .09,
                child: _FactCard(
                  width: w,
                  discovery: discoveries[4],
                  color: WelcomeSkill.all[1].of(context),
                  faded: true,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * .04,
                height * .2,
                w * .22,
                height * .12,
              ),
              child: Transform.rotate(
                angle: -.045,
                child: CurioFloat(
                  distance: 5,
                  child: _FactCard(
                    width: w,
                    discovery: discoveries[0],
                    color: WelcomeSkill.all[2].of(context),
                  ),
                ),
              ),
            ),
            Positioned(
              right: w * .04,
              bottom: 0,
              child: CurioFloat(
                distance: 4,
                phase: .4,
                child: _Chip(
                  icon: Icons.local_fire_department_rounded,
                  label: '5-day streak',
                  color: coral,
                ),
              ),
            ),
            Positioned(
              left: -w * .02,
              top: height * .06,
              child: Icon(Icons.auto_awesome_rounded, color: spark, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.width,
    required this.discovery,
    required this.color,
    this.faded = false,
  });

  final double width;
  final Discovery discovery;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Opacity(
      opacity: faded ? .7 : 1,
      child: Container(
        width: width,
        padding: EdgeInsets.all(width * .07),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .35), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: width * .2,
              height: width * .2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(width * .06),
              ),
              child: Icon(
                discovery.icon,
                color: Colors.white,
                size: width * .11,
              ),
            ),
            SizedBox(width: width * .055),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEW DISCOVERY',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discovery.title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      color: ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discovery.fact,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
    decoration: BoxDecoration(
      color: curioColor(context, CurioColors.surface, CurioColorsLight.surface),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .14),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: curioColor(context, CurioColors.ink, CurioColorsLight.ink),
          ),
        ),
      ],
    ),
  );
}

/// A glimpse of the parent view, for the "Grow" intro slide.
class GrowthArt extends StatelessWidget {
  const GrowthArt({this.height = 260, super.key});
  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    const levels = [.72, .56, .41, .64];
    final w = height * 1.05;
    // Sized by its content (not a fixed height) so large text grows the
    // card instead of clipping it; callers scale the whole piece to fit.
    return _Decorative(
      child: SizedBox(
        width: w * 1.12,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(top: height * .12, right: w * .08),
              child: CurioFloat(
                distance: 4,
                child: Container(
                  width: w,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THIS WEEK',
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Alex is growing',
                                  style: TextStyle(
                                    fontFamily: 'Fraunces',
                                    color: ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ProgressRing(
                            value: .8,
                            size: 44,
                            color: forest,
                            child: Text(
                              '4/5',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < WelcomeSkill.all.length; i++) ...[
                        Row(
                          children: [
                            Icon(
                              WelcomeSkill.all[i].icon,
                              size: 15,
                              color: WelcomeSkill.all[i].of(context),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 64,
                              child: Text(
                                WelcomeSkill.all[i].label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _GrowingBar(
                                value: levels[i],
                                color: WelcomeSkill.all[i].of(context),
                                delay: Duration(milliseconds: 200 + i * 140),
                              ),
                            ),
                          ],
                        ),
                        if (i < WelcomeSkill.all.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: CurioFloat(
                distance: 4,
                phase: .5,
                child: _Chip(
                  icon: Icons.mark_email_read_rounded,
                  label: 'Weekly note',
                  color: forest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowingBar extends StatefulWidget {
  const _GrowingBar({
    required this.value,
    required this.color,
    required this.delay,
  });
  final double value;
  final Color color;
  final Duration delay;

  @override
  State<_GrowingBar> createState() => _GrowingBarState();
}

class _GrowingBarState extends State<_GrowingBar> {
  bool _grown = false;
  Timer? _grow;

  @override
  void initState() {
    super.initState();
    _grow = Timer(widget.delay, () => setState(() => _grown = true));
  }

  @override
  void dispose() {
    _grow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CurioProgressBar(
    value: _grown || MediaQuery.disableAnimationsOf(context)
        ? widget.value
        : .04,
    color: widget.color,
    height: 7,
  );
}

/// An envelope with the brand spark, for the code-entry screen.
class InboxArt extends StatelessWidget {
  const InboxArt({this.size = 76, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final spark = curioColor(
      context,
      CurioColors.spark,
      CurioColorsLight.spark,
    );
    return _Decorative(
      child: SizedBox.square(
        dimension: size * 1.2,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: forest.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(size * .32),
                  border: Border.all(color: forest.withValues(alpha: .28)),
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  color: forest,
                  size: size * .5,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: CurioFloat(
                distance: 3,
                child: CustomPaint(
                  size: Size.square(size * .42),
                  painter: _SparkPainter(spark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    CurioMarkGeometry.sparkPath(size.center(Offset.zero), size.width / 2),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_SparkPainter old) => old.color != color;
}
