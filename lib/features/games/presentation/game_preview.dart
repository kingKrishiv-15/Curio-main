import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tiny, glanceable picture of how each game plays — drawn on the vivid
/// card art so a child can tell games apart before reading a word ("4 · 11 ·
/// 18 · ?" is Sequence; a closing range bar is Squeeze).
///
/// Everything is laid out on a fixed 150 × 84 canvas and scaled to fit, so
/// previews stay crisp at any card size and ignore the reader's text scale
/// (they're decorative; the card's own text carries the meaning).
class GamePreview extends StatelessWidget {
  const GamePreview({required this.gameId, required this.color, super.key});

  final String gameId;

  /// The game's skill colour; text on white chips is a deep shade of it.
  final Color color;

  static const _w = 150.0, _h = 84.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          child: SizedBox(
            width: _w,
            height: _h,
            child: Center(child: _build(_Ink(color))),
          ),
        ),
      ),
    );
  }

  Widget _build(_Ink ink) => switch (gameId) {
    'odd_cluster' => _oddCluster(ink),
    'sequence' => _sequence(ink),
    'bridge' => _bridge(ink),
    'cascade' => _cascade(ink),
    'loophole' => _loophole(ink),
    'squeeze' => _squeeze(ink),
    'link_lab' => _linkLab(),
    'signal_grid' => _signalGrid(ink),
    'pattern_forge' => _patternForge(ink),
    'evidence_garden' => _evidence(ink),
    'frostlands_night_1' => _frostlands(),
    'scale' => _scale(ink),
    'mirror' => _mirror(),
    'verdict' => _verdict(ink),
    'whos_who' => _whosWho(ink),
    _ => const Icon(Icons.extension_rounded, color: Colors.white, size: 48),
  };

  // --- Pieces -----------------------------------------------------------------

  static Widget _chip(
    String text,
    _Ink ink, {
    bool solid = true,
    double width = 30,
    double height = 30,
    double size = 14,
    bool display = true,
  }) => Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: solid ? Colors.white : Colors.white.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(height * .32),
      border: solid
          ? null
          : Border.all(color: Colors.white.withValues(alpha: .85), width: 1.4),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontFamily: display ? 'Fraunces' : 'DM Sans',
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1,
        color: solid ? ink.deep : Colors.white,
      ),
    ),
  );

  static Widget _arrow({IconData icon = Icons.arrow_forward_rounded}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Icon(icon, size: 11, color: Colors.white.withValues(alpha: .85)),
      );

  static Widget _cell(double size, {double alpha = .28, Widget? child}) =>
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(size * .28),
        ),
        child: child,
      );

  static Widget _grid(
    int rows,
    int cols,
    double size,
    double gap,
    Widget Function(int r, int c) build,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var r = 0; r < rows; r++) ...[
        if (r > 0) SizedBox(height: gap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var c = 0; c < cols; c++) ...[
              if (c > 0) SizedBox(width: gap),
              build(r, c),
            ],
          ],
        ),
      ],
    ],
  );

  // --- Games -----------------------------------------------------------------

  Widget _oddCluster(_Ink ink) => _grid(
    4,
    4,
    14,
    4,
    (r, c) => _cell(
      14,
      alpha: r == 0
          ? 1
          : (r == 2 && c == 1) || (r == 3 && c == 2)
          ? .6
          : .26,
    ),
  );

  Widget _sequence(_Ink ink) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _chip('4', ink),
      const SizedBox(width: 6),
      _chip('11', ink),
      const SizedBox(width: 6),
      _chip('18', ink),
      const SizedBox(width: 6),
      _chip('?', ink, solid: false),
    ],
  );

  Widget _bridge(_Ink ink) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _chip('7', ink, width: 28, height: 28, size: 13),
      _arrow(),
      _chip('×3', ink, solid: false, width: 26, height: 22, size: 11),
      _arrow(),
      _chip('x²', ink, solid: false, width: 26, height: 22, size: 11),
      _arrow(),
      _chip('?', ink, width: 28, height: 28, size: 13),
    ],
  );

  Widget _cascade(_Ink ink) {
    Widget bar(double w, double alpha) => Container(
      width: w,
      height: 15,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(96, 1),
        _arrow(icon: Icons.arrow_downward_rounded),
        bar(80, .6),
        _arrow(icon: Icons.arrow_downward_rounded),
        bar(64, .35),
      ],
    );
  }

  Widget _loophole(_Ink ink) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.format_quote_rounded,
        size: 34,
        color: Colors.white.withValues(alpha: .9),
      ),
      const SizedBox(width: 4),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip(
                '90%',
                ink,
                solid: false,
                width: 36,
                height: 20,
                size: 10,
                display: false,
              ),
              const SizedBox(width: 4),
              _chip(
                'agree',
                ink,
                solid: false,
                width: 42,
                height: 20,
                size: 10,
                display: false,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
            ),
            child: _chip(
              'surveyed',
              ink,
              width: 66,
              height: 22,
              size: 11,
              display: false,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _squeeze(_Ink ink) {
    TextStyle label = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('?', ink, width: 26, height: 22, size: 13),
        const SizedBox(height: 6),
        SizedBox(
          width: 132,
          height: 12,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .26),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Positioned(
                left: 48,
                width: 34,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 132,
          child: Row(
            children: [
              Text('1', style: label),
              const Spacer(),
              Text('100', style: label),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linkLab() =>
      CustomPaint(size: const Size(120, 76), painter: _NetworkPainter());

  Widget _signalGrid(_Ink ink) {
    const pattern = [
      [1, 2, 1, 2],
      [2, 1, 2, 1],
      [1, 0, 2, 2],
      [2, 2, 0, 1],
    ];
    return _grid(4, 4, 15, 3, (r, c) {
      final v = pattern[r][c];
      return _cell(
        15,
        alpha: v == 0 ? .16 : .32,
        child: v == 0
            ? null
            : Icon(
                v == 1 ? Icons.auto_awesome_rounded : Icons.waves_rounded,
                size: 10,
                color: Colors.white,
              ),
      );
    });
  }

  Widget _patternForge(_Ink ink) {
    Widget dots(int n) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var j = 0; j <= i; j++) ...[
                if (j > 0) const SizedBox(width: 3),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        dots(1),
        const SizedBox(width: 12),
        dots(2),
        const SizedBox(width: 12),
        dots(3),
        const SizedBox(width: 12),
        _chip('?', ink, solid: false, width: 30, height: 30),
      ],
    );
  }

  Widget _evidence(_Ink ink) => SizedBox(
    width: 120,
    height: 76,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.14,
          child: Transform.translate(
            offset: const Offset(-18, 0),
            child: _card(.35),
          ),
        ),
        Transform.rotate(
          angle: .08,
          child: Transform.translate(
            offset: const Offset(12, 4),
            child: _card(.7),
          ),
        ),
        const Positioned(
          right: 6,
          top: 2,
          child: Icon(Icons.search_rounded, size: 40, color: Colors.white),
        ),
      ],
    ),
  );

  static Widget _card(double alpha) => Container(
    width: 58,
    height: 42,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in [36.0, 24.0, 30.0]) ...[
          Container(
            width: w,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    ),
  );

  Widget _frostlands() =>
      CustomPaint(size: const Size(140, 76), painter: _MountainPainter());

  Widget _scale(_Ink ink) => SizedBox(
    width: 140,
    height: 80,
    child: Stack(
      children: [
        const Positioned(
          left: 42,
          top: 0,
          child: Icon(Icons.balance_rounded, size: 56, color: Colors.white),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: _chip('3/4', ink, width: 40, height: 24, size: 12),
        ),
        Positioned(
          right: 4,
          bottom: 14,
          child: _chip('0.7', ink, width: 40, height: 24, size: 12),
        ),
      ],
    ),
  );

  Widget _mirror() {
    const pattern = [
      [1, 0, 1],
      [1, 1, 0],
      [0, 1, 0],
      [1, 0, 1],
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grid(
          4,
          3,
          12,
          3,
          (r, c) => _cell(12, alpha: pattern[r][c] == 1 ? 1 : .2),
        ),
        Container(
          width: 2,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.white.withValues(alpha: .9),
        ),
        _grid(4, 3, 12, 3, (r, c) {
          final filled = pattern[r][2 - c] == 1;
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: filled && c == 0 ? .7 : .12,
              ),
              borderRadius: BorderRadius.circular(3.4),
              border: filled
                  ? Border.all(color: Colors.white, width: 1.2)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _verdict(_Ink ink) {
    Widget button(IconData icon, bool picked) => Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: picked ? Colors.white : Colors.white.withValues(alpha: .22),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: picked ? ink.deep : Colors.white),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('“Always late!”', ink, width: 112, height: 26, size: 12),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.thumb_up_rounded, false),
            const SizedBox(width: 10),
            button(Icons.thumb_down_rounded, true),
            const SizedBox(width: 10),
            button(Icons.question_mark_rounded, false),
          ],
        ),
      ],
    );
  }

  Widget _whosWho(_Ink ink) {
    const ticks = {(0, 1), (1, 2), (2, 0)};
    return _grid(3, 3, 19, 4, (r, c) {
      final yes = ticks.contains((r, c));
      return _cell(
        19,
        alpha: yes ? 1 : .22,
        child: Icon(
          yes ? Icons.check_rounded : Icons.close_rounded,
          size: 12,
          color: yes ? ink.deep : Colors.white.withValues(alpha: .8),
        ),
      );
    });
  }
}

