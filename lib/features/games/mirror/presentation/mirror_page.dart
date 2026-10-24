import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/mirror.dart';

class MirrorPage extends StatefulWidget {
  const MirrorPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<MirrorPage> createState() => _MirrorPageState();
}

class _MirrorPageState extends State<MirrorPage> {
  static const _game = 'mirror';
  static const _rules = [
    'A dashed mirror line splits the board. The pattern on one side is locked.',
    'Tap squares on the other side to paint the pattern’s reflection. Tap a square again to rub it out.',
    'Press Check when it looks right. Right on the first check scores 100, the second 60, the third 30.',
    'After a check, ✕ marks a square that shouldn’t be painted and a dotted outline shows one that’s missing.',
    'Three mirrors a day: down the middle, across the middle, then corner to corner — the trickiest!',
  ];

  final _introKey = GlobalKey();
  late List<MirrorRound> _rounds = _newRounds();
  int _current = 0;
  int _practiceShift = 0;
  bool _alreadyDone = false;
  bool _recorded = false;
  String? _message;
  GameNoticeTone _tone = GameNoticeTone.info;

  bool get _practice => _practiceShift > 0;
  MirrorRound get _round => _rounds[_current];
  bool get _dayOver => _rounds.every((r) => r.over);
  int get _total => _rounds.fold(0, (sum, r) => sum + r.points);
  int get _maxTotal => _rounds.length * MirrorRound.maxPoints;

  List<MirrorRound> _newRounds() {
    final day = DailyPick.dayNumber(widget.date);
    return [
      for (final puzzle in mirrorPuzzles(
        mirrorSeed(day, practice: _practiceShift),
      ))
        MirrorRound(puzzle),
    ];
  }

  void _paint(int cell) {
    if (_round.over || _round.puzzle.isLocked(cell)) return;
    HapticFeedback.selectionClick();
    setState(() => _round.toggle(cell));
  }

  void _clear() => setState(_round.clear);

