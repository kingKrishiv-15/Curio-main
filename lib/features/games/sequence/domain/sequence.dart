/// Sequence: numbers appear one at a time, linked by a hidden rule. After
/// each reveal the player either commits to the next number or pays to see
/// another — cracking it early is worth far more.
///
/// The fairness problem is ambiguity: from 2, 4 alone, "add 2" and "double"
/// both fit, and a player could be right but marked wrong. So guessing only
/// opens once the visible numbers pin the answer down: [opensAt] finds the
/// first point where every common reading a player might reasonably make
/// predicts the same next number. Tests run it over the whole bank, so an
/// ambiguous sequence can't ship.
class SequenceRule {
  const SequenceRule({
    required this.name,
    required this.explanation,
    required this.terms,
  });

  final String name;
  final String explanation;

  /// Long enough for [opensAt] plus a few paid reveals.
  final List<int> terms;
}

/// Next-term predictions from every simple rule that fits [prefix]. A rule
/// with n free choices needs at least n numbers to be a plausible reading;
/// the less natural "alternating steps" reading also needs one number of
/// confirmation before it counts.
Set<int> plausibleNextTerms(List<int> prefix) {
  final out = <int>{};
  final n = prefix.length;
  if (n < 2) return out;
  final diffs = [for (var i = 1; i < n; i++) prefix[i] - prefix[i - 1]];

  // Add the same amount each time.
  if (diffs.every((d) => d == diffs.first)) out.add(prefix.last + diffs.first);

  // Multiply by the same amount (whole number or exact fraction).
  if (prefix.first != 0 && prefix.every((t) => t != 0)) {
    final num = prefix[1], den = prefix[0];
    final fits = [
      for (var i = 1; i < n; i++) prefix[i] * den == prefix[i - 1] * num,
    ].every((ok) => ok);
    if (fits && (prefix.last * num) % den == 0) {
      out.add(prefix.last * num ~/ den);
    }
  }

  if (n >= 3) {
    // Differences grow by the same amount (squares, triangular numbers…).
    final second = [for (var i = 1; i < diffs.length; i++) diffs[i] - diffs[i - 1]];
    if (second.every((s) => s == second.first)) {
      out.add(prefix.last + diffs.last + second.first);
    }

    // Multiply then add: next = p × previous + q, with whole p and q.
    final d0 = prefix[1] - prefix[0];
    if (d0 != 0 && (prefix[2] - prefix[1]) % d0 == 0) {
      final p = (prefix[2] - prefix[1]) ~/ d0;
      final q = prefix[1] - p * prefix[0];
      final fits = [
        for (var i = 1; i < n; i++) prefix[i] == p * prefix[i - 1] + q,
      ].every((ok) => ok);
      if (fits) out.add(p * prefix.last + q);
    }

    // Add the two numbers before.
    final fib = [
      for (var i = 2; i < n; i++) prefix[i] == prefix[i - 1] + prefix[i - 2],
    ].every((ok) => ok);
    if (fib) out.add(prefix[n - 1] + prefix[n - 2]);
  }

  // Two steps taking turns (+5, −2, +5, −2…), once confirmed.
  if (n >= 4) {
    final alternating = [
      for (var i = 2; i < diffs.length; i++) diffs[i] == diffs[i - 2],
    ].every((ok) => ok);
    if (alternating) out.add(prefix.last + diffs[diffs.length - 2]);
  }
  return out;
}

/// The fewest numbers to show before guessing is fair: from there on, every
/// plausible reading agrees with the true next term. Null if that never
/// happens within the authored terms (the sequence is rejected).
int? opensAt(List<int> terms) {
  for (var k = 3; k < terms.length; k++) {
    var fair = true;
    for (var j = k; j < terms.length; j++) {
      final predictions = plausibleNextTerms(terms.sublist(0, j));
      if (predictions.any((p) => p != terms[j])) {
        fair = false;
        break;
      }
    }
    if (fair) return k;
  }
  return null;
}

/// One round: guess the next number, or buy another before committing.
class SequenceRound {
  SequenceRound(this.rule) : shown = opensAt(rule.terms)!;

  static const startPoints = 100;
  static const revealCost = 30;
  static const wrongCost = 20;
  static const minPoints = 10;

  final SequenceRule rule;
  int shown;
  int points = startPoints;
  bool solved = false;
  bool failed = false;
  final List<int> wrongGuesses = [];

