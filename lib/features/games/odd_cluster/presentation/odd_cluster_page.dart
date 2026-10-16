import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/odd_cluster.dart';

class OddClusterPage extends StatefulWidget {
  const OddClusterPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<OddClusterPage> createState() => _OddClusterPageState();
}

class _OddClusterPageState extends State<OddClusterPage> {
  static const _game = 'odd_cluster';
  static const _rules = [
    'Sixteen tiles hide four groups of four. Each group shares one precise piece of knowledge.',
    'Pick four tiles and submit. A correct group locks in.',
    '“One away” means three of your four belong together.',
    'Four mistakes and the puzzle ends. One group is always sneaky — its tiles look like they belong somewhere easier.',
  ];

  late OddClusterGame _puzzle = _newGame();
  final Set<String> _selected = {};
  String? _message;
  GameNoticeTone _tone = GameNoticeTone.info;
  int _practiceShift = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceShift > 0;

  OddClusterGame _newGame() {
    final day = DailyPick.dayNumber(widget.date) + _practiceShift;
    return OddClusterGame(
      oddClusterPuzzles[day % oddClusterPuzzles.length],
      seed: day,
    );
  }

  void _toggle(String word) {
    if (_puzzle.finished) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = null;
      if (!_selected.remove(word) && _selected.length < 4) _selected.add(word);
    });
  }

  void _submit() {
    if (_selected.length != 4) return;
    final verdict = _puzzle.guess(Set.of(_selected));
    setState(() {
      switch (verdict) {
        case ClusterVerdict.found:
          HapticFeedback.mediumImpact();
          _message = 'Found: ${_puzzle.found.last.title}.';
          _tone = GameNoticeTone.good;
          _selected.clear();
        case ClusterVerdict.oneAway:
          HapticFeedback.heavyImpact();
          _message = 'One away! Three of those belong together.';
          _tone = GameNoticeTone.close;
        case ClusterVerdict.wrong:
          HapticFeedback.heavyImpact();
          _message = 'Not a group. Look for a more precise link.';
          _tone = GameNoticeTone.bad;
        case ClusterVerdict.repeat:
          _message = 'You’ve already tried those four.';
          _tone = GameNoticeTone.info;
      }
      if (_puzzle.finished) {
        _selected.clear();
        _message = null;
      }
    });
    if (_puzzle.finished && !_practice) {
      _alreadyDone = awardDaily(context, _game);
    }
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _puzzle = _newGame();
      _selected.clear();
      _message = null;
    });
  }

  String get _share =>
      'Curio · Odd Cluster\n${_puzzle.shareGrid()}\n'
      '${_puzzle.won ? 'Solved' : '${_puzzle.found.length}/4 groups'}'
      ' · ${_puzzle.mistakes} mistakes';

  @override
  Widget build(BuildContext context) {
    final groups = [..._puzzle.found, ..._puzzle.revealed];
    return CurioPage(
      title: 'Odd Cluster',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice puzzle' : 'Daily knowledge puzzle',
            title: _puzzle.won
                ? 'Every cluster found.'
                : _puzzle.lost
                ? 'So close.'
                : 'Find the four clusters',
            subtitle:
                'Four groups of four. One of them is sneaky — trust knowledge, not looks.',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '3–5 min'),
              GameMetaChip(icon: Icons.psychology_alt_rounded, label: 'Reasoning'),
            ],
            trailing: _MistakeDots(left: _puzzle.mistakesLeft),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: PracticeBadge()),
          ],
          const SizedBox(height: 16),
          for (final group in groups) ...[
            _GroupBar(group: group, revealed: _puzzle.revealed.contains(group)),
            const SizedBox(height: 8),
          ],
          if (!_puzzle.finished) ...[
            _Board(
              words: _puzzle.board,
              selected: _selected,
              onTap: _toggle,
            ),
            const SizedBox(height: 14),
            if (_message != null) ...[
              GameNotice(message: _message!, tone: _tone),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Shuffle tiles',
                  onPressed: () => setState(() => _puzzle.shuffle(Random())),
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: const Text('Deselect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const Key('cluster_submit'),
                    onPressed: _selected.length == 4 ? _submit : null,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            GameResultCard(
              gameId: 'odd_cluster',
              title: _puzzle.won
                  ? (_puzzle.mistakes == 0 ? 'Flawless!' : 'Solved!')
                  : 'Here’s how they fit.',
              score: _puzzle.won ? '4 / 4' : '${_puzzle.found.length} / 4',
              shareText: _share,
              xp: _practice ? null : gameRewards[_game]!.xp,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
            ),
          ],
        ],
      ),
    );
  }
}

Color _tierColor(BuildContext context, int tier) => switch (tier) {
  0 => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  1 => curioColor(context, CurioColors.forest, CurioColorsLight.forest),
  2 => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  _ => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
};

class _Board extends StatelessWidget {
  const _Board({required this.words, required this.selected, required this.onTap});

  final List<String> words;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 3) / 4;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final word in words)
              SizedBox(
                width: width,
                height: width.clamp(56.0, 84.0) * .8,
                child: _Tile(
                  word: word,
                  selected: selected.contains(word),
                  onTap: () => onTap(word),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.word, required this.selected, required this.onTap});

  final String word;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final outline = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Semantics(
      button: true,
      selected: selected,
      label: word,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('cluster_$word'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? coral : surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? coral : outline, width: 1.3),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                word,
                maxLines: 1,
                style: TextStyle(
                  // Coral is bright in both modes: dark ink on it (design §7).
                  color: selected
                      ? curioColor(context, CurioColors.night, CurioColorsLight.ink)
                      : ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: .3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.group, required this.revealed});
  final ClusterGroup group;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(context, group.tier);
    final muted = curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .55), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.title.toUpperCase(),
                  style: TextStyle(
                    color: curioColor(context, CurioColors.ink, CurioColorsLight.ink),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: .6,
                  ),
                ),
              ),
              if (revealed)
                Text(
                  'REVEALED',
                  style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.words.join(' · '),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(group.explanation, style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}

class _MistakeDots extends StatelessWidget {
  const _MistakeDots({required this.left});
  final int left;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final idle = curioColor(context, CurioColors.outline, CurioColorsLight.outline);
    return Semantics(
      label: '$left mistakes left',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < OddClusterGame.maxMistakes; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < left ? coral : idle,
              ),
            ),
        ],
      ),
    );
  }
}
