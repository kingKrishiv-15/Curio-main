import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/whos_who.dart';

/// Who's Who: two small logic-grid puzzles a day — three children, then four
/// — each worked out from a handful of true clues.
class WhosWhoPage extends StatefulWidget {
  const WhosWhoPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<WhosWhoPage> createState() => _WhosWhoPageState();
}

class _WhosWhoPageState extends State<WhosWhoPage> {
  static const _game = 'whos_who';
  static const _rules = [
    'Every child has exactly one of each thing, and no two children share.',
    'Read the clues — every one is true — then tap a cell in the table to choose.',
    'Tap a clue to cross it off once you’ve used it.',
    'Check answers says how many are right and marks wrong cells with ✕, without giving the answers away.',
    'Each puzzle is worth 100 points. A hint fills in one cell for 25; a wrong check costs 15.',
  ];
  static const _intro =
      'Tap a cell to choose. Tap a clue to cross it off once you’ve used it.';
  static const _numberWords = {3: 'Three', 4: 'Four', 5: 'Five'};

  final _scroll = ScrollController();
  late List<WhoRound> _rounds = _newRounds();
  int _current = 0;
  int _practiceShift = 0;
  bool _alreadyDone = false;
  bool _awarded = false;
  String? _message = _intro;
  GameNoticeTone _tone = GameNoticeTone.info;

  bool get _practice => _practiceShift > 0;
  WhoRound get _round => _rounds[_current];
  bool get _allSolved => _rounds.every((r) => r.solved);
  int get _total =>
      _rounds.fold(0, (sum, r) => sum + (r.solved ? r.points : 0));
  int get _maxTotal => _rounds.length * WhoRound.startPoints;

  /// Today's pair, or a practice pair from a different seed.
  List<WhoRound> _newRounds() {
    final day = DailyPick.dayNumber(widget.date);
    final seed = _practice ? day * 1000 + _practiceShift : day;
    return [for (final puzzle in WhoPuzzle.dailySet(seed)) WhoRound(puzzle)];
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pick(WhoCell cell) async {
    final round = _round;
    if (round.solved || round.hinted.contains(cell)) return;
    final choice = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PickerSheet(round: round, cell: cell),
    );
    if (choice == null || !mounted || !identical(round, _round)) return;
    if (round.choose(cell, choice < 0 ? null : choice)) {
      HapticFeedback.selectionClick();
      setState(() => _message = null);
    }
  }

  void _toggleClue(int index) => setState(() => _round.toggleClue(index));

  void _celebrate(WhoRound round, String lead) {
    HapticFeedback.mediumImpact();
    _message = '$lead +${round.points} points.';
    _tone = GameNoticeTone.good;
  }

  void _check() {
    final round = _round;
    if (round.solved) return;
    final result = round.check();
    setState(() {
      if (result.solved) {
        _celebrate(
          round,
          round.points == WhoRound.startPoints
              ? 'Spot on — no help needed!'
              : 'Solved!',
        );
      } else if (result.empty > 0) {
        _message = result.empty == 1
            ? 'One cell still needs a choice.'
            : '${result.empty} cells still need a choice.';
        _tone = GameNoticeTone.info;
      } else {
        HapticFeedback.heavyImpact();
        _message =
            '${result.right} of ${result.total} right. Have another look at the cells marked ✕.';
        _tone = result.right * 2 >= result.total
            ? GameNoticeTone.close
            : GameNoticeTone.bad;
      }
    });
    _finishIfDone();
  }

  void _hint() {
    final round = _round;
    if (round.solved) return;
    final cell = round.hint();
    setState(() {
      if (round.solved) {
        _celebrate(
          round,
          cell == null
              ? 'Every cell was already right!'
              : 'That hint finished it!',
        );
      } else if (cell != null) {
        final puzzle = round.puzzle;
        final fact = puzzle.categories[cell.category].statement(
          puzzle.names[cell.child],
          puzzle.answer(cell.child, cell.category),
          positive: true,
        );
        _message = 'Hint: $fact';
        _tone = GameNoticeTone.info;
      }
    });
    _finishIfDone();
  }

  /// Records today's daily once, when its last puzzle is solved.
  void _finishIfDone() {
    if (!_allSolved || _practice || _awarded) return;
    _awarded = true;
    _alreadyDone = awardDaily(context, _game);
  }

  void _next() {
    _toTop();
    setState(() {
      _current++;
      final size = _round.puzzle.size;
      _message =
          '${_numberWords[size] ?? '$size'} children this time — you’ve got this!';
      _tone = GameNoticeTone.info;
    });
  }

  void _practiceRound() {
    _toTop();
    setState(() {
      _practiceShift++;
      _rounds = _newRounds();
      _current = 0;
      _message = 'A fresh pair to practise on — just for fun, no XP.';
      _tone = GameNoticeTone.info;
    });
  }

