import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/crowns.dart';

class CrownsPage extends StatefulWidget {
  const CrownsPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<CrownsPage> createState() => _CrownsPageState();
}

enum _Tool { crown, mark }

class _CrownsPageState extends State<CrownsPage> {
  static const _game = 'crowns';
  static const _rules = [
    'Put one crown in every row and every column.',
    'Each colour is a kingdom, and every kingdom gets exactly one crown too.',
    'Crowns can’t touch each other — not even corner to corner.',
    'Squares a crown rules out sink into the board, so you can see where not to look.',
    'Use Mark × to note squares you’re sure about. Stuck? A hint places one crown.',
  ];

  int _practice = 0;
  late List<CrownsBoard> _boards = _newBoards();
  int _current = 0;
  late CrownsGame _puzzle = CrownsGame(_boards.first);
  _Tool _tool = _Tool.crown;
  int _hints = 0;
  bool _alreadyDone = false;
  bool _finished = false;

  bool get _lastBoard => _current == _boards.length - 1;

  List<CrownsBoard> _newBoards() =>
      dailyCrowns(DailyPick.dayNumber(widget.date) + _practice * 37);

  void _tap(Square square) {
    if (_puzzle.solved) return;
    setState(() {
      _tool == _Tool.crown
          ? _puzzle.toggleCrown(square)
          : _puzzle.toggleMark(square);
    });
    if (_puzzle.solved) {
      HapticFeedback.mediumImpact();
      if (_lastBoard) _finish();
    } else if (_tool == _Tool.crown) {
      HapticFeedback.selectionClick();
    }
  }

  void _hint() {
    setState(() {
      _puzzle.hint();
      _hints++;
    });
    if (_puzzle.solved && _lastBoard) _finish();
  }

  void _finish() {
    setState(() => _finished = true);
    if (_practice == 0) _alreadyDone = awardDaily(context, _game);
  }

  void _next() {
    setState(() {
      _current++;
      _puzzle = CrownsGame(_boards[_current]);
      _tool = _Tool.crown;
    });
  }

  void _practiceRound() {
    setState(() {
      _practice++;
      _boards = _newBoards();
      _current = 0;
      _puzzle = CrownsGame(_boards.first);
      _tool = _Tool.crown;
      _hints = 0;
      _finished = false;
    });
  }

  String get _share =>
      'Curio · Crowns\n${'👑' * _boards.length}  '
      '${_hints == 0 ? 'no hints' : '$_hints ${_hints == 1 ? 'hint' : 'hints'}'}';

