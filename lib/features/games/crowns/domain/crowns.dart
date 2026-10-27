import 'crowns_boards.dart';

/// A kingdom map: [regions] gives each square's kingdom (row by row), and
/// [solution] the crown's column in each row.
class CrownsBoard {
  const CrownsBoard({
    required this.size,
    required this.regions,
    required this.solution,
  });

  final int size;
  final List<int> regions;
  final List<int> solution;

  int regionAt(int row, int column) => regions[row * size + column];

  /// The same puzzle turned [turns] quarter-turns clockwise, mirrored first
  /// when [mirror] — every one still has exactly one solution.
  CrownsBoard transformed({required int turns, required bool mirror}) {
    (int, int) move(int row, int column) {
      var (r, c) = (row, mirror ? size - 1 - column : column);
      for (var i = 0; i < turns % 4; i++) {
        (r, c) = (c, size - 1 - r);
      }
      return (r, c);
    }

    final regions = List.filled(size * size, 0);
    final solution = List.filled(size, 0);
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        final (r, c) = move(row, column);
        regions[r * size + c] = regionAt(row, column);
      }
      final (r, c) = move(row, this.solution[row]);
      solution[r] = c;
    }
    return CrownsBoard(size: size, regions: regions, solution: solution);
  }
}

/// Today's boards: a 5×5 warm-up, then a 6×6.
List<CrownsBoard> dailyCrowns(int day) => [
  for (final size in [5, 6]) _pick(size, day),
];

CrownsBoard _pick(int size, int day) {
  final pool = [
    for (final b in crownsBoards)
      if (b.size == size) b,
  ];
  // Walk the pool and its eight orientations, so a board doesn't repeat
  // for months.
  final step = day % (pool.length * 8);
  return pool[step % pool.length].transformed(
    turns: step ~/ pool.length % 4,
    mirror: step ~/ (pool.length * 4) == 1,
  );
}

/// Every way to finish [board]: one crown per row, column and kingdom, with
/// no two crowns touching, even corner to corner. Stops after [limit].
List<List<int>> solveCrowns(CrownsBoard board, {int limit = 2}) {
  final n = board.size;
  final found = <List<int>>[];
  final columns = <int>{}, kingdoms = <int>{};
  final placed = <int>[];
  void search(int row) {
    if (found.length >= limit) return;
    if (row == n) {
      found.add([...placed]);
      return;
    }
    for (var c = 0; c < n; c++) {
      final k = board.regionAt(row, c);
      if (columns.contains(c) || kingdoms.contains(k)) continue;
      if (row > 0 && (c - placed.last).abs() <= 1) continue;
      columns.add(c);
      kingdoms.add(k);
      placed.add(c);
      search(row + 1);
      placed.removeLast();
      kingdoms.remove(k);
      columns.remove(c);
    }
  }

  search(0);
  return found;
}

/// A square, by row and column.
typedef Square = (int row, int column);

/// A game in progress on one board.
class CrownsGame {
  CrownsGame(this.board);

  final CrownsBoard board;
  final Set<Square> crowns = {};
  final Set<Square> marks = {};

  int get size => board.size;

  /// Two crowns clash when they share a row, column or kingdom, or touch.
  bool clash(Square a, Square b) =>
      a != b &&
      (a.$1 == b.$1 ||
          a.$2 == b.$2 ||
          board.regionAt(a.$1, a.$2) == board.regionAt(b.$1, b.$2) ||
          ((a.$1 - b.$1).abs() <= 1 && (a.$2 - b.$2).abs() <= 1));

  /// Crowns that break a rule.
  Set<Square> get conflicts => {
    for (final a in crowns)
      if (crowns.any((b) => clash(a, b))) a,
  };

  /// Squares a placed crown already rules out — shown faded, to help.
  bool blocked(Square square) =>
      !crowns.contains(square) && crowns.any((c) => clash(c, square));

  bool get solved => crowns.length == size && conflicts.isEmpty;

  void toggleCrown(Square square) {
    marks.remove(square);
    if (!crowns.remove(square)) crowns.add(square);
  }

  void toggleMark(Square square) {
    if (crowns.contains(square)) return;
    if (!marks.remove(square)) marks.add(square);
  }

  /// Places one crown from the answer that isn't on the board yet, clearing
  /// anything in its way. Null when every crown is already right.
  Square? hint() {
    for (var row = 0; row < size; row++) {
      final square = (row, board.solution[row]);
      if (crowns.contains(square)) continue;
      crowns.removeWhere((c) => clash(c, square));
      marks.remove(square);
      crowns.add(square);
      return square;
    }
    return null;
  }

  void clear() {
    crowns.clear();
    marks.clear();
  }
}
