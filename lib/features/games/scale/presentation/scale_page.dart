import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/scale.dart';

/// Tip the Scale: two amounts on a balance — which is more, or are they
/// equal? Eight rounds a day; the beam tips to the true side after each
/// answer and both amounts are written the same way to show why.
class ScalePage extends StatefulWidget {
  const ScalePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends State<ScalePage> {
  static const _gameId = 'scale';
  static const _rules = [
    'Two amounts sit on the scale: fractions, decimals, percentages, quick sums or whole numbers.',
    'Tap the side that’s more — or “They’re equal” if they balance.',
    'The scale tips to the true side, then shows both amounts written the same way so you can see why.',
    'Eight rounds a day: three warm-ups, three mixed forms, then two close calls.',
  ];
  static const _cheers = [
    'Spot on!',
    'Nicely weighed!',
    'Sharp thinking!',
    'Yes — well judged!',
  ];

  final _scroll = ScrollController();
  final _nextKey = GlobalKey();
  late ScaleGame _game = _newGame();
  int _practiceShift = 0;
  bool _alreadyDone = false;
  bool _awarded = false;
  bool _showResult = false;

  bool get _practice => _practiceShift > 0;

  ScaleGame _newGame() => ScaleGame.forDay(
    DailyPick.dayNumber(widget.date),
    practice: _practiceShift,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Duration _motion(int ms) => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: ms);

  void _answer(ScaleSide side) {
    if (_game.answered) return;
    final correct = _game.answer(side);
    if (correct) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() {});
    if (_game.finished && !_practice && !_awarded) {
      _awarded = true;
      _alreadyDone = awardDaily(context, _gameId);
    }
    // Bring "Next" into view if a big text size pushed it off screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _nextKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: _motion(320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _next() {
    if (!_game.answered) return;
    setState(() {
      if (_game.isLast) {
        _showResult = true;
      } else {
        _game.next();
      }
    });
    _scrollToTop();
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _game = _newGame();
      _showResult = false;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final duration = _motion(320);
      if (duration == Duration.zero) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
      }
    });
  }

  String _verdict(ScaleRound round, ScaleSide pick) {
    final answer = round.answer;
    final side = answer == ScaleSide.left ? 'left' : 'right';
    if (pick == answer) {
      return answer == ScaleSide.equal
          ? 'Perfectly balanced — they’re equal!'
          : '${_cheers[_game.current % _cheers.length]} The $side side is more.';
    }
    if (answer == ScaleSide.equal) {
      return 'Not quite — they’re exactly equal. Same amount, different look!';
    }
    if (pick == ScaleSide.equal) {
      return 'Not quite — they’re not equal. The $side side is more.';
    }
    return round.tier == ScaleTier.close
        ? 'Not quite — the $side side is more. Close calls are tricky!'
        : 'Not quite — the $side side is more.';
  }

  String get _resultTitle => switch (_game.score) {
    8 => 'Perfectly balanced!',
    >= 6 => 'Nicely weighed!',
    >= 4 => 'Good weighing.',
    _ => 'Every weigh-in teaches something.',
  };

  String get _share =>
      'Curio · Tip the Scale\n${_game.shareGrid}  ${_game.score}/${_game.rounds.length}';

  @override
  Widget build(BuildContext context) {
    final round = _game.round;
    final pick = _game.pickAt(_game.current);
    return CurioPage(
      title: 'Tip the Scale',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice round' : 'Daily number puzzle',
            title: _showResult ? 'All weighed up.' : 'Which side is more?',
            subtitle:
                'Weigh up two amounts, then tap the side that’s more — or call it equal.',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
              GameMetaChip(
                icon: Icons.calculate_rounded,
                label: 'Number sense',
              ),
            ],
            trailing: _RoundPips(game: _game),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          if (!_showResult) ...[
            _Board(
              // A fresh scale each round, so its idle sway starts over.
              key: ValueKey('scale_board_${_practiceShift}_${_game.current}'),
              round: round,
              index: _game.current,
              total: _game.rounds.length,
              pick: pick,
              onPick: _answer,
            ),
            if (pick != null) ...[
              const SizedBox(height: 14),
              GameNotice(
                message: _verdict(round, pick),
                tone: pick == round.answer
                    ? GameNoticeTone.good
                    : GameNoticeTone.bad,
              ),
              const SizedBox(height: 14),
              KeyedSubtree(
                key: _nextKey,
                child: PrimaryButton(
                  key: const Key('scale_next'),
                  label: _game.isLast ? 'See result' : 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ] else ...[
            GameResultCard(
              title: _resultTitle,
              score: '${_game.score} / ${_game.rounds.length}',
              shareText: _share,
              xp: _practice ? null : gameRewards[_gameId]!.xp,
              alreadyDone: _alreadyDone,
              gameId: _gameId,
              onPractice: _practiceRound,
            ),
            const SizedBox(height: 22),
            SectionHeading(
              _practice ? 'Your practice weigh-ins' : 'Today’s weigh-ins',
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _game.rounds.length; i++)
              _RecapRow(
                index: i,
                round: _game.rounds[i],
                correct: _game.correctAt(i) ?? false,
              ),
          ],
        ],
      ),
    );
  }
}

