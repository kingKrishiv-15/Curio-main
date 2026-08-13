import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/curio_state.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/widgets/curio_ui.dart';

class _LinkGroup {
  const _LinkGroup(this.title, this.detail, this.words, this.color);

  final String title;
  final String detail;
  final List<String> words;
  final Color color;
}

const _groups = <_LinkGroup>[
  _LinkGroup('Rocky planets', 'Worlds with a solid, rocky surface', [
    'MERCURY',
    'VENUS',
    'EARTH',
    'MARS',
  ], CurioColors.gold),
  _LinkGroup('String family', 'Instruments played with strings', [
    'VIOLIN',
    'VIOLA',
    'CELLO',
    'HARP',
  ], CurioColors.teal),
  _LinkGroup('Gemstones', 'Minerals prized for colour and rarity', [
    'RUBY',
    'SAPPHIRE',
    'EMERALD',
    'OPAL',
  ], CurioColors.coral),
  _LinkGroup('World rivers', 'Major rivers from four continents', [
    'NILE',
    'AMAZON',
    'GANGES',
    'THAMES',
  ], CurioColors.frost),
];

const _board = <String>[
  'MERCURY',
  'VIOLIN',
  'RUBY',
  'NILE',
  'AMAZON',
  'VENUS',
  'SAPPHIRE',
  'CELLO',
  'EMERALD',
  'EARTH',
  'GANGES',
  'HARP',
  'MARS',
  'OPAL',
  'VIOLA',
  'THAMES',
];

class LinkLabPage extends StatefulWidget {
  const LinkLabPage({super.key});

  @override
  State<LinkLabPage> createState() => _LinkLabPageState();
}

class _LinkLabPageState extends State<LinkLabPage> {
  final Set<String> _selected = <String>{};
  final List<_LinkGroup> _solved = <_LinkGroup>[];
  int _mistakesLeft = 4;
  String? _message;
  bool _rewardGranted = false;

  bool get _complete => _solved.length == _groups.length;

  void _toggle(String word) {
    if (_complete || _solved.any((group) => group.words.contains(word))) return;
    HapticFeedback.selectionClick();
    setState(() {
      _message = null;
      if (!_selected.remove(word)) {
        if (_selected.length < 4) _selected.add(word);
      }
    });
  }

  void _submit() {
    if (_selected.length != 4) {
      setState(() => _message = 'Choose exactly four tiles that share a link.');
      return;
    }
    final match = _groups.where(
      (group) =>
          !_solved.contains(group) &&
          group.words.toSet().containsAll(_selected),
    );
    if (match.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _solved.add(match.first);
        _selected.clear();
        _message = 'Connection found — ${match.first.title}.';
      });
      if (_complete && !_rewardGranted) {
        _rewardGranted = true;
        CurioScope.of(context).completeActivity(
          id: CurioState.dailyActivityId('link_lab'),
          xp: 90,
          skill: 'Reasoning',
          factId: 'classification_science',
        );
      }
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _mistakesLeft = (_mistakesLeft - 1).clamp(0, 4);
      _selected.clear();
      _message = _mistakesLeft == 0
          ? 'Fresh eyes help. Use a hint, then try a new combination.'
          : 'Not the link — those words belong in different groups.';
    });
  }

  void _hint() {
    final remaining = _groups.firstWhere((group) => !_solved.contains(group));
    setState(
      () => _message =
          'Hint: one group is about ${remaining.detail.toLowerCase()}.',
    );
  }

  void _share() {
    const marks = ['🟨', '🟩', '🟪', '🟦'];
    final result =
        'Curio · Link Lab\n${marks.take(_solved.length).join()}\n'
        '${4 - _mistakesLeft} mistakes · Knowledge connected';
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Spoiler-free result copied')));
  }

  @override
  Widget build(BuildContext context) {
    final solvedWords = _solved.expand((group) => group.words).toSet();
    return CurioPage(
      title: 'Link Lab',
      actions: [
        IconButton(
          tooltip: 'Get a hint',
          onPressed: _complete ? null : _hint,
          icon: const Icon(Icons.lightbulb_outline_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const CurioEyebrow('Daily knowledge puzzle'),
          const SizedBox(height: 6),
          Text(
            _complete ? 'Brilliantly connected.' : 'Find the hidden links',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          const Text(
            'Create four groups of four. Each group shares one precise connection.',
            style: TextStyle(color: CurioColors.navyMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const GameMetaChip(
                icon: Icons.schedule_rounded,
                label: '3–5 min',
              ),
              const SizedBox(width: 15),
              const GameMetaChip(
                icon: Icons.psychology_alt_rounded,
                label: 'Categorisation',
              ),
              const Spacer(),
              Semantics(
                label: '$_mistakesLeft mistakes remaining',
                child: Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _mistakesLeft
                            ? CurioColors.coral
                            : CurioColors.creamDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._solved.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: group.color.withValues(alpha: .3)),
                ),
                child: Column(
                  children: [
                    Text(
                      group.title.toUpperCase(),
                      style: TextStyle(
                        color: group.color == CurioColors.gold
                            ? const Color(0xFF8B6411)
                            : group.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.words.join(' · '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CurioColors.navySoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_complete)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 24) / 4;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _board
                      .where((word) => !solvedWords.contains(word))
                      .map((word) {
                        final selected = _selected.contains(word);
                        return SizedBox(
                          width: width,
                          height: 70,
                          child: Material(
                            color: selected
                                ? CurioColors.coral
                                : CurioColors.surface,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              key: Key('link_$word'),
                              onTap: () => _toggle(word),
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: selected
                                        ? CurioColors.coral
                                        : CurioColors.creamDeep,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : CurioColors.navy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                );
              },
            ),
          if (_message != null) ...[
            const SizedBox(height: 13),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Container(
                key: ValueKey(_message),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: CurioColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: CurioColors.coral,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(_message!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_complete) ...[
            CurioCard(
              color: CurioColors.greenSoft,
              borderColor: CurioColors.green.withValues(alpha: .3),
              child: const Row(
                children: [
                  ProgressRing(
                    value: 1,
                    color: CurioColors.green,
                    child: Icon(Icons.check_rounded, color: CurioColors.green),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+90 XP earned',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Classification discovery unlocked',
                          style: TextStyle(
                            color: CurioColors.navyMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Copy my result',
              icon: Icons.ios_share_rounded,
              onPressed: _share,
              color: CurioColors.green,
            ),
          ] else
            PrimaryButton(
              label: _selected.length == 4
                  ? 'Check connection'
                  : 'Select ${4 - _selected.length} more',
              icon: Icons.hub_rounded,
              onPressed: _selected.length == 4 ? _submit : null,
            ),
        ],
      ),
    );
  }
}
