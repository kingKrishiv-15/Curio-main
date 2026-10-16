import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../domain/cascade.dart';

class CascadePage extends StatefulWidget {
  const CascadePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<CascadePage> createState() => _CascadePageState();
}

class _CascadePageState extends State<CascadePage> {
  static const _game = 'cascade';
  static const _rules = [
    'A claim sits at the top. Below it are twelve possible consequences.',
    'Build a chain of five where each step happens because of the one above: this, therefore this, therefore this.',
    'Some tiles are true but lead nowhere. Some sound obvious but evidence says otherwise.',
    'Long-press to drag steps into order, or use the arrows. Check your chain when all five are in place.',
  ];

  late CascadeGame _puzzle = _newGame();
  int _practiceShift = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceShift > 0;

  CascadeGame _newGame() {
    final day = DailyPick.dayNumber(widget.date) + _practiceShift;
    return CascadeGame(cascadeClaims[day % cascadeClaims.length], seed: day);
  }

  void _toggle(CascadeTile tile) {
    HapticFeedback.selectionClick();
    setState(() => _puzzle.toggle(tile));
  }

  void _submit() {
    setState(_puzzle.submit);
    HapticFeedback.mediumImpact();
    if (_practice) return;
    _alreadyDone = awardDaily(context, _game);
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _puzzle = _newGame();
    });
  }

  String get _share {
    final marks = (_puzzle.verdicts ?? const <SlotVerdict>[])
        .map(
          (v) => switch (v) {
            SlotVerdict.exact => '🟩',
            SlotVerdict.misplaced => '🟨',
            SlotVerdict.sideEffect => '🟦',
            SlotVerdict.myth => '🟥',
          },
        )
        .join('⬇️');
    return 'Curio · Cascade\n$marks\n${_puzzle.score}/100';
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _puzzle.submitted;
    return CurioPage(
      title: 'Cascade',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice chain' : 'Daily cause-and-effect',
            title: submitted ? 'See where it held.' : 'Follow the chain',
            subtitle:
                'Pick five consequences that each lead to the next. Evidence beats what merely sounds right.',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '4 min'),
              GameMetaChip(icon: Icons.manage_search_rounded, label: 'Evidence'),
            ],
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: PracticeBadge()),
          ],
          const SizedBox(height: 16),
          _ClaimCard(claim: _puzzle.claim.claim),
          const SizedBox(height: 6),
          const _Therefore(),
          _Chain(
            puzzle: _puzzle,
            onMove: (from, to) => setState(() => _puzzle.move(from, to)),
            onRemove: _toggle,
          ),
          const SizedBox(height: 16),
          if (!submitted) ...[
            SectionHeading(
              'Possible consequences',
              subtitle: '${_puzzle.picked.length} of ${CascadeGame.chainLength} chosen',
            ),
            const SizedBox(height: 10),
            for (final tile in _puzzle.pool)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PoolTile(
                  tile: tile,
                  chosen: _puzzle.picked.contains(tile),
                  enabled: _puzzle.picked.contains(tile) || !_puzzle.full,
                  onTap: () => _toggle(tile),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('cascade_submit'),
              onPressed: _puzzle.full ? _submit : null,
              child: Text(
                _puzzle.full
                    ? 'Check my chain'
                    : 'Choose ${CascadeGame.chainLength - _puzzle.picked.length} more',
              ),
            ),
          ] else ...[
            const SectionHeading('The real chain'),
            const SizedBox(height: 10),
            for (var i = 0; i < _puzzle.claim.chain.length; i++)
              _ExplainTile(
                index: i + 1,
                tile: _puzzle.claim.chain[i],
              ),
            const SizedBox(height: 12),
            const SectionHeading(
              'Sounded right, but…',
              subtitle: 'The evidence behind the tempting tiles',
            ),
            const SizedBox(height: 10),
            for (final tile in _puzzle.claim.extras.where(
              (t) => t.kind == CascadeKind.myth,
            ))
              _ExplainTile(tile: tile),
            const SizedBox(height: 14),
            GameResultCard(
              gameId: 'cascade',
              title: _puzzle.score == 100
                  ? 'Unbreakable chain!'
                  : _puzzle.score >= 60
                  ? 'Strong reasoning.'
                  : 'Every broken link teaches something.',
              score: '${_puzzle.score} / 100',
              shareText: _share,
              xp: _practice ? null : 90,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});
  final String claim;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: dark ? CurioColors.heroGradient : CurioColorsLight.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE CLAIM',
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            claim,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}