  void _check() {
    final round = _round;
    if (!round.canCheck) return;
    final result = round.check();
    if (result.correct) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() {
      if (result.correct) {
        _message = round.checks == 1
            ? 'Perfect reflection, first time! +${round.points} points.'
            : 'Perfect reflection! +${round.points} points.';
        _tone = GameNoticeTone.good;
      } else if (round.revealed) {
        _message =
            'Here’s the true reflection: dotted squares were missing and ✕ squares weren’t needed. Mirrors are tricky — well tried!';
        _tone = GameNoticeTone.bad;
      } else {
        final extra = result.extra.length;
        final left = round.checksLeft;
        _message =
            '${result.right} of ${result.total} squares right'
            '${extra == 0 ? '' : ', plus $extra that shouldn’t be painted'}. '
            'Fix the marked squares and check again — '
            '$left ${left == 1 ? 'check' : 'checks'} left.';
        _tone = extra + result.missing.length <= 2
            ? GameNoticeTone.close
            : GameNoticeTone.bad;
      }
    });
    _finishIfDone();
  }

  void _next() {
    setState(() {
      _current++;
      _message = null;
    });
    _showPuzzle();
  }

  void _finishIfDone() {
    if (!_dayOver || _practice || _recorded) return;
    _recorded = true;
    _alreadyDone = awardDaily(context, _game);
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _rounds = _newRounds();
      _current = 0;
      _message = null;
    });
    _showPuzzle();
  }

  /// Brings the new puzzle's heading to the top, so the whole board is in
  /// view rather than whatever was under the button just pressed.
  void _showPuzzle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final intro = _introKey.currentContext;
      if (!mounted || intro == null) return;
      unawaited(
        Scrollable.ensureVisible(
          intro,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  String get _share =>
      'Curio · Mirror\n'
      '${_rounds.map((r) => r.shareMark).join()}  $_total/$_maxTotal';

  String get _resultTitle {
    if (_total == _maxTotal) return 'Mirror master!';
    if (_total >= 200) return 'Sharp eyes!';
    if (_total >= 100) return 'Nicely reflected!';
    return 'Well tried — mirrors are tricky!';
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final last = _current == _rounds.length - 1;
    final showResult = _dayOver && last;
    final left = round.checksLeft;
    return CurioPage(
      title: 'Mirror',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice round' : 'Daily pattern puzzle',
            title: showResult ? 'All three mirrored.' : 'Paint the reflection',
            subtitle:
                'Flip the pattern across the dashed mirror line, square by square.',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '3–4 min'),
              GameMetaChip(icon: Icons.blur_on_rounded, label: 'Patterns'),
            ],
            trailing: _PuzzlePips(rounds: _rounds, current: _current),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          _PuzzleIntro(
            key: _introKey,
            round: round,
            index: _current,
            total: _rounds.length,
          ),
          const SizedBox(height: 12),
          _MirrorBoard(round: round, onTap: _paint),
          if (round.lastCheck != null && !round.solved) ...[
            const SizedBox(height: 12),
            _Legend(revealed: round.revealed),
          ],
          const SizedBox(height: 14),
          GameNotice(
            message: _message ?? _tip(round.puzzle.axis),
            tone: _message == null ? GameNoticeTone.info : _tone,
          ),
          const SizedBox(height: 14),
          if (!round.over) ...[
            PrimaryButton(
              key: const Key('mirror_check'),
              label: 'Check ($left ${left == 1 ? 'try' : 'tries'} left)',
              icon: Icons.flip_rounded,
              onPressed: round.canCheck ? _check : null,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('mirror_clear'),
              onPressed: round.painted.isEmpty ? null : _clear,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Clear my squares'),
            ),
          ] else if (!showResult)
            PrimaryButton(
              key: const Key('mirror_next'),
              label: 'Next puzzle',
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            )
          else
            CurioFadeSlideIn(
              child: GameResultCard(
                title: _resultTitle,
                score: '$_total / $_maxTotal',
                shareText: _share,
                xp: _practice ? null : gameRewards[_game]!.xp,
                alreadyDone: _alreadyDone,
                onPractice: _practiceRound,
                gameId: _game,
              ),
            ),
        ],
      ),
    );
  }
}

String _tip(MirrorAxis axis) => switch (axis) {
  MirrorAxis.vertical =>
    'Tap a square to paint it. Each square keeps its row and lands just as far from the mirror on the other side.',
  MirrorAxis.horizontal =>
    'Each square keeps its column and lands just as far below the mirror as it sits above it.',
  MirrorAxis.diagonal =>
    'Tricky one! Rows turn into columns: row 1, column 4 lands on row 4, column 1. Squares on the line stay put.',
};

class _PuzzleIntro extends StatelessWidget {
  const _PuzzleIntro({
    required this.round,
    required this.index,
    required this.total,
    super.key,
  });

  final MirrorRound round;
  final int index, total;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final accent = curioColor(
      context,
      CurioColors.coralStrong,
      CurioColorsLight.coralStrong,
    );
    final (title, how) = switch (round.puzzle.axis) {
      MirrorAxis.vertical => (
        'Mirror down the middle',
        'The left half is the pattern. Paint the right half to match it in the mirror.',
      ),
      MirrorAxis.horizontal => (
        'Mirror across the middle',
        'The top half is the pattern. Paint the bottom half to match it in the mirror.',
      ),
      MirrorAxis.diagonal => (
        'Mirror from corner to corner',
        'The pattern sits on and above the line. Paint below the line to match it in the mirror.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'PUZZLE ${index + 1} OF $total',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              round.over
                  ? (round.solved ? '+${round.points}' : 'No points')
                  : 'Worth ${round.worth}',
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(how, style: TextStyle(color: soft, height: 1.4)),
      ],
    );
  }
}

/// How a square looks: the locked pattern side, the paint side, and the
/// marks a check leaves behind.
enum _Look {
  patternEmpty,
  patternFilled,
  empty,
  painted,

