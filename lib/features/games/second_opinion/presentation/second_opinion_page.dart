import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/minigame_service.dart';
import '../../../../core/widgets/curio_clay.dart';
import '../../../../core/widgets/curio_ui.dart';
import '../../../../theme/curio_tokens.dart';
import '../../common/game_kit.dart';
import '../data/second_opinion_gateways.dart';
import '../domain/second_opinion.dart';

enum _Phase { loading, failed, brief, verdict, debrief }

/// The daily anchor game. One five minute clock runs across reading the
/// brief, asking follow-ups and flagging claims; it never pauses.
class SecondOpinionPage extends StatefulWidget {
  const SecondOpinionPage({this.gateway, super.key});

  /// Injected in tests. By default the server gateway is used when a
  /// learner is signed in, and the demo gateway otherwise.
  final SecondOpinionGateway? gateway;

  static const _rules = [
    'An AI wrote the brief. Exactly three of its claims do not hold up.',
    'You may ask up to three of six follow-up questions. Some expose a mistake and some tell you nothing.',
    'Then flag the three claims you do not trust and submit. You get one submission.',
    'The clock runs for five minutes from the moment you open the game and never pauses. Time left adds to your score.',
  ];

  @override
  State<SecondOpinionPage> createState() => _SecondOpinionPageState();
}

class _SecondOpinionPageState extends State<SecondOpinionPage> {
  late final SecondOpinionGateway _gateway =
      widget.gateway ??
      (MinigameService().isSignedIn
          ? ServerSecondOpinionGateway()
          : DemoSecondOpinionGateway());

