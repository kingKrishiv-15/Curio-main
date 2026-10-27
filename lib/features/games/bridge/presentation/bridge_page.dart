import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../domain/bridge.dart';

class BridgePage extends StatefulWidget {
  const BridgePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<BridgePage> createState() => _BridgePageState();
}

class _BridgePageState extends State<BridgePage> {
  static const _game = 'bridge';
  static const _tileCounts = [4, 5, 5];
  static const _rules = [
    'Turn the start number into the target using every tile exactly once.',
    'Long-press and drag tiles to reorder them, or use the arrows.',
    'The number after each tile updates as you move them — watch it travel.',
    'Every step must stay a whole number. A hint locks the next tile in place but costs points.',
  ];

  late List<BridgeRound> _rounds = _newRounds();
  int _current = 0;
  int _practiceShift = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceShift > 0;
  BridgeRound get _round => _rounds[_current];
  bool get _allSolved => _rounds.every((r) => r.solved);
  int get _total => _rounds.fold(0, (sum, r) => sum + r.points);

  List<BridgeRound> _newRounds() {
    final day = DailyPick.dayNumber(widget.date) + _practiceShift * 1000;
    return [
      for (var i = 0; i < _tileCounts.length; i++)
        BridgeRound(
          BridgePuzzle.generate(Random(day * 10 + i), tileCount: _tileCounts[i]),
        ),
    ];
  }

  void _update(VoidCallback change) {
    if (_round.solved) return;
    setState(change);
    if (_round.solved) {
      HapticFeedback.mediumImpact();
      _finishIfDone();
    }
  }

  void _move(int from, int to) => _update(() => _round.move(from, to));

  void _hint() => _update(() => _round.hint());

  void _next() => setState(() => _current++);

  void _finishIfDone() {
    if (!_allSolved || _practice) return;
    _alreadyDone = awardDaily(context, _game);
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _rounds = _newRounds();
      _current = 0;
    });
  }

  String get _share {
    final marks = _rounds.map((r) => r.hints == 0 ? '🟩' : '🟨').join();
    return 'Curio · Bridge\n$marks  $_total/${_rounds.length * 100}';
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final last = _current == _rounds.length - 1;
    return CurioPage(
      title: 'Bridge',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice bridges' : 'Daily number puzzle',
            title: _allSolved && last ? 'Every bridge built.' : 'Build the bridge',
            subtitle: 'Use every tile once. The order is the puzzle.',
            chips: [
              const GameMetaChip(icon: Icons.schedule_rounded, label: '3–5 min'),
              GameMetaChip(
                icon: Icons.layers_rounded,
                label: 'Bridge ${_current + 1} of ${_rounds.length}',
              ),
            ],
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: PracticeBadge()),
          ],
          const SizedBox(height: 16),
          _EndPoint(label: 'START', value: round.puzzle.start),
          const SizedBox(height: 8),
          _TileList(round: round, onMove: _move),
          const SizedBox(height: 8),
          _EndPoint(
            label: 'TARGET',
            value: round.puzzle.target,
            reached: round.solved,
            current: round.values.last,
          ),
          const SizedBox(height: 14),
          if (!round.solved) ...[
            GameNotice(
              message: round.puzzle.solutions == 1
                  ? 'Only one order works today. Hunt for it!'
                  : '${round.puzzle.solutions} different orders work — find any of them.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('bridge_hint'),
              onPressed: _hint,
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
              label: const Text('Hint: place the next tile (−30)'),
            ),
          ] else if (!last) ...[
            GameNotice(
              message: 'Bridge built! +${round.points} points.',
              tone: GameNoticeTone.good,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Next bridge',
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            ),
          ] else
            GameResultCard(
              gameId: 'bridge',
              title: _total == _rounds.length * 100 ? 'Master builder!' : 'All bridges built.',
              score: '$_total / ${_rounds.length * 100}',
              shareText: _share,
              xp: _practice ? null : 80,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
        ],
      ),
    );
  }
}

class _EndPoint extends StatelessWidget {
  const _EndPoint({
    required this.label,
    required this.value,
    this.reached = false,
    this.current,
  });

  final String label;
  final int value;
  final bool reached;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final navy = curioColor(context, CurioColors.navy, CurioColorsLight.navy);
    final success = curioColor(context, CurioColors.success, CurioColorsLight.success);
    // `navy` is coral in light mode, where gold text wouldn't read (§7).
    final labelColor = curioColor(
      context,
      CurioColors.gold,
      Colors.white.withValues(alpha: .85),
    );
    final isTarget = current != null || label == 'TARGET';
    return Semantics(
      label: '$label $value${isTarget && !reached ? ', currently ${current ?? 'not a whole number'}' : ''}',
      excludeSemantics: true,
      // Label and live value stack on the left so a big number never runs
      // out of room on a small phone at large text.
      child: CurioClay(
        radius: 20,
        color: reached ? success : navy,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: reached ? Colors.black87 : labelColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 12,
                    ),
                  ),
                  if (isTarget && !reached)
                    Text(
                      'now ${current ?? '—'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (reached)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle_rounded, color: Colors.black87),
              ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: reached ? Colors.black87 : Colors.white,
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

class _TileList extends StatelessWidget {
  const _TileList({required this.round, required this.onMove});

  final BridgeRound round;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final values = round.values;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: !round.solved,
      itemCount: round.order.length,
      onReorderItem: onMove,
      itemBuilder: (context, i) => Padding(
        // Each tile is its own object (even two "÷4"s), so it can be the key.
        key: ObjectKey(round.order[i]),
        padding: const EdgeInsets.only(bottom: 8),
        child: _OpRow(
          op: round.order[i],
          value: values[i],
          locked: round.solved,
          canUp: i > 0,
          canDown: i < round.order.length - 1,
          onUp: () => onMove(i, i - 1),
          onDown: () => onMove(i, i + 1),
        ),
      ),
    );
  }
}

class _OpRow extends StatelessWidget {
  const _OpRow({
    required this.op,
    required this.value,
    required this.locked,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
  });

  final BridgeOp op;
  final int? value;
  final bool locked, canUp, canDown;
  final VoidCallback onUp, onDown;

  @override
  Widget build(BuildContext context) {
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final outline = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    final gold = curioColor(context, CurioColors.saffron, CurioColorsLight.saffron);
    final danger = curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final muted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return Semantics(
      label: '${op.spoken}, giving ${value ?? 'not a whole number'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outline, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withValues(alpha: .6)),
              ),
              child: Text(
                op.label,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, size: 18, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? 'not whole' : '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: value == null ? 13 : 20,
                  color: value == null ? danger : null,
                ),
              ),
            ),
            if (!locked) ...[
              IconButton(
                tooltip: 'Move ${op.label} up',
                visualDensity: VisualDensity.compact,
                onPressed: canUp ? onUp : null,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                tooltip: 'Move ${op.label} down',
                visualDensity: VisualDensity.compact,
                onPressed: canDown ? onDown : null,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
