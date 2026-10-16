import 'dart:math';

import '../../sequence/domain/sequence.dart';

/// Pattern Forge: three quick pattern questions a day, each a different kind,
/// so it never repeats the Sequence game's "type the next number":
///
/// 1. **What comes next?** Pick the next number from four.
/// 2. **Which rule?** Pick the one rule (of four) that makes the pattern.
/// 3. **Repair it.** One number is wrong: find it.
///
/// Everything is generated from the date. Fairness leans on Sequence's own
/// checker: a "next" question only shows numbers once every plausible reading
/// ([plausibleNextTerms], [opensAt]) agrees on the answer, and a "repair"
/// pattern is only used when fixing the wrong number is the *only* single
/// change that makes it follow a plausible rule.
enum RuleKind {
  add,
  multiply,
  divide,
  steps,
  squares,
  triangular,
  twoBefore,
  alternate,
  doublePlus,
}

/// One rule family with its numbers filled in, e.g. "add 4" or "add 5, then
/// take away 2, taking turns".
class PatternRule {
  const PatternRule(this.kind, [this.a = 0, this.b = 0]);

  final RuleKind kind;

  /// add: the step · multiply/divide: the factor · steps: first step and how
  /// much it grows · alternate: the two steps · doublePlus: × a, then + b.
  final int a, b;

  /// Starting numbers the rule needs before it can carry on.
  int get seeds => kind == RuleKind.twoBefore ? 2 : 1;

  /// Whether this reads as a real, distinct rule (no "add 0" or "× 1").
  bool get sensible => switch (kind) {
    RuleKind.add => a != 0,
    RuleKind.multiply || RuleKind.divide => a >= 2,
    RuleKind.steps => a > 0 && b > 0,
    RuleKind.alternate => a > 0 && b != 0 && a != b,
    RuleKind.doublePlus => a >= 2 && b != 0 && b.abs() <= 5,
    _ => true,
  };

  /// [length] numbers that follow this rule from [start], or null if it
  /// can't start there (division that isn't exact, a non-square start…).
  List<int>? from(List<int> start, int length) {
    if (start.length < seeds) return null;
    switch (kind) {
      case RuleKind.squares:
        final r = _root(start.first);
        if (r == null) return null;
        return [for (var k = 0; k < length; k++) (r + k) * (r + k)];
      case RuleKind.triangular:
        final n = _triangleIndex(start.first);
        if (n == null) return null;
        return [for (var k = 0; k < length; k++) (n + k) * (n + k + 1) ~/ 2];
      default:
    }
    final t = start.sublist(0, seeds);
    while (t.length < length) {
      final i = t.length;
      final prev = t[i - 1];
      final int? next = switch (kind) {
        RuleKind.add => prev + a,
        RuleKind.multiply => prev * a,
        RuleKind.divide => prev % a == 0 ? prev ~/ a : null,
        RuleKind.steps => prev + a + (i - 1) * b,
        RuleKind.twoBefore => prev + t[i - 2],
        RuleKind.alternate => prev + (i.isOdd ? a : b),
        RuleKind.doublePlus => prev * a + b,
        RuleKind.squares || RuleKind.triangular => null,
      };
      if (next == null) return null;
      t.add(next);
    }
    return t.sublist(0, length);
  }

  /// Whether this rule, started from the first number(s), makes exactly
  /// [terms].
  bool fits(List<int> terms) {
    final made = from(terms, terms.length);
    if (made == null) return false;
    for (var i = 0; i < terms.length; i++) {
      if (made[i] != terms[i]) return false;
    }
    return true;
  }

