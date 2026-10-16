import 'dart:math';

/// Where the mirror line runs on a Mirror board.
enum MirrorAxis {
  /// Down the middle: the left half is the pattern, paint the right half.
  vertical,

  /// Across the middle: the top half is the pattern, paint the bottom half.
  horizontal,

  /// Corner to corner, top left to bottom right: the squares on and above
  /// the line are the pattern, paint below it.
  diagonal,
}

/// Where square [cell] lands in the mirror on a [size] × [size] board.
/// Squares are numbered row by row from the top left (`row * size + col`).
/// Reflecting twice always brings a square home.
int reflectCell(
  int cell,
  MirrorAxis axis, {
  int size = MirrorPuzzle.boardSize,
}) {
  final row = cell ~/ size, col = cell % size;
  return switch (axis) {
    MirrorAxis.vertical => row * size + (size - 1 - col),
    MirrorAxis.horizontal => (size - 1 - row) * size + col,
    MirrorAxis.diagonal => col * size + row,
  };
}

/// Whether [cell] is on the pattern (given, locked) side of the mirror. For
/// the diagonal that includes the squares the line runs through.
bool onPatternSide(
  int cell,
  MirrorAxis axis, {
  int size = MirrorPuzzle.boardSize,
}) {
  final row = cell ~/ size, col = cell % size;
  return switch (axis) {
    MirrorAxis.vertical => col < size ~/ 2,
    MirrorAxis.horizontal => row < size ~/ 2,
    MirrorAxis.diagonal => col >= row,
  };
}

/// Whether the mirror runs straight through [cell] — only ever true on the
/// diagonal. Those squares are their own reflection.
bool onMirrorLine(
  int cell,
  MirrorAxis axis, {
  int size = MirrorPuzzle.boardSize,
}) => axis == MirrorAxis.diagonal && cell ~/ size == cell % size;

/// Mirror: a board split by a mirror line. One side holds a pattern; the
/// player paints its reflection on the other side, then checks.
///
/// The board is an even size, so a straight mirror runs *between* squares.
/// The diagonal runs *through* its squares: each is its own reflection, so
/// they count as pattern side and stay locked.
///
/// Puzzles come from a seed, so a day's set is the same for everyone, and a
/// pattern is only kept when it's worth solving ([isWorthSolving]): a fair
/// amount to paint, no row or column that's all-or-nothing, and no shortcut
/// — sliding the pattern across, or spinning it round, must never give the
/// same answer as flipping it.
class MirrorPuzzle {
  MirrorPuzzle({
    required this.axis,
    required Set<int> given,
    this.size = boardSize,
  }) : given = Set.unmodifiable(given);

  static const boardSize = 6;

  /// Share of the pattern side that's filled.
  static const minDensity = .3;
  static const maxDensity = .5;

  /// Fewest filled squares, and fewest squares to paint.
  static const minSquares = 5;

  final MirrorAxis axis;
  final int size;

  /// The filled squares on the pattern side — shown and locked.
  final Set<int> given;

  /// Every square on the pattern side, filled or not.
  late final List<int> patternSide = [
    for (var cell = 0; cell < size * size; cell++)
      if (onPatternSide(cell, axis, size: size)) cell,
  ];

  /// Every square the player may paint.
  late final List<int> paintSide = [
    for (var cell = 0; cell < size * size; cell++)
      if (!onPatternSide(cell, axis, size: size)) cell,
  ];

  /// The answer: where every filled square lands in the mirror (squares on
  /// the line reflect onto themselves, so they're already done).
  late final Set<int> target = Set.unmodifiable({
    for (final cell in given)
      if (!onMirrorLine(cell, axis, size: size))
        reflectCell(cell, axis, size: size),
  });

  /// Pattern-side squares can't be painted, filled or not.
  bool isLocked(int cell) => onPatternSide(cell, axis, size: size);

  double get density => given.length / patternSide.length;

  /// The generator's quality bar (see the class docs).
  bool get isWorthSolving {
    if (density < minDensity || density > maxDensity) return false;
    if (given.length < minSquares || target.length < minSquares) return false;
    // An empty row gives nothing to think about; a full one is just "fill
    // the line". Only lines of three or more squares count.
    for (final line in _lines) {
      if (line.length < 3) continue;
      final filled = line.where(given.contains).length;
      if (filled == 0 || filled == line.length) return false;
    }
    final offLine = given.where((c) => !onMirrorLine(c, axis, size: size));
    for (final wrongMove in _wrongMoves) {
      final moved = {for (final cell in offLine) wrongMove(cell)};
      if (moved.length == target.length && moved.containsAll(target)) {
        return false;
      }
    }
    return true;
  }

  /// Each row and column of the board, cut down to its squares strictly on
  /// the pattern side (squares on the line are already their own answer).
  List<List<int>> get _lines {
    bool strict(int cell) =>
        onPatternSide(cell, axis, size: size) &&
        !onMirrorLine(cell, axis, size: size);
    return [
      for (var n = 0; n < size; n++) ...[
        [
          for (var k = 0; k < size; k++)
            if (strict(n * size + k)) n * size + k,
        ],
        [
          for (var k = 0; k < size; k++)
            if (strict(k * size + n)) k * size + n,
        ],
      ],
    ];
  }

