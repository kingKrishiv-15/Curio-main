import 'dart:math';

/// Tip the Scale: two amounts sit on the pans of a balance and the player
/// says which is more, or that they balance. Fractions, decimals,
/// percentages, quick sums and whole numbers are all compared exactly.
///
/// Every value is a [Rational], so 2/5 and 40% are *equal*, not "equal to
/// within a rounding error". A day's eight rounds ramp up: three warm-ups
/// (same kind, clear gap), three mixed forms (different kinds), then two
/// close calls (within 10%). One or two rounds balance exactly, no amount
/// appears twice, and the bigger side is spread evenly between left and
/// right, so no blind strategy beats half marks. Tests run the generator
/// over hundreds of days to hold all of that.

/// An exact fraction in lowest terms, with the sign on the numerator.
class Rational implements Comparable<Rational> {
  factory Rational(int numerator, [int denominator = 1]) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
    }
    final divisor = numerator.gcd(denominator) * denominator.sign;
    return Rational._(numerator ~/ divisor, denominator ~/ divisor);
  }

  const Rational._(this.numerator, this.denominator);

  static const zero = Rational._(0, 1);

  final int numerator;

  /// Always positive.
  final int denominator;

  bool get isWhole => denominator == 1;
  bool get isNegative => numerator < 0;

  Rational operator +(Rational other) => Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator -(Rational other) => Rational(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator *(Rational other) =>
      Rational(numerator * other.numerator, denominator * other.denominator);

  Rational operator /(Rational other) =>
      Rational(numerator * other.denominator, denominator * other.numerator);

  Rational operator -() => Rational._(-numerator, denominator);

  Rational abs() => isNegative ? -this : this;

  /// Compares by cross-multiplying: exact, never a floating-point guess.
  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator <(Rational other) => compareTo(other) < 0;
  bool operator <=(Rational other) => compareTo(other) <= 0;
  bool operator >(Rational other) => compareTo(other) > 0;
  bool operator >=(Rational other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  /// How many decimal places it takes to write this exactly, or null when
  /// the decimal never ends (1/3 = 0.333…). Only denominators made of 2s and
  /// 5s end.
  int? get decimalPlaces {
    var rest = denominator, twos = 0, fives = 0;
    while (rest % 2 == 0) {
      rest ~/= 2;
      twos++;
    }
    while (rest % 5 == 0) {
      rest ~/= 5;
      fives++;
    }
    return rest == 1 ? max(twos, fives) : null;
  }

  /// The exact decimal, padded with zeros to at least [places] places:
  /// 5/8 → "0.625", 3/4 with 3 places → "0.750", 7 → "7".
  String toDecimalString({int places = 0}) {
    final exact = decimalPlaces;
    if (exact == null) throw StateError('$this has no exact decimal form.');
    final digits = max(exact, places);
    var scale = 1;
    for (var i = 0; i < digits; i++) {
      scale *= 10;
    }
    final scaled = (numerator * (scale ~/ denominator)).abs();
    final sign = isNegative ? '-' : '';
    final whole = scaled ~/ scale;
    if (digits == 0) return '$sign$whole';
    return '$sign$whole.${'${scaled % scale}'.padLeft(digits, '0')}';
  }

  /// "3/4", or just "2" for a whole number.
  String toFractionString() =>
      isWhole ? '$numerator' : '$numerator/$denominator';

  @override
  String toString() => toFractionString();
}

/// How far apart two positive amounts are, as a share of the larger one:
/// 0 when they're equal, 1/10 for 9 against 10.
Rational relativeGap(Rational a, Rational b) {
  final big = a > b ? a : b;
  final small = a > b ? b : a;
  if (big == Rational.zero) return Rational.zero;
  return (big - small) / big;
}

/// [a] and [b] written the same way so they can be compared at a glance:
/// decimals to the same number of places when both end (0.750 and 0.625),
/// otherwise fractions over the lowest common denominator (4/12 and 3/12).
(String, String) sharedForms(Rational a, Rational b) {
  final placesA = a.decimalPlaces, placesB = b.decimalPlaces;
  if (placesA != null && placesB != null) {
    final places = max(placesA, placesB);
    return (
      a.toDecimalString(places: places),
      b.toDecimalString(places: places),
    );
  }
  final common =
      a.denominator ~/ a.denominator.gcd(b.denominator) * b.denominator;
  String over(Rational r) =>
      '${r.numerator * (common ~/ r.denominator)}/$common';
  return (over(a), over(b));
}

/// A fraction in words for a screen reader: "three quarters", "one half".
/// Falls back to "7 over 15" outside the everyday names.
String fractionWords(int numerator, int denominator) {
  const counts = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', //
    'seven', 'eight', 'nine', 'ten', 'eleven',
  ];
  const names = {
    2: ('half', 'halves'),
    3: ('third', 'thirds'),
    4: ('quarter', 'quarters'),
    5: ('fifth', 'fifths'),
    6: ('sixth', 'sixths'),
    7: ('seventh', 'sevenths'),
    8: ('eighth', 'eighths'),
    9: ('ninth', 'ninths'),
    10: ('tenth', 'tenths'),
    11: ('eleventh', 'elevenths'),
    12: ('twelfth', 'twelfths'),
  };
  final name = names[denominator];
  if (name == null || numerator < 0 || numerator >= counts.length) {
    return '$numerator over $denominator';
  }
  return '${counts[numerator]} ${numerator == 1 ? name.$1 : name.$2}';
}

