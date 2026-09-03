import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/minigame_service.dart';
import '../../../../core/theme/curio_colors.dart';
import '../../../../core/theme/curio_colors_light.dart';
import '../../../../core/widgets/curio_ui.dart';

/// Loophole: a statement that is technically true but misleading. Tap the one
/// word or phrase doing the deceptive work. Three statements, two guesses
/// each.
///
/// Everything that decides right or wrong happens server-side - this screen
/// sends a tapped token index and renders whatever verdict comes back. It
/// never holds the answer, so there is nothing here to read out of the
/// binary or the network log.
class LoopholePage extends StatefulWidget {
  const LoopholePage({super.key, this.service});

  /// Injectable for tests; defaults to the real service.
  final MinigameService? service;

  @override
  State<LoopholePage> createState() => _LoopholePageState();
}

class _LoopholePageState extends State<LoopholePage> {
  static const _type = 'loophole';

  late final MinigameService _service = widget.service ?? MinigameService();

  bool _loading = true;
  String? _error;
  DailyPuzzle? _puzzle;
  PuzzleAttempt? _attempt;
  int _streak = 0;

  // Per-round view state, rebuilt from the server's attempt state on resume.
  int _round = 0;
  int _guessesUsed = 0;
  List<int> _marks = const [];
  int? _revealedTarget;
  String? _explanation;
  int? _lastTapped;
  bool _submitting = false;
  bool _finished = false;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> get _rounds {
    final raw = _puzzle?.config['rounds'] as List? ?? const [];
    return raw.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  List<String> get _tokens {
    if (_round >= _rounds.length) return const [];
    final raw = _rounds[_round]['tokens'] as List? ?? const [];
    return raw.map((t) => t as String).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_service.isSignedIn) {
        throw const MinigameNotAvailable(
          'Sign in to play the daily puzzle. Everyone gets the same one.',
        );
      }

      final today = DateTime.now();
      final puzzle = await _service.fetchPuzzle(_type, today);
      if (puzzle == null) {
        throw const MinigameNotAvailable('No Loophole published for today yet.');
      }

      final attempt = await _service.startAttempt(puzzle.id);
      final streak = await _service.currentStreak(_type);

      if (!mounted) return;
      setState(() {
        _puzzle = puzzle;
        _attempt = attempt;
        _streak = streak;
        // Resume exactly where the server says this player left off.
        _round = (attempt.state['round'] as int?) ?? 0;
        _guessesUsed = (attempt.state['guesses'] as int?) ?? 0;
        _marks = ((attempt.state['marks'] as List?) ?? const [])
            .map((m) => m as int)
            .toList();
        _finished = attempt.isFinished;
        _finalScore = attempt.score;
        _loading = false;
      });
    } on MinigameNotAvailable catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load today\'s puzzle. $error';
        _loading = false;
      });
    }
  }

  Future<void> _tap(int tokenIndex) async {
    if (_submitting || _finished || _revealedTarget != null) return;
    final attempt = _attempt;
    if (attempt == null) return;

    HapticFeedback.selectionClick();
    setState(() {
      _submitting = true;
      _lastTapped = tokenIndex;
    });

    try {
      final verdict = await _service.submitMove(
        attemptId: attempt.id,
        moveData: {'round': _round, 'token_index': tokenIndex},
        // Stable per (round, guess): a retry replays rather than re-spends.
        idempotencyKey: '${attempt.id}:r$_round:g${_guessesUsed + 1}',
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _guessesUsed = (verdict.data['guesses_used'] as int?) ?? _guessesUsed + 1;
        _marks = verdict.marks;
        if (verdict.isRoundOver) {
          _revealedTarget = verdict.target;
          _explanation = verdict.explanation;
        }
        if (verdict.isFinished) {
          _finished = true;
          _finalScore = verdict.score;
        }
      });

      if (verdict.isCorrect) {
        HapticFeedback.mediumImpact();
      }
      if (verdict.isFinished) {
        // Only a completed day counts toward the streak.
        await _service.recordStreak(_type, DateTime.now());
        final streak = await _service.currentStreak(_type);
        if (mounted) setState(() => _streak = streak);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'That guess did not save. $error';
      });
    }
  }

  void _nextRound() {
    setState(() {
      _round += 1;
      _guessesUsed = 0;
      _revealedTarget = null;
      _explanation = null;
      _lastTapped = null;
    });
  }

  String get _shareText {
    final date = _puzzle?.date ?? DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final squares = _marks
        .map((m) => m == 2 ? '🟩' : (m == 1 ? '🟨' : '⬛'))
        .join();
    // Squares only: how it went, never which words were the catch.
    return 'Curio Loophole · ${months[date.month - 1]} ${date.day}\n'
        '$squares  ${_finalScore ?? 0}/6';
  }

  @override
  Widget build(BuildContext context) {
    return CurioPage(
      title: 'Loophole',
      actions: [
        IconButton(
          tooltip: 'How to play',
          onPressed: _showHowToPlay,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _buildBoard(context),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: curioColor(context, CurioColors.surface, CurioColorsLight.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to play', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...[
              'Every statement is technically true - and still misleading.',
              'Tap the one word or phrase doing the deceptive work.',
              'Two guesses per statement, three statements a day.',
              'Everyone gets the same three. Compare without spoiling.',
            ].map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: curioColor(context, CurioColors.coral, CurioColorsLight.coral),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final rounds = _rounds;
    final showingResult = _finished && _round >= rounds.length - 1 && _revealedTarget == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const CurioEyebrow('Daily reasoning puzzle'),
        const SizedBox(height: 6),
        Text(
          _finished ? 'Nicely spotted.' : 'Find the catch',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 7),
        Text(
          'Each statement is true. One word is doing something sneaky.',
          style: TextStyle(color: curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const GameMetaChip(icon: Icons.schedule_rounded, label: '2 min'),
            const SizedBox(width: 12),
            GameMetaChip(
              icon: Icons.local_fire_department_rounded,
              label: '$_streak day streak',
            ),
            const Spacer(),
            _RoundPips(total: rounds.length, marks: _marks, current: _round),
          ],
        ),
        const SizedBox(height: 18),
        if (_finished) ...[
          _ResultCard(
            score: _finalScore ?? 0,
            outOf: rounds.length * 2,
            shareText: _shareText,
          ),
          if (_explanation != null) ...[
            const SizedBox(height: 14),
            _ExplanationCard(text: _explanation!),
          ],
        ] else ...[
          _StatementCard(
            statement: rounds.isEmpty ? '' : rounds[_round]['statement'] as String,
            tokens: _tokens,
            revealedTarget: _revealedTarget,
            lastTapped: _lastTapped,
            guessesUsed: _guessesUsed,
            enabled: !_submitting && _revealedTarget == null,
            onTap: _tap,
          ),
          if (_explanation != null) ...[
            const SizedBox(height: 14),
            _ExplanationCard(text: _explanation!),
            const SizedBox(height: 14),
            PrimaryButton(
              label: _round + 1 >= rounds.length ? 'See result' : 'Next statement',
              onPressed: _round + 1 >= rounds.length ? _load : _nextRound,
            ),
          ],
        ],
        if (showingResult) const SizedBox(height: 8),
      ],
    );
  }
}

