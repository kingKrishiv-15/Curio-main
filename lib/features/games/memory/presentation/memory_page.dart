import 'package:flutter/material.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/memory_game.dart';

const memorySymbols = <(IconData, String)>[
  (Icons.pets_rounded, 'Paw'),
  (Icons.local_florist_rounded, 'Flower'),
  (Icons.star_rounded, 'Star'),
  (Icons.bedtime_rounded, 'Moon'),
  (Icons.wb_sunny_rounded, 'Sun'),
  (Icons.sailing_rounded, 'Boat'),
  (Icons.rocket_launch_rounded, 'Rocket'),
  (Icons.park_rounded, 'Tree'),
  (Icons.icecream_rounded, 'Ice cream'),
  (Icons.music_note_rounded, 'Music'),
  (Icons.favorite_rounded, 'Heart'),
  (Icons.sports_baseball_rounded, 'Ball'),
];

class MemoryPage extends StatefulWidget {
  const MemoryPage({this.date, this.trail = false, super.key});
  final DateTime? date;
  final bool trail;

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  late final _date = widget.date ?? DateTime.now();
  int _practice = 0;
  late MemoryMatchGame _match = MemoryMatchGame(_seed);
  late MemoryTrailGame _trail = MemoryTrailGame(_seed);
  bool _result = false, _alreadyDone = false;
  String _message = 'Turn over two cards to look for a pair.';
  int get _seed => DailyPick.dayNumber(_date) - _practice;
  String get _id => widget.trail ? 'memory_trail' : 'memory_match';
  String get _title => widget.trail ? 'Memory Trail' : 'Memory Match';

  void _finish() {
    if (_result) return;
    if (_practice == 0) _alreadyDone = awardDaily(context, _id);
    setState(() => _result = true);
  }

  void _flip(int index) {
    if (!_match.flip(index)) return;
    setState(() {
      _message = _match.needsReset
          ? 'Different pictures. Remember their places, then try another pair.'
          : _match.flipped.isEmpty
          ? 'A pair! Great remembering.'
          : 'Now turn over one more card.';
    });
    if (_match.finished) _finish();
  }

  void _choose(int symbol) {
    if (!_trail.choose(symbol)) return;
    setState(() {});
  }

  void _nextTrail() {
    if (_trail.isLast) {
      _finish();
    } else {
      setState(_trail.next);
    }
  }

  void _replay() => setState(() {
    _practice++;
    _match = MemoryMatchGame(_seed);
    _trail = MemoryTrailGame(_seed);
    _result = false;
    _message = 'Turn over two cards to look for a pair.';
  });