enum QuantityKind { fraction, decimal, percent, expression, whole }

/// One amount on a pan: what it shows, what it's worth, and how to say it.
class Quantity {
  const Quantity({
    required this.label,
    required this.value,
    required this.kind,
    required this.spoken,
  });

  /// A proper fraction, deliberately left unreduced if given that way (6/8).
  factory Quantity.fraction(int numerator, int denominator) => Quantity(
    label: '$numerator/$denominator',
    value: Rational(numerator, denominator),
    kind: QuantityKind.fraction,
    spoken: fractionWords(numerator, denominator),
  );

  /// [hundredths] ÷ 100 as a decimal: 35 → "0.35", 50 → "0.5".
  factory Quantity.decimal(int hundredths) {
    final value = Rational(hundredths, 100);
    return Quantity(
      label: value.toDecimalString(),
      value: value,
      kind: QuantityKind.decimal,
      spoken: value.toDecimalString(),
    );
  }

  factory Quantity.percent(int percent) => Quantity(
    label: '$percent%',
    value: Rational(percent, 100),
    kind: QuantityKind.percent,
    spoken: '$percent percent',
  );

  factory Quantity.whole(int value) => Quantity(
    label: '$value',
    value: Rational(value),
    kind: QuantityKind.whole,
    spoken: '$value',
  );

  factory Quantity.product(int a, int b) => Quantity(
    label: '$a × $b',
    value: Rational(a * b),
    kind: QuantityKind.expression,
    spoken: '$a times $b',
  );

  factory Quantity.square(int a) => Quantity(
    label: '$a²',
    value: Rational(a * a),
    kind: QuantityKind.expression,
    spoken: '$a squared',
  );

  factory Quantity.difference(int a, int b) => Quantity(
    label: '$a − $b',
    value: Rational(a - b),
    kind: QuantityKind.expression,
    spoken: '$a minus $b',
  );

  /// Only exact divisions: 144 ÷ 12, never 10 ÷ 3.
  factory Quantity.quotient(int a, int b) {
    if (b == 0 || a % b != 0) {
      throw ArgumentError('$a ÷ $b does not divide exactly');
    }
    return Quantity(
      label: '$a ÷ $b',
      value: Rational(a, b),
      kind: QuantityKind.expression,
      spoken: '$a divided by $b',
    );
  }

  factory Quantity.fractionOf(int numerator, int denominator, int amount) =>
      Quantity(
        label: '$numerator/$denominator of $amount',
        value: Rational(numerator * amount, denominator),
        kind: QuantityKind.expression,
        spoken: '${fractionWords(numerator, denominator)} of $amount',
      );

  factory Quantity.percentOf(int percent, int amount) => Quantity(
    label: '$percent% of $amount',
    value: Rational(percent * amount, 100),
    kind: QuantityKind.expression,
    spoken: '$percent percent of $amount',
  );

  /// What the pan shows: "3/4", "0.35", "40%", "7 × 8", "56".
  final String label;
  final Rational value;
  final QuantityKind kind;

  /// The same amount worded for a screen reader: "three quarters".
  final String spoken;

  @override
  String toString() => label;
}

enum ScaleSide { left, right, equal }

/// Where a round sits in the day's ramp.
enum ScaleTier {
  warmUp('Warm-up'),
  mixed('Mixed forms'),
  close('Close call');

  const ScaleTier(this.label);
  final String label;
}

