import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/verdict.dart';

/// Verdict: a claim, one piece of evidence, and a decision — does the
/// evidence support the claim, go against it, or can't it tell us yet? Five
/// a day, each followed by why and the thinking tool behind it.
class VerdictPage extends StatefulWidget {
  const VerdictPage({super.key, this.date});

  /// For tests; defaults to today.
  final DateTime? date;

  @override
  State<VerdictPage> createState() => _VerdictPageState();
}

class _VerdictPageState extends State<VerdictPage> {
  static const _id = 'verdict';
  static const _rules = [
    'Each round shows a claim — something someone says is true — and one piece of evidence.',
    'Decide what the evidence does: supports the claim, goes against it, or can’t tell us yet.',
    '“Can’t tell yet” is a real answer. Pick it when the evidence is missing something, like enough people or a fair comparison.',
    'Judge only what the evidence shows, not what you already think.',
    'Five claims a day. After each one, see why — and the thinking tool that cracks it.',
  ];
  static const _praise = [
    'Spot on!',
    'Nicely weighed!',
    'Sharp thinking!',
    'Exactly right!',
    'Well judged!',
  ];

  final _scroll = ScrollController();
  final _revealKey = GlobalKey();
  late VerdictGame _game = VerdictGame(verdictDailySet(_day));
  int _practiceShift = 0;
  bool _alreadyDone = false;
  bool _showResult = false;

  int get _day => DailyPick.dayNumber(widget.date);
  bool get _practice => _practiceShift > 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _answer(Verdict verdict) {
    final round = _game.round;
    if (round.answered) return;
    setState(() => round.pick(verdict));
    if (round.right) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    // Today's daily is done the moment its last claim has a verdict.
    if (_game.allAnswered && !_practice) {
      _alreadyDone = awardDaily(context, _id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bringRevealIntoView());
  }

  /// After an answer, scroll just enough to show the explanation and the
  /// Next button — or, if that's taller than the screen, its top.
  void _bringRevealIntoView() {
    final target = _revealKey.currentContext;
    if (!mounted || target == null || !_scroll.hasClients) return;
    final box = target.findRenderObject();
    final fits =
        box is RenderBox &&
        box.size.height <= _scroll.position.viewportDimension;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignmentPolicy: fits
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.explicit,
    );
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    setState(() {
      if (_game.isLast) {
        _showResult = true;
      } else {
        _game.next();
      }
    });
    _toTop();
  }

  void _practiceRound() {
    setState(() {
      _practiceShift++;
      _game = VerdictGame(verdictPracticeSet(_day, _practiceShift));
      _showResult = false;
    });
    _toTop();
  }

  String get _share =>
      'Curio · Verdict\n${_game.shareGrid}  ${_game.score}/${_game.rounds.length}';

  String _notice(VerdictRound round) {
    final finding = switch (round.item.verdict) {
      Verdict.supports => 'the evidence supports the claim',
      Verdict.against => 'the evidence goes against the claim',
      Verdict.cantTell => 'this evidence can’t settle it yet',
    };
    if (!round.right) return 'Not quite — $finding. Here’s why.';
    final praise = _praise[_game.current % _praise.length];
    return '$praise ${finding[0].toUpperCase()}${finding.substring(1)}.';
  }

  String get _resultTitle => switch (_game.score) {
    5 => 'Case closed — all five!',
    3 || 4 => 'Sharp thinking.',
    _ => 'Every case makes you sharper.',
  };

