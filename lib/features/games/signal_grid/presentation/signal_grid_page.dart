import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/curio_state.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/widgets/curio_ui.dart';

enum _Signal { spark, wave }

class SignalGridPage extends StatefulWidget {
  const SignalGridPage({super.key});

  @override
  State<SignalGridPage> createState() => _SignalGridPageState();
}

class _SignalGridPageState extends State<SignalGridPage> {
  static const _solution = <_Signal>[
    _Signal.spark,
    _Signal.wave,
    _Signal.spark,
    _Signal.wave,
    _Signal.spark,
    _Signal.wave,
    _Signal.wave,
    _Signal.spark,
    _Signal.wave,
    _Signal.spark,
    _Signal.spark,
    _Signal.wave,
    _Signal.wave,
    _Signal.spark,
    _Signal.wave,
    _Signal.spark,
  ];
  static const _givens = <int>{0, 3, 5, 10, 12, 15};

  late final List<_Signal?> _cells = List<_Signal?>.generate(
    16,
    (index) => _givens.contains(index) ? _solution[index] : null,
  );
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
      setState(() => _message = '$empty cells are still waiting for a signal.');
      return;
    }
    final errors = <int>{};
    for (var index = 0; index < _cells.length; index++) {
      if (_cells[index] != _solution[index]) errors.add(index);
    }
    if (errors.isNotEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errors = errors;
        _message =
            '${errors.length} signals break the balance. Recheck the highlighted cells.';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _complete = true;
      _errors.clear();
      _message = 'Every signal is in perfect balance.';
    });
    CurioScope.of(context).completeActivity(
      id: CurioState.dailyActivityId('signal_grid'),
      xp: 100,
      skill: 'Reasoning',
      factId: 'binary_patterns',
    );
  }

  void _hint() {
    if (_hintsLeft == 0 || _complete) return;
    final index = List.generate(16, (index) => index).firstWhere(
      (index) => !_givens.contains(index) && _cells[index] != _solution[index],
      orElse: () => -1,
    );
    if (index < 0) return;
    setState(() {
      _cells[index] = _solution[index];
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
          const CurioEyebrow('Daily logic puzzle', color: CurioColors.tealDark),
          const SizedBox(height: 6),
          Text(
            _complete ? 'Grid harmonised.' : 'Balance the signals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          const Text(
            'Place two sparks and two waves in every row and column. No two lines may match.',
            style: TextStyle(color: CurioColors.navyMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '4–6 min',
              ),
              const SizedBox(width: 15),
              const GameMetaChip(icon: Icons.grid_view_rounded, label: 'Logic'),
              const Spacer(),
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
                    color: CurioColors.navy,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30102C26),
                        blurRadius: 30,
                        offset: Offset(0, 14),
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
                              ? CurioColors.orangeSoft
                              : given
                              ? CurioColors.forestStrong
                              : CurioColors.surface,
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
                                      color: CurioColors.forestSoft,
                                      size: 22,
                                    )
                                  : Icon(
                                      signal == _Signal.spark
                                          ? Icons.auto_awesome_rounded
                                          : Icons.waves_rounded,
                                      key: ValueKey('${signal.name}_$index'),
                                      color: signal == _Signal.spark
                                          ? CurioColors.gold
                                          : given
                                          ? CurioColors.saffron
                                          : CurioColors.teal,
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
              color: _complete ? CurioColors.greenSoft : CurioColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _complete
                    ? CurioColors.green.withValues(alpha: .3)
                    : CurioColors.creamDeep,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _complete
                      ? Icons.check_circle_rounded
                      : Icons.tips_and_updates_outlined,
                  color: _complete ? CurioColors.green : CurioColors.coral,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_message)),
                Text(
                  '$filled/16',
                  style: const TextStyle(
                    color: CurioColors.navyMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          PrimaryButton(
            label: _complete ? '+100 XP earned' : 'Check my grid',
            icon: _complete
                ? Icons.emoji_events_rounded
                : Icons.task_alt_rounded,
            onPressed: _complete ? null : _check,
            color: CurioColors.teal,
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
            backgroundColor: CurioColors.tealSoft,
            foregroundColor: CurioColors.tealDark,
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