  String get _share {
    final marks = _rounds
        .map((r) => r.points == WhoRound.startPoints ? '🟩' : '🟨')
        .join();
    return 'Curio · Who’s Who\n$marks  $_total/$_maxTotal';
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final last = _current == _rounds.length - 1;
    final showResult = _allSolved && last;
    return CurioPage(
      title: 'Who’s Who',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice round' : 'Daily logic puzzle',
            title: showResult ? 'Everyone sorted!' : 'Who has what?',
            subtitle:
                'Read the clues, then fill in the table. Every clue is true!',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '4–6 min'),
              GameMetaChip(icon: Icons.psychology_rounded, label: 'Reasoning'),
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
          _ClueCard(
            round: round,
            number: _current + 1,
            total: _rounds.length,
            onToggle: _toggleClue,
          ),
          const SizedBox(height: 14),
          _AnswerTable(round: round, onPick: _pick),
          const SizedBox(height: 14),
          if (_message != null) ...[
            GameNotice(message: _message!, tone: _tone),
            const SizedBox(height: 14),
          ],
          if (!round.solved) ...[
            PrimaryButton(
              key: const Key('whos_who_check'),
              label: 'Check answers',
              icon: Icons.task_alt_rounded,
              onPressed: _check,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('whos_who_hint'),
              onPressed: _hint,
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
              label: const Text(
                'Hint: fill in one cell (−${WhoRound.hintCost})',
              ),
            ),
          ] else if (!last)
            PrimaryButton(
              key: const Key('whos_who_next'),
              label: 'Next puzzle',
              icon: Icons.arrow_forward_rounded,
              onPressed: _next,
            )
          else
            GameResultCard(
              title: _total == _maxTotal ? 'Logic legend!' : 'Nicely reasoned.',
              score: '$_total / $_maxTotal',
              shareText: _share,
              xp: _practice ? null : gameRewards[_game]!.xp,
              alreadyDone: _alreadyDone,
              gameId: _game,
              onPractice: _practiceRound,
            ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(WhoCategory category) => switch (category) {
  WhoCategory.pet => Icons.pets_rounded,
  WhoCategory.colour => Icons.palette_rounded,
  WhoCategory.snack => Icons.cookie_rounded,
  WhoCategory.hobby => Icons.interests_rounded,
};

/// Each child's initial gets its own bright colour (with dark ink on top).
Color _childColour(BuildContext context, int index) => switch (index % 4) {
  0 => curioColor(context, CurioColors.coral, CurioColorsLight.coral),
  1 => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  2 => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  _ => curioColor(context, CurioColors.forest, CurioColorsLight.forest),
};

String _capitalised(String item) =>
    item.isEmpty ? item : item[0].toUpperCase() + item.substring(1);

class _ClueCard extends StatelessWidget {
  const _ClueCard({
    required this.round,
    required this.number,
    required this.total,
    required this.onToggle,
  });

  final WhoRound round;
  final int number, total;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final texts = round.puzzle.clueTexts;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PUZZLE $number OF $total · CLUES',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    round.solved ? '+${round.points}' : 'Worth ${round.points}',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: coral, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < texts.length; i++)
            _ClueRow(
              index: i,
              text: texts[i],
              used: round.usedClues.contains(i),
              onTap: () => onToggle(i),
            ),
        ],
      ),
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.index,
    required this.text,
    required this.used,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final plum = curioColor(context, CurioColors.plum, CurioColorsLight.plum);
    return Semantics(
      button: true,
      label: 'Clue ${index + 1}: $text${used ? ' Crossed off.' : ''}',
      hint: used ? 'Tap to bring it back' : 'Tap to cross it off',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        key: Key('whos_who_clue_$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: used
                      ? curioColor(
                          context,
                          CurioColors.surfaceMuted,
                          CurioColorsLight.surfaceMuted,
                        )
                      : curioColor(
                          context,
                          CurioColors.plumSoft,
                          CurioColorsLight.plumSoft,
                        ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: used
                        ? Colors.transparent
                        : plum.withValues(alpha: .7),
                  ),
                ),
                child: used
                    ? Icon(Icons.check_rounded, size: 16, color: muted)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: used ? muted : ink,
                      decoration: used ? TextDecoration.lineThrough : null,
                      decorationColor: muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row per child, one column per category. On narrow screens or with
/// large text each child gets a small block instead, so nothing is squeezed.
class _AnswerTable extends StatelessWidget {
  const _AnswerTable({required this.round, required this.onPick});

  final WhoRound round;
  final ValueChanged<WhoCell> onPick;

  @override
  Widget build(BuildContext context) {
    final puzzle = round.puzzle;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your answers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final width = constraints.maxWidth / scale;
              if (width >= 300) return _table();
              return Column(
                children: [
                  for (var child = 0; child < puzzle.size; child++)
                    _ChildBlock(
                      round: round,
                      child: child,
                      sideBySide: width >= 200,
                      last: child == puzzle.size - 1,
                      onPick: onPick,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _table() {
    final puzzle = round.puzzle;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth()},
      defaultColumnWidth: const FlexColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            for (final category in puzzle.categories)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                child: _CategoryHeading(category),
              ),
          ],
        ),
        for (var child = 0; child < puzzle.size; child++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ChildLabel(name: puzzle.names[child], index: child),
              ),
              for (var c = 0; c < puzzle.categories.length; c++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: _AnswerCell(
                    round: round,
                    cell: (child: child, category: c),
                    onTap: onPick,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ChildBlock extends StatelessWidget {
  const _ChildBlock({
    required this.round,
    required this.child,
    required this.sideBySide,
    required this.last,
    required this.onPick,
  });

  final WhoRound round;
  final int child;
  final bool sideBySide, last;
  final ValueChanged<WhoCell> onPick;

  @override
  Widget build(BuildContext context) {
    final puzzle = round.puzzle;
    final cells = [
      for (var c = 0; c < puzzle.categories.length; c++)
        _AnswerCell(
          round: round,
          cell: (child: child, category: c),
          onTap: onPick,
          caption: true,
        ),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChildLabel(name: puzzle.names[child], index: child),
          const SizedBox(height: 8),
          if (sideBySide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cells.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: cells[i]),
                  ],
                ],
              ),
            )
          else
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              cells[i],
            ],
        ],
      ),
    );
  }
}

