import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../domain/sequence.dart';

class SequencePage extends StatefulWidget {
  const SequencePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<SequencePage> createState() => _SequencePageState();
}

class _SequencePageState extends State<SequencePage> {
  static const _game = 'sequence';
  static const _roundsPerDay = 3;
  static const _rules = [
    'Numbers appear one at a time, linked by a hidden rule.',
    'Guess the next number now — or reveal one more for 30 points.',
    'A wrong guess costs 20. Each sequence starts at 100 points.',
    'You only guess once the numbers shown are enough to pin the rule down, so a fair guess is never marked wrong.',
  ];

  final _input = TextEditingController();
  late List<SequenceRound> _rounds = _newRounds();
  int _current = 0;
  int _practiceShift = 0;
  bool _alreadyDone = false;
  String? _message;
  GameNoticeTone _tone = GameNoticeTone.info;

  bool get _practice => _practiceShift > 0;
  SequenceRound get _round => _rounds[_current];
  bool get _dayOver => _rounds.every((r) => r.over);
  int get _total => _rounds.fold(0, (sum, r) => sum + (r.solved ? r.points : 0));

  List<SequenceRound> _newRounds() {
    final day = DailyPick.dayNumber(widget.date) + _practiceShift;
    return [
      for (var i = 0; i < _roundsPerDay; i++)
        SequenceRound(sequenceBank[(day * _roundsPerDay + i) % sequenceBank.length]),
    ];
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _guess() {
    final value = int.tryParse(_input.text.trim());
    if (value == null || _round.over) return;
    final correct = _round.guess(value);
    _input.clear();
    setState(() {
      if (correct) {
        HapticFeedback.mediumImpact();
        _message = 'Cracked it! +${_round.points} points.';
        _tone = GameNoticeTone.good;
      } else if (_round.failed) {
        HapticFeedback.heavyImpact();
        _message = 'Out of points — the next number was ${_round.target}.';
        _tone = GameNoticeTone.bad;
      } else {
        HapticFeedback.heavyImpact();
        _message = 'Not $value. That cost ${SequenceRound.wrongCost} points.';
        _tone = GameNoticeTone.bad;
      }
    });
    _finishIfDone();
  }

  void _reveal() {
    setState(() {
      _round.reveal();
      _message = 'One more number revealed. Worth ${_round.points} now.';
      _tone = GameNoticeTone.info;
    });
  }

  void _next() {
    setState(() {
      _current++;
      _message = null;
    });
  }

  void _finishIfDone() {
    if (!_dayOver || _practice) return;
    _alreadyDone = awardDaily(context, _game);
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _rounds = _newRounds();
      _current = 0;
      _message = null;
    });
  }

  String get _share {
    final marks = _rounds
        .map((r) => !r.solved ? '⬛' : r.points >= 70 ? '🟩' : '🟨')
        .join();
    return 'Curio · Sequence\n$marks  $_total/${_roundsPerDay * SequenceRound.startPoints}';
  }

  @override
  Widget build(BuildContext context) {
    final showResult = _dayOver && _current == _rounds.length - 1;
    return CurioPage(
      title: 'Sequence',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice sequences' : 'Daily pattern puzzle',
            title: showResult ? 'Patterns spotted.' : 'What comes next?',
            subtitle:
                'Commit early for big points, or buy more evidence first. Your call.',
            chips: [
              const GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
              GameMetaChip(icon: Icons.stars_rounded, label: '$_total points'),
            ],
            trailing: _RoundPips(rounds: _rounds, current: _current),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: PracticeBadge()),
          ],
          const SizedBox(height: 16),
          _SequenceCard(round: _round, index: _current, total: _rounds.length),
          const SizedBox(height: 14),
          if (_message != null) ...[
            GameNotice(message: _message!, tone: _tone),
            const SizedBox(height: 14),
          ],
          if (!_round.over) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('sequence_input'),
                    controller: _input,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,7}')),
                    ],
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _guess(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(hintText: 'Next number'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('sequence_guess'),
                    onPressed: _guess,
                    child: const Text('Guess'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('sequence_reveal'),
              onPressed: _round.canReveal ? _reveal : null,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                _round.canReveal
                    ? 'Reveal one more (−${SequenceRound.revealCost})'
                    : 'No more reveals',
              ),
            ),
          ] else ...[
            _RuleCard(round: _round),
            const SizedBox(height: 14),
            if (!showResult)
              PrimaryButton(
                label: 'Next sequence',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              )
            else
              GameResultCard(
                gameId: 'sequence',
                title: _total >= 240 ? 'Pattern master!' : 'Well reasoned.',
                score: '$_total / ${_roundsPerDay * SequenceRound.startPoints}',
                shareText: _share,
                xp: _practice ? null : 80,
                alreadyDone: _alreadyDone,
                onPractice: _practiceRound,
              ),
          ],
        ],
      ),
    );
  }
}

class _SequenceCard extends StatelessWidget {
  const _SequenceCard({required this.round, required this.index, required this.total});

  final SequenceRound round;
  final int index, total;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted);
    final rose = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final numbers = round.over ? round.rule.terms.sublist(0, round.shown + 1) : round.visible;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SEQUENCE ${index + 1} OF $total',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                round.over
                    ? (round.solved ? '+${round.points}' : '0')
                    : 'Worth ${round.points}',
                style: TextStyle(color: rose, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Sequence so far: ${numbers.join(', ')}${round.over ? '' : ', then a hidden number'}',
            excludeSemantics: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < numbers.length; i++)
                  _NumberChip(
                    value: '${numbers[i]}',
                    highlight: round.over && i == numbers.length - 1,
                    solved: round.solved,
                  ),
                if (!round.over) const _NumberChip(value: '?', mystery: true),
              ],
            ),
          ),
          if (round.wrongGuesses.isNotEmpty && !round.over) ...[
            const SizedBox(height: 12),
            Text(
              'Not: ${round.wrongGuesses.join(', ')}',
              style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.value,
    this.highlight = false,
    this.solved = false,
    this.mystery = false,
  });

  final String value;
  final bool highlight, solved, mystery;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final success = curioColor(context, CurioColors.success, CurioColorsLight.success);
    final danger = curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final surface = curioColor(context, CurioColors.surfaceMuted, CurioColorsLight.surfaceMuted);
    final accent = highlight ? (solved ? success : danger) : coral;
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight || mystery ? accent.withValues(alpha: .14) : surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight || mystery ? accent : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: mystery ? coral : null,
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.round});
  final SequenceRound round;

  @override
  Widget build(BuildContext context) {
    final gold = curioColor(context, CurioColors.saffron, CurioColorsLight.saffron);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The rule: ${round.rule.name}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(round.rule.explanation, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundPips extends StatelessWidget {
  const _RoundPips({required this.rounds, required this.current});
  final List<SequenceRound> rounds;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sequence ${current + 1} of ${rounds.length}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rounds.length; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rounds[i].solved
                    ? curioColor(context, CurioColors.success, CurioColorsLight.success)
                    : rounds[i].failed
                    ? curioColor(context, CurioColors.danger, CurioColorsLight.danger)
                    : i == current
                    ? curioColor(context, CurioColors.coral, CurioColorsLight.coral)
                    : curioColor(context, CurioColors.outline, CurioColorsLight.outline),
              ),
            ),
        ],
      ),
    );
  }
}
