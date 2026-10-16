import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/pattern_forge.dart';

class PatternForgePage extends StatefulWidget {
  const PatternForgePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<PatternForgePage> createState() => _PatternForgePageState();
}

class _PatternForgePageState extends State<PatternForgePage> {
  static const _game = 'pattern_forge';
  static const _rules = [
    'Three pattern puzzles a day, each a different kind.',
    'What comes next? Pick the number that carries the pattern on.',
    'Which rule? Pick the one rule that makes every number shown.',
    'Repair it: one number breaks the pattern. Tap it to fix it.',
    'You get one try at each. The working is shown after every answer.',
  ];

  late ForgeDay _day = _newDay();
  int _current = 0;

  /// Per question: the option index (or, for repair, the position) tapped.
  final List<int?> _picks = [null, null, null];
  int _practiceRound = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceRound > 0;
  ForgeQuestion get _question => _day.questions[_current];
  bool get _answered => _picks[_current] != null;
  bool get _finished => _picks.every((p) => p != null);

  ForgeDay _newDay() => ForgeDay.forDay(
    forgeDay(DailyPick.dayNumber(widget.date), practice: _practiceRound),
  );

  bool _isRight(int i) {
    final pick = _picks[i];
    if (pick == null) return false;
    return switch (_day.questions[i]) {
      NextQuestion(:final options, :final answer) => options[pick] == answer,
      RuleQuestion(:final answer) => pick == answer,
      RepairQuestion(:final wrongIndex) => pick == wrongIndex,
    };
  }

  int get _score =>
      [for (var i = 0; i < 3; i++) _isRight(i)].where((r) => r).length;

  void _pick(int value) {
    if (_answered) return;
    setState(() => _picks[_current] = value);
    if (_isRight(_current)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    if (_finished && !_practice) {
      _alreadyDone = awardDaily(context, _game);
    }
  }

  void _next() => setState(() => _current++);

  void _startPractice() {
    setState(() {
      _practiceRound++;
      _day = _newDay();
      _current = 0;
      _picks.setAll(0, [null, null, null]);
    });
  }

  String get _share {
    const names = ['Next', 'Rule', 'Repair'];
    final marks = [
      for (var i = 0; i < 3; i++) '${names[i]} ${_isRight(i) ? '🟩' : '🟥'}',
    ].join(' · ');
    return 'Curio · Pattern Forge\n$marks\n$_score / 3';
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    return CurioPage(
      title: 'Pattern Forge',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice forge' : 'Daily pattern forge',
            title: _finished ? 'Patterns forged.' : 'Crack three patterns',
            subtitle:
                'Pick what comes next, name the rule, then find the number that doesn’t belong.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–5 min',
              ),
              const GameMetaChip(
                icon: Icons.blur_on_rounded,
                label: 'Patterns',
              ),
              GameMetaChip(
                icon: Icons.check_circle_outline_rounded,
                label: '$_score of 3 right',
              ),
            ],
            trailing: _Pips(
              results: [
                for (var i = 0; i < 3; i++)
                  _picks[i] == null ? null : _isRight(i),
              ],
              current: _current,
            ),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          _QuestionCard(
            question: q,
            index: _current,
            pick: _picks[_current],
            onTapNumber: q is RepairQuestion ? _pick : null,
          ),
          const SizedBox(height: 14),
          if (q is NextQuestion)
            _Options(
              labels: [for (final o in q.options) '$o'],
              answer: q.options.indexOf(q.answer),
              pick: _picks[_current],
              big: true,
              onPick: _pick,
            )
          else if (q is RuleQuestion)
            _Options(
              labels: [for (final o in q.options) o.description],
              answer: q.answer,
              pick: _picks[_current],
              big: false,
              onPick: _pick,
            ),
          if (_answered) ...[
            const SizedBox(height: 4),
            GameNotice(
              message: _verdict(q, _isRight(_current)),
              tone: _isRight(_current)
                  ? GameNoticeTone.good
                  : GameNoticeTone.bad,
            ),
            const SizedBox(height: 12),
            _Working(question: q),
            const SizedBox(height: 14),
            if (!_finished)
              PrimaryButton(
                key: const Key('forge_next'),
                label: 'Next pattern',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              )
            else
              GameResultCard(
                title: _score == 3
                    ? 'Master forger!'
                    : _score == 2
                    ? 'Sharp pattern spotting.'
                    : 'Every pattern teaches a rule.',
                score: '$_score / 3',
                shareText: _share,
                xp: _practice ? null : gameRewards[_game]!.xp,
                alreadyDone: _alreadyDone,
                gameId: _game,
                onPractice: _startPractice,
              ),
          ] else if (q is RepairQuestion)
            const GameNotice(
              message: 'Tap the number that breaks the pattern.',
            ),
        ],
      ),
    );
  }

  String _verdict(ForgeQuestion q, bool right) => switch (q) {
    NextQuestion(:final answer) =>
      right ? 'Right — $answer comes next.' : 'Not quite — $answer comes next.',
    RuleQuestion(:final rule) =>
      right ? 'Right rule!' : 'Not quite — the rule is “${rule.description}”.',
    RepairQuestion(:final shown, :final wrongIndex, :final correctValue) =>
      right
          ? 'Found it! ${shown[wrongIndex]} should be $correctValue.'
          : 'Not that one — ${shown[wrongIndex]} should be $correctValue.',
  };
}

