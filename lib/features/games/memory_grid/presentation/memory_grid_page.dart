import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../../game_catalog.dart';
import '../../presentation/game_banner.dart';
import '../domain/memory_grid.dart';

class MemoryGridPage extends StatefulWidget {
  const MemoryGridPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<MemoryGridPage> createState() => _MemoryGridPageState();
}

enum _Phase { ready, watching, recall, feedback, done }

class _MemoryGridPageState extends State<MemoryGridPage> {
  static const _game = 'memory_grid';
  static const _rules = [
    'Some squares glow for a moment. Don’t tap yet — just watch.',
    'When they go dark, tap the same squares. Tap one again to take it back.',
    'The board checks itself when you’ve marked the right number of squares.',
    'Six rounds, each a little trickier. A wrong pattern costs a heart and shows you the answer.',
  ];

  int _practice = 0;
  late MemoryGrid _grid = MemoryGrid(_seed);
  _Phase _phase = _Phase.ready;
  GridResult? _result;
  Timer? _flash;
  bool _alreadyDone = false;

  int get _seed => DailyPick.dayNumber(widget.date) + _practice * 1000;

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  void _watch() {
    setState(() => _phase = _Phase.watching);
    _flash?.cancel();
    _flash = Timer(_grid.settings.flash, () {
      if (mounted) setState(() => _phase = _Phase.recall);
    });
  }

  void _tap(int square) {
    if (_phase != _Phase.recall) return;
    HapticFeedback.selectionClick();
    final result = _grid.toggle(square);
    setState(() {
      if (result == null) return;
      _result = result;
      _phase = _Phase.feedback;
    });
    if (result == GridResult.matched) {
      HapticFeedback.mediumImpact();
      if (_grid.round == gridRounds.length - 1) _continue();
    } else if (result == GridResult.missed) {
      HapticFeedback.heavyImpact();
      if (_grid.over) _finish();
    }
  }

  void _continue() {
    _grid.advance(matched: _result == GridResult.matched);
    if (_grid.over) {
      _finish();
    } else {
      _watch();
    }
  }

  void _finish() {
    setState(() => _phase = _Phase.done);
    if (_practice == 0) _alreadyDone = awardDaily(context, _game);
  }

  void _practiceRound() {
    _flash?.cancel();
    setState(() {
      _practice++;
      _grid = MemoryGrid(_seed);
      _phase = _Phase.ready;
      _result = null;
    });
  }

  String get _share =>
      'Curio · Memory Grid\n'
      '${'🟪' * _grid.cleared}${'⬜' * (gridRounds.length - _grid.cleared)}  '
      '${_grid.cleared}/${gridRounds.length}';