  String get description => switch (kind) {
    RuleKind.add => a >= 0 ? 'Add $a each time' : 'Take away ${-a} each time',
    RuleKind.multiply =>
      a == 2 ? 'Double each time' : 'Multiply by $a each time',
    RuleKind.divide => a == 2 ? 'Halve each time' : 'Divide by $a each time',
    RuleKind.steps => 'Add $a, then ${a + b}, then ${a + 2 * b}…',
    RuleKind.squares => 'Square numbers (1, 4, 9, 16…)',
    RuleKind.triangular => 'Triangle numbers (1, 3, 6, 10…)',
    RuleKind.twoBefore => 'Add the two numbers before',
    RuleKind.alternate =>
      'Add $a, then ${b > 0 ? 'add $b' : 'take away ${-b}'}, taking turns',
    RuleKind.doublePlus =>
      '${a == 2 ? 'Double' : 'Multiply by $a'}, then '
          '${b > 0 ? 'add $b' : 'take away ${-b}'}',
  };

  /// How the number at [i] is made, e.g. "7 + 4 = 11" or "4 × 4 = 16".
  String step(List<int> t, int i) => switch (kind) {
    RuleKind.add => '${t[i - 1]} ${_signed(a)} = ${t[i]}',
    RuleKind.multiply => '${t[i - 1]} × $a = ${t[i]}',
    RuleKind.divide => '${t[i - 1]} ÷ $a = ${t[i]}',
    RuleKind.steps => '${t[i - 1]} ${_signed(a + (i - 1) * b)} = ${t[i]}',
    RuleKind.squares => '${_root(t[i])} × ${_root(t[i])} = ${t[i]}',
    RuleKind.triangular => '${t[i - 1]} + ${_triangleIndex(t[i])} = ${t[i]}',
    RuleKind.twoBefore => '${t[i - 2]} + ${t[i - 1]} = ${t[i]}',
    RuleKind.alternate => '${t[i - 1]} ${_signed(i.isOdd ? a : b)} = ${t[i]}',
    RuleKind.doublePlus => '${t[i - 1]} × $a ${_signed(b)} = ${t[i]}',
  };

  @override
  bool operator ==(Object other) =>
      other is PatternRule &&
      other.kind == kind &&
      other.a == a &&
      other.b == b;

  @override
  int get hashCode => Object.hash(kind, a, b);

  @override
  String toString() => description;
}

String _signed(int n) => n >= 0 ? '+ $n' : '− ${-n}';

int? _root(int n) {
  if (n < 1) return null;
  final r = sqrt(n).round();
  return r * r == n ? r : null;
}

int? _triangleIndex(int n) {
  for (var k = 1; k * (k + 1) ~/ 2 <= n; k++) {
    if (k * (k + 1) ~/ 2 == n) return k;
  }
  return null;
}

/// Whether [terms] follows one of the simple rules a player might read into
/// it — the same readings Sequence uses to keep guessing fair.
bool followsPlausibleRule(List<int> terms) =>
    terms.length >= 4 &&
    plausibleNextTerms(terms.sublist(0, terms.length - 1)).contains(terms.last);

/// For each position of [terms], the other values that would make the whole
/// list follow a plausible rule if that one number alone were changed.
/// Positions that can't be repaired are left out.
Map<int, Set<int>> singleRepairs(List<int> terms) {
  final out = <int, Set<int>>{};
  for (var i = 0; i < terms.length; i++) {
    for (final v in _candidatesAt(terms, i)) {
      if (v == terms[i]) continue;
      final fixed = List.of(terms)..[i] = v;
      if (followsPlausibleRule(fixed)) (out[i] ??= <int>{}).add(v);
    }
  }
  return out;
}