class _Therefore extends StatelessWidget {
  const _Therefore();

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_downward_rounded, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              'therefore',
              style: TextStyle(color: muted, fontSize: 11.5, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chain extends StatelessWidget {
  const _Chain({required this.puzzle, required this.onMove, required this.onRemove});

  final CascadeGame puzzle;
  final void Function(int from, int to) onMove;
  final ValueChanged<CascadeTile> onRemove;

  @override
  Widget build(BuildContext context) {
    final verdicts = puzzle.verdicts;
    final empty = CascadeGame.chainLength - puzzle.picked.length;
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !puzzle.submitted,
          itemCount: puzzle.picked.length,
          onReorderItem: onMove,
          itemBuilder: (context, i) => Padding(
            key: ValueKey(puzzle.picked[i].text),
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              children: [
                _ChainSlot(
                  index: i,
                  tile: puzzle.picked[i],
                  verdict: verdicts?[i],
                  canMoveUp: !puzzle.submitted && i > 0,
                  canMoveDown: !puzzle.submitted && i < puzzle.picked.length - 1,
                  onUp: () => onMove(i, i - 1),
                  onDown: () => onMove(i, i + 1),
                  onRemove: puzzle.submitted ? null : () => onRemove(puzzle.picked[i]),
                ),
                if (i < CascadeGame.chainLength - 1) const _Therefore(),
              ],
            ),
          ),
        ),
        for (var i = 0; i < empty; i++) ...[
          _EmptySlot(index: puzzle.picked.length + i),
          if (puzzle.picked.length + i < CascadeGame.chainLength - 1) const _Therefore(),
        ],
      ],
    );
  }
}

Color _verdictColor(BuildContext context, SlotVerdict? verdict) => switch (verdict) {
  SlotVerdict.exact => curioColor(context, CurioColors.success, CurioColorsLight.success),
  SlotVerdict.misplaced => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  SlotVerdict.sideEffect => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  SlotVerdict.myth => curioColor(context, CurioColors.danger, CurioColorsLight.danger),
  null => curioColor(context, CurioColors.coral, CurioColorsLight.coral),
};

class _ChainSlot extends StatelessWidget {
  const _ChainSlot({
    required this.index,
    required this.tile,
    required this.verdict,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int index;
  final CascadeTile tile;
  final SlotVerdict? verdict;
  final bool canMoveUp, canMoveDown;
  final VoidCallback onUp, onDown;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(context, verdict);
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    final verdictText = switch (verdict) {
      SlotVerdict.exact => 'Right link, right place.',
      SlotVerdict.misplaced => 'A real link — but it belongs at step ${_stepOf(tile)}.',
      SlotVerdict.sideEffect => tile.note,
      SlotVerdict.myth => tile.note,
      null => null,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .6), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: curioColor(context, CurioColors.night, CurioColorsLight.ink),
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tile.text, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
                if (verdictText != null) ...[
                  const SizedBox(height: 4),
                  Text(verdictText, style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
                ],
              ],
            ),
          ),
          if (onRemove != null) ...[
            IconButton(
              tooltip: 'Move up',
              visualDensity: VisualDensity.compact,
              onPressed: canMoveUp ? onUp : null,
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Move down',
              visualDensity: VisualDensity.compact,
              onPressed: canMoveDown ? onDown : null,
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  int _stepOf(CascadeTile tile) {
    for (final claim in cascadeClaims) {
      final i = claim.chain.indexOf(tile);
      if (i >= 0) return i + 1;
    }
    return 0;
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final outline = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    final muted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 1.2),
      ),
      child: Text(
        'Step ${index + 1} — tap a consequence below',
        style: TextStyle(color: muted, fontSize: 13),
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  const _PoolTile({
    required this.tile,
    required this.chosen,
    required this.enabled,
    required this.onTap,
  });

  final CascadeTile tile;
  final bool chosen, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final outline = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    return Semantics(
      button: true,
      selected: chosen,
      child: Opacity(
        opacity: enabled ? 1 : .45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: chosen ? coral.withValues(alpha: .12) : surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: chosen ? coral : outline, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(
                    chosen ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    size: 20,
                    color: chosen ? coral : outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tile.text, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplainTile extends StatelessWidget {
  const _ExplainTile({required this.tile, this.index});
  final CascadeTile tile;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final link = tile.kind == CascadeKind.link;
    final color = link
        ? curioColor(context, CurioColors.success, CurioColorsLight.success)
        : curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: .16), shape: BoxShape.circle),
            child: index != null
                ? Text('$index', style: TextStyle(color: color, fontWeight: FontWeight.w900))
                : Icon(Icons.close_rounded, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tile.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(tile.note, style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