String _kindTitle(ForgeKind kind) => switch (kind) {
  ForgeKind.next => 'What comes next?',
  ForgeKind.rule => 'Which rule makes this pattern?',
  ForgeKind.repair => 'Repair it: which number is wrong?',
};

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.pick,
    required this.onTapNumber,
  });

  final ForgeQuestion question;
  final int index;
  final int? pick;
  final ValueChanged<int>? onTapNumber;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final q = question;
    final List<int> numbers = switch (q) {
      NextQuestion(:final shown) => shown,
      RuleQuestion(:final shown) => shown,
      RepairQuestion(:final shown) => shown,
    };
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION ${index + 1} OF 3',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(
              _kindTitle(q.kind),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 14),
          if (q is RepairQuestion)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < numbers.length; i++)
                  _NumberChip(
                    key: Key('forge_number_$i'),
                    value: '${numbers[i]}',
                    fixed: pick != null && i == q.wrongIndex
                        ? '${q.correctValue}'
                        : null,
                    mark: pick == null
                        ? null
                        : i == q.wrongIndex
                        ? true
                        : i == pick
                        ? false
                        : null,
                    semanticLabel: 'Number ${i + 1}: ${numbers[i]}',
                    onTap: pick == null ? () => onTapNumber?.call(i) : null,
                  ),
              ],
            )
          else
            Semantics(
              label:
                  'Pattern: ${numbers.join(', ')}${q is NextQuestion ? ', then a hidden number' : ''}',
              excludeSemantics: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in numbers) _NumberChip(value: '$n'),
                  if (q is NextQuestion)
                    _NumberChip(
                      value: pick == null ? '?' : '${q.answer}',
                      mystery: pick == null,
                      mark: pick == null ? null : true,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.value,
    this.fixed,
    this.mark,
    this.mystery = false,
    this.semanticLabel,
    this.onTap,
    super.key,
  });

  final String value;

  /// The corrected number, shown beside a struck-through wrong one.
  final String? fixed;

  /// true ✓, false ✗, null nothing.
  final bool? mark;
  final bool mystery;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final coral = curioColor(
      context,
      CurioColors.coral,
      CurioColorsLight.coral,
    );
    final success = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.success,
    );
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
    );
    final sunk = curioColor(
      context,
      CurioColors.surfaceMuted,
      CurioColorsLight.surfaceMuted,
    );
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    final accent = switch (mark) {
      true => success,
      false => danger,
      null => mystery ? coral : null,
    };
    final style = TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: curioColor(context, CurioColors.ink, CurioColorsLight.ink),
    );
    final chip = Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent?.withValues(alpha: .14) ?? sunk,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ?? (onTap != null ? outline : Colors.transparent),
          width: 1.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            Icon(
              mark! ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            textAlign: TextAlign.center,
            style: fixed == null
                ? style
                : style.copyWith(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 17,
                  ),
          ),
          if (fixed != null) ...[
            const SizedBox(width: 6),
            Text('→ $fixed', style: style),
          ],
        ],
      ),
    );
    if (onTap == null && semanticLabel == null) return chip;
    return Semantics(
      button: onTap != null,
      label: [
        semanticLabel ?? value,
        if (fixed != null) 'should be $fixed',
        if (mark == false) 'your pick',
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: chip,
        ),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.labels,
    required this.answer,
    required this.pick,
    required this.big,
    required this.onPick,
  });

  final List<String> labels;
  final int answer;
  final int? pick;

  /// Numbers sit two to a row; rule descriptions get the full width.
  final bool big;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = big
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < labels.length; i++)
              SizedBox(
                width: width,
                child: _OptionTile(
                  key: Key('forge_option_$i'),
                  label: labels[i],
                  big: big,
                  state: pick == null
                      ? _OptionState.open
                      : i == answer
                      ? _OptionState.right
                      : i == pick
                      ? _OptionState.wrong
                      : _OptionState.other,
                  onTap: pick == null ? () => onPick(i) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _OptionState { open, right, wrong, other }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.big,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool big;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final success = curioColor(
      context,
      CurioColors.success,
      CurioColorsLight.success,
    );
    final danger = curioColor(
      context,
      CurioColors.danger,
      CurioColorsLight.danger,
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
    final accent = switch (state) {
      _OptionState.right => success,
      _OptionState.wrong => danger,
      _ => null,
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: switch (state) {
        _OptionState.right => '$label, right answer',
        _OptionState.wrong => '$label, your pick, not right',
        _ => label,
      },
      excludeSemantics: true,
      child: Opacity(
        opacity: state == _OptionState.other ? .55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: big ? 14 : 13,
              ),
              decoration: BoxDecoration(
                color: accent?.withValues(alpha: .14) ?? surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent ?? outline, width: 1.4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: big
                          ? TextStyle(
                              color: ink,
                              fontFamily: 'Fraunces',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            )
                          : TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                    ),
                  ),
                  if (accent != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      state == _OptionState.right
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rule and how each number is made from the ones before.
class _Working extends StatelessWidget {
  const _Working({required this.question});
  final ForgeQuestion question;

  @override
  Widget build(BuildContext context) {
    final gold = curioColor(
      context,
      CurioColors.saffronStrong,
      CurioColorsLight.saffronStrong,
    );
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
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
                Text(
                  'The rule: ${question.rule.description}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  question.steps.join('\n'),
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.results, required this.current});
  final List<bool?> results;
  final int current;

  @override
  Widget build(BuildContext context) {
    final right = results.where((r) => r == true).length;
    return Semantics(
      label: 'Question ${current + 1} of 3, $right right so far',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < results.length; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (results[i]) {
                  true => curioColor(
                    context,
                    CurioColors.success,
                    CurioColorsLight.success,
                  ),
                  false => curioColor(
                    context,
                    CurioColors.danger,
                    CurioColorsLight.danger,
                  ),
                  null when i == current => curioColor(
                    context,
                    CurioColors.coral,
                    CurioColorsLight.coral,
                  ),
                  null => curioColor(
                    context,
                    CurioColors.outline,
                    CurioColorsLight.outline,
                  ),
                },
              ),
            ),
        ],
      ),
    );
  }
}