  @override
  Widget build(BuildContext context) {
    final round = _game.round;
    return CurioPage(
      title: 'Verdict',
      actions: const [HowToPlayButton(rules: _rules)],
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          GameHeader(
            eyebrow: _practice ? 'Practice round' : 'Daily evidence puzzle',
            title: _showResult ? 'The verdicts are in.' : 'Weigh the evidence',
            subtitle:
                'Read the claim, then the evidence. Does it back the claim up, knock it down — or leave us guessing?',
            chips: const [
              GameMetaChip(icon: Icons.schedule_rounded, label: '3 min'),
              GameMetaChip(
                icon: Icons.manage_search_rounded,
                label: 'Evidence',
              ),
            ],
            trailing: _RoundPips(game: _game),
          ),
          if (_practice) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: PracticeBadge(),
            ),
          ],
          const SizedBox(height: 16),
          if (!_showResult) ...[
            CurioFadeSlideIn(
              key: ValueKey('verdict_${_practiceShift}_${_game.current}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClaimCard(
                    claim: round.item.claim,
                    index: _game.current,
                    total: _game.rounds.length,
                  ),
                  const SizedBox(height: 10),
                  _EvidenceCard(evidence: round.item.evidence),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What does the evidence do?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final verdict in Verdict.values) ...[
              _AnswerButton(
                verdict: verdict,
                round: round,
                onPressed: () => _answer(verdict),
              ),
              const SizedBox(height: 10),
            ],
            if (round.answered)
              Column(
                key: _revealKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  GameNotice(
                    message: _notice(round),
                    tone: round.right
                        ? GameNoticeTone.good
                        : GameNoticeTone.bad,
                  ),
                  const SizedBox(height: 12),
                  _ExplanationCard(item: round.item),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    key: const Key('verdict_next'),
                    label: _game.isLast ? 'See result' : 'Next claim',
                    icon: _game.isLast
                        ? Icons.gavel_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
          ] else ...[
            SectionHeading(
              _practice ? 'Practice cases' : 'Today’s cases',
              subtitle: 'Each verdict, and the thinking tool behind it',
            ),
            const SizedBox(height: 12),
            for (final r in _game.rounds) _RecapTile(round: r),
            const SizedBox(height: 8),
            GameResultCard(
              title: _resultTitle,
              score: '${_game.score} / ${_game.rounds.length}',
              shareText: _share,
              xp: _practice ? null : gameRewards[_id]!.xp,
              alreadyDone: _alreadyDone,
              onPractice: _practiceRound,
              gameId: _id,
            ),
          ],
        ],
      ),
    );
  }
}