  /// Painted, but the last check said it shouldn't be.
  wrong,

  /// Empty, but the last check said it belongs in the reflection.
  missing,

  /// Missing when the answer was revealed.
  missed,
}

/// Where each square sits. A straight mirror gets a wider gap to run down,
/// and the grid is centred the other way so the board stays square.
class _Grid {
  _Grid(double side, this.axis, this.size)
    : split = axis == MirrorAxis.diagonal ? 0 : _mirrorGap - _gap,
      cell =
          (side -
              2 * pad -
              (size - 1) * _gap -
              (axis == MirrorAxis.diagonal ? 0 : _mirrorGap - _gap)) /
          size;

  static const pad = 8.0;
  static const _gap = 5.0;
  static const _mirrorGap = 14.0;

  final MirrorAxis axis;
  final int size;
  final double split, cell;

  double left(int col) =>
      pad +
      col * (cell + _gap) +
      switch (axis) {
        MirrorAxis.vertical => col >= size ~/ 2 ? split : 0,
        MirrorAxis.horizontal => split / 2,
        MirrorAxis.diagonal => 0,
      };

  double top(int row) =>
      pad +
      row * (cell + _gap) +
      switch (axis) {
        MirrorAxis.horizontal => row >= size ~/ 2 ? split : 0,
        MirrorAxis.vertical => split / 2,
        MirrorAxis.diagonal => 0,
      };
}

class _MirrorBoard extends StatefulWidget {
  const _MirrorBoard({required this.round, required this.onTap});

  final MirrorRound round;
  final ValueChanged<int> onTap;

  @override
  State<_MirrorBoard> createState() => _MirrorBoardState();
}

