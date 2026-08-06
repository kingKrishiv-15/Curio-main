import 'package:flutter/material.dart';

import '../../../../core/state/curio_state.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/widgets/curio_ui.dart';

enum EvidenceRank { strong, weak, misleading }

class _Clue {
  const _Clue(this.title, this.detail, this.correct);
  final String title;
  final String detail;
  final EvidenceRank correct;
}

const _clues = <_Clue>[
  _Clue(
    'Weather station log',
    'Heavy rain and strong wind were recorded between 1 and 3 a.m.',
    EvidenceRank.strong,
  ),
  _Clue(
    'A muddy footprint',
    'One shoe print appears beside the broken tomato plants.',
    EvidenceRank.weak,
  ),
  _Clue(
    'A dramatic post',
    '“A monster attacked the garden!” says an anonymous account.',
    EvidenceRank.misleading,
  ),
];

class EvidenceDetectivePage extends StatefulWidget {
  const EvidenceDetectivePage({super.key});

  @override
  State<EvidenceDetectivePage> createState() => _EvidenceDetectivePageState();
}

class _EvidenceDetectivePageState extends State<EvidenceDetectivePage> {
  final Map<int, EvidenceRank> _answers = {};
  bool _submitted = false;

  int get _score => List.generate(
    _clues.length,
    (index) => _answers[index] == _clues[index].correct ? 1 : 0,
  ).where((value) => value == 1).length;

  void _submit() {
    if (_answers.length != _clues.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rank every clue before closing the case.'),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
    CurioScope.of(context).completeActivity(
      id: 'evidence_garden_1',
      xp: 70,
      skill: 'Evidence',
      factId: 'weather_evidence',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      title: 'Evidence Detective',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          CurioCard(
            color: CurioColors.frostDark,
            borderColor: CurioColors.frostDark,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CASE 001 · THE GARDEN',
                  style: TextStyle(
                    color: CurioColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'The school garden was damaged overnight. What evidence should we trust?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(_clues.length, (index) {
            final clue = _clues[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: CurioCard(
                borderColor: _submitted && _answers[index] == clue.correct
                    ? CurioColors.green
                    : CurioColors.creamDeep,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: CurioColors.tealSoft,
                          foregroundColor: CurioColors.tealDark,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            clue.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      clue.detail,
                      style: const TextStyle(color: CurioColors.navyMuted),
                    ),
                    const SizedBox(height: 13),
                    SegmentedButton<EvidenceRank>(
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: EvidenceRank.strong,
                          label: Text('Strong'),
                        ),
                        ButtonSegment(
                          value: EvidenceRank.weak,
                          label: Text('Weak'),
                        ),
                        ButtonSegment(
                          value: EvidenceRank.misleading,
                          label: Text('Misleading'),
                        ),
                      ],
                      selected: _answers[index] == null
                          ? <EvidenceRank>{}
                          : <EvidenceRank>{_answers[index]!},
                      onSelectionChanged: _submitted
                          ? null
                          : (selection) => setState(
                              () => _answers[index] = selection.first,
                            ),
                    ),
                    if (_submitted) ...[
                      const SizedBox(height: 10),
                      Text(
                        _answers[index] == clue.correct
                            ? 'Good call. This ranking matches the evidence.'
                            : 'Look again: this clue is ${clue.correct.name}.',
                        style: TextStyle(
                          color: _answers[index] == clue.correct
                              ? CurioColors.green
                              : CurioColors.coral,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (!_submitted)
            PrimaryButton(
              label: 'Close the case',
              icon: Icons.fact_check_rounded,
              onPressed: _submit,
            )
          else
            CurioCard(
              color: CurioColors.goldSoft,
              borderColor: CurioColors.gold,
              child: Column(
                children: [
                  Text(
                    'Case closed: $_score / ${_clues.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The weather record is strongest because it is measured, timestamped and independent. One footprint matters, but it cannot explain the whole event by itself.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '+70 XP · New discovery unlocked',
                    style: TextStyle(
                      color: CurioColors.tealDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
