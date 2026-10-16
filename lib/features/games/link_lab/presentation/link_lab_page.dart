import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/link_lab.dart';

class LinkLabPage extends StatefulWidget {
  const LinkLabPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<LinkLabPage> createState() => _LinkLabPageState();
}

class _LinkLabPageState extends State<LinkLabPage> {
  static const _game = 'link_lab';
  static const _rules = [
    'Sixteen tiles hide four groups of four. Each group shares one clear link.',
    'Pick four tiles and check them. A right group locks in and shows why its tiles belong together.',
    '“So close” means three of your four belong together.',
    'Stuck? Hints are free, and mistakes never end the game — they’re just counted.',
  ];

  late LinkLabGame _puzzle = _newGame();
  final Set<String> _selected = {};
  String? _message;
  GameNoticeTone _tone = GameNoticeTone.info;
  int _practiceRound = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceRound > 0;

  LinkLabGame _newGame() => LinkLabGame.forDay(
    linkLabDay(DailyPick.dayNumber(widget.date), practice: _practiceRound),
  );

  void _toggle(String word) {
    if (_puzzle.won) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = null;
      if (!_selected.remove(word) && _selected.length < 4) _selected.add(word);
    });
  }

  void _submit() {
    if (_selected.length != 4 || _puzzle.won) return;
    final verdict = _puzzle.guess(Set.of(_selected));
    setState(() {
      switch (verdict) {
        case LinkVerdict.found:
          HapticFeedback.mediumImpact();
          _message = 'Linked: ${_puzzle.found.last.title}.';
          _tone = GameNoticeTone.good;
          _selected.clear();
        case LinkVerdict.oneAway:
          HapticFeedback.heavyImpact();
          _message = 'So close! Three of those four belong together.';
          _tone = GameNoticeTone.close;
        case LinkVerdict.wrong:
          HapticFeedback.heavyImpact();
          _message =
              'Not a group yet. Swap a tile or take a hint — mistakes never end the game.';
          _tone = GameNoticeTone.bad;
        case LinkVerdict.repeat:
          _message = 'You’ve already tried those four.';
          _tone = GameNoticeTone.info;
      }
      if (_puzzle.won) {
        _selected.clear();
        _message = null;
      }
    });
    if (_puzzle.won && !_practice) {
      _alreadyDone = awardDaily(context, _game);
    }
  }

  void _hint() {
    final hint = _puzzle.hint();
    if (hint == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = hint.word == null
          ? 'Hint: one group is “${hint.group.title}”.'
          : 'Hint: ${hint.word} belongs in “${hint.group.title}”.';
      _tone = GameNoticeTone.info;
    });
  }

  void _startPractice() {
    setState(() {
      _practiceRound++;
      _puzzle = _newGame();
      _selected.clear();
      _message = null;
    });
  }

  static String _count(int n, String thing) =>
      '${n == 0 ? 'No' : n} $thing${n == 1 ? '' : 's'}';

  String get _share =>
      'Curio · Link Lab\n${_puzzle.shareGrid()}\n'
      '${_count(_puzzle.mistakes, 'mistake')} · '
      '${_count(_puzzle.hints, 'hint').toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return CurioPage(
      title: 'Link Lab',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice puzzle' : 'Daily knowledge puzzle',
            title: puzzle.won
                ? 'Brilliantly connected.'
                : 'Find the hidden links',
            subtitle:
                'Make four groups of four. Hints are free and mistakes never end the game.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–5 min',
              ),
              const GameMetaChip(
                icon: Icons.psychology_alt_rounded,
                label: 'Reasoning',
              ),
              GameMetaChip(
                icon: Icons.close_rounded,
                label: _count(puzzle.mistakes, 'mistake'),
              ),
              GameMetaChip(
                icon: Icons.lightbulb_outline_rounded,
                label: _count(puzzle.hints, 'hint'),
              ),
            ],
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          for (final group in puzzle.found) ...[
            _GroupBar(group: group, colour: puzzle.colourOf(group)),
            const SizedBox(height: 8),
          ],
          if (!puzzle.won) ...[
            _Board(
              words: puzzle.board,
              selected: _selected,
              hinted: puzzle.pointedAt,
              onTap: _toggle,
            ),
            const SizedBox(height: 14),
            if (_message != null) ...[
              GameNotice(message: _message!, tone: _tone),
              const SizedBox(height: 12),
            ],
            if (puzzle.named.any((g) => !puzzle.found.contains(g))) ...[
              _HintPanel(puzzle: puzzle),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                IconButton.outlined(
                  key: const Key('link_shuffle'),
                  tooltip: 'Shuffle tiles',
                  onPressed: () => setState(() => puzzle.shuffle(Random())),
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('link_hint'),
                    onPressed: _hint,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: const Text('Hint'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              key: const Key('link_submit'),
              label: _selected.length == 4
                  ? 'Check connection'
                  : 'Select ${4 - _selected.length} more',
              icon: Icons.hub_rounded,
              onPressed: _selected.length == 4 ? _submit : null,
            ),
          ] else ...[
            const SizedBox(height: 8),
            GameResultCard(
              title: puzzle.mistakes == 0 && puzzle.hints == 0
                  ? 'Flawless links!'
                  : puzzle.mistakes == 0
                  ? 'No mistakes!'
                  : 'All four linked!',
              score: _count(puzzle.mistakes, 'mistake'),
              shareText: _share,
              xp: _practice ? null : gameRewards[_game]!.xp,
              alreadyDone: _alreadyDone,
              gameId: _game,
              onPractice: _startPractice,
            ),
          ],
        ],
      ),
    );
  }
}