/// The words the explanation ends on for each answer.
String verdictText(ScaleSide side) => switch (side) {
  ScaleSide.left => 'left is more',
  ScaleSide.right => 'right is more',
  ScaleSide.equal => 'they’re equal',
};

/// One weigh-in: two amounts, and which is more.
class ScaleRound {
  const ScaleRound({
    required this.left,
    required this.right,
    required this.tier,
  });

  final Quantity left, right;
  final ScaleTier tier;

  String get leftLabel => left.label;
  String get rightLabel => right.label;
  Rational get leftValue => left.value;
  Rational get rightValue => right.value;

  ScaleSide get answer => switch (left.value.compareTo(right.value)) {
    > 0 => ScaleSide.left,
    < 0 => ScaleSide.right,
    _ => ScaleSide.equal,
  };

  /// Both values in one shared form — see [sharedForms].
  (String, String) get shared => sharedForms(left.value, right.value);

  /// "3/4 = 0.750", or just "0.35" when the label is already in that form.
  String get leftWorking => _working(left, shared.$1);
  String get rightWorking => _working(right, shared.$2);

  String get verdict => verdictText(answer);

  /// "3/4 = 0.750 · 5/8 = 0.625 → left is more"
  String get explanation => '$leftWorking · $rightWorking → $verdict';

  /// The explanation worded for a screen reader.
  String get spokenExplanation {
    final (l, r) = shared;
    String say(Quantity q, String form) => q.label == form
        ? q.spoken
        : '${q.spoken} is ${form.replaceFirst('/', ' over ')}';
    return '${say(left, l)}, and ${say(right, r)}, so $verdict.';
  }

  static String _working(Quantity q, String form) =>
      q.label == form ? q.label : '${q.label} = $form';

  @override
  String toString() => '$leftLabel vs $rightLabel';
}

/// A day's eight rounds and the player's answers so far.
class ScaleGame {
  ScaleGame(List<ScaleRound> rounds)
    : rounds = List.unmodifiable(rounds),
      _picks = List<ScaleSide?>.filled(rounds.length, null);

  /// The set for [day] (DailyPick.dayNumber) — or, with [practice] above 0,
  /// a practice set that never repeats a daily one.
  factory ScaleGame.forDay(int day, {int practice = 0}) => ScaleGame(
    generateScaleRounds(Random(scaleSeed(day, practice: practice))),
  );

  static const roundCount = 8;

  final List<ScaleRound> rounds;
  final List<ScaleSide?> _picks;
  int _current = 0;

  int get current => _current;
  ScaleRound get round => rounds[_current];
  bool get answered => _picks[_current] != null;
  bool get isLast => _current == rounds.length - 1;
  bool get finished => _picks.every((p) => p != null);

  int get score => [
    for (var i = 0; i < rounds.length; i++)
      if (_picks[i] == rounds[i].answer) i,
  ].length;

  ScaleSide? pickAt(int index) => _picks[index];

  /// Null until that round is answered.
  bool? correctAt(int index) =>
      _picks[index] == null ? null : _picks[index] == rounds[index].answer;

  /// Records [side] for the current round; true when it's right.
  bool answer(ScaleSide side) {
    if (answered) {
      throw StateError('Round ${_current + 1} is already answered.');
    }
    _picks[_current] = side;
    return side == round.answer;
  }

  void next() {
    if (!answered) throw StateError('Answer this round first.');
    if (isLast) throw StateError('That was the last round.');
    _current++;
  }

  /// 🟩 for each right answer, 🟥 for each miss — no numbers, no spoilers.
  String get shareGrid => [
    for (var i = 0; i < rounds.length; i++)
      switch (correctAt(i)) {
        true => '🟩',
        false => '🟥',
        null => '⬜',
      },
  ].join();
}

/// Daily sets use `day * 1000`; practice rounds take the 999 seeds after
/// it, so a practice set can never be another day's daily.
int scaleSeed(int day, {int practice = 0}) =>
    day * 1000 + (practice <= 0 ? 0 : 1 + (practice - 1) % 999);

// ───────────────────────────── Generator ─────────────────────────────

typedef _Entry = ({Quantity quantity, double weight});
typedef _PairType = (QuantityKind, QuantityKind);

const _fraction = QuantityKind.fraction;
const _decimal = QuantityKind.decimal;
const _percent = QuantityKind.percent;
const _expression = QuantityKind.expression;
const _whole = QuantityKind.whole;

/// Mixed rounds always put two different kinds on the pans.
const _mixedTypes = <_PairType>[
  (_fraction, _decimal),
  (_fraction, _percent),
  (_decimal, _percent),
  (_expression, _whole),
];

