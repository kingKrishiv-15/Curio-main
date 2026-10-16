import 'dart:math';

/// Bridge: a start number, a target, and a handful of operation tiles.
/// Arrange every tile so the start becomes the target. Order is the whole
/// game — squaring then doubling is not doubling then squaring.
///
/// Puzzles are built backwards from a solution (pick a start, apply random
/// operations, whatever you land on is the target), so every puzzle is
/// solvable. Division only appears where it divides evenly, so every step
/// stays a whole number, and [solutionCount] measures how many orderings
/// work so too-easy puzzles can be rejected.
enum BridgeOpKind { add, subtract, multiply, divide, square }

class BridgeOp {
  const BridgeOp(this.kind, [this.operand = 0]);

  final BridgeOpKind kind;
  final int operand;

  String get label => switch (kind) {
    BridgeOpKind.add => '+$operand',
    BridgeOpKind.subtract => '−$operand',
    BridgeOpKind.multiply => '×$operand',
    BridgeOpKind.divide => '÷$operand',
    BridgeOpKind.square => 'x²',
  };

  String get spoken => switch (kind) {
    BridgeOpKind.add => 'add $operand',
    BridgeOpKind.subtract => 'subtract $operand',
    BridgeOpKind.multiply => 'multiply by $operand',
    BridgeOpKind.divide => 'divide by $operand',
    BridgeOpKind.square => 'square it',
  };

  /// Null when the step isn't allowed: a remainder, or dropping below 1.
  int? apply(int value) => switch (kind) {
    BridgeOpKind.add => value + operand,
    BridgeOpKind.subtract => value - operand >= 1 ? value - operand : null,
    BridgeOpKind.multiply => value * operand,
    BridgeOpKind.divide => value % operand == 0 ? value ~/ operand : null,
    BridgeOpKind.square => value * value,
  };
}

/// Running values after each op; null from the first invalid step onward.
List<int?> runBridge(int start, List<BridgeOp> ops) {
  final values = <int?>[];
  int? value = start;
  for (final op in ops) {
    value = value == null ? null : op.apply(value);
    values.add(value);
  }
  return values;
}

bool solves(int start, int target, List<BridgeOp> ops) {
  final values = runBridge(start, ops);
  return values.isNotEmpty && values.last == target;
}

Iterable<List<T>> _permutations<T>(List<T> items) sync* {
  if (items.length <= 1) {
    yield List.of(items);
    return;
  }
  for (var i = 0; i < items.length; i++) {
    final rest = List.of(items)..removeAt(i);
    for (final tail in _permutations(rest)) {
      yield [items[i], ...tail];
    }
  }
}

/// How many distinct orderings reach the target.
int solutionCount(int start, int target, List<BridgeOp> ops) {
  final seen = <String>{};
  for (final order in _permutations(ops)) {
    if (solves(start, target, order)) {
      seen.add(order.map((o) => o.label).join(','));
    }
  }
  return seen.length;
}

class BridgePuzzle {
  const BridgePuzzle({
    required this.start,
    required this.target,
    required this.tiles,
    required this.solution,
    required this.solutions,
  });

  final int start;
  final int target;

  /// The tiles in their starting (scrambled) order.
  final List<BridgeOp> tiles;

  /// One ordering that works — the one the puzzle was built from.
  final List<BridgeOp> solution;

  /// How many orderings work in total. 1 means a single-solution day.
  final int solutions;

  static const maxValue = 999;
  static const maxSolutions = 4;

  /// Builds a solvable puzzle from [random]. Never returns one that's already
  /// solved in its starting order, or that has too many easy answers.
  factory BridgePuzzle.generate(Random random, {int tileCount = 5}) {
    while (true) {
      final start = 2 + random.nextInt(11);
      var value = start;
      final ops = <BridgeOp>[];
      var ok = true;
      for (var i = 0; i < tileCount && ok; i++) {
        final op = _pickOp(random, value, ops);
        final next = op?.apply(value);
        if (op == null || next == null || next > maxValue) {
          ok = false;
        } else {
          ops.add(op);
          value = next;
        }
      }
      if (!ok || value == start) continue;
      if (ops.map((o) => o.kind).toSet().length < 3) continue;
      final count = solutionCount(start, value, ops);
      if (count > maxSolutions) continue;

      final tiles = List.of(ops);
      for (var tries = 0; tries < 20 && solves(start, value, tiles); tries++) {
        tiles.shuffle(random);
      }
      if (solves(start, value, tiles)) continue;
      return BridgePuzzle(
        start: start,
        target: value,
        tiles: tiles,
        solution: ops,
        solutions: count,
      );
    }
  }

  static BridgeOp? _pickOp(Random random, int value, List<BridgeOp> used) {
    final options = <BridgeOp>[
      BridgeOp(BridgeOpKind.add, 2 + random.nextInt(18)),
      if (value > 3) BridgeOp(BridgeOpKind.subtract, 1 + random.nextInt(min(value - 2, 15))),
      if (value * 2 <= maxValue)
        BridgeOp(BridgeOpKind.multiply, 2 + random.nextInt(value * 5 <= maxValue ? 4 : 1)),
      for (final d in const [2, 3, 4, 5])
        if (value % d == 0 && value > d) BridgeOp(BridgeOpKind.divide, d),
      if (value >= 2 && value <= 25 && !used.any((o) => o.kind == BridgeOpKind.square))
        const BridgeOp(BridgeOpKind.square),
    ];
    // Favour the tiles that make order matter: × ÷ and x².
    final weighted = [
      for (final op in options) ...[
        op,
        if (op.kind != BridgeOpKind.add && op.kind != BridgeOpKind.subtract) op,
      ],
    ];
    return weighted.isEmpty ? null : weighted[random.nextInt(weighted.length)];
  }
}

/// A player's working arrangement of one puzzle.
class BridgeRound {
  BridgeRound(this.puzzle) : order = List.of(puzzle.tiles);

  final BridgePuzzle puzzle;
  final List<BridgeOp> order;
  int hints = 0;

  List<int?> get values => runBridge(puzzle.start, order);
  bool get solved => solves(puzzle.start, puzzle.target, order);
  int get points => solved ? max(20, 100 - 30 * hints) : 0;

  void move(int from, int to) {
    if (to < 0 || to >= order.length || from == to) return;
    order.insert(to, order.removeAt(from));
  }

  /// Places the next tile of the built-in solution, starting from the left.
  /// Returns false when there's nothing left to fix.
  bool hint() {
    for (var i = 0; i < order.length; i++) {
      final want = puzzle.solution[i];
      if (order[i].label != want.label) {
        final from = order.indexWhere((o) => o.label == want.label, i);
        move(from, i);
        hints++;
        return true;
      }
    }
    return false;
  }
}