  bool get over => solved || failed;
  int get target => rule.terms[shown];
  List<int> get visible => rule.terms.sublist(0, shown);

  /// Keep at least one number hidden, and don't sell evidence that would
  /// leave nothing to win.
  bool get canReveal =>
      !over && shown < rule.terms.length - 1 && points - revealCost >= minPoints;

  void reveal() {
    if (!canReveal) throw StateError('No more numbers to reveal.');
    shown++;
    points -= revealCost;
    wrongGuesses.clear();
  }

  /// True when right. A wrong guess costs points; running out ends the round.
  bool guess(int value) {
    if (over) throw StateError('This round is over.');
    if (value == target) {
      solved = true;
      points = points.clamp(minPoints, startPoints);
      return true;
    }
    wrongGuesses.add(value);
    points -= wrongCost;
    if (points < minPoints) {
      failed = true;
      points = 0;
    }
    return false;
  }
}

List<int> _build(int count, int Function(int index, List<int> sofar) next) {
  final terms = <int>[];
  for (var i = 0; i < count; i++) {
    terms.add(next(i, terms));
  }
  return terms;
}

/// The bank. Lengths are generous; [opensAt] decides how many start visible.
final sequenceBank = <SequenceRule>[
  SequenceRule(
    name: 'Add 7',
    explanation: 'Each number is 7 more than the one before.',
    terms: _build(8, (i, t) => i == 0 ? 4 : t.last + 7),
  ),
  SequenceRule(
    name: 'Double, then take away 1',
    explanation: 'Double each number and subtract 1: 3 → 5 → 9 → 17.',
    terms: _build(8, (i, t) => i == 0 ? 3 : t.last * 2 - 1),
  ),
  SequenceRule(
    name: 'Square numbers',
    explanation: '1 × 1, 2 × 2, 3 × 3… The gaps grow by 2 each time: 3, 5, 7, 9.',
    terms: _build(8, (i, t) => (i + 1) * (i + 1)),
  ),
  SequenceRule(
    name: 'Add the two before',
    explanation:
        'Each number is the sum of the two before it — the Fibonacci pattern, found in sunflower seeds and pinecones.',
    terms: _build(9, (i, t) => i == 0 ? 2 : i == 1 ? 3 : t[i - 1] + t[i - 2]),
  ),
  SequenceRule(
    name: 'Multiply by 3',
    explanation: 'Each number is three times the one before.',
    terms: _build(8, (i, t) => i == 0 ? 1 : t.last * 3),
  ),
  SequenceRule(
    name: 'Triangular numbers',
    explanation:
        'Add 2, then 3, then 4… These are the numbers of dots you can stack in a triangle.',
    terms: _build(8, (i, t) => (i + 1) * (i + 2) ~/ 2),
  ),
  SequenceRule(
    name: '× 2, × 3, × 4…',
    explanation:
        'Multiply by 2, then 3, then 4, and so on. Mathematicians call these factorials.',
    terms: _build(8, (i, t) => i == 0 ? 1 : t.last * (i + 1)),
  ),
  SequenceRule(
    name: 'Add 5, take away 2',
    explanation: 'Two steps take turns: add 5, then subtract 2, again and again.',
    terms: _build(8, (i, t) => i == 0 ? 10 : t.last + (i.isOdd ? 5 : -2)),
  ),
  SequenceRule(
    name: 'Take away 6',
    explanation: 'Each number is 6 less than the one before.',
    terms: _build(8, (i, t) => i == 0 ? 60 : t.last - 6),
  ),
  SequenceRule(
    name: 'Double, then add 2',
    explanation: 'Double each number and add 2: 1 → 4 → 10 → 22.',
    terms: _build(8, (i, t) => i == 0 ? 1 : t.last * 2 + 2),
  ),
  SequenceRule(
    name: 'Cube numbers',
    explanation: '1 × 1 × 1, 2 × 2 × 2, 3 × 3 × 3… They grow fast.',
    terms: _build(8, (i, t) => (i + 1) * (i + 1) * (i + 1)),
  ),
  SequenceRule(
    name: 'Halve it',
    explanation: 'Each number is half the one before.',
    terms: _build(8, (i, t) => i == 0 ? 384 : t.last ~/ 2),
  ),
];
