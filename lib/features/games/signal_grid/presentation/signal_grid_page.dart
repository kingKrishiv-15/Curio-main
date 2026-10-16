import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/signal_grid.dart';

enum _Signal { spark, wave }

class SignalGridPage extends StatefulWidget {
  const SignalGridPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<SignalGridPage> createState() => _SignalGridPageState();
}

class _SignalGridPageState extends State<SignalGridPage> {
  late SignalPuzzle _puzzle = _newPuzzle();
  late List<_Signal?> _cells = _startingCells();
  int _practiceShift = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceShift > 0;
  Set<int> get _givens => _puzzle.givens;
  _Signal _solutionAt(int i) =>
      _puzzle.solution[i] ? _Signal.spark : _Signal.wave;

  SignalPuzzle _newPuzzle() => SignalPuzzle.forDay(
    DailyPick.dayNumber(widget.date) + _practiceShift * 1000,
  );

  List<_Signal?> _startingCells() => List<_Signal?>.generate(
    16,
    (index) => _givens.contains(index) ? _solutionAt(index) : null,
  );

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _puzzle = _newPuzzle();
      _cells = _startingCells();
      _errors = <int>{};
      _hintsLeft = 3;
      _complete = false;
      _message = 'Practice grid ready. Balance every row and column.';
    });
  }

  Set<int> _errors = <int>{};
  int _hintsLeft = 3;
  String _message = 'Tap an empty cell to cycle between spark and wave.';
  bool _complete = false;

  void _cycle(int index) {
    if (_givens.contains(index) || _complete) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errors.remove(index);
      _message = 'Keep balancing every row and column.';
      _cells[index] = switch (_cells[index]) {
        null => _Signal.spark,
        _Signal.spark => _Signal.wave,
        _Signal.wave => null,
      };
    });
  }

  void _check() {
    final empty = _cells.where((cell) => cell == null).length;
    if (empty > 0) {
      setState(
        () => _message =
            '$empty ${empty == 1 ? 'cell is' : 'cells are'} still waiting for a signal.',
      );
      return;
    }
    // Any board that follows the rules is right — not just the stored one.
    final errors = SignalPuzzle.violations([
      for (final cell in _cells) cell == _Signal.spark,
    ])..removeAll(_givens);
    if (errors.isNotEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errors = errors;
        _message =
            'Some rows or columns break the balance. Recheck the highlighted ones.';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _complete = true;
      _errors.clear();
      _message = 'Every signal is in perfect balance.';
    });
    if (!_practice) _alreadyDone = awardDaily(context, 'signal_grid');
  }

  void _hint() {
    if (_hintsLeft == 0 || _complete) return;
    final index = List.generate(16, (index) => index).firstWhere(
      (index) => !_givens.contains(index) && _cells[index] != _solutionAt(index),
      orElse: () => -1,
    );
    if (index < 0) return;
    setState(() {
      _cells[index] = _solutionAt(index);
      _errors.remove(index);
      _hintsLeft--;
      _message =
          'Hint placed at row ${index ~/ 4 + 1}, column ${index % 4 + 1}.';
    });
  }

  void _showRules() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Signal Grid works',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const _Rule(
                icon: Icons.balance_rounded,
                text: 'Each row and column needs two sparks and two waves.',
              ),
              const _Rule(
                icon: Icons.filter_2_rounded,
                text: 'No row or column can be identical to another.',
              ),
              const _Rule(
                icon: Icons.touch_app_rounded,
                text: 'Tap a cell to cycle spark, wave, then empty.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled = _cells.whereType<_Signal>().length;
    return CurioPage(
      title: 'Signal Grid',
      actions: [
        IconButton(
          tooltip: 'How to play',
          onPressed: _showRules,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          if (_practice) ...[
            const Align(alignment: Alignment.centerLeft, child: PracticeBadge()),
            const SizedBox(height: 10),
          ],
          CurioEyebrow(
            _practice ? 'Practice logic puzzle' : 'Daily logic puzzle',
            color: curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark),
          ),
          const SizedBox(height: 6),
          Text(
            _complete ? 'Grid harmonised.' : 'Balance the signals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            'Place two sparks and two waves in every row and column. No two lines may match.',
            style: TextStyle(
              color: curioColor(context, CurioColors.navyMuted, CurioColorsLight.navyMuted),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Wrap(
                  spacing: 15,
                  runSpacing: 6,
                  children: [
                    GameMetaChip(icon: Icons.schedule_rounded, label: '4–6 min'),
                    GameMetaChip(
                      icon: Icons.grid_view_rounded,
                      label: 'Reasoning',
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _hintsLeft > 0 && !_complete ? _hint : null,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: Text('Hint $_hintsLeft'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    // Light mode's `navy` is bright coral, which fights the
                    // green clue tiles; a calm sunken tone frames them instead.
                    color: curioColor(
                      context,
                      CurioColors.navy,
                      CurioColorsLight.surfaceMuted,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        // Dark mode: translucent near-black-green overlay.
                        // Light mode counterpart: translucent dark ink tone
                        // at the same alpha (0x30).
                        color: curioColor(
                          context,
                          const Color(0x30102C26),
                          const Color(0x302E2417),
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final signal = _cells[index];
                      final given = _givens.contains(index);
                      final error = _errors.contains(index);
                      return Semantics(
                        button: !given,
                        label:
                            'Row ${index ~/ 4 + 1}, column ${index % 4 + 1}, ${signal?.name ?? 'empty'}${given ? ', fixed' : ''}',
                        child: Material(
                          key: Key('signal_$index'),
                          color: error
                              ? curioColor(context, CurioColors.orangeSoft, CurioColorsLight.orangeSoft)
                              : given
                              ? curioColor(context, CurioColors.forestStrong, CurioColorsLight.forestStrong)
                              : curioColor(context, CurioColors.surface, CurioColorsLight.surface),
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            onTap: given ? null : () => _cycle(index),
                            borderRadius: BorderRadius.circular(15),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: signal == null
                                  ? Icon(
                                      Icons.add_rounded,
                                      key: ValueKey('empty_$index'),
                                      color: curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted),
                                      size: 22,
                                    )
                                  : Icon(
                                      signal == _Signal.spark
                                          ? Icons.auto_awesome_rounded
                                          : Icons.waves_rounded,
                                      key: ValueKey('${signal.name}_$index'),
                                      color: signal == _Signal.spark
                                          ? curioColor(context, CurioColors.gold, CurioColorsLight.gold)
                                          : given
                                          ? curioColor(context, CurioColors.saffron, CurioColorsLight.saffron)
                                          : curioColor(context, CurioColors.teal, CurioColorsLight.teal),
                                      size: 31,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _complete
                  ? curioColor(context, CurioColors.greenSoft, CurioColorsLight.greenSoft)
                  : curioColor(context, CurioColors.surface, CurioColorsLight.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _complete
                    ? curioColor(context, CurioColors.green, CurioColorsLight.green).withValues(alpha: .3)
                    : curioColor(context, CurioColors.creamDeep, CurioColorsLight.creamDeep),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _complete
                      ? Icons.check_circle_rounded
                      : Icons.tips_and_updates_outlined,
                  color: _complete
                      ? curioColor(context, CurioColors.green, CurioColorsLight.green)
                      : curioColor(context, CurioColors.coral, CurioColorsLight.coral),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_message)),
                Text(
                  '$filled/16',
                  style: TextStyle(
                    color: curioColor(context, CurioColors.navyMuted, CurioColorsLight.navyMuted),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          if (!_complete)
            PrimaryButton(
              label: 'Check my grid',
              icon: Icons.task_alt_rounded,
              onPressed: _check,
              color: curioColor(context, CurioColors.teal, CurioColorsLight.teal),
            )
          else
            GameResultCard(
              gameId: 'signal_grid',
              title: _hintsLeft == 3 ? 'Pure deduction!' : 'Balanced!',
              score: _hintsLeft == 3
                  ? 'No hints'
                  : '${3 - _hintsLeft} hint${3 - _hintsLeft == 1 ? '' : 's'}',
              shareText:
                  'Curio · Signal Grid\n🟨🟦🟨🟦\nBalanced with ${3 - _hintsLeft} hints',
              xp: _practice ? null : gameRewards['signal_grid']!.xp,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: curioColor(context, CurioColors.tealSoft, CurioColorsLight.tealSoft),
            foregroundColor: curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