class _ChildLabel extends StatelessWidget {
  const _ChildLabel({required this.name, required this.index});

  final String name;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _childColour(context, index),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              name[0],
              style: TextStyle(
                // A bright accent takes dark ink (design §7).
                color: curioColor(
                  context,
                  CurioColors.night,
                  CurioColorsLight.ink,
                ),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading(this.category);

  final WhoCategory category;

  @override
  Widget build(BuildContext context) {
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Row(
      children: [
        Icon(_categoryIcon(category), size: 16, color: soft),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            category.label,
            style: TextStyle(
              color: soft,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// A table cell: a real button showing the choice (or "Choose…"), with its
/// state spelled out by an icon as well as colour.
class _AnswerCell extends StatelessWidget {
  const _AnswerCell({
    required this.round,
    required this.cell,
    required this.onTap,
    this.caption = false,
  });

  final WhoRound round;
  final WhoCell cell;
  final ValueChanged<WhoCell> onTap;

  /// Shows the category name inside the cell, for layouts without headings.
  final bool caption;

  @override
  Widget build(BuildContext context) {
    final puzzle = round.puzzle;
    final category = puzzle.categories[cell.category];
    final pick = round.pickAt(cell);
    final value = pick == null ? null : puzzle.items[cell.category][pick];
    final wrong = round.wrong.contains(cell);
    final hinted = round.hinted.contains(cell);
    final solved = round.solved;
    final locked = solved || hinted;

    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final (fill, border, icon, iconColor) = switch (null) {
      _ when wrong => (
        curioColor(
          context,
          CurioColors.dangerSoft,
          CurioColorsLight.dangerSoft,
        ),
        curioColor(context, CurioColors.danger, CurioColorsLight.danger),
        Icons.close_rounded,
        curioColor(context, CurioColors.danger, CurioColorsLight.danger),
      ),
      _ when hinted => (
        curioColor(
          context,
          CurioColors.saffronSoft,
          CurioColorsLight.saffronSoft,
        ),
        curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
        Icons.lightbulb_rounded,
        curioColor(
          context,
          CurioColors.saffronStrong,
          CurioColorsLight.saffronStrong,
        ),
      ),
      _ when solved => (
        curioColor(
          context,
          CurioColors.successSoft,
          CurioColorsLight.successSoft,
        ),
        curioColor(context, CurioColors.success, CurioColorsLight.success),
        Icons.check_rounded,
        curioColor(context, CurioColors.success, CurioColorsLight.success),
      ),
      _ when value == null => (
        curioColor(
          context,
          CurioColors.surfaceMuted,
          CurioColorsLight.surfaceMuted,
        ),
        outline,
        Icons.expand_more_rounded,
        soft,
      ),
      _ => (
        curioColor(context, CurioColors.surface, CurioColorsLight.surface),
        outline,
        Icons.expand_more_rounded,
        soft,
      ),
    };
    final status = [
      if (wrong) 'marked wrong',
      if (hinted) 'from a hint',
      if (solved && !hinted) 'correct',
    ];
    final label =
        '${puzzle.names[cell.child]}’s ${category.noun}: ${value ?? 'not chosen'}'
        '${status.isEmpty ? '' : ', ${status.join(', ')}'}';
    final key = '${cell.child}_${cell.category}';

    return Semantics(
      button: true,
      enabled: !locked,
      label: label,
      onTap: locked ? null : () => onTap(cell),
      excludeSemantics: true,
      child: Material(
        color: fill,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: wrong ? 2 : 1.3),
        ),
        child: InkWell(
          key: Key('whos_who_cell_$key'),
          onTap: locked ? null : () => onTap(cell),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caption)
                          Text(
                            category.label.toUpperCase(),
                            style: TextStyle(
                              color: soft,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                        Text(
                          value == null ? 'Choose…' : _capitalised(value),
                          style: TextStyle(
                            color: value == null ? soft : ink,
                            fontSize: 14.5,
                            fontWeight: value == null
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    icon,
                    key: wrong ? Key('whos_who_wrong_$key') : null,
                    size: 20,
                    color: iconColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picker for one cell. Pops the chosen item's index, or -1 to clear.
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.round, required this.cell});

  final WhoRound round;
  final WhoCell cell;

  @override
  Widget build(BuildContext context) {
    final puzzle = round.puzzle;
    final category = puzzle.categories[cell.category];
    final items = puzzle.items[cell.category];
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${puzzle.names[cell.child]}’s ${category.noun}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Already chosen for someone else? Picking it moves it here.',
              style: TextStyle(color: soft, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < items.length; i++) ...[
              _OptionRow(round: round, cell: cell, item: i),
              const SizedBox(height: 8),
            ],
            if (round.pickAt(cell) != null)
              TextButton.icon(
                key: const Key('whos_who_clear'),
                onPressed: () => Navigator.of(context).pop(-1),
                icon: const Icon(Icons.backspace_outlined, size: 18),
                label: const Text('Clear this cell'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.round,
    required this.cell,
    required this.item,
  });

  final WhoRound round;
  final WhoCell cell;
  final int item;

  @override
  Widget build(BuildContext context) {
    final puzzle = round.puzzle;
    final name = puzzle.items[cell.category][item];
    final owner = round.ownerOf(cell.category, item);
    final mine = owner == cell.child;
    final otherOwner = owner != null && !mine ? puzzle.names[owner] : null;
    final allowed = mine || round.canChoose(cell, item);

    final plum = curioColor(context, CurioColors.plum, CurioColorsLight.plum);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final label = [
      name,
      if (mine) 'current choice',
      if (otherOwner != null) 'chosen for $otherOwner',
      if (!allowed) 'fixed by a hint',
    ].join(', ');
    void choose() => Navigator.of(context).pop(item);

    return Semantics(
      button: true,
      selected: mine,
      enabled: allowed,
      label: label,
      onTap: allowed ? choose : null,
      excludeSemantics: true,
      child: Material(
        color: mine
            ? curioColor(
                context,
                CurioColors.plumSoft,
                CurioColorsLight.plumSoft,
              )
            : curioColor(
                context,
                CurioColors.surfaceMuted,
                CurioColorsLight.surfaceMuted,
              ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: mine
                ? plum
                : curioColor(
                    context,
                    CurioColors.outline,
                    CurioColorsLight.outline,
                  ),
            width: mine ? 1.8 : 1.2,
          ),
        ),
        child: InkWell(
          key: Key('whos_who_option_$item'),
          onTap: allowed ? choose : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    mine
                        ? Icons.check_circle_rounded
                        : allowed
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.lightbulb_rounded,
                    color: mine ? plum : soft,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: _capitalised(name),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        children: [
                          if (otherOwner != null)
                            TextSpan(
                              text: '  ($otherOwner)',
                              style: TextStyle(
                                color: soft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One pip per puzzle: a tick when solved, a ring on the current one.
class _PuzzlePips extends StatelessWidget {
  const _PuzzlePips({required this.rounds, required this.current});

  final List<WhoRound> rounds;
  final int current;

  @override
  Widget build(BuildContext context) {
    final solved = rounds.where((r) => r.solved).length;
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    return Semantics(
      label: 'Puzzle ${current + 1} of ${rounds.length}, $solved solved',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rounds.length; i++)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rounds[i].solved
                    ? curioColor(
                        context,
                        CurioColors.success,
                        CurioColorsLight.success,
                      )
                    : i == current
                    ? curioColor(
                        context,
                        CurioColors.coralSoft,
                        CurioColorsLight.coralSoft,
                      )
                    : curioColor(
                        context,
                        CurioColors.outline,
                        CurioColorsLight.outline,
                      ),
                border: !rounds[i].solved && i == current
                    ? Border.all(color: coral, width: 2)
                    : null,
              ),
              child: rounds[i].solved
                  ? Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: curioColor(
                        context,
                        CurioColors.night,
                        CurioColorsLight.ink,
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