/// The card holding the scale, the round number and either the "equal"
/// button or, once answered, the working.
class _Board extends StatelessWidget {
  const _Board({
    required this.round,
    required this.index,
    required this.total,
    required this.pick,
    required this.onPick,
    super.key,
  });

  final ScaleRound round;
  final int index, total;
  final ScaleSide? pick;
  final ValueChanged<ScaleSide> onPick;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                'ROUND ${index + 1} OF $total',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              _TierTag(tier: round.tier),
            ],
          ),
          const SizedBox(height: 4),
          RepaintBoundary(
            child: _BalanceScale(
              round: round,
              pick: pick,
              onPick: pick == null ? onPick : null,
            ),
          ),
          const SizedBox(height: 14),
          if (pick == null)
            OutlinedButton.icon(
              key: const Key('scale_equal'),
              onPressed: () => onPick(ScaleSide.equal),
              icon: const Icon(Icons.balance_rounded, size: 20),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('They’re equal'),
              ),
            )
          else
            _Working(round: round),
        ],
      ),
    );
  }
}

class _TierTag extends StatelessWidget {
  const _TierTag({required this.tier});
  final ScaleTier tier;

  @override
  Widget build(BuildContext context) {
    final saffron = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffron,
    );
    final strong = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: saffron.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(
                  switch (tier) {
                    ScaleTier.warmUp => Icons.directions_walk_rounded,
                    ScaleTier.mixed => Icons.shuffle_rounded,
                    ScaleTier.close => Icons.compare_arrows_rounded,
                  },
                  size: 14,
                  color: strong,
                ),
              ),
            ),
            TextSpan(text: tier.label),
          ],
        ),
        style: TextStyle(
          color: ink,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// "3/4 = 0.750 · 5/8 = 0.625 → left is more", broken only between parts.
class _Working extends StatelessWidget {
  const _Working({required this.round});
  final ScaleRound round;

  @override
  Widget build(BuildContext context) {
    final fill = curioColor(
      context,
      CurioColors.surfaceMuted,
      CurioColorsLight.surfaceMuted,
    );
    final strong = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    const style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 1.35,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: round.spokenExplanation,
      excludeSemantics: true,
      child: Container(
        key: const Key('scale_explanation'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.calculate_rounded, size: 19, color: strong),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Wrap(
                spacing: 7,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(round.leftWorking, style: style),
                  Text('·', style: style.copyWith(color: muted)),
                  Text(round.rightWorking, style: style),
                  Text('→ ${round.verdict}', style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ScaleColours = ({
  Color frame,
  Color string,
  Color beam,
  Color pivot,
  Color dish,
});

/// Sizes that depend on how wide the scale is.
class _ScaleGeometry {
  _ScaleGeometry(this.width)
    : panWidth = (width - gap) / 2,
      arm = (width + gap) / 4 {
    // A few degrees of tilt, but never more than [maxDrop] of travel on a
    // wide screen.
    maxAngle = math.min(
      7 * math.pi / 180,
      math.asin(math.min(1, maxDrop / arm)),
    );
  }

  static const gap = 30.0;
  static const maxDrop = 16.0;
  static const beamThickness = 7.0;
  static const dishDepth = 11.0;
  static const baseHeight = 8.0;

  final double width, panWidth;

  /// From the pivot to the middle of a pan.
  final double arm;
  late final double maxAngle;

  double get rise => arm * math.sin(maxAngle);
  double get beamY => rise + 12;

  /// Down to the tops of the cards: the strings, plus room so a rising
  /// card's inner corner never meets the tilted beam.
  double get top => beamY + 16 + (panWidth / 2) * math.tan(maxAngle);
  double get bottom => dishDepth + rise + 10 + baseHeight;
}

/// The balance itself: a post and base, a beam that tips, and two pans that
/// hang from it. Sways gently while waiting (unless motion is reduced), then
/// tips to the heavier side once [pick] arrives.
class _BalanceScale extends StatefulWidget {
  const _BalanceScale({
    required this.round,
    required this.pick,
    required this.onPick,
  });

  final ScaleRound round;
  final ScaleSide? pick;
  final ValueChanged<ScaleSide>? onPick;

  @override
  State<_BalanceScale> createState() => _BalanceScaleState();
}

class _BalanceScaleState extends State<_BalanceScale>
    with TickerProviderStateMixin {
  /// As shares of the full tilt.
  static const _swayShare = .17;
  static const _wobbleShare = .45;

  late final _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final _tip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Where the beam was (as a share of full tilt) when the answer landed.
  double _from = 0;

  bool get _answered => widget.pick != null;

  @override
  void initState() {
    super.initState();
    if (_answered) _tip.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_answered) {
      _sway.stop();
      if (MediaQuery.disableAnimationsOf(context)) _tip.value = 1;
    } else {
      syncLoop(_sway, context);
    }
  }

  @override
  void didUpdateWidget(covariant _BalanceScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pick == null && widget.pick != null) {
      _from = _swayTilt;
      _sway.stop();
      if (MediaQuery.disableAnimationsOf(context)) {
        _tip.value = 1;
      } else {
        _tip.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    _tip.dispose();
    super.dispose();
  }

  double get _swayTilt =>
      _sway.isAnimating ? _swayShare * math.sin(2 * math.pi * _sway.value) : 0;

  /// −1 is fully down on the left, 1 fully down on the right.
  double get _tilt {
    if (!_answered) return _swayTilt;
    final answer = widget.round.answer;
    final target = switch (answer) {
      ScaleSide.left => -1.0,
      ScaleSide.right => 1.0,
      ScaleSide.equal => 0.0,
    };
    final t = _tip.value;
    if (t >= 1) return target;
    // A quick drop, one overshoot, then rest — like a real balance.
    final settle = 1 - math.exp(-5 * t) * math.cos(2.5 * math.pi * t);
    final wobble = answer == ScaleSide.equal
        ? _wobbleShare * math.exp(-4 * t) * math.sin(3 * math.pi * t)
        : 0.0;
    return _from + (target - _from) * settle + wobble;
  }

  @override
  Widget build(BuildContext context) {
    final colours = (
      frame: curioColor(
        context,
        CurioColors.inkMuted,
        CurioColorsLight.inkMuted,
      ),
      string: curioColor(
        context,
        CurioColors.inkMuted,
        CurioColorsLight.inkMuted,
      ).withValues(alpha: .8),
      beam: curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
      pivot: curioColor(
        context,
        CurioColors.saffronStrong,
        CurioColorsLight.saffronStrong,
      ),
      dish: curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
    );
    final (leftShared, rightShared) = widget.round.shared;
    // Built once per build, so animation frames only move them.
    final left = _Pan(
      side: ScaleSide.left,
      quantity: widget.round.left,
      shared: leftShared,
      answer: widget.round.answer,
      pick: widget.pick,
      onPick: widget.onPick,
    );
    final right = _Pan(
      side: ScaleSide.right,
      quantity: widget.round.right,
      shared: rightShared,
      answer: widget.round.answer,
      pick: widget.pick,
      onPick: widget.onPick,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _ScaleGeometry(constraints.maxWidth);
        return AnimatedBuilder(
          animation: Listenable.merge([_sway, _tip]),
          builder: (context, _) {
            final angle = _tilt * geometry.maxAngle;
            final drop = geometry.arm * math.sin(angle);
            return CustomPaint(
              painter: _ScalePainter(
                geometry: geometry,
                angle: angle,
                colours: colours,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: geometry.top,
                  bottom: geometry.bottom,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          key: const ValueKey('scale_left_hang'),
                          offset: Offset(0, -drop),
                          child: left,
                        ),
                      ),
                      const SizedBox(width: _ScaleGeometry.gap),
                      Expanded(
                        child: Transform.translate(
                          key: const ValueKey('scale_right_hang'),
                          offset: Offset(0, drop),
                          child: right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter({
    required this.geometry,
    required this.angle,
    required this.colours,
  });

  final _ScaleGeometry geometry;
  final double angle;
  final _ScaleColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final cx = size.width / 2;
    final rimY = size.height - g.bottom;
    final baseY = size.height - _ScaleGeometry.baseHeight;
    final drop = g.arm * math.sin(angle);
    final reach = g.arm * math.cos(angle);
    final leftEnd = Offset(cx - reach, g.beamY - drop);
    final rightEnd = Offset(cx + reach, g.beamY + drop);
    final frame = Paint()..color = colours.frame;

    // Post and base.
    canvas.drawPath(
      Path()
        ..moveTo(cx - 3, g.beamY)
        ..lineTo(cx + 3, g.beamY)
        ..lineTo(cx + 6, baseY)
        ..lineTo(cx - 6, baseY)
        ..close(),
      frame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 46, baseY, 92, _ScaleGeometry.baseHeight),
        const Radius.circular(4),
      ),
      frame,
    );

    // Strings and dishes; the cards hang in front of the strings.
    final string = Paint()
      ..color = colours.string
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final dish = Paint()..color = colours.dish;
    final rim = Paint()
      ..color = colours.pivot
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final half = g.panWidth / 2 - 2;
    for (final (end, x, dy) in [
      (leftEnd, g.panWidth / 2, -drop),
      (rightEnd, size.width - g.panWidth / 2, drop),
    ]) {
      final y = rimY + dy;
      canvas
        ..drawLine(end, Offset(x - half, y), string)
        ..drawLine(end, Offset(x + half, y), string)
        ..drawPath(
          Path()
            ..moveTo(x - half, y)
            ..quadraticBezierTo(
              x,
              y + 2 * _ScaleGeometry.dishDepth,
              x + half,
              y,
            )
            ..close(),
          dish,
        )
        ..drawLine(Offset(x - half, y), Offset(x + half, y), rim);
    }

    // Beam, hooks and pivot on top.
    canvas.drawLine(
      leftEnd,
      rightEnd,
      Paint()
        ..color = colours.beam
        ..strokeWidth = _ScaleGeometry.beamThickness
        ..strokeCap = StrokeCap.round,
    );
    final pivot = Paint()..color = colours.pivot;
    canvas
      ..drawCircle(leftEnd, 4, pivot)
      ..drawCircle(rightEnd, 4, pivot)
      ..drawCircle(Offset(cx, g.beamY), 8, pivot)
      ..drawCircle(Offset(cx, g.beamY), 3, Paint()..color = colours.beam);
  }

  @override
  bool shouldRepaint(covariant _ScalePainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.geometry.width != geometry.width ||
      oldDelegate.colours != colours;
}

enum _Outcome { more, less, equal }

/// One pan's card: the amount, and either "Left is more" (before) or the
/// amount in the shared form plus More / Less / Equal (after).
class _Pan extends StatelessWidget {
  const _Pan({
    required this.side,
    required this.quantity,
    required this.shared,
    required this.answer,
    required this.pick,
    required this.onPick,
  });

  final ScaleSide side;
  final Quantity quantity;
  final String shared;
  final ScaleSide answer;
  final ScaleSide? pick;
  final ValueChanged<ScaleSide>? onPick;

  @override
  Widget build(BuildContext context) {
    final name = side == ScaleSide.left ? 'Left' : 'Right';
    final answered = pick != null;
    final picked = pick == side;
    final right = pick == answer;
    final outcome = answer == ScaleSide.equal
        ? _Outcome.equal
        : answer == side
        ? _Outcome.more
        : _Outcome.less;
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final accent = !picked
        ? null
        : right
        ? curioColor(context, CurioColors.success, CurioColorsLight.success)
        : curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final outcomeWord = switch (outcome) {
      _Outcome.more => 'More',
      _Outcome.less => 'Less',
      _Outcome.equal => 'Equal',
    };
    final tap = answered || onPick == null ? null : () => onPick!(side);
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        enabled: tap != null,
        label: answered ? '$name pan' : '$name is more',
        value: answered
            ? [
                quantity.spoken,
                if (shared != quantity.label) 'which is $shared',
                outcomeWord,
                if (picked) right ? 'your pick, right' : 'your pick, not quite',
              ].join(', ')
            : quantity.spoken,
        onTap: tap,
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('scale_${side.name}'),
                  onTap: tap,
                  borderRadius: radius,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: radius,
                      border: Border.all(
                        color: accent ?? outline,
                        width: accent == null ? 1.2 : 2.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _ValueText(quantity.label),
                    ),
                    const SizedBox(height: 8),
                    if (!answered)
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.touch_app_rounded,
                                  size: 15,
                                  color: coral,
                                ),
                              ),
                            ),
                            TextSpan(text: '$name is more'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: soft,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else ...[
                      if (shared != quantity.label) ...[
                        Text(
                          '= $shared',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: soft,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      _OutcomeTag(outcome: outcome, word: outcomeWord),
                    ],
                  ],
                ),
              ),
            ),
            if (picked)
              Positioned(
                top: -11,
                left: side == ScaleSide.left ? 10 : null,
                right: side == ScaleSide.right ? 10 : null,
                child: _PickBadge(right: right, colour: accent!),
              ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeTag extends StatelessWidget {
  const _OutcomeTag({required this.outcome, required this.word});
  final _Outcome outcome;
  final String word;

  @override
  Widget build(BuildContext context) {
    final (fill, icon) = switch (outcome) {
      _Outcome.more => (
        curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
        Icons.arrow_downward_rounded,
      ),
      _Outcome.less => (
        curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted),
        Icons.arrow_upward_rounded,
      ),
      _Outcome.equal => (
        curioColor(context, CurioColors.blue, CurioColorsLight.blue),
        Icons.balance_rounded,
      ),
    };
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(icon, size: 14, color: ink),
              ),
            ),
            TextSpan(text: word),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// ✓ or ✗ on the pan the player chose.
class _PickBadge extends StatelessWidget {
  const _PickBadge({required this.right, required this.colour});
  final bool right;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: surface,
        shape: BoxShape.circle,
        border: Border.all(color: colour, width: 2),
      ),
      child: Icon(
        right ? Icons.check_rounded : Icons.close_rounded,
        size: 14,
        color: colour,
      ),
    );
  }
}

/// A pan's label in Fraunces, with any fraction stacked the school way.
class _ValueText extends StatelessWidget {
  const _ValueText(this.label);
  final String label;

  static final _fraction = RegExp(r'(\d+)/(\d+)');

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 30,
      height: 1.1,
      fontWeight: FontWeight.w600,
      color: curioColor(context, CurioColors.ink, CurioColorsLight.ink),
    );
    final parts = <Widget>[];
    var at = 0;
    for (final m in _fraction.allMatches(label)) {
      if (m.start > at) {
        parts.add(Text(label.substring(at, m.start), style: style));
      }
      parts.add(
        _StackedFraction(m[1]!, m[2]!, style: style.copyWith(fontSize: 21)),
      );
      at = m.end;
    }
    if (at < label.length) parts.add(Text(label.substring(at), style: style));
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}

class _StackedFraction extends StatelessWidget {
  const _StackedFraction(
    this.numerator,
    this.denominator, {
    required this.style,
  });
  final String numerator, denominator;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(numerator, textAlign: TextAlign.center, style: style),
        Container(
          height: 2.4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(denominator, textAlign: TextAlign.center, style: style),
      ],
    ),
  );
}

/// Eight pips in two rows of four: ✓ right, ✗ missed, a ring for the
/// current round. Two rows keep the header's chips room at large text.
class _RoundPips extends StatelessWidget {
  const _RoundPips({required this.game});
  final ScaleGame game;

  @override
  Widget build(BuildContext context) {
    final total = game.rounds.length;
    final label = game.finished
        ? '${game.score} of $total right'
        : 'Round ${game.current + 1} of $total, ${game.score} right so far';
    Widget pip(int i) => Padding(
      padding: const EdgeInsets.all(2),
      child: _Pip(
        correct: game.correctAt(i),
        current: i == game.current && !game.finished,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < total; row += 4)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = row; i < math.min(row + 4, total); i++) pip(i),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.correct, required this.current});
  final bool? correct;
  final bool current;

  @override
  Widget build(BuildContext context) {
    const size = 15.0;
    if (correct == true) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: curioColor(
            context,
            CurioColors.success,
            CurioColorsLight.success,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 11,
          color: curioColor(context, CurioColors.night, CurioColorsLight.ink),
        ),
      );
    }
    if (correct == false) {
      final danger = curioColor(
        context,
        CurioColors.danger,
        CurioColorsLight.danger,
      );
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: danger, width: 1.6),
        ),
        child: Icon(Icons.close_rounded, size: 10, color: danger),
      );
    }
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: current
            ? Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: coral, width: 2.2),
                ),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: coral,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: outline,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}

/// One line of the end-of-day recap.
class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.index,
    required this.round,
    required this.correct,
  });

  final int index;
  final ScaleRound round;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final colour = correct
        ? curioColor(context, CurioColors.success, CurioColorsLight.success)
        : curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: colour.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: colour, width: 1.4),
              ),
              child: Icon(
                correct ? Icons.check_rounded : Icons.close_rounded,
                size: 15,
                color: colour,
                semanticLabel: correct ? 'Right' : 'Not quite',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.  ${round.leftLabel}  vs  ${round.rightLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    round.explanation,
                    style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
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