  @override
  Widget build(BuildContext context) {
    final accent = bannerFill(
      context,
      gameColor(_game, skillColor(context, 'Memory')),
    );
    final s = _grid.settings;
    final (message, tone) = switch (_phase) {
      _Phase.ready => (
        'Squares will glow for a moment. Watch, then tap where they were.',
        GameNoticeTone.info,
      ),
      _Phase.watching => (
        'Watch closely — remember every glowing square.',
        GameNoticeTone.info,
      ),
      _Phase.recall => (
        'Your turn: tap ${s.cells} squares. '
            '${s.cells - _grid.marked.length} to go.',
        GameNoticeTone.info,
      ),
      _Phase.feedback when _result == GridResult.matched => (
        'Perfect memory! The next pattern is a little trickier.',
        GameNoticeTone.good,
      ),
      _Phase.feedback => (
        'Not quite — green shows the squares that glowed.',
        GameNoticeTone.bad,
      ),
      _Phase.done when _grid.won => (
        'All ${gridRounds.length} patterns remembered!',
        GameNoticeTone.good,
      ),
      _Phase.done => (
        'Out of hearts — you remembered ${_grid.cleared} '
            '${_grid.cleared == 1 ? 'pattern' : 'patterns'}.',
        GameNoticeTone.close,
      ),
    };
    return CurioPage(
      title: 'Memory Grid',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice > 0
                ? 'Practice patterns'
                : 'Daily flash & recall',
            title: _phase == _Phase.done
                ? (_grid.won ? 'Sharp as ever.' : 'Great effort.')
                : 'Watch, then remember.',
            subtitle:
                'Squares glow, then vanish. Tap the same ones back. Each round '
                'adds a little more to remember.',
            chips: [
              const GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
              GameMetaChip(
                icon: Icons.flag_rounded,
                label: _grid.won
                    ? 'All rounds'
                    : 'Round ${_grid.round + 1} of ${gridRounds.length}',
              ),
            ],
            trailing: _Hearts(left: _grid.livesLeft),
          ),
          if (_practice > 0) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          _Board(grid: _grid, phase: _phase, accent: accent, onTap: _tap),
          const SizedBox(height: 14),
          GameNotice(message: message, tone: tone),
          const SizedBox(height: 14),
          if (_phase == _Phase.ready)
            PrimaryButton(
              key: const Key('grid_start'),
              label: 'Show me the pattern',
              icon: Icons.visibility_rounded,
              onPressed: _watch,
            )
          else if (_phase == _Phase.feedback)
            PrimaryButton(
              key: const Key('grid_next'),
              label: _result == GridResult.matched
                  ? 'Next round'
                  : 'Try a new pattern',
              icon: Icons.arrow_forward_rounded,
              onPressed: _continue,
            )
          else if (_phase == _Phase.done)
            GameResultCard(
              gameId: _game,
              title: _grid.won ? 'Every pattern!' : 'Patterns remembered',
              score: '${_grid.cleared} / ${gridRounds.length}',
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

class _Hearts extends StatelessWidget {
  const _Hearts({required this.left});
  final int left;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Semantics(
      label: '$left of ${MemoryGrid.lives} hearts left',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < MemoryGrid.lives; i++)
            Icon(
              i < left ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: i < left ? coral : muted,
            ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.grid,
    required this.phase,
    required this.accent,
    required this.onTap,
  });

  final MemoryGrid grid;
  final _Phase phase;
  final Color accent;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = grid.settings.size;
    final green = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.forest,
    );
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1,
          child: GlassCard(
            radius: 28,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var r = 0; r < n; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < n; c++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(n > 4 ? 4 : 5),
                              child: _square(context, r * n + c, green, danger),
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

  Widget _square(BuildContext context, int i, Color green, Color danger) {
    final inPattern = grid.pattern.contains(i);
    final marked = grid.marked.contains(i);
    final review = phase == _Phase.feedback || phase == _Phase.done;
    // Empty squares are dents waiting to be filled; glowing and marked ones
    // puff up out of the board.
    final (
      Color? color,
      bool raised,
      Color? ring,
      IconData? icon,
    ) = switch (phase) {
      _Phase.watching when inPattern => (
        accent,
        true,
        null,
        Icons.auto_awesome,
      ),
      _Phase.recall when marked => (
        accent.withValues(alpha: .7),
        true,
        null,
        null,
      ),
      _ when review && inPattern && marked => (
        green.withValues(alpha: .55),
        true,
        null,
        Icons.check_rounded,
      ),
      _ when review && inPattern => (
        green.withValues(alpha: .22),
        false,
        green,
        null,
      ),
      _ when review && marked => (
        danger.withValues(alpha: .35),
        true,
        null,
        Icons.close_rounded,
      ),
      _ => (null, false, null, null),
    };
    final state = icon == Icons.auto_awesome
        ? 'glowing'
        : icon == Icons.check_rounded
        ? 'remembered'
        : ring != null
        ? 'missed'
        : icon == Icons.close_rounded
        ? 'wrong'
        : marked
        ? 'marked'
        : 'empty';
    return Semantics(
      button: phase == _Phase.recall,
      label: 'Square ${i + 1}, $state',
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('grid_$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: AnimatedScale(
          scale: raised ? 1 : .94,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: CurioClay(
            radius: 16,
            pressed: !raised,
            color: color,
            outline: ring,
            child: icon == null
                ? const SizedBox.expand()
                : Center(child: Icon(icon, color: Colors.white, size: 26)),
          ),
        ),
      ),
    );
  }
}
