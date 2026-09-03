import 'package:flutter/material.dart';

import '../../../../core/state/curio_state.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';

class _PatternQuestion {
  const _PatternQuestion(this.sequence, this.options, this.answer, this.rule);
  final String sequence;
  final List<int> options;
  final int answer;
  final String rule;
}

const _questions = <_PatternQuestion>[
  _PatternQuestion(
    '2, 6, 12, 20, ?',
    [28, 30, 32],
    30,
    'Add 4, then 6, then 8, then 10.',
  ),
  _PatternQuestion(
    '81, 27, 9, 3, ?',
    [0, 1, 2],
    1,
    'Each number is divided by 3.',
  ),
  _PatternQuestion(
    '3, 4, 7, 11, 18, ?',
    [25, 28, 29],
    29,
    'Add the previous two numbers: 11 + 18 = 29.',
  ),
];

class PatternForgePage extends StatefulWidget {
  const PatternForgePage({super.key});

  @override
  State<PatternForgePage> createState() => _PatternForgePageState();
}

class _PatternForgePageState extends State<PatternForgePage> {
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _answered = false;

  void _choose(int value) {
    if (_answered) return;
    final question = _questions[_index];
    setState(() {
      _selected = value;
      _answered = true;
      if (value == question.answer) _score++;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      CurioScope.of(context).completeActivity(
        id: CurioState.dailyActivityId('pattern_forge'),
        xp: 60,
        skill: 'Patterns',
        factId: 'fibonacci_nature',
      );
      setState(() => _index++);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tealSoft = curioColor(context, CurioColors.tealSoft, CurioColorsLight.tealSoft);
    final teal = curioColor(context, CurioColors.teal, CurioColorsLight.teal);
    final gold = curioColor(context, CurioColors.gold, CurioColorsLight.gold);
    final tealDark = curioColor(context, CurioColors.tealDark, CurioColorsLight.tealDark);
    final navyMuted = curioColor(context, CurioColors.navyMuted, CurioColorsLight.navyMuted);
    final navy = curioColor(context, CurioColors.navy, CurioColorsLight.navy);
    final onDark = curioColor(context, CurioColors.onDark, CurioColorsLight.onDark);
    final green = curioColor(context, CurioColors.green, CurioColorsLight.green);
    final coral = curioColor(context, CurioColors.coral, CurioColorsLight.coral);
    final greenSoft = curioColor(context, CurioColors.greenSoft, CurioColorsLight.greenSoft);
    final coralSoft = curioColor(context, CurioColors.coralSoft, CurioColorsLight.coralSoft);
    final surface = curioColor(context, CurioColors.surface, CurioColorsLight.surface);
    final goldSoft = curioColor(context, CurioColors.goldSoft, CurioColorsLight.goldSoft);
    final saffronStrong = curioColor(context, CurioColors.saffronStrong, CurioColorsLight.saffronStrong);
    if (_index >= _questions.length) {
      return CurioPage(
        title: 'Pattern Forge',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CurioCard(
            color: tealSoft,
            borderColor: teal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 60,
                  color: gold,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pattern forged!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'You solved $_score of ${_questions.length} patterns and earned 60 XP.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Back to learning',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_index];
    return CurioPage(
      title: 'Pattern Forge',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                'Puzzle ${_index + 1} of ${_questions.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: tealDark,
                ),
              ),
              const Spacer(),
              Text(
                '$_score correct',
                style: TextStyle(color: navyMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: teal,
            backgroundColor: tealSoft,
          ),
          const SizedBox(height: 20),
          CurioCard(
            color: navy,
            borderColor: navy,
            child: Column(
              children: [
                Text(
                  'WHAT COMES NEXT?',
                  style: TextStyle(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  question.sequence,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onDark,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...question.options.map((option) {
            final isSelected = _selected == option;
            final isCorrect = _answered && option == question.answer;
            final color = isCorrect
                ? green
                : isSelected
                ? coral
                : teal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CurioCard(
                onTap: () => _choose(option),
                color: isCorrect
                    ? greenSoft
                    : isSelected
                    ? coralSoft
                    : surface,
                borderColor: color.withValues(alpha: .6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$option',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Icon(
                        Icons.check_circle_rounded,
                        color: green,
                      ),
                  ],
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 5),
            CurioCard(
              color: goldSoft,
              borderColor: gold,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: saffronStrong,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(question.rule)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _index == _questions.length - 1
                  ? 'Finish forge'
                  : 'Next pattern',
              onPressed: _next,
            ),
          ],
        ],
      ),
    );
  }
}