const _closeTypes = <_PairType>[
  (_fraction, _fraction),
  (_fraction, _decimal),
  (_fraction, _percent),
  (_decimal, _percent),
  (_expression, _whole),
  (_expression, _expression),
];

/// "0.35 vs 35%" is too plain to be the last-round twist.
const _closeEqualTypes = <_PairType>[
  (_fraction, _fraction),
  (_fraction, _decimal),
  (_fraction, _percent),
  (_expression, _whole),
  (_expression, _expression),
];

enum _Relation { clear, apart, close, equal }

final _quarter = Rational(1, 4);
final _twoThirds = Rational(2, 3);
final _tenth = Rational(1, 10);
final _half = Rational(1, 2);

bool _fits(_Relation relation, Rational a, Rational b) {
  final gap = relativeGap(a, b);
  return switch (relation) {
    // Warm-ups: a clear gap, but not an absurd one.
    _Relation.clear => gap >= _quarter && gap <= _twoThirds,
    _Relation.apart => gap > _tenth && gap <= _half,
    _Relation.close => gap > Rational.zero && gap <= _tenth,
    _Relation.equal => gap == Rational.zero,
  };
}

/// Every amount a pan can show, by kind, with how often to pick it.
final Map<QuantityKind, List<_Entry>> _catalogue = {
  _fraction: [
    for (var q = 2; q <= 12; q++)
      for (var p = 1; p < q; p++)
        // Unreduced fractions (6/8) turn up now and then, on purpose.
        (quantity: Quantity.fraction(p, q), weight: p.gcd(q) == 1 ? 1.0 : .15),
  ],
  _decimal: [
    for (var h = 5; h <= 95; h++)
      (quantity: Quantity.decimal(h), weight: h % 10 == 0 ? 4.0 : 1.0),
  ],
  _percent: [
    for (var p = 5; p <= 95; p += 5)
      (quantity: Quantity.percent(p), weight: p % 10 == 0 ? 1.5 : 1.0),
  ],
  _expression: _expressions(),
};

/// Quick sums a child can do in their head, every one with a whole answer.
/// Each form gets the same total weight, however many entries it has.
List<_Entry> _expressions() {
  int step(int percent) => 100 ~/ percent.gcd(100);
  final forms = <List<Quantity>>[
    [
      for (var a = 2; a <= 12; a++)
        for (var b = a; b <= 12; b++) Quantity.product(a, b),
    ],
    [
      for (final a in [for (var a = 2; a <= 15; a++) a, 20, 25, 30])
        Quantity.square(a),
    ],
    [
      for (final a in const [50, 100, 200, 500])
        for (var b = a ~/ 10; b <= a - a ~/ 10; b++) Quantity.difference(a, b),
    ],
    [
      for (var b = 2; b <= 12; b++)
        for (var n = 2; n <= 15; n++) Quantity.quotient(n * b, b),
    ],
    [
      for (final q in const [2, 3, 4, 5, 6, 8, 10])
        for (var p = 1; p < q; p++)
          if (p.gcd(q) == 1)
            for (var k = 1; k <= 10; k++)
              if (p * k >= 2) Quantity.fractionOf(p, q, q * k),
    ],
    [
      for (final pct in const [10, 20, 25, 50, 75])
        for (var m = step(pct); m <= 200; m += step(pct))
          if (pct * m ~/ 100 >= 2) Quantity.percentOf(pct, m),
    ],
  ];
  return [
    for (final form in forms)
      for (final q in form) (quantity: q, weight: 1 / form.length),
  ];
}

T _weightedPick<T>(Random random, List<T> items, double Function(T) weight) {
  final total = items.fold<double>(0, (sum, item) => sum + weight(item));
  var roll = random.nextDouble() * total;
  for (final item in items) {
    roll -= weight(item);
    if (roll < 0) return item;
  }
  return items.last;
}

/// Amounts of [kind] that sit in [relation] to [target].
List<_Entry> _options(QuantityKind kind, Rational target, _Relation relation) {
  if (kind != _whole) {
    return [
      for (final entry in _catalogue[kind]!)
        if (_fits(relation, target, entry.quantity.value)) entry,
    ];
  }
  if (!target.isWhole) return const [];
  final n = target.numerator;
  return [
    for (var w = max(2, n ~/ 2 - 1); w <= min(999, n * 2 + 1); w++)
      if (_fits(relation, target, Rational(w)))
        (quantity: Quantity.whole(w), weight: 1.0),
  ];
}

