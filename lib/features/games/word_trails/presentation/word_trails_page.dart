import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/word_trails.dart';

class WordTrailsPage extends StatefulWidget {
  const WordTrailsPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<WordTrailsPage> createState() => _WordTrailsPageState();
}

class _WordTrailsPageState extends State<WordTrailsPage> {
  static const _game = 'word_trails';
  static const _hints = 3;
  static const _rules = [
    'The story has missing words, and they’re all hiding in the letters.',
    'Tap letters that touch — sideways, up, down or corner to corner — to spell a word.',
    'Every letter belongs to exactly one word, and the words follow the story’s order.',
    'Found one? Pick what it means to fill its gap in the story.',
    'Stuck? A hint lights up where the next word starts. Tap the last letter again to undo it.',
  ];

  int _practice = 0;
  late WordTrail _trail = _newTrail();
  final List<int> _traced = [];
  int? _asking;
  final Set<String> _wrongChoices = {};
  int _hintsLeft = _hints;
  int? _hinted;
  int _mistakes = 0;
  bool _alreadyDone = false;
  String _message = 'Tap touching letters to spell a word from the story.';
  GameNoticeTone _tone = GameNoticeTone.info;

  WordTrail _newTrail() =>
      WordTrail.daily(DailyPick.dayNumber(widget.date) + _practice);