  /// What a player gets by spinning the pattern half way round, or by
  /// sliding it across instead of flipping it. Neither may happen to be right.
  List<int Function(int)> get _wrongMoves {
    final half = size ~/ 2;
    return [
      (cell) => size * size - 1 - cell,
      if (axis == MirrorAxis.vertical) (cell) => cell + half,
      if (axis == MirrorAxis.horizontal) (cell) => cell + half * size,
    ];
  }

  /// A puzzle worth solving, drawn from [random]. Deterministic: the same
  /// seed always gives the same puzzle.
  factory MirrorPuzzle.generate(
    Random random,
    MirrorAxis axis, {
    int size = boardSize,
  }) {
    assert(
      size.isEven && size >= boardSize,
      'An even board keeps squares off a straight mirror line.',
    );
    final side = [
      for (var cell = 0; cell < size * size; cell++)
        if (onPatternSide(cell, axis, size: size)) cell,
    ];
    final fewest = max(minSquares, (side.length * minDensity).ceil());
    final most = (side.length * maxDensity).floor();
    while (true) {
      final count = fewest + random.nextInt(most - fewest + 1);
      final given = (List.of(side)..shuffle(random)).take(count).toSet();
      final puzzle = MirrorPuzzle(axis: axis, given: given, size: size);
      if (puzzle.isWorthSolving) return puzzle;
    }
  }
}

/// A seed's three puzzles, easiest first: a mirror down the middle, one
/// across the middle, then corner to corner.
List<MirrorPuzzle> mirrorPuzzles(int seed) {
  final random = Random(seed);
  return [
    for (final axis in MirrorAxis.values) MirrorPuzzle.generate(random, axis),
  ];
}

/// The seed for a day's puzzles, or for that day's [practice]th practice set
/// (1, 2, …), which lands far away from any daily seed.
int mirrorSeed(int day, {int practice = 0}) =>
    practice == 0 ? day : day * 1000 + practice;

/// What one press of Check found.
class MirrorCheck {
  MirrorCheck(Set<int> painted, Set<int> target)
    : total = target.length,
      extra = Set.unmodifiable(painted.difference(target)),
      missing = Set.unmodifiable(target.difference(painted));

  /// Squares in the true reflection.
  final int total;

  /// Painted, but not part of the reflection.
  final Set<int> extra;

  /// Part of the reflection, but not painted.
  final Set<int> missing;

  /// Reflection squares that were painted.
  int get right => total - missing.length;
  bool get correct => extra.isEmpty && missing.isEmpty;
}

/// One puzzle being played: the squares painted so far and up to three
/// checks. Right first time scores 100, then 60, then 30; a third miss
/// reveals the answer for 0.
class MirrorRound {
  MirrorRound(this.puzzle);

  static const maxChecks = 3;

  /// Points for being right on the first, second or third check.
  static const checkPoints = [100, 60, 30];
  static const maxPoints = 100;

  final MirrorPuzzle puzzle;
  final Set<int> painted = {};
  int checks = 0;
  bool solved = false;

  /// Three checks missed, so the answer is shown.
  bool revealed = false;
  MirrorCheck? lastCheck;
  Set<int>? _lastChecked;

  bool get over => solved || revealed;
  int get checksLeft => maxChecks - checks;
  int get points => solved ? checkPoints[checks - 1] : 0;

  /// What a right answer on the next check earns (or what was earned).
  int get worth => over ? points : checkPoints[checks];

  /// Checking an empty board, or the same painting twice, would only waste
  /// a check.
  bool get canCheck {
    if (over || painted.isEmpty) return false;
    final last = _lastChecked;
    return last == null ||
        last.length != painted.length ||
        !last.containsAll(painted);
  }

  /// Paints or rubs out [cell]. False when it can't change: a locked square,
  /// or the puzzle is over.
  bool toggle(int cell) {
    if (over || puzzle.isLocked(cell)) return false;
    if (!painted.remove(cell)) painted.add(cell);
    return true;
  }

  void clear() {
    if (!over) painted.clear();
  }

  MirrorCheck check() {
    if (over) throw StateError('This puzzle is finished.');
    final result = MirrorCheck(painted, puzzle.target);
    checks++;
    lastCheck = result;
    _lastChecked = Set.of(painted);
    if (result.correct) {
      solved = true;
    } else if (checks == maxChecks) {
      revealed = true;
    }
    return result;
  }

  /// Squares the last check said shouldn't be painted, and still are. Empty
  /// before the first check — the board never hints for free.
  Set<int> get markedExtra =>
      lastCheck?.extra.intersection(painted) ?? const <int>{};

  /// Squares the last check said were missing, and still are.
  Set<int> get markedMissing =>
      lastCheck?.missing.difference(painted) ?? const <int>{};

  /// 🟩 right on the first check, 🟨 second, 🟧 third, ⬛ not solved.
  String get shareMark => solved ? const ['🟩', '🟨', '🟧'][checks - 1] : '⬛';
}
