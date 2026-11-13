/// Second Opinion: an AI-written brief with exactly three claims that do
/// not hold up. Ask up to three follow-up questions, flag three claims,
/// submit once. Nothing here calls a model: every word was written ahead
/// of time and arrives as one daily puzzle.
library;

/// The fixed follow-up questions. They never change, so players learn which
/// kind of mistake each one catches.
enum Probe {
  source('source', 'How do you know that?'),
  current('current', 'Is that still true?'),
  example('example', 'Give me a specific example.'),
  counter('counter', 'What is the strongest argument against this?'),
  scope('scope', 'Did you answer what I actually asked?'),
  unsure('unsure', 'What are you unsure about here?');

  const Probe(this.id, this.question);
  final String id;
  final String question;

  static Probe? byId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// The five ways a claim can fail.
enum Flaw {
  fabricated('fabricated', 'Fabricated'),
  confidentGuess('confident_guess', 'Confident guess'),
  outOfDate('out_of_date', 'Out of date'),
  scopeDrift('scope_drift', 'Scope drift'),
  cherryPicked('cherry_picked', 'Cherry-picked');

  const Flaw(this.id, this.label);
  final String id;
  final String label;

  static Flaw byId(String? id) =>
      values.firstWhere((f) => f.id == id, orElse: () => Flaw.fabricated);
}

class Claim {
  const Claim(this.id, this.text);
  final String id;
  final String text;
}

/// What the client is allowed to know before it submits.
class SecondOpinionPuzzle {
  const SecondOpinionPuzzle({
    required this.number,
    required this.topic,
    required this.brief,
    required this.claims,
    this.seconds = totalSeconds,
  });

  factory SecondOpinionPuzzle.fromConfig(Map<String, dynamic> config) =>
      SecondOpinionPuzzle(
        number: (config['number'] as num?)?.toInt() ?? 0,
        topic: config['topic'] as String? ?? '',
        brief: config['brief'] as String? ?? '',
        claims: [
          for (final c in (config['claims'] as List? ?? const []))
            Claim((c as Map)['id'] as String, c['text'] as String),
        ],
        seconds: (config['seconds'] as num?)?.toInt() ?? totalSeconds,
      );

  static const totalSeconds = 300;
  static const maxProbes = 3;
  static const flagCount = 3;

  final int number;
  final String topic;
  final String brief;
  final List<Claim> claims;
  final int seconds;
}

/// One flawed claim, as the debrief shows it.
class FlawedClaim {
  const FlawedClaim({
    required this.claimId,
    required this.flaw,
    required this.catcher,
    required this.why,
  });
  final String claimId;
  final Flaw flaw;

  /// The probe that would have exposed it.
  final Probe catcher;
  final String why;
}

/// The graded result of the one submission.
class SecondOpinionVerdict {
  const SecondOpinionVerdict({
    required this.chosen,
    required this.flawed,
    required this.asked,
    required this.goodProbes,
    required this.secondsLeft,
    required this.base,
    required this.penalty,
    required this.probeBonus,
    required this.timeBonus,
    required this.score,
  });

  factory SecondOpinionVerdict.fromJson(Map<String, dynamic> json) {
    final flawed = Map<String, dynamic>.from(json['flawed'] as Map? ?? {});
    final breakdown = Map<String, dynamic>.from(
      json['breakdown'] as Map? ?? {},
    );
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    return SecondOpinionVerdict(
      chosen: {for (final c in (json['chosen'] as List? ?? const [])) '$c'},
      flawed: [
        for (final e in flawed.entries)
          FlawedClaim(
            claimId: e.key,
            flaw: Flaw.byId((e.value as Map)['type'] as String?),
            catcher:
                Probe.byId((e.value as Map)['probe'] as String?) ??
                Probe.source,
            why: (e.value as Map)['why'] as String? ?? '',
          ),
      ]..sort((a, b) => a.claimId.compareTo(b.claimId)),
      asked: [
        for (final p in (json['probes'] as List? ?? const []))
          if (Probe.byId('$p') != null) Probe.byId('$p')!,
      ],
      goodProbes: n(json['good_probes']),
      secondsLeft: n(json['seconds_left']),
      base: n(breakdown['base']),
      penalty: n(breakdown['penalty']),
      probeBonus: n(breakdown['probes']),
      timeBonus: n(breakdown['time']),
      score: n(json['score']),
    );
  }

  final Set<String> chosen;
  final List<FlawedClaim> flawed;
  final List<Probe> asked;
  final int goodProbes;
  final int secondsLeft;
  final int base, penalty, probeBonus, timeBonus, score;

  int get hits => flawed.where((f) => chosen.contains(f.claimId)).length;
  bool caught(FlawedClaim claim) => chosen.contains(claim.claimId);

  /// The teaching line for one flawed claim: what was asked against what
  /// would have caught it.
  String lesson(FlawedClaim claim) {
    final kind = claim.flaw.label.toLowerCase();
    final catcher = '"${claim.catcher.question}"';
    if (asked.contains(claim.catcher)) {
      return 'You asked $catcher, and that is the question that exposes a $kind claim.';
    }
    if (asked.isEmpty) {
      return 'You asked nothing. $catcher would have exposed this $kind claim.';
    }
    final first = '"${asked.first.question}"';
    return 'You asked $first. This claim was $kind, and $catcher would have exposed it.';
  }
}

/// The scoring rule, shared by the demo gateway and the tests. The server
/// applies the same rule in validate_second_opinion_move.
({int base, int penalty, int probes, int time, int score}) scoreSecondOpinion({
  required int hits,
  required int falseFlags,
  required int goodProbes,
  required int secondsLeft,
}) {
  final base = 400 * hits;
  final penalty = 150 * falseFlags;
  final probes = goodProbes >= 1 ? 200 + 100 * (goodProbes - 1) : 0;
  final time = secondsLeft.clamp(0, 300);
  final total = base - penalty + probes + time;
  return (
    base: base,
    penalty: penalty,
    probes: probes,
    time: time,
    score: total < 0 ? 0 : total,
  );
}

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// The spoiler-safe share text: which claims were flagged is not in it.
String secondOpinionShare(int number, SecondOpinionVerdict v) {
  final marks = '${'🟩' * v.hits}${'⬜' * (3 - v.hits)}';
  final probes = v.goodProbes == 1
      ? '1 good probe'
      : '${v.goodProbes} good probes';
  return 'Second Opinion #$number\n'
      '$marks  ${v.hits}/3   🔍 $probes   ${_clock(v.secondsLeft)} left';
}

/// Where a session stands when the page opens (fresh or resumed).
class SecondOpinionSession {
  const SecondOpinionSession({
    required this.puzzle,
    required this.secondsLeft,
    this.replies = const {},
    this.verdict,
  });
  final SecondOpinionPuzzle puzzle;
  final int secondsLeft;

  /// Replies to probes already asked, in the order they were asked.
  final Map<Probe, String> replies;

  /// Set when today's attempt is already finished.
  final SecondOpinionVerdict? verdict;
}

class SecondOpinionUnavailable implements Exception {
  const SecondOpinionUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// How the page talks to whatever holds the answers. The server gateway is
/// the real one; the demo gateway exists so the app can be shown without an
/// account.
abstract class SecondOpinionGateway {
  Future<SecondOpinionSession> open();
  Future<String> ask(Probe probe);
  Future<SecondOpinionVerdict> submit(Set<String> claimIds);
}
