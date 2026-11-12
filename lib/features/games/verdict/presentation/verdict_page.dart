import 'package:flutter/material.dart';
import 'package:curio/theme/curio_tokens.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_motion.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../common/game_kit.dart';
import '../../common/game_rewards.dart';
import '../domain/verdict.dart';

/// Verdict: a claim, one piece of evidence, and a decision, does the
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
    'Each round shows a claim, something someone says is true, and one piece of evidence.',
    'Decide what the evidence does: supports the claim, goes against it, or can’t tell us yet.',
    '“Can’t tell yet” is a real answer. Pick it when the evidence is missing something, like enough people or a fair comparison.',
    'Judge only what the evidence shows, not what you already think.',
    'Five claims a day. After each one, see why, and the thinking tool that cracks it.',
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
  /// Next button, or, if that's taller than the screen, its top.
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
          : CurioTokens.slow,
      curve: CurioTokens.curve,
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
      'Curio Verdict\n${_game.shareGrid}  ${_game.score}/${_game.rounds.length}';

  String _notice(VerdictRound round) {
    final finding = switch (round.item.verdict) {
      Verdict.supports => 'the evidence supports the claim',
      Verdict.against => 'the evidence goes against the claim',
      Verdict.cantTell => 'this evidence can’t settle it yet',
    };
    if (!round.right) return 'Here $finding.';
    return 'You judged it correctly: $finding.';
  }

  String get _resultTitle => switch (_game.score) {
    5 => 'Case closed, all five!',
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GameHeader(
            title: _showResult ? 'The verdicts are in.' : 'Weigh the evidence',
            subtitle:
                'Read the claim, then the evidence. Does it back the claim up, knock it down, or leave us guessing?',
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
                  const SizedBox(height: 12),
                  _EvidenceCard(evidence: round.item.evidence),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'What does the evidence do?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final verdict in Verdict.values) ...[
              _AnswerButton(
                verdict: verdict,
                round: round,
                onPressed: () => _answer(verdict),
              ),
              const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
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
    final soft = CurioTokens.textSecondary;
    return GlassCard(
      radius: CurioTokens.radiusCard,
      tint: CurioTokens.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Claim ${index + 1} of $total',
                  semanticsLabel: 'Claim ${index + 1} of $total',
                  style: TextStyle(
                    color: soft,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  claim,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    height: 1.22,
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
    final blue = CurioTokens.tintLogic;
    final soft = CurioTokens.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GlassCard(
        radius: CurioTokens.radiusCard,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.manage_search_rounded, size: 18, color: blue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Evidence',
                    semanticsLabel: 'Evidence',
                    style: TextStyle(
                      color: soft,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(evidence, style: const TextStyle(fontSize: 14, height: 1.45)),
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
    final ink = CurioTokens.textPrimary;
    final muted = CurioTokens.textSecondary;
    final onBright = CurioTokens.base;
    final success = CurioTokens.correct;
    final danger = CurioTokens.wrong;

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
      tile = CurioTokens.tintLogic;
      tileIcon = onBright;
      text = ink;
      icon = _verdictIcon(verdict);
      status = null;
    } else if (correct) {
      fill = CurioTokens.surfaceRaised;
      ring = success;
      tile = success;
      tileIcon = onBright;
      text = ink;
      icon = Icons.check_rounded;
      status = chosen ? 'Your verdict, right!' : 'The right verdict';
    } else if (chosen) {
      fill = CurioTokens.surfaceRaised;
      ring = danger;
      tile = danger;
      tileIcon = onBright;
      text = ink;
      icon = Icons.close_rounded;
      status = 'Your verdict, not this time';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CurioTokens.radiusCard),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 38,
            child: CurioClay(
              radius: CurioTokens.radiusCard,
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
                  const SizedBox(height: 4),
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
      radius: CurioTokens.radiusCard,
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
    final blue = CurioTokens.tintLogic;
    return Semantics(
      label: 'Thinking tool: ${tool.label}',
      excludeSemantics: true,
      child: CurioClay(
        radius: CurioTokens.radiusPill,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: CurioTokens.surfaceRaised,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_rounded, size: 14, color: blue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tool.label,
                style: TextStyle(
                  color: CurioTokens.textPrimary,
                  fontSize: 13,
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
    final gold = CurioTokens.tintMaths;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
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
    final color = right ? CurioTokens.correct : CurioTokens.wrong;
    final soft = CurioTokens.textSecondary;
    final verdict = round.item.verdict.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox.square(
              dimension: 28,
              child: CurioClay(
                radius: CurioTokens.radiusCard,
                color: color,
                child: Icon(
                  right ? Icons.check_rounded : Icons.close_rounded,
                  size: 17,
                  color: CurioTokens.base,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  right
                      ? 'Right, $verdict'
                      : 'Not quite, the verdict was “$verdict”, not “${round.picked?.label}”.',
                  style: TextStyle(color: soft, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
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
    final onBright = CurioTokens.base;
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
                    ? CurioTokens.correct
                    : CurioTokens.wrong,
                border: game.rounds[i].answered
                    ? null
                    : Border.all(
                        width: 2,
                        color: i == game.current
                            ? CurioTokens.wrong
                            : CurioTokens.border,
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