  @override
  Widget build(BuildContext context) {
    final solved = _puzzle.solved;
    return CurioPage(
      title: 'Crowns',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice > 0 ? 'Practice kingdoms' : 'Daily logic puzzle',
            title: _finished
                ? 'Every kingdom crowned.'
                : 'Crown every kingdom.',
            subtitle:
                'One crown in each row, each column and each colour. Crowns '
                'can’t touch — not even at the corners.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–5 min',
              ),
              GameMetaChip(
                icon: Icons.grid_on_rounded,
                label:
                    'Board ${_current + 1} of ${_boards.length} · '
                    '${_puzzle.size}×${_puzzle.size}',
              ),
            ],
          ),
          if (_practice > 0) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 14),
          _RuleTracker(game: _puzzle),
          const SizedBox(height: 14),
          _Board(game: _puzzle, onTap: _tap),
          const SizedBox(height: 14),
          if (!solved) ...[
            Row(
              children: [
                Expanded(
                  child: _ToolButton(
                    key: const Key('crowns_tool_crown'),
                    label: 'Crown',
                    icon: const _CrownGlyph(size: 20),
                    selected: _tool == _Tool.crown,
                    onTap: () => setState(() => _tool = _Tool.crown),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolButton(
                    key: const Key('crowns_tool_mark'),
                    label: 'Mark',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    selected: _tool == _Tool.mark,
                    onTap: () => setState(() => _tool = _Tool.mark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('crowns_hint'),
                    onPressed: _hint,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: const Text('Hint'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('crowns_clear'),
                    onPressed: _puzzle.crowns.isEmpty && _puzzle.marks.isEmpty
                        ? null
                        : () => setState(_puzzle.clear),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
            if (_puzzle.conflicts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const GameNotice(
                message:
                    'Two crowns clash — they share a row, column or kingdom, '
                    'or they touch. The ringed ones need to move.',
                tone: GameNoticeTone.bad,
              ),
            ],
          ] else if (!_lastBoard) ...[
            const GameNotice(
              message: 'Kingdom crowned! The next board is a little bigger.',
              tone: GameNoticeTone.good,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              key: const Key('crowns_next'),
              label: 'Next board',
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            ),
          ] else
            GameResultCard(
              gameId: _game,
              title: _hints == 0 ? 'No hints needed!' : 'Kingdoms crowned!',
              score: '${_boards.length} / ${_boards.length}',
              shareText: _share,
              xp: _practice > 0 ? null : gameRewards[_game]!.xp,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
        ],
      ),
    );
  }
}

/// The three rules, each ticking over as it's satisfied.
class _RuleTracker extends StatelessWidget {
  const _RuleTracker({required this.game});
  final CrownsGame game;

  @override
  Widget build(BuildContext context) {
    final n = game.size;
    int count(int Function(Square) key) {
      final seen = <int, int>{};
      for (final c in game.crowns) {
        seen.update(key(c), (v) => v + 1, ifAbsent: () => 1);
      }
      return seen.values.where((v) => v == 1).length;
    }

    final rows = count((s) => s.$1);
    final columns = count((s) => s.$2);
    final kingdoms = count((s) => game.board.regionAt(s.$1, s.$2));
    return Row(
      children: [
        for (final (i, (label, done)) in [
          ('Rows', rows),
          ('Columns', columns),
          ('Kingdoms', kingdoms),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _RuleChip(label: label, done: done, of: n),
          ),
        ],
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label, required this.done, required this.of});
  final String label;
  final int done, of;

  @override
  Widget build(BuildContext context) {
    final complete = done == of;
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Semantics(
      label: '$label: $done of $of',
      excludeSemantics: true,
      child: CurioClay(
        radius: 16,
        color: complete ? forest.withValues(alpha: .18) : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Column(
          children: [
            Text(
              '$done/$of',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: complete ? forest : null,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kingdomNames = ['green', 'coral', 'gold', 'blue', 'purple', 'pink'];

Color _kingdomColor(BuildContext context, int kingdom) => switch (kingdom) {
  0 => curioColor(context, CurioColors.forest, CurioColorsLight.forest),
  1 => curioColor(context, CurioColors.coral, CurioColorsLight.coral),
  2 => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  3 => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  4 => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
  _ => curioColor(context, CurioColors.rose, CurioColorsLight.rose),
};

class _Board extends StatelessWidget {
  const _Board({required this.game, required this.onTap});
  final CrownsGame game;
  final ValueChanged<Square> onTap;

  @override
  Widget build(BuildContext context) {
    final n = game.size;
    final conflicts = game.conflicts;
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AspectRatio(
          aspectRatio: 1,
          child: GlassCard(
            radius: 26,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                for (var r = 0; r < n; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < n; c++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _square(
                                context,
                                (r, c),
                                conflicts,
                                danger,
                                ink,
                                muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _square(
    BuildContext context,
    Square square,
    Set<Square> conflicts,
    Color danger,
    Color ink,
    Color muted,
  ) {
    final kingdom = game.board.regionAt(square.$1, square.$2);
    final crown = game.crowns.contains(square);
    final mark = game.marks.contains(square);
    final blocked = game.blocked(square);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final state = crown
        ? 'crown'
        : mark
        ? 'marked'
        : blocked
        ? 'ruled out'
        : 'empty';
    return Semantics(
      button: true,
      label:
          'Row ${square.$1 + 1}, column ${square.$2 + 1}, '
          '${_kingdomNames[kingdom % _kingdomNames.length]} kingdom, $state',
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('crowns_${square.$1}_${square.$2}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(square),
        child: CurioClay(
          radius: 10,
          // Kingdoms keep their colour either way; squares a crown rules
          // out sink into the board and carry a small dot.
          pressed: blocked || mark,
          color: _kingdomColor(
            context,
            kingdom,
          ).withValues(alpha: dark ? .5 : .38),
          outline: conflicts.contains(square) ? danger : null,
          child: Center(
            child: crown
                ? FractionallySizedBox(
                    widthFactor: .62,
                    heightFactor: .62,
                    child: FittedBox(child: _CrownGlyph(size: 24, color: ink)),
                  )
                : mark
                ? FractionallySizedBox(
                    widthFactor: .5,
                    heightFactor: .5,
                    child: FittedBox(
                      child: Icon(Icons.close_rounded, color: muted),
                    ),
                  )
                : blocked
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: .7),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The tool in hand is pushed in, like a held-down key.
        child: CurioClay(
          radius: 18,
          pressed: selected,
          color: selected ? coral.withValues(alpha: .22) : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple three-point crown, since Material has no crown icon.
class _CrownGlyph extends StatelessWidget {
  const _CrownGlyph({this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _CrownPainter(color ?? IconTheme.of(context).color!),
    ),
  );
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(w * .1, h * .78)
        ..lineTo(w * .06, h * .28)
        ..lineTo(w * .32, h * .52)
        ..lineTo(w * .5, h * .16)
        ..lineTo(w * .68, h * .52)
        ..lineTo(w * .94, h * .28)
        ..lineTo(w * .9, h * .78)
        ..close(),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * .1,
        h * .82,
        w * .9,
        h * .94,
        Radius.circular(h * .04),
      ),
      paint,
    );
    for (final x in [.06, .5, .94]) {
      canvas.drawCircle(
        Offset(w * x, x == .5 ? h * .14 : h * .26),
        w * .07,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}