/// Every value position [i] could take for [s] to follow one of the rule
/// families in [plausibleNextTerms]. Each family is fixed by three
/// neighbouring numbers, so it's extended from a run of three that skips [i].
/// Needs at least six numbers and no two neighbours equal.
Set<int> _candidatesAt(List<int> s, int i) {
  assert(s.length >= 6);
  final a = i >= 3 ? 0 : i + 1;
  final x = s[a], y = s[a + 1], z = s[a + 2];
  final t = i - a; // steps from the run's start, may be negative
  final out = <int>{};

  // Same step each time.
  out.add(x + t * (y - x));

  // Same multiplier each time (a whole number or an exact fraction).
  if (x != 0 && y != 0) {
    int? cur = x;
    for (var k = 0; k < t.abs() && cur != null; k++) {
      if (t > 0) {
        cur = (cur * y) % x == 0 ? cur * y ~/ x : null;
      } else {
        cur = (cur * x) % y == 0 ? cur * x ~/ y : null;
      }
    }
    if (cur != null) out.add(cur);
  }

  // Steps that grow by the same amount.
  out.add(x + t * (y - x) + t * (t - 1) ~/ 2 * ((z - y) - (y - x)));

  // Multiply then add: next = p × previous + q.
  final d0 = y - x;
  if (d0 != 0 && (z - y) % d0 == 0) {
    final p = (z - y) ~/ d0, q = y - p * x;
    int? cur = x;
    for (var k = 0; k < t.abs() && cur != null; k++) {
      if (t > 0) {
        cur = p * cur + q;
      } else {
        cur = p != 0 && (cur - q) % p == 0 ? (cur - q) ~/ p : null;
      }
    }
    if (cur != null) out.add(cur);
  }

  // Add the two before, run forwards or backwards from x, y.
  {
    var lo = x, hi = y; // values at positions k, k + 1
    var k = a;
    while (k > i) {
      final before = hi - lo;
      hi = lo;
      lo = before;
      k--;
    }
    while (k + 1 < i) {
      final after = lo + hi;
      lo = hi;
      hi = after;
      k++;
    }
    out.add(k == i ? lo : hi);
  }

  // Two steps taking turns: step at (j - a) even is y - x, odd is z - y.
  int stepAt(int j) => (j - a).isEven ? y - x : z - y;
  var v = x;
  if (i < a) {
    for (var j = a - 1; j >= i; j--) {
      v -= stepAt(j);
    }
  } else {
    for (var j = a; j < i; j++) {
      v += stepAt(j);
    }
  }
  out.add(v);
  return out;
}

enum ForgeKind { next, rule, repair }

sealed class ForgeQuestion {
  const ForgeQuestion(this.rule, this.terms);

  final PatternRule rule;

  /// The pattern, all correct — for the explanation.
  final List<int> terms;

  ForgeKind get kind;

  /// The working: how each number after the first is made.
  List<String> get steps => [
    for (var i = rule.seeds; i < terms.length; i++) rule.step(terms, i),
  ];
}

/// Pick the number that comes next.
class NextQuestion extends ForgeQuestion {
  const NextQuestion(super.rule, super.terms, this.shown, this.options);

  final List<int> shown;
  final List<int> options;

  int get answer => terms[shown.length];

  @override
  ForgeKind get kind => ForgeKind.next;
}

/// Pick the one rule that makes the pattern.
class RuleQuestion extends ForgeQuestion {
  const RuleQuestion(super.rule, super.terms, this.options);

  final List<PatternRule> options;

  List<int> get shown => terms;
  int get answer => options.indexOf(rule);

  @override
  ForgeKind get kind => ForgeKind.rule;
}

/// Find the one number that breaks the pattern.
class RepairQuestion extends ForgeQuestion {
  const RepairQuestion(super.rule, super.terms, this.shown, this.wrongIndex);

  /// The pattern with one number changed.
  final List<int> shown;
  final int wrongIndex;

  int get correctValue => terms[wrongIndex];

  @override
  ForgeKind get kind => ForgeKind.repair;
}

/// One day's three questions: next, rule, repair — each from a different
/// rule family.
class ForgeDay {
  const ForgeDay(this.questions);

  final List<ForgeQuestion> questions;

  /// Shown numbers and answers stay small enough for mental maths.
  static const maxValue = 500;