  @override
  Widget build(BuildContext context) => CurioPage(
    title: _title,
    actions: [
      HowToPlayButton(
        rules: widget.trail
            ? const [
                'Study the pictures in order. Take as long as you need.',
                'Tap “I’m ready” to hide the trail, then tap the pictures in the same order.',
                'There are five trails. Each has one more picture. A mistake shows the trail so you can learn.',
              ]
            : const [
                'Turn over two cards. Matching pictures stay face up.',
                'If they are different, remember their places and tap “Try another pair”.',
                'Find all six pairs. There is no timer or guess limit.',
              ],
      ),
    ],
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GameHeader(
          eyebrow: 'Today’s memory game',
          title: _title,
          subtitle: widget.trail
              ? 'Look carefully. Remember the order. Follow the trail.'
              : 'A little attention makes a big difference. Find all six pairs!',
          chips: const [
            GameMetaChip(icon: Icons.psychology_rounded, label: 'Memory'),
            GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
          ],
        ),
        if (_practice > 0)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ),
        const SizedBox(height: 20),
        if (_result)
          GameResultCard(
            title: widget.trail ? 'Trail complete!' : 'Every pair found!',
            score: widget.trail ? '${_trail.score} / 5' : '6 / 6 pairs',
            shareText:
                'Curio · $_title\n${widget.trail ? '${_trail.score} of 5 trails remembered' : 'Six pairs in ${_match.moves} turns'}',
            gameId: _id,
            xp: _practice == 0 ? gameRewards[_id]!.xp : null,
            alreadyDone: _alreadyDone,
            onPractice: _replay,
          )
        else if (widget.trail)
          ..._trailBoard()
        else ...[
          Text(
            '${_match.matched.length ~/ 2} of 6 pairs · ${_match.moves} turns',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _symbolGrid([
            for (var i = 0; i < _match.cards.length; i++)
              _symbolButton(
                key: Key('memory_card_$i'),
                symbol: _match.visible(i) ? _match.cards[i] : null,
                label: _match.visible(i)
                    ? 'Card ${i + 1}, ${memorySymbols[_match.cards[i]].$2}${_match.matched.contains(i) ? ', matched' : ''}'
                    : 'Card ${i + 1}, face down',
                onTap: _match.visible(i) || _match.needsReset
                    ? null
                    : () => _flip(i),
                state: _match.matched.contains(i)
                    ? _Face.matched
                    : _match.flipped.contains(i)
                    ? _Face.turned
                    : _Face.down,
              ),
          ]),
          const SizedBox(height: 16),
          GameNotice(
            message: _message,
            tone: _match.needsReset ? GameNoticeTone.info : GameNoticeTone.good,
          ),
          if (_match.needsReset) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('memory_hide'),
              onPressed: () => setState(() {
                _match.hideUnmatched();
                _message = 'Where was the matching picture?';
              }),
              child: const Text('Try another pair'),
            ),
          ],
        ],
      ],
    ),
  );

  List<Widget> _trailBoard() => [
    Text(
      'Trail ${_trail.round + 1} of 5 · ${_trail.trail.length} pictures',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    const SizedBox(height: 12),
    if (_trail.studying || _trail.answered) ...[
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < _trail.trail.length; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${i + 1}'),
                  const SizedBox(height: 4),
                  Icon(memorySymbols[_trail.trail[i]].$1, size: 32),
                  Text(memorySymbols[_trail.trail[i]].$2),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
    if (_trail.studying)
      FilledButton(
        key: const Key('trail_ready'),
        onPressed: () => setState(_trail.startRecall),
        child: const Text('I’m ready — hide the trail'),
      )
    else if (_trail.answered) ...[
      GameNotice(
        message: _trail.correct == true
            ? 'You remembered the whole trail!'
            : 'Good try! Here is the trail in order. Try saying each picture’s name.',
        tone: _trail.correct == true
            ? GameNoticeTone.good
            : GameNoticeTone.info,
      ),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('trail_next'),
        onPressed: _nextTrail,
        child: Text(_trail.isLast ? 'See result' : 'Next trail'),
      ),
    ] else ...[
      GameNotice(
        message:
            'Which picture was number ${_trail.position + 1}? ${_trail.position} remembered so far.',
      ),
      const SizedBox(height: 12),
      _symbolGrid([
        for (var i = 0; i < memorySymbols.length; i++)
          _symbolButton(
            key: Key('trail_symbol_$i'),
            symbol: i,
            label: memorySymbols[i].$2,
            onTap: () => _choose(i),
          ),
      ]),
    ],
  ];

  Widget _symbolGrid(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 600 ? 4 : 3;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );

  /// A face-down card is a plum card back; a turned one keeps a plum ring
  /// until its pair is decided, and a matched pair settles into green.
  Widget _symbolButton({
    required Key key,
    required int? symbol,
    required String label,
    required VoidCallback? onTap,
    _Face state = _Face.up,
  }) {
    final plum = curioColor(context, CurioColors.plum, CurioColorsLight.plum);
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: CurioClay(
        radius: 18,
        color: switch (state) {
          _Face.down => plum.withValues(alpha: .16),
          _Face.matched => curioColor(
            context,
            CurioColors.successSoft,
            CurioColorsLight.successSoft,
          ),
          _ => null,
        },
        outline: state == _Face.turned ? plum : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: key,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      symbol == null
                          ? Icons.question_mark_rounded
                          : memorySymbols[symbol].$1,
                      color: symbol == null ? plum : null,
                      size: 28,
                    ),
                    if (symbol != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        memorySymbols[symbol].$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Face { up, down, turned, matched }