class _MirrorBoardState extends State<_MirrorBoard>
    with SingleTickerProviderStateMixin {
  late final _glint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlint();
  }

  @override
  void didUpdateWidget(covariant _MirrorBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGlint();
  }

  /// The mirror glints while there's painting to do — and only when motion
  /// is allowed.
  void _syncGlint() {
    if (widget.round.over) {
      _glint.stop();
    } else {
      syncLoop(_glint, context);
    }
  }

  @override
  void dispose() {
    _glint.dispose();
    super.dispose();
  }

  _Look _lookOf(int cell, Set<int> extra, Set<int> missing) {
    final round = widget.round;
    if (round.puzzle.isLocked(cell)) {
      return round.puzzle.given.contains(cell)
          ? _Look.patternFilled
          : _Look.patternEmpty;
    }
    if (extra.contains(cell)) return _Look.wrong;
    if (missing.contains(cell)) {
      return round.revealed ? _Look.missed : _Look.missing;
    }
    return round.painted.contains(cell) ? _Look.painted : _Look.empty;
  }

  String _label(int cell, _Look look) {
    final puzzle = widget.round.puzzle;
    final size = puzzle.size;
    final state = switch (look) {
      _Look.patternEmpty => 'empty, locked',
      _Look.patternFilled => 'filled, locked',
      _Look.empty => 'empty',
      _Look.painted => 'filled',
      _Look.wrong => 'filled, shouldn’t be painted',
      _Look.missing => 'empty, should be painted',
      _Look.missed => 'empty, part of the reflection',
    };
    final onLine = onMirrorLine(cell, puzzle.axis, size: size)
        ? ', on the mirror line'
        : '';
    return 'Row ${cell ~/ size + 1}, column ${cell % size + 1}, $state$onLine';
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final puzzle = round.puzzle;
    final size = puzzle.size;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Square, at most 430 wide, and short enough to see whole on a phone
    // turned sideways.
    final side = (MediaQuery.sizeOf(context).height - 140).clamp(260.0, 430.0);
    final extra = round.markedExtra, missing = round.markedMissing;
    final success = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.success,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: side),
        child: AspectRatio(
          aspectRatio: 1,
          // A raised board; the green ring fades in once it's solved.
          child: TweenAnimationBuilder<Color?>(
            key: const Key('mirror_board'),
            tween: ColorTween(
              end: round.solved ? success : success.withValues(alpha: 0),
            ),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 300),
            builder: (context, ring, child) => CurioClay(
              radius: CurioRadius.large,
              outline: ring,
              padding: const EdgeInsets.all(2),
              child: child!,
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final grid = _Grid(box.maxWidth, puzzle.axis, size);
                return Stack(
                  children: [
                    for (var cell = 0; cell < size * size; cell++)
                      Positioned(
                        left: grid.left(cell % size),
                        top: grid.top(cell ~/ size),
                        width: grid.cell,
                        height: grid.cell,
                        child: Builder(
                          builder: (context) {
                            final look = _lookOf(cell, extra, missing);
                            final canPaint =
                                !round.over && !puzzle.isLocked(cell);
                            return _Cell(
                              index: cell,
                              look: look,
                              extent: grid.cell,
                              label: _label(cell, look),
                              onTap: canPaint ? () => widget.onTap(cell) : null,
                            );
                          },
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _MirrorLinePainter(
                              axis: puzzle.axis,
                              glint: _glint,
                              showGlint: !reduceMotion && !round.over,
                              line: curioColor(
                                context,
                                CurioColors.ink,
                                CurioColorsLight.ink,
                              ),
                              halo: clayBase(context),
                              shine: curioColor(
                                context,
                                CurioColors.spark,
                                CurioColorsLight.spark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.look,
    required this.extent,
    required this.label,
    this.onTap,
  });

  final int index;
  final _Look look;
  final double extent;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('mirror_cell_$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(_cellRadius(extent)),
          child: _CellFace(look: look, extent: extent, index: index),
        ),
      ),
    );
  }
}

double _cellRadius(double extent) => math.max(4, extent * .22);

/// A square's picture. Filled squares carry a dot and marked ones a ✕ or a
/// dotted outline, so none of it relies on colour alone.
class _CellFace extends StatelessWidget {
  const _CellFace({required this.look, required this.extent, this.index});

  final _Look look;
  final double extent;

  /// Board squares key their marks (for tests); legend swatches don't.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    // Coral is a bright accent in both modes, so marks on it are dark (§7).
    final onCoral = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
    );
    final faint = curioColor(
      context,
      CurioColors.outlineSoft,
      CurioColorsLight.outlineSoft,
    );
    final hint = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = _cellRadius(extent);

    final filled = switch (look) {
      _Look.patternFilled || _Look.painted || _Look.wrong => true,
      _ => false,
    };
    final glyph = switch (look) {
      _Look.patternFilled ||
      _Look.painted => Icon(Icons.circle, size: extent * .36, color: onCoral),
      _Look.wrong => Icon(
        Icons.close_rounded,
        size: extent * .62,
        color: onCoral,
      ),
      _Look.missed => Icon(
        Icons.circle_outlined,
        size: extent * .42,
        color: hint,
      ),
      _ => null,
    };

    final Widget body = Center(
      child: glyph == null
          ? null
          : TweenAnimationBuilder<double>(
              // A new mark pops in; with reduced motion it's simply there.
              key: ValueKey(look),
              tween: Tween(begin: reduceMotion ? 1 : .55, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: glyph,
            ),
    );
    // Filled squares are raised coral tiles and paintable blanks are dents
    // to fill. The pattern side's blanks stay flat: nothing goes there.
    Widget face = look == _Look.patternEmpty
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: faint, width: 1.2),
            ),
            child: body,
          )
        : TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: filled ? coral : clayBase(context)),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            builder: (context, colour, child) => CurioClay(
              radius: radius,
              color: colour,
              pressed: !filled,
              child: child!,
            ),
            child: body,
          );
    final key = index;
    if (look == _Look.missing || look == _Look.missed) {
      face = CustomPaint(
        key: key == null ? null : Key('mirror_missing_$key'),
        foregroundPainter: _DottedOutlinePainter(color: hint, radius: radius),
        child: face,
      );
    } else if (look == _Look.wrong && key != null) {
      face = KeyedSubtree(key: Key('mirror_extra_$key'), child: face);
    }
    return face;
  }
}