  factory ForgeDay.forDay(int day) {
    final random = Random(day * 7919 + 104729);
    final families = List.of(RuleKind.values)..shuffle(random);
    final questions = <ForgeQuestion>[];
    for (final type in ForgeKind.values) {
      ForgeQuestion? made;
      for (var f = 0; made == null; f++) {
        if (f > families.length * 20) {
          throw StateError('No fair ${type.name} question for day $day');
        }
        final kind = families[f % families.length];
        if (questions.any((q) => q.rule.kind == kind)) continue;
        for (var attempt = 0; attempt < 12 && made == null; attempt++) {
          final (rule, start) = _draw(kind, random);
          made = switch (type) {
            ForgeKind.next => _next(rule, start, random),
            ForgeKind.rule => _ruleQuestion(rule, start, random),
            ForgeKind.repair => _repair(rule, start, random),
          };
        }
      }
      questions.add(made);
    }
    return ForgeDay(questions);
  }

  static int _between(Random r, int lo, int hi) => lo + r.nextInt(hi - lo + 1);

  /// A rule from [kind] with random, kid-sized numbers, and its start.
  static (PatternRule, List<int>) _draw(RuleKind kind, Random r) =>
      switch (kind) {
        RuleKind.add =>
          r.nextBool()
              ? (PatternRule(kind, _between(r, 2, 11)), [_between(r, 1, 30)])
              : (PatternRule(kind, -_between(r, 2, 9)), [_between(r, 60, 99)]),
        RuleKind.multiply =>
          r.nextInt(3) == 0
              ? (PatternRule(kind, 3), [_between(r, 1, 2)])
              : (PatternRule(kind, 2), [_between(r, 1, 7)]),
        RuleKind.divide => (PatternRule(kind, 2), [64 * _between(r, 1, 7)]),
        RuleKind.steps => (
          PatternRule(kind, _between(r, 1, 4), _between(r, 1, 3)),
          [_between(r, 1, 12)],
        ),
        RuleKind.squares => (
          PatternRule(kind),
          [pow(_between(r, 1, 6), 2).toInt()],
        ),
        RuleKind.triangular => () {
          final n = _between(r, 1, 4);
          return (PatternRule(kind), [n * (n + 1) ~/ 2]);
        }(),
        RuleKind.twoBefore => () {
          final first = _between(r, 1, 4);
          return (PatternRule(kind), [first, first + _between(r, 1, 4)]);
        }(),
        RuleKind.alternate =>
          r.nextBool()
              ? () {
                  final up = _between(r, 3, 8);
                  return (
                    PatternRule(kind, up, -_between(r, 1, up - 1)),
                    [_between(r, 1, 20)],
                  );
                }()
              : () {
                  final up = _between(r, 1, 6);
                  var other = _between(r, 1, 6);
                  if (other == up) other = up % 6 + 1;
                  return (PatternRule(kind, up, other), [_between(r, 1, 20)]);
                }(),
        RuleKind.doublePlus => switch (r.nextInt(5)) {
          0 => (PatternRule(kind, 2, 1), [_between(r, 1, 5)]),
          1 => (PatternRule(kind, 2, -1), [_between(r, 2, 6)]),
          2 => (PatternRule(kind, 2, 2), [_between(r, 1, 4)]),
          3 => (PatternRule(kind, 3, 1), [_between(r, 1, 2)]),
          _ => (PatternRule(kind, 3, -1), [_between(r, 1, 3)]),
        },
      };

  static bool _small(Iterable<int> values) =>
      values.every((v) => v >= 0 && v <= maxValue);