  void _tap(int square) {
    if (_asking != null || _trail.squares[square].word == null) return;
    if (_trail.solved.contains(_trail.squares[square].word)) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_traced.isNotEmpty && _traced.last == square) {
        _traced.removeLast();
        return;
      }
      if (_traced.contains(square)) return;
      // A letter that doesn't touch the trace starts a new one.
      if (_traced.isNotEmpty && !WordTrail.touching(_traced.last, square)) {
        _traced.clear();
      }
      _traced.add(square);
      final w = _trail.wordFor(_traced);
      if (w != null) {
        _asking = w;
        _hinted = null;
        _message =
            'You found “${_trail.story.words[w].answer}”! What does it mean?';
        _tone = GameNoticeTone.good;
      } else if (_traced.length >= _trail.longestLeft) {
        _traced.clear();
        _mistakes++;
        _message = 'That’s not one of the story words. Try another trail!';
        _tone = GameNoticeTone.close;
      }
    });
  }

  void _choose(String choice) {
    final w = _asking!;
    if (choice != _trail.story.words[w].meaning) {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrongChoices.add(choice);
        _mistakes++;
        _message =
            'Not that one — read the story around the gap and try again.';
        _tone = GameNoticeTone.bad;
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _trail.solved.add(w);
      _asking = null;
      _wrongChoices.clear();
      _traced.clear();
      _message = _trail.finished
          ? 'Story complete!'
          : 'Right! Its gap in the story is filled. Find the next word.';
      _tone = GameNoticeTone.good;
    });
    if (_trail.finished && _practice == 0) {
      _alreadyDone = awardDaily(context, _game);
    }
  }

  void _hint() {
    final next = [
      for (var w = 0; w < _trail.paths.length; w++)
        if (!_trail.solved.contains(w)) w,
    ].first;
    setState(() {
      _hintsLeft--;
      _traced.clear();
      _hinted = _trail.paths[next].first;
      _message = 'The glowing letter starts the next word.';
      _tone = GameNoticeTone.info;
    });
  }

  void _practiceRound() {
    setState(() {
      _practice++;
      _trail = _newTrail();
      _traced.clear();
      _asking = null;
      _wrongChoices.clear();
      _hintsLeft = _hints;
      _hinted = null;
      _mistakes = 0;
      _message = 'A new story! Tap touching letters to spell its words.';
      _tone = GameNoticeTone.info;
    });
  }

  String get _share =>
      'Curio · Word Trails\n${'📖' * _trail.story.words.length}  '
      '${_mistakes == 0 ? 'no slips' : '$_mistakes ${_mistakes == 1 ? 'slip' : 'slips'}'}';

  @override
  Widget build(BuildContext context) {
    final words = _trail.story.words;
    return CurioPage(
      title: 'Word Trails',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice > 0 ? 'Practice story' : 'Daily word trail',
            title: _trail.finished ? 'Story told.' : _trail.story.title,
            subtitle:
                'Find the story’s missing words in the letters, then show you '
                'know what they mean.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–4 min',
              ),
              GameMetaChip(
                icon: Icons.auto_stories_rounded,
                label: '${_trail.solved.length} of ${words.length} words',
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
          _StoryRibbon(trail: _trail),
          const SizedBox(height: 14),
          _Board(trail: _trail, traced: _traced, hinted: _hinted, onTap: _tap),
          const SizedBox(height: 14),
          GameNotice(message: _message, tone: _tone),
          const SizedBox(height: 14),
          if (_asking != null)
            _MeaningGate(
              word: words[_asking!].answer,
              choices: _trail.choicesFor(_asking!),
              wrong: _wrongChoices,
              onChoose: _choose,
            )
          else if (!_trail.finished)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('trail_hint'),
                    onPressed: _hintsLeft > 0 ? _hint : null,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: Text('Hint ($_hintsLeft)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('trail_clear'),
                    onPressed: _traced.isEmpty
                        ? null
                        : () => setState(_traced.clear),
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            )
          else
            GameResultCard(
              gameId: _game,
              title: _mistakes == 0 ? 'Not a single slip!' : 'Story complete!',
              score: '${words.length} / ${words.length}',
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

Color _wordColor(BuildContext context, TrailWord word) => word.key
    ? curioColor(context, CurioColors.saffron, CurioColorsLight.saffron)
    : curioColor(context, CurioColors.forest, CurioColorsLight.forest);

/// The story, with a gap for every word still hidden.
class _StoryRibbon extends StatelessWidget {
  const _StoryRibbon({required this.trail});
  final WordTrail trail;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final strong = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forestStrong,
    );
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffronStrong,
    );
    final spans = <InlineSpan>[];
    final parts = trail.story.story.split(RegExp(r'\{(\d+)\}'));
    final blanks = RegExp(
      r'\{(\d+)\}',
    ).allMatches(trail.story.story).map((m) => int.parse(m.group(1)!));
    for (final (i, w) in [null, ...blanks].indexed) {
      if (w != null) {
        final word = trail.story.words[w];
        spans.add(
          trail.solved.contains(w)
              ? TextSpan(
                  text: word.answer.toLowerCase(),
                  style: TextStyle(
                    color: word.key ? gold : strong,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : TextSpan(
                  text: '_' * word.answer.length,
                  style: TextStyle(color: muted, letterSpacing: 1.5),
                ),
        );
      }
      spans.add(TextSpan(text: parts[i]));
    }
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STORY',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(children: spans),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 19, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.trail,
    required this.traced,
    required this.hinted,
    required this.onTap,
  });

  final WordTrail trail;
  final List<int> traced;
  final int? hinted;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const n = WordTrail.size;
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffronStrong,
    );
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1,
          child: GlassCard(
            radius: 28,
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
                              padding: const EdgeInsets.all(4),
                              child: _square(
                                context,
                                r * n + c,
                                coral,
                                gold,
                                ink,
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
    int i,
    Color coral,
    Color gold,
    Color ink,
  ) {
    final square = trail.squares[i];
    // Blank squares are dents in the board.
    if (square.word == null) {
      return const CurioClay(
        radius: 14,
        pressed: true,
        child: SizedBox.expand(),
      );
    }
    final word = trail.story.words[square.word!];
    final solved = trail.solved.contains(square.word);
    final step = traced.indexOf(i);
    final active = step >= 0;
    return Semantics(
      button: !solved,
      label:
          '${square.letter}${solved
              ? ', part of ${word.answer}'
              : active
              ? ', letter ${step + 1} of your trail'
              : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('trail_$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        // Found words settle into the board in their colour; the letters
        // you're tracing are pushed in.
        child: CurioClay(
          radius: 14,
          pressed: solved || active,
          color: solved
              ? _wordColor(context, word).withValues(alpha: .3)
              : active
              ? coral.withValues(alpha: .28)
              : null,
          outline: active
              ? coral
              : hinted == i
              ? gold
              : null,
          child: Center(
            child: Text(
              square.letter,
              textScaler: TextScaler.noScaling,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "What does it mean?" — three clay answers, wrong picks sinking in.
class _MeaningGate extends StatelessWidget {
  const _MeaningGate({
    required this.word,
    required this.choices,
    required this.wrong,
    required this.onChoose,
  });

  final String word;
  final List<String> choices;
  final Set<String> wrong;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'WHAT DOES ${word.toUpperCase()} MEAN?',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, choice) in choices.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Semantics(
              button: true,
              enabled: !wrong.contains(choice),
              label: choice,
              excludeSemantics: true,
              child: GestureDetector(
                key: Key('trail_choice_$i'),
                behavior: HitTestBehavior.opaque,
                onTap: wrong.contains(choice) ? null : () => onChoose(choice),
                child: CurioClay(
                  radius: 18,
                  pressed: wrong.contains(choice),
                  color: wrong.contains(choice)
                      ? danger.withValues(alpha: .14)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: wrong.contains(choice) ? muted : null,
                            decoration: wrong.contains(choice)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (wrong.contains(choice))
                        Icon(Icons.close_rounded, color: danger, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
