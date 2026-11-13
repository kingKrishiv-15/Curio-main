import 'dart:convert';

import '../../../../core/services/minigame_service.dart';
import '../domain/second_opinion.dart';
import 'demo_puzzle.dart';

/// The real gateway. The server holds the answers, starts the clock when
/// the attempt row is created, hands back one pre-written reply per probe
/// and grades the single submission. Idempotency keys are derived from the
/// attempt, so a retried request returns the first verdict.
class ServerSecondOpinionGateway implements SecondOpinionGateway {
  ServerSecondOpinionGateway({MinigameService? service, this.date})
    : _service = service ?? MinigameService();

  final MinigameService _service;

  /// Null means "whatever day the server says it is".
  final DateTime? date;
  String? _attemptId;

  @override
  Future<SecondOpinionSession> open() async {
    final puzzle = date == null
        ? await _service.fetchTodaysPuzzle('second_opinion')
        : await _service.fetchPuzzle("second_opinion", date!);
    if (puzzle == null) {
      throw const SecondOpinionUnavailable(
        'Today\'s Second Opinion has not been published yet.',
      );
    }
    final opened = await _service.openSecondOpinion(puzzle.id);
    _attemptId = opened['attempt_id'] as String;
    final replies = Map<String, dynamic>.from(opened['replies'] as Map? ?? {});
    final verdict = opened['verdict'];
    return SecondOpinionSession(
      puzzle: SecondOpinionPuzzle.fromConfig(puzzle.config),
      secondsLeft: (opened['seconds_left'] as num?)?.toInt() ?? 0,
      replies: {
        for (final id in (opened['probes'] as List? ?? const []))
          if (Probe.byId('$id') != null)
            Probe.byId('$id')!: replies['$id'] as String? ?? '',
      },
      verdict: verdict == null
          ? null
          : SecondOpinionVerdict.fromJson(
              Map<String, dynamic>.from(verdict as Map),
            ),
    );
  }

  @override
  Future<String> ask(Probe probe) async {
    final verdict = await _service.submitMove(
      attemptId: _attemptId!,
      moveData: {'type': 'probe', 'probe': probe.id},
      idempotencyKey: '$_attemptId:probe:${probe.id}',
    );
    return verdict.data['reply'] as String? ?? '';
  }

  @override
  Future<SecondOpinionVerdict> submit(Set<String> claimIds) async {
    final verdict = await _service.submitMove(
      attemptId: _attemptId!,
      moveData: {'type': 'submit', 'claims': claimIds.toList()..sort()},
      idempotencyKey: '$_attemptId:submit',
    );
    return SecondOpinionVerdict.fromJson(verdict.data);
  }
}

/// Demo mode only: one fixed puzzle, graded on the device with the same
/// rules as the server. It is not in the daily schedule, so nothing about a
/// real day can be read out of the app.
class DemoSecondOpinionGateway implements SecondOpinionGateway {
  DemoSecondOpinionGateway({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final Map<String, dynamic> _data =
      jsonDecode(demoSecondOpinionJson) as Map<String, dynamic>;
  static Map<String, dynamic> get _answer =>
      _data['answer'] as Map<String, dynamic>;

  // Held for the life of the app, so leaving the page does not pause or
  // reset the clock, just as on the server.
  static DateTime? _startedAt;
  static final List<Probe> _asked = [];
  static SecondOpinionVerdict? _verdict;

  /// Starts the demo afresh (tests, and the screenshot tool).
  static void reset() {
    _startedAt = null;
    _asked.clear();
    _verdict = null;
  }

  SecondOpinionPuzzle get _puzzle =>
      SecondOpinionPuzzle.fromConfig(_data['public'] as Map<String, dynamic>);

  int get _secondsLeft {
    final elapsed = _now().difference(_startedAt!).inSeconds;
    return (_puzzle.seconds - elapsed).clamp(0, _puzzle.seconds);
  }

  String _reply(Probe probe) =>
      (_answer['replies'] as Map<String, dynamic>)[probe.id] as String;

  @override
  Future<SecondOpinionSession> open() async {
    _startedAt ??= _now();
    return SecondOpinionSession(
      puzzle: _puzzle,
      secondsLeft: _secondsLeft,
      replies: {for (final p in _asked) p: _reply(p)},
      verdict: _verdict,
    );
  }

  @override
  Future<String> ask(Probe probe) async {
    if (_verdict != null) throw StateError('Already submitted.');
    if (_asked.contains(probe)) return _reply(probe);
    if (_asked.length >= SecondOpinionPuzzle.maxProbes) {
      throw StateError('Only three probes may be asked.');
    }
    _asked.add(probe);
    return _reply(probe);
  }

  @override
  Future<SecondOpinionVerdict> submit(Set<String> claimIds) async {
    if (_verdict != null) return _verdict!;
    if (claimIds.length != SecondOpinionPuzzle.flagCount) {
      throw StateError('Flag exactly three claims.');
    }
    final flawed = _answer['flawed'] as Map<String, dynamic>;
    final exposes = _answer['exposes'] as Map<String, dynamic>;
    final hits = claimIds.where(flawed.containsKey).length;
    final good = _asked
        .where((p) => (exposes[p.id] as List? ?? const []).isNotEmpty)
        .length;
    final left = _secondsLeft;
    final score = scoreSecondOpinion(
      hits: hits,
      falseFlags: claimIds.length - hits,
      goodProbes: good,
      secondsLeft: left,
    );
    return _verdict = SecondOpinionVerdict.fromJson({
      'chosen': claimIds.toList(),
      'flawed': flawed,
      'probes': [for (final p in _asked) p.id],
      'good_probes': good,
      'seconds_left': left,
      'score': score.score,
      'breakdown': {
        'base': score.base,
        'penalty': score.penalty,
        'probes': score.probes,
        'time': score.time,
      },
    });
  }
}