  static NextQuestion? _next(PatternRule rule, List<int> start, Random r) {
    final all = rule.from(start, 7);
    if (all == null) return null;
    final opens = opensAt(all);
    if (opens == null || opens > 5) return null;
    final count = max(opens, 4);
    final shown = all.sublist(0, count);
    final answer = all[count];
    if (!_small([...shown, answer])) return null;
    final readings = plausibleNextTerms(shown);
    if (readings.length != 1 || readings.single != answer) return null;

    final last = shown.last, before = shown[count - 2];
    final gap = last - before;
    final tempting = <int>[
      last + gap, // carries on the last step unchanged
      answer + 1,
      answer - 1,
      last + (shown[1] - shown[0]), // repeats the first step
      answer + (answer - last), // one step too far
      last + before, // adds the two before
      last * 2,
      answer + 2,
      answer - 2,
      answer + 10,
      answer - 10,
    ];
    final seen = <int>{answer, ...shown};
    final pool = [
      for (final t in tempting)
        if (t >= 0 && t <= maxValue * 2 && seen.add(t)) t,
    ];
    if (pool.length < 3) return null;
    final picks = (pool.take(5).toList()..shuffle(r)).take(3);
    final options = [answer, ...picks]..shuffle(r);
    return NextQuestion(rule, all.sublist(0, count + 1), shown, options);
  }

  static RuleQuestion? _ruleQuestion(
    PatternRule rule,
    List<int> start,
    Random r,
  ) {
    final shown = rule.from(start, 5);
    if (shown == null || !_small(shown) || !rule.fits(shown)) return null;
    final g1 = shown[1] - shown[0], g2 = shown[2] - shown[1];
    final tempting = <PatternRule>[
      PatternRule(RuleKind.add, g1),
      PatternRule(RuleKind.steps, g1, 1),
      PatternRule(RuleKind.multiply, 2),
      const PatternRule(RuleKind.twoBefore),
      PatternRule(RuleKind.add, g2),
      PatternRule(RuleKind.alternate, g1, g2),
      PatternRule(RuleKind.steps, g1, 2),
      PatternRule(RuleKind.doublePlus, 2, shown[1] - 2 * shown[0]),
      PatternRule(RuleKind.multiply, 3),
      PatternRule(RuleKind.add, g1 + 1),
      const PatternRule(RuleKind.squares),
      const PatternRule(RuleKind.triangular),
    ];
    final seen = <String>{rule.description};
    final pool = [
      for (final t in tempting)
        if (t.sensible && !t.fits(shown) && seen.add(t.description)) t,
    ];
    if (pool.length < 3) return null;
    final picks = (pool.take(6).toList()..shuffle(r)).take(3);
    final options = [rule, ...picks]..shuffle(r);
    return RuleQuestion(rule, shown, options);
  }

  static RepairQuestion? _repair(PatternRule rule, List<int> start, Random r) {
    final terms = rule.from(start, 6);
    if (terms == null || !_small(terms) || !followsPlausibleRule(terms)) {
      return null;
    }
    final positions = [1, 2, 3, 4, 5]..shuffle(r);
    for (final w in positions) {
      final offsets = [1, -1, 2, -2, 3, -3]..shuffle(r);
      for (final o in offsets) {
        final shown = List.of(terms)..[w] = terms[w] + o;
        if (!isFairRepair(shown, w, terms[w])) continue;
        return RepairQuestion(rule, terms, shown, w);
      }
    }
    return null;
  }

  /// The checks a repair pattern must pass: nothing fits as it stands, and
  /// putting [correct] back at [wrongIndex] is the only single change that
  /// makes it follow a plausible rule.
  static bool isFairRepair(List<int> shown, int wrongIndex, int correct) {
    if (!_small(shown)) return false;
    for (var i = 1; i < shown.length; i++) {
      if (shown[i] == shown[i - 1]) return false;
    }
    if (followsPlausibleRule(shown)) return false;
    final repairs = singleRepairs(shown);
    return repairs.length == 1 &&
        repairs[wrongIndex]?.length == 1 &&
        repairs[wrongIndex]!.single == correct;
  }
}

/// Today's practice rounds step back a day at a time, so they're always
/// a different set from today's — and never tomorrow's.
int forgeDay(int today, {int practice = 0}) => today - max(practice, 0);