/// The claim, as a big pull-quote.
class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.index,
    required this.total,
  });

  final String claim;
  final int index, total;

  @override
  Widget build(BuildContext context) {
    final blue = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return GlassCard(
      radius: 24,
      tint: curioColor(
        context,
        CurioColors.blueSoft,
        CurioColorsLight.blueSoft,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 18, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              '“',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 58,
                height: 1,
                fontWeight: FontWeight.w600,
                color: blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'CLAIM ${index + 1} OF $total',
                  semanticsLabel: 'Claim ${index + 1} of $total',
                  style: TextStyle(
                    color: soft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  claim,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 1.22,
                    letterSpacing: -.4,
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

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.evidence});
  final String evidence;

  @override
  Widget build(BuildContext context) {
    final blue = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.manage_search_rounded, size: 18, color: blue),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'EVIDENCE',
                    semanticsLabel: 'Evidence',
                    style: TextStyle(
                      color: soft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(evidence, style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

IconData _verdictIcon(Verdict verdict) => switch (verdict) {
  Verdict.supports => Icons.thumb_up_alt_rounded,
  Verdict.against => Icons.thumb_down_alt_rounded,
  Verdict.cantTell => Icons.question_mark_rounded,
};

/// One of the three verdicts. Once the claim is judged, the right verdict
/// and the player's pick are marked with a tick or cross *and* words.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.verdict,
    required this.round,
    required this.onPressed,
  });

  final Verdict verdict;
  final VerdictRound round;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final answered = round.answered;
    final chosen = round.picked == verdict;
    final correct = round.item.verdict == verdict;
    final ink = curioColor(context, CurioColors.ink, CurioColorsLight.ink);
    final muted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    final onBright = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
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

    // Before judging, the themed clay button. After, it goes flat and a
    // clay body shows how each verdict fared; the ones that weren't in play
    // sink back as dents.
    final Color? fill, ring, tile;
    final Color tileIcon, text;
    final IconData icon;
    final String? status;
    if (!answered) {
      fill = null;
      ring = null;
      tile = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
      tileIcon = onBright;
      text = ink;
      icon = _verdictIcon(verdict);
      status = null;
    } else if (correct) {
      fill = curioColor(
        context,
        CurioColors.successSoft,
        CurioColorsLight.successSoft,
      );
      ring = success;
      tile = success;
      tileIcon = onBright;
      text = ink;
      icon = Icons.check_rounded;
      status = chosen ? 'Your verdict — right!' : 'The right verdict';
    } else if (chosen) {
      fill = curioColor(
        context,
        CurioColors.dangerSoft,
        CurioColorsLight.dangerSoft,
      );
      ring = danger;
      tile = danger;
      tileIcon = onBright;
      text = ink;
      icon = Icons.close_rounded;
      status = 'Your verdict — not this time';
    } else {
      fill = null;
      ring = null;
      tile = null;
      tileIcon = muted;
      text = muted;
      icon = _verdictIcon(verdict);
      status = null;
    }

    final button = OutlinedButton(
      key: Key('verdict_${verdict.name}'),
      onPressed: answered ? null : onPressed,
      style: OutlinedButton.styleFrom(
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: ink,
        disabledForegroundColor: text,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 38,
            child: CurioClay(
              radius: 19,
              color: tile,
              pressed: tile == null,
              child: Icon(icon, size: 21, color: tileIcon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  verdict.label,
                  style: TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    if (!answered) return button;
    return CurioClay(
      radius: 18,
      color: fill,
      outline: ring,
      pressed: ring == null,
      child: button,
    );
  }
}

class _ToolPill extends StatelessWidget {
  const _ToolPill({required this.tool});
  final ThinkingTool tool;

  @override
  Widget build(BuildContext context) {
    final blue = curioColor(context, CurioColors.blue, CurioColorsLight.blue);
    return Semantics(
      label: 'Thinking tool: ${tool.label}',
      excludeSemantics: true,
      child: CurioClay(
        radius: 99,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        color: curioColor(
          context,
          CurioColors.blueSoft,
          CurioColorsLight.blueSoft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_rounded, size: 14, color: blue),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                tool.label,
                style: TextStyle(
                  color: curioColor(
                    context,
                    CurioColors.ink,
                    CurioColorsLight.ink,
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.item});
  final VerdictItem item;

  @override
  Widget build(BuildContext context) {
    final gold = curioColor(
      context,
      CurioColors.saffron,
      CurioColorsLight.saffron,
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
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Why?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _ToolPill(tool: item.tool),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.explanation, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the end-of-day recap: the claim, how it went (icon and
/// words), the verdict and its thinking tool.
class _RecapTile extends StatelessWidget {
  const _RecapTile({required this.round});
  final VerdictRound round;

  @override
  Widget build(BuildContext context) {
    final right = round.right;
    final color = right
        ? curioColor(context, CurioColors.success, CurioColorsLight.success)
        : curioColor(context, CurioColors.danger, CurioColorsLight.danger);
    final soft = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final verdict = round.item.verdict.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SizedBox.square(
              dimension: 28,
              child: CurioClay(
                radius: 14,
                color: color,
                child: Icon(
                  right ? Icons.check_rounded : Icons.close_rounded,
                  size: 17,
                  color: curioColor(
                    context,
                    CurioColors.night,
                    CurioColorsLight.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.item.claim,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  right
                      ? 'Right — $verdict'
                      : 'Not quite — the verdict was “$verdict”, not “${round.picked?.label}”.',
                  style: TextStyle(color: soft, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                _ToolPill(tool: round.item.tool),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One pip per claim: a tick or cross once judged, a ring for the one in
/// play. Screen readers hear the progress in words instead.
class _RoundPips extends StatelessWidget {
  const _RoundPips({required this.game});
  final VerdictGame game;

  @override
  Widget build(BuildContext context) {
    final total = game.rounds.length;
    final onBright = curioColor(
      context,
      CurioColors.night,
      CurioColorsLight.ink,
    );
    return Semantics(
      label: game.allAnswered
          ? '${game.score} of $total right'
          : 'Claim ${game.current + 1} of $total, ${game.score} right so far',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !game.rounds[i].answered
                    ? Colors.transparent
                    : game.rounds[i].right
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
                border: game.rounds[i].answered
                    ? null
                    : Border.all(
                        width: 2,
                        color: i == game.current
                            ? curioColor(
                                context,
                                CurioColors.coral,
                                CurioColorsLight.coral,
                              )
                            : curioColor(
                                context,
                                CurioColors.outline,
                                CurioColorsLight.outline,
                              ),
                      ),
              ),
              child: game.rounds[i].answered
                  ? Icon(
                      game.rounds[i].right
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 11,
                      color: onBright,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