/// Group colours follow the share squares: 🟨 🟩 🟦 🟪.
Color _groupColour(BuildContext context, int index) => switch (index) {
  0 => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
  1 => curioColor(context, CurioColors.forest, CurioColorsLight.forest),
  2 => curioColor(context, CurioColors.blue, CurioColorsLight.blue),
  _ => curioColor(context, CurioColors.plum, CurioColorsLight.plum),
};

class _Board extends StatelessWidget {
  const _Board({
    required this.words,
    required this.selected,
    required this.hinted,
    required this.onTap,
  });

  final List<String> words;
  final Set<String> selected;
  final Set<String> hinted;
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
                child: _Tile(
                  word: word,
                  selected: selected.contains(word),
                  hinted: hinted.contains(word),
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
  const _Tile({
    required this.word,
    required this.selected,
    required this.hinted,
    required this.onTap,
  });

  final String word;
  final bool selected, hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    // Coral is bright in both modes: dark ink on it (design §7).
    final onCoral = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
    );
    final saffron = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: hinted ? '$word, from a hint' : word,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('link_$word'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? coral : surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? coral : outline,
                width: selected ? 2 : 1.3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected ? onCoral : ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: .3,
                    ),
                  ),
                ),
                // A shape as well as a colour, so "chosen" never relies on
                // colour alone.
                if (selected || hinted)
                  Positioned(
                    top: -9,
                    right: -5,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.lightbulb_rounded,
                      size: 14,
                      color: selected ? onCoral : saffron,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.group, required this.colour});
  final LinkGroup group;
  final int colour;

  @override
  Widget build(BuildContext context) {
    final color = _groupColour(context, colour);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link_rounded, size: 18, color: ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title.toUpperCase(),
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.words.join(' · '),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            group.why,
            style: TextStyle(color: muted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Every link a hint has named that's still hidden, so it isn't forgotten
/// the moment the next tile is tapped.
class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.puzzle});
  final LinkLabGame puzzle;

  @override
  Widget build(BuildContext context) {
    final saffron = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final open = [
      for (final g in puzzle.named)
        if (!puzzle.found.contains(g)) g,
    ];
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: saffron, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your hints',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final g in open) ...[
                  const SizedBox(height: 4),
                  Text(_line(g), style: TextStyle(color: muted, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _line(LinkGroup g) {
    final shown = g.words.where(puzzle.pointedAt.contains).toList();
    return shown.isEmpty
        ? 'A group: “${g.title}”'
        : 'A group: “${g.title}”, including ${shown.join(', ')}';
  }
}