  _Phase _phase = _Phase.loading;
  String? _error;
  SecondOpinionPuzzle? _puzzle;
  final Map<Probe, String> _replies = {};
  final Set<String> _flagged = {};
  SecondOpinionVerdict? _verdict;
  Probe? _asking;
  bool _submitting = false;
  int _secondsLeft = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final session = await _gateway.open();
      if (!mounted) return;
      setState(() {
        _puzzle = session.puzzle;
        _replies
          ..clear()
          ..addAll(session.replies);
        _secondsLeft = session.secondsLeft;
        _verdict = session.verdict;
        _phase = session.verdict == null ? _Phase.brief : _Phase.debrief;
      });
      if (session.verdict == null) _startClock();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error =
            error is SecondOpinionUnavailable || error is MinigameNotAvailable
            ? '$error'
            : 'Second Opinion could not be loaded. Check your connection and try again.';
      });
    }
  }

  void _startClock() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _ask(Probe probe) async {
    if (_asking != null ||
        _replies.containsKey(probe) ||
        _replies.length >= SecondOpinionPuzzle.maxProbes) {
      return;
    }
    setState(() => _asking = probe);
    try {
      final reply = await _gateway.ask(probe);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() => _replies[probe] = reply);
    } catch (_) {
      _say('That question could not be sent. Try again.');
    } finally {
      if (mounted) setState(() => _asking = null);
    }
  }

  void _toggle(String claimId) {
    setState(() {
      if (!_flagged.remove(claimId) &&
          _flagged.length < SecondOpinionPuzzle.flagCount) {
        _flagged.add(claimId);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || _flagged.length != SecondOpinionPuzzle.flagCount) return;
    setState(() => _submitting = true);
    try {
      final verdict = await _gateway.submit(_flagged);
      if (!mounted) return;
      _ticker?.cancel();
      awardDaily(context, 'second_opinion');
      setState(() {
        _verdict = verdict;
        _phase = _Phase.debrief;
      });
    } catch (_) {
      _say(
        'Your flags could not be sent. Nothing was submitted, so try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => CurioPage(
    title: 'Second Opinion',
    actions: const [HowToPlayButton(rules: SecondOpinionPage._rules)],
    child: switch (_phase) {
      _Phase.loading => const Center(child: CircularProgressIndicator()),
      _Phase.failed => _Failed(message: _error ?? '', onRetry: _open),
      _Phase.brief => _timed(_brief(context)),
      _Phase.verdict => _timed(_claims(context)),
      _Phase.debrief => _Debrief(puzzle: _puzzle!, verdict: _verdict!),
    },
  );

  Widget _timed(Widget child) => Column(
    children: [
      _Clock(secondsLeft: _secondsLeft, total: _puzzle!.seconds),
      Expanded(child: child),
    ],
  );

  Widget _brief(BuildContext context) {
    final puzzle = _puzzle!;
    final left = SecondOpinionPuzzle.maxProbes - _replies.length;
    return ListView(
      key: const Key('so_brief'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          'We asked an AI about ${puzzle.topic}. Here is what it said.',
          style: CurioTokens.bodySmall,
        ),
        const SizedBox(height: 12),
        CurioClay(
          raised: true,
          color: CurioTokens.surfaceRaised,
          padding: const EdgeInsets.all(24),
          child: Text(puzzle.brief, style: CurioTokens.body),
        ),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: Text(
            'Ask a follow-up',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          left == 0
              ? 'You have asked all three.'
              : left == 1
              ? '1 question left.'
              : '$left questions left.',
          key: const Key('so_probes_left'),
          style: CurioTokens.bodySmall,
        ),
        const SizedBox(height: 4),
        for (final probe in Probe.values)
          _ProbeRow(
            probe: probe,
            reply: _replies[probe],
            busy: _asking == probe,
            enabled: left > 0 && _asking == null,
            onAsk: () => _ask(probe),
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('so_to_verdict'),
          onPressed: () => setState(() => _phase = _Phase.verdict),
          child: const Text('Go to the claims'),
        ),
      ],
    );
  }

  Widget _claims(BuildContext context) {
    final puzzle = _puzzle!;
    final need = SecondOpinionPuzzle.flagCount - _flagged.length;
    return ListView(
      key: const Key('so_verdict'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Three of these do not hold up',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Flag three, then submit. You get one submission.',
          style: CurioTokens.bodySmall,
        ),
        const SizedBox(height: 4),
        for (final claim in puzzle.claims)
          _ClaimRow(
            claim: claim,
            flagged: _flagged.contains(claim.id),
            onTap: _submitting ? null : () => _toggle(claim.id),
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('so_submit'),
          onPressed: need == 0 && !_submitting ? _submit : null,
          child: Text(
            need == 0
                ? 'Submit'
                : need == 1
                ? 'Flag 1 more'
                : 'Flag $need more',
          ),
        ),
      ],
    );
  }
}

String _clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// The one countdown, pinned above both playing phases.
class _Clock extends StatelessWidget {
  const _Clock({required this.secondsLeft, required this.total});

  final int secondsLeft, total;

  @override
  Widget build(BuildContext context) {
    final out = secondsLeft <= 0;
    return Semantics(
      label: out
          ? 'Time is up. You can still submit, with no time bonus.'
          : '${_clockText(secondsLeft)} left',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Row(
          children: [
            Text(
              out ? '0:00, no time bonus' : _clockText(secondsLeft),
              key: const Key('so_timer'),
              style: CurioTokens.label.copyWith(
                color: secondsLeft <= 30
                    ? CurioTokens.wrong
                    : CurioTokens.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CurioTokens.radiusPill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : secondsLeft / total,
                  minHeight: 4,
                  color: secondsLeft <= 30
                      ? CurioTokens.wrong
                      : CurioTokens.accent,
                  backgroundColor: CurioTokens.surfaceRaised,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProbeRow extends StatelessWidget {
  const _ProbeRow({
    required this.probe,
    required this.reply,
    required this.busy,
    required this.enabled,
    required this.onAsk,
  });

  final Probe probe;
  final String? reply;
  final bool busy, enabled;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final asked = reply != null;
    final row = DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CurioTokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    probe.question,
                    style: CurioTokens.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: asked || enabled
                          ? CurioTokens.textPrimary
                          : CurioTokens.textSecondary,
                    ),
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (!asked && enabled)
                  const Icon(
                    Icons.add_rounded,
                    color: CurioTokens.textSecondary,
                  ),
              ],
            ),
            if (asked) ...[
              const SizedBox(height: 8),
              Text(
                reply!,
                key: Key('so_reply_${probe.id}'),
                style: CurioTokens.bodySmall.copyWith(
                  color: CurioTokens.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (asked || !enabled) return row;
    return Semantics(
      button: true,
      child: InkWell(
        key: Key('so_probe_${probe.id}'),
        onTap: onAsk,
        child: row,
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({
    required this.claim,
    required this.flagged,
    required this.onTap,
  });

  final Claim claim;
  final bool flagged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: flagged,
    child: InkWell(
      key: Key('so_claim_${claim.id}'),
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CurioTokens.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(
                flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                color: flagged ? CurioTokens.wrong : CurioTokens.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(claim.text, style: CurioTokens.body)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          key: const Key('so_error'),
          style: CurioTokens.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

/// Phase C: the score, the three claims that did not hold up, and for each
/// one the question that would have caught it.
class _Debrief extends StatelessWidget {
  const _Debrief({required this.puzzle, required this.verdict});

  final SecondOpinionPuzzle puzzle;
  final SecondOpinionVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final share = secondOpinionShare(puzzle.number, verdict);
    final text = {for (final c in puzzle.claims) c.id: c.text};
    final falseFlags = verdict.chosen.length - verdict.hits;
    return ListView(
      key: const Key('so_debrief'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        CurioClay(
          raised: true,
          color: CurioTokens.surfaceRaised,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                verdict.hits == 3
                    ? 'You caught all three'
                    : 'You caught ${verdict.hits} of 3',
                style: CurioTokens.label,
              ),
              const SizedBox(height: 8),
              Text(
                '${verdict.score}',
                key: const Key('so_score'),
                style: CurioTokens.display,
              ),
              const SizedBox(height: 16),
              _Line(
                'Flawed claims caught, ${verdict.hits}',
                '+${verdict.base}',
              ),
              _Line(
                'Clean claims flagged, $falseFlags',
                verdict.penalty == 0 ? '0' : '-${verdict.penalty}',
              ),
              _Line(
                'Probes that exposed a mistake, ${verdict.goodProbes}',
                '+${verdict.probeBonus}',
              ),
              _Line(
                'Time left, ${_clockText(verdict.secondsLeft)}',
                '+${verdict.timeBonus}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('so_copy'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: share));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Result copied. It gives nothing away.'),
                    ),
                  );
                },
                child: const Text('Copy result'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          share,
          key: const Key('so_share'),
          style: CurioTokens.bodySmall.copyWith(
            fontFamilyFallback: const [
              'Segoe UI Emoji',
              'Apple Color Emoji',
              'Noto Color Emoji',
            ],
          ),
        ),
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: Text(
            'The three that did not hold up',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final claim in verdict.flawed)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CurioTokens.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                key: Key('so_flaw_${claim.claimId}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${claim.flaw.label}. ${verdict.caught(claim) ? 'You flagged it.' : 'You missed it.'}',
                    style: CurioTokens.label.copyWith(
                      color: verdict.caught(claim)
                          ? CurioTokens.correct
                          : CurioTokens.wrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text[claim.claimId] ?? '',
                    style: CurioTokens.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    claim.why,
                    style: CurioTokens.bodySmall.copyWith(
                      color: CurioTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(verdict.lesson(claim), style: CurioTokens.bodySmall),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          key: const Key('so_done'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.points);

  final String label, points;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: CurioTokens.bodySmall)),
        Text(
          points,
          style: CurioTokens.bodySmall.copyWith(color: CurioTokens.textPrimary),
        ),
      ],
    ),
  );
}