/// The statement itself, as tappable tokens. Once a round closes, the target
/// is marked green and a wrong final guess is marked red - the two states a
/// player needs to learn from.
class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.statement,
    required this.tokens,
    required this.revealedTarget,
    required this.lastTapped,
    required this.guessesUsed,
    required this.enabled,
    required this.onTap,
  });

  final String statement;
  final List<String> tokens;
  final int? revealedTarget;
  final int? lastTapped;
  final int guessesUsed;
  final bool enabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 18, color: curioColor(context, CurioColors.saffron, CurioColorsLight.saffron)),
              const SizedBox(width: 6),
              Text(
                guessesUsed == 0
                    ? 'Two guesses'
                    : (guessesUsed == 1 ? 'One guess left' : 'Round over'),
                style: TextStyle(
                  color: curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Statement: $statement. Tap the misleading word.',
            child: Wrap(
              spacing: 7,
              runSpacing: 9,
              children: [
                for (var i = 0; i < tokens.length; i++)
                  _TokenChip(
                    label: tokens[i],
                    state: _stateFor(i),
                    onTap: enabled ? () => onTap(i) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TokenState _stateFor(int index) {
    if (revealedTarget == index) return _TokenState.correct;
    if (revealedTarget != null && lastTapped == index) return _TokenState.wrong;
    if (revealedTarget == null && lastTapped == index) return _TokenState.missed;
    return _TokenState.idle;
  }
}

enum _TokenState { idle, correct, wrong, missed }

class _TokenChip extends StatefulWidget {
  const _TokenChip({required this.label, required this.state, this.onTap});

  final String label;
  final _TokenState state;
  final VoidCallback? onTap;

  @override
  State<_TokenChip> createState() => _TokenChipState();
}

class _TokenChipState extends State<_TokenChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Reduce-motion players get the colour change without the squash.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scale = _pressed && !reduceMotion ? 0.94 : 1.0;

    final (bg, fg, border) = switch (widget.state) {
      _TokenState.correct => (curioColor(context, CurioColors.successSoft, CurioColorsLight.successSoft), curioColor(context, CurioColors.success, CurioColorsLight.success), curioColor(context, CurioColors.success, CurioColorsLight.success)),
      _TokenState.wrong => (curioColor(context, CurioColors.dangerSoft, CurioColorsLight.dangerSoft), curioColor(context, CurioColors.danger, CurioColorsLight.danger), curioColor(context, CurioColors.danger, CurioColorsLight.danger)),
      _TokenState.missed => (curioColor(context, CurioColors.saffronSoft, CurioColorsLight.saffronSoft), curioColor(context, CurioColors.saffron, CurioColorsLight.saffron), curioColor(context, CurioColors.saffron, CurioColorsLight.saffron)),
      _TokenState.idle => (curioColor(context, CurioColors.surfaceMuted, CurioColorsLight.surfaceMuted), curioColor(context, CurioColors.ink, CurioColorsLight.ink), curioColor(context, CurioColors.outlineSoft, CurioColorsLight.outlineSoft)),
    };

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduceMotion ? 0 : 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Text(
            widget.label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: curioColor(context, CurioColors.saffron, CurioColorsLight.saffron)),
              const SizedBox(width: 7),
              Text('Why', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 9),
          Text(text, style: TextStyle(color: curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft), height: 1.5)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.score, required this.outOf, required this.shareText});

  final int score;
  final int outOf;
  final String shareText;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$score / $outOf', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Text(
            'Come back tomorrow for three more.',
            style: TextStyle(color: curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: curioColor(context, CurioColors.surfaceMuted, CurioColorsLight.surfaceMuted),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(shareText, style: const TextStyle(height: 1.6, fontSize: 15)),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Copy result',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Result copied - no spoilers in it')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 34, color: curioColor(context, CurioColors.inkMuted, CurioColorsLight.inkMuted)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: curioColor(context, CurioColors.inkSoft, CurioColorsLight.inkSoft), height: 1.5),
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// One pip per statement: filled as each is finished, coloured by how it
/// went, so progress through the day is readable at a glance.
class _RoundPips extends StatelessWidget {
  const _RoundPips({required this.total, required this.marks, required this.current});

  final int total;
  final List<int> marks;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Statement ${current + 1} of $total',
      child: Row(
        children: List.generate(total, (index) {
          final Color color;
          if (index < marks.length) {
            color = switch (marks[index]) {
              2 => curioColor(context, CurioColors.success, CurioColorsLight.success),
              1 => curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
              _ => curioColor(context, CurioColors.danger, CurioColorsLight.danger),
            };
          } else {
            color = index == current ? curioColor(context, CurioColors.coral, CurioColorsLight.coral) : curioColor(context, CurioColors.outlineSoft, CurioColorsLight.outlineSoft);
          }
          return Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          );
        }),
      ),
    );
  }
}
