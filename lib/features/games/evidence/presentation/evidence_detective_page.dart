import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/evidence_cases.dart';

class EvidenceDetectivePage extends StatefulWidget {
  const EvidenceDetectivePage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<EvidenceDetectivePage> createState() => _EvidenceDetectivePageState();
}

class _EvidenceDetectivePageState extends State<EvidenceDetectivePage> {
  static const _game = 'evidence_garden';
  static const _rules = [
    'Read the case, then rank each clue before deciding what happened.',
    'Strong: specific and checkable — measured, written down at the time, or something you can see — and it points one way.',
    'Weak: probably true, but it fits lots of explanations, so it can’t settle the case alone.',
    'Misleading: sounds convincing but points the wrong way — a rumour, a guess about a person, or a superstition.',
    'A case doesn’t always have one of each. Close the case to see how you did.',
  ];

  late EvidenceCase _case = _newCase();
  final Map<int, EvidenceRank> _ranks = {};
  bool _submitted = false;
  int _practiceRound = 0;
  bool _alreadyDone = false;

  bool get _practice => _practiceRound > 0;
  int get _score => _case.score(_ranks);

  EvidenceCase _newCase() => evidenceCaseFor(
    DailyPick.dayNumber(widget.date),
    practice: _practiceRound,
  );

  void _rank(int clue, EvidenceRank rank) {
    if (_submitted) return;
    HapticFeedback.selectionClick();
    setState(() => _ranks[clue] = rank);
  }

  void _submit() {
    if (_submitted || _ranks.length != _case.clues.length) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitted = true);
    if (!_practice) _alreadyDone = awardDaily(context, _game);
  }

  void _startPractice() {
    setState(() {
      _practiceRound++;
      _case = _newCase();
      _ranks.clear();
      _submitted = false;
    });
  }

  String get _share {
    final marks = [
      for (var i = 0; i < _case.clues.length; i++)
        _ranks[i] == _case.clues[i].rank ? '🟩' : '🟥',
    ].join();
    return 'Curio · Evidence Detective\n'
        'CASE ${_case.number.toString().padLeft(3, '0')}  $marks  '
        '$_score/${_case.clues.length}';
  }

  @override
  Widget build(BuildContext context) {
    final left = _case.clues.length - _ranks.length;
    return CurioPage(
      title: 'Evidence Detective',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice case' : 'Daily evidence case',
            title: _submitted ? 'Case closed.' : 'Weigh the evidence',
            subtitle:
                'Rank each clue as strong, weak or misleading before you decide what happened.',
            chips: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '4–6 min',
              ),
              const GameMetaChip(
                icon: Icons.manage_search_rounded,
                label: 'Evidence',
              ),
              GameMetaChip(
                icon: Icons.fact_check_outlined,
                label: '${_ranks.length} of ${_case.clues.length} ranked',
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
          _CaseCard(evidenceCase: _case),
          const SizedBox(height: 16),
          for (var i = 0; i < _case.clues.length; i++) ...[
            _ClueCard(
              index: i,
              clue: _case.clues[i],
              rank: _ranks[i],
              submitted: _submitted,
              onRank: (rank) => _rank(i, rank),
            ),
            const SizedBox(height: 12),
          ],
          if (!_submitted)
            PrimaryButton(
              key: const Key('evidence_submit'),
              label: left == 0
                  ? 'Close the case'
                  : 'Rank ${left == 1 ? '1 more clue' : '$left more clues'}',
              icon: Icons.fact_check_rounded,
              onPressed: left == 0 ? _submit : null,
            )
          else ...[
            _SummaryCard(summary: _case.summary),
            const SizedBox(height: 14),
            GameResultCard(
              title: _score == _case.clues.length
                  ? 'Case cracked!'
                  : _score >= 2
                  ? 'Sharp detective work.'
                  : 'Every case trains your eye.',
              score: '$_score / ${_case.clues.length}',
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

Color _rankColour(BuildContext context, EvidenceRank rank) => switch (rank) {
  EvidenceRank.strong => curioColor(
    context,
    CurioColors.success,
    CurioColorsLight.success,
  ),
  EvidenceRank.weak => curioColor(
    context,
    CurioColors.saffron,
    CurioColorsLight.saffron,
  ),
  EvidenceRank.misleading => curioColor(
    context,
    CurioColors.danger,
    CurioColorsLight.danger,
  ),
};

IconData _rankIcon(EvidenceRank rank) => switch (rank) {
  EvidenceRank.strong => Icons.verified_rounded,
  EvidenceRank.weak => Icons.help_outline_rounded,
  EvidenceRank.misleading => Icons.warning_amber_rounded,
};

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.evidenceCase});
  final EvidenceCase evidenceCase;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: dark
            ? CurioColors.heroGradient
            : CurioColorsLight.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evidenceCase.heading,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              evidenceCase.question,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClueCard extends StatelessWidget {
  const _ClueCard({
    required this.index,
    required this.clue,
    required this.rank,
    required this.submitted,
    required this.onRank,
  });

  final int index;
  final EvidenceClue clue;
  final EvidenceRank? rank;
  final bool submitted;
  final ValueChanged<EvidenceRank> onRank;

  @override
  Widget build(BuildContext context) {
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final blue = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final right = rank == clue.rank;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900),
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
          const SizedBox(height: 8),
          Text(clue.detail, style: TextStyle(color: muted, height: 1.45)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in EvidenceRank.values)
                _RankPill(
                  key: Key('rank_${index}_${option.name}'),
                  rank: option,
                  selected: rank == option,
                  onTap: submitted ? null : () => onRank(option),
                ),
            ],
          ),
          if (submitted) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 20,
                  color: right
                      ? curioColor(
                          context,
                          CurioColors.success,
                          CurioColorsLight.success,
                        )
                      : curioColor(
                          context,
                          CurioColors.danger,
                          CurioColorsLight.danger,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        right
                            ? 'Good call — ${clue.rank.label.toLowerCase()}.'
                            : 'You said ${rank!.label.toLowerCase()} — it’s ${clue.rank.label.toLowerCase()}.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        clue.why,
                        style: TextStyle(color: muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RankPill extends StatelessWidget {
  const _RankPill({
    required this.rank,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final EvidenceRank rank;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _rankColour(context, rank);
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final outline = curioColor(
      context,
      CurioColors.outline,
      CurioColorsLight.outline,
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: 'Rank as ${rank.label}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: .2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected ? color : outline,
                width: selected ? 2 : 1.3,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The tick, not just the colour, says which one is chosen.
                Icon(
                  selected ? Icons.check_rounded : _rankIcon(rank),
                  size: 18,
                  color: selected ? ink : color,
                ),
                const SizedBox(width: 6),
                Text(
                  rank.label,
                  style: TextStyle(
                    color: ink,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    final blue = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_search_rounded, color: blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What the evidence shows',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(summary, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