class _Ink {
  _Ink(Color color) : deep = Color.lerp(color, Colors.black, .62)!;

  /// Readable text colour on white chips: a deep shade of the skill colour.
  final Color deep;
}

class _NetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      Offset(size.width * .14, size.height * .3),
      Offset(size.width * .46, size.height * .14),
      Offset(size.width * .82, size.height * .34),
      Offset(size.width * .32, size.height * .8),
      Offset(size.width * .7, size.height * .82),
    ];
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in [(0, 1), (1, 2), (0, 3), (3, 4), (1, 4), (2, 4)]) {
      canvas.drawLine(nodes[a], nodes[b], line);
    }
    for (var i = 0; i < nodes.length; i++) {
      canvas.drawCircle(
        nodes[i],
        i == 1 ? 9 : 6.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter oldDelegate) => false;
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Aurora ribbon.
    final aurora = Path()..moveTo(0, h * .3);
    for (var x = 0.0; x <= w; x += 4) {
      aurora.lineTo(x, h * .26 + math.sin(x / w * math.pi * 2.2) * h * .1);
    }
    canvas.drawPath(
      aurora,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    // Mountains.
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * .3, h * .42)
        ..lineTo(w * .55, h)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: .55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .3, h)
        ..lineTo(w * .62, h * .3)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = Colors.white,
    );
    // A star.
    canvas.drawCircle(
      Offset(w * .86, h * .12),
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_MountainPainter oldDelegate) => false;
}