class _DottedOutlinePainter extends CustomPainter {
  const _DottedOutlinePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.4),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 3, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// The bold dashed mirror line, with a glint that slides along it now and
/// then. The dashes have a tray-coloured edge so they stay readable where
/// the diagonal crosses filled squares.
class _MirrorLinePainter extends CustomPainter {
  _MirrorLinePainter({
    required this.axis,
    required this.glint,
    required this.showGlint,
    required this.line,
    required this.halo,
    required this.shine,
  }) : super(repaint: glint);

  final MirrorAxis axis;
  final Animation<double> glint;
  final bool showGlint;
  final Color line, halo, shine;

  @override
  void paint(Canvas canvas, Size size) {
    // Kept inside the board's rounded corners.
    const inset = _Grid.pad + 2;
    final (start, end) = switch (axis) {
      MirrorAxis.vertical => (
        Offset(size.width / 2, inset),
        Offset(size.width / 2, size.height - inset),
      ),
      MirrorAxis.horizontal => (
        Offset(inset, size.height / 2),
        Offset(size.width - inset, size.height / 2),
      ),
      MirrorAxis.diagonal => (
        const Offset(inset, inset),
        Offset(size.width - inset, size.height - inset),
      ),
    };
    final along = end - start;
    final length = along.distance;
    if (length <= 0) return;
    final step = along / length;
    void dashes(Paint paint) {
      for (var d = 0.0; d < length; d += 17) {
        canvas.drawLine(
          start + step * d,
          start + step * math.min(d + 10, length),
          paint,
        );
      }
    }

    dashes(
      Paint()
        ..color = halo
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    dashes(
      Paint()
        ..color = line
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    if (!showGlint) return;
    // The glint crosses in the first part of each loop, then rests.
    final t = glint.value / .4;
    if (t >= 1) return;
    final centre = start + along * Curves.easeInOut.transform(t);
    canvas.drawLine(
      centre - step * 14,
      centre + step * 14,
      Paint()
        ..color = shine.withValues(alpha: .9 * math.sin(math.pi * t))
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _MirrorLinePainter oldDelegate) =>
      oldDelegate.axis != axis ||
      oldDelegate.glint != glint ||
      oldDelegate.showGlint != showGlint ||
      oldDelegate.line != line ||
      oldDelegate.halo != halo ||
      oldDelegate.shine != shine;
}

/// A key to the marks, shown once a check has left some on the board.
class _Legend extends StatelessWidget {
  const _Legend({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    Widget item(_Look look, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: 22,
            child: _CellFace(look: look, extent: 22),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: soft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(_Look.wrong, 'Shouldn’t be painted'),
        if (revealed)
          item(_Look.missed, 'Missed — part of the reflection')
        else
          item(_Look.missing, 'Missing'),
      ],
    );
  }
}

class _PuzzlePips extends StatelessWidget {
  const _PuzzlePips({required this.rounds, required this.current});

  final List<MirrorRound> rounds;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Puzzle ${current + 1} of ${rounds.length}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rounds.length; i++)
            Container(
              // The current puzzle is a longer pill, not just another colour.
              width: i == current && !rounds[i].over ? 20 : 10,
              height: 10,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: rounds[i].solved
                    ? curioColor(
                        context,
                        CurioColors.success,
                        CurioColorsLight.success,
                      )
                    : rounds[i].revealed
                    ? curioColor(
                        context,
                        CurioColors.danger,
                        CurioColorsLight.danger,
                      )
                    : i == current
                    ? curioColor(
                        context,
                        CurioColors.coral,
                        CurioColorsLight.coral,
                      )
                    : curioColor(
                        context,
                        CurioColors.outline,
                        CurioColorsLight.outline,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
