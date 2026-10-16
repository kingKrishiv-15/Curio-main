import 'dart:math';

/// Signal Grid: a 4×4 board where every row and column holds two sparks and
/// two waves, and no two rows (or two columns) are identical.
///
/// Every valid board is enumerated up front (there are only a few dozen), so
/// each day's puzzle is one of them with just enough cells revealed that it
/// is the *only* board fitting the clues — solvable by deduction, never
/// guessing. Answers are then checked against the rules rather than one
/// stored grid.
class SignalPuzzle {
  const SignalPuzzle({required this.solution, required this.givens});

  /// true = spark, false = wave; row-major.
  final List<bool> solution;
  final Set<int> givens;

  static const size = 4;

  static final List<List<bool>> allBoards = _enumerate();

  factory SignalPuzzle.forDay(int day) {
    final solution = allBoards[day % allBoards.length];
    final order = List.generate(size * size, (i) => i)..shuffle(Random(day));
    final givens = <int>{};
    for (final cell in order) {
      givens.add(cell);
      if (_matches(solution, givens) == 1) break;
    }
    // Trim clues that aren't needed, so the puzzle asks for real deduction.
    for (final cell in List.of(givens)) {
      givens.remove(cell);
      if (_matches(solution, givens) != 1) givens.add(cell);
    }
    return SignalPuzzle(solution: solution, givens: givens);
  }

  static int _matches(List<bool> solution, Set<int> givens) => allBoards
      .where((board) => givens.every((i) => board[i] == solution[i]))
      .length;

  /// Cells in any row or column that breaks a rule. Empty means the board is
  /// complete and valid (callers check for blanks first).
  static Set<int> violations(List<bool?> cells) {
    final bad = <int>{};
    List<int> line(int n, {required bool row}) => [
      for (var k = 0; k < size; k++) row ? n * size + k : k * size + n,
    ];
    for (final row in [true, false]) {
      final lines = [for (var n = 0; n < size; n++) line(n, row: row)];
      final keys = [for (final l in lines) l.map((i) => cells[i]).join()];
      for (var n = 0; n < size; n++) {
        final sparks = lines[n].where((i) => cells[i] == true).length;
        final duplicate = keys.where((k) => k == keys[n]).length > 1;
        if (sparks != 2 || duplicate) bad.addAll(lines[n]);
      }
    }
    return bad;
  }

  static List<List<bool>> _enumerate() {
    final rows = <List<bool>>[
      for (var mask = 0; mask < 16; mask++)
        if (_bits(mask) == 2) [for (var b = 3; b >= 0; b--) mask >> b & 1 == 1],
    ];
    final boards = <List<bool>>[];
    void build(List<List<bool>> chosen) {
      if (chosen.length == size) {
        final board = [for (final r in chosen) ...r];
        if (violations(board).isEmpty) boards.add(board);
        return;
      }
      for (final row in rows) {
        if (!chosen.contains(row)) build([...chosen, row]);
      }
    }

    build([]);
    return boards;
  }

  static int _bits(int n) => n == 0 ? 0 : (n & 1) + _bits(n >> 1);
}