/// Builds a day's eight rounds from [random]: three warm-ups, three mixed
/// forms, two close calls; one or two equal rounds among rounds 4–8; no
/// amount used twice; the bigger side split evenly between left and right.
List<ScaleRound> generateScaleRounds(Random random) {
  while (true) {
    final rounds = _attempt(random);
    if (rounds != null) return rounds;
  }
}

List<ScaleRound>? _attempt(Random random) {
  final equalCount = 1 + random.nextInt(2);
  final equalSlots = ([
    3,
    4,
    5,
    6,
    7,
  ]..shuffle(random)).take(equalCount).toSet();

  // Three different kinds to warm up on; percentages are the plainest.
  const warmUpWeights = {
    _fraction: 3.0,
    _decimal: 3.0,
    _expression: 3.0,
    _percent: 1.0,
  };
  final warmUps = <QuantityKind>[];
  while (warmUps.length < 3) {
    warmUps.add(
      _weightedPick(random, [
        for (final kind in warmUpWeights.keys)
          if (!warmUps.contains(kind)) kind,
      ], (kind) => warmUpWeights[kind]!),
    );
  }

  final usedValues = <Rational>{};
  final usedTypes = <_PairType>{};
  final pairs = <(Quantity, Quantity, ScaleTier)>[];
  for (var i = 0; i < ScaleGame.roundCount; i++) {
    final tier = i < 3
        ? ScaleTier.warmUp
        : i < 6
        ? ScaleTier.mixed
        : ScaleTier.close;
    final equal = equalSlots.contains(i);
    if (i == 6) usedTypes.clear();
    final _PairType type;
    final _Relation relation;
    if (tier == ScaleTier.warmUp) {
      type = (warmUps[i], warmUps[i]);
      relation = _Relation.clear;
    } else {
      final choices = tier == ScaleTier.mixed
          ? _mixedTypes
          : equal
          ? _closeEqualTypes
          : _closeTypes;
      // Vary the pairings within a tier while there are fresh ones.
      final fresh = [
        for (final t in choices)
          if (!usedTypes.contains(t)) t,
      ];
      final pool = fresh.isEmpty ? choices : fresh;
      type = pool[random.nextInt(pool.length)];
      relation = equal
          ? _Relation.equal
          : tier == ScaleTier.mixed
          ? _Relation.apart
          : _Relation.close;
    }
    usedTypes.add(type);

    final pair = _pair(random, type, relation, usedValues);
    if (pair == null) return null;
    usedValues
      ..add(pair.$1.value)
      ..add(pair.$2.value);
    pairs.add((pair.$1, pair.$2, tier));
  }

  // Put the bigger amount on the left in exactly half of the unequal
  // rounds (give or take one), chosen at random.
  final unequal = [
    for (var i = 0; i < pairs.length; i++)
      if (pairs[i].$1.value != pairs[i].$2.value) i,
  ];
  final leftCount =
      unequal.length ~/ 2 + (unequal.length.isOdd && random.nextBool() ? 1 : 0);
  final leftBigger = (List.of(
    unequal,
  )..shuffle(random)).take(leftCount).toSet();

  return [
    for (var i = 0; i < pairs.length; i++)
      _place(pairs[i], i, leftBigger, random),
  ];
}

ScaleRound _place(
  (Quantity, Quantity, ScaleTier) pair,
  int index,
  Set<int> leftBigger,
  Random random,
) {
  final (a, b, tier) = pair;
  final bool aOnLeft;
  if (a.value == b.value) {
    aOnLeft = random.nextBool();
  } else {
    aOnLeft = (a.value > b.value) == leftBigger.contains(index);
  }
  return ScaleRound(left: aOnLeft ? a : b, right: aOnLeft ? b : a, tier: tier);
}

(Quantity, Quantity)? _pair(
  Random random,
  _PairType type,
  _Relation relation,
  Set<Rational> usedValues,
) {
  for (var tries = 0; tries < 60; tries++) {
    final a = _weightedPick(
      random,
      _catalogue[type.$1]!,
      (e) => e.weight,
    ).quantity;
    if (usedValues.contains(a.value)) continue;
    final options = [
      for (final entry in _options(type.$2, a.value, relation))
        if (entry.quantity.label != a.label &&
            !usedValues.contains(entry.quantity.value))
          entry,
    ];
    if (options.isEmpty) continue;
    return (a, _weightedPick(random, options, (e) => e.weight).quantity);
  }
  return null;
}
