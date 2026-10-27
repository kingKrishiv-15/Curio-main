import 'dart:math';

/// One round's challenge: a [size]×[size] grid where [cells] squares glow
/// for [flash] before the player marks them from memory.
typedef GridRound = ({int size, int cells, Duration flash});

/// A gentle climb: from three squares on a 3×3 grid to six on a 5×5, with
/// a long first look that shortens a little each round. No recall timer —
/// younger players can take their time.
const gridRounds = <GridRound>[
  (size: 3, cells: 3, flash: Duration(milliseconds: 2200)),
  (size: 3, cells: 4, flash: Duration(milliseconds: 2100)),
  (size: 4, cells: 4, flash: Duration(milliseconds: 2000)),
  (size: 4, cells: 5, flash: Duration(milliseconds: 1900)),
  (size: 4, cells: 6, flash: Duration(milliseconds: 1800)),
  (size: 5, cells: 6, flash: Duration(milliseconds: 1700)),
];

/// What happened when a pattern was checked.
enum GridResult { matched, missed }

/// A run of flash-and-recall rounds with three lives.
class MemoryGrid {
  MemoryGrid(this.seed) {
    _newPattern();
  }

  static const lives = 3;

  /// Everyone on the same day sees the same patterns.
  final int seed;
  int round = 0;
  int misses = 0;
  int _attempt = 0;
  late Set<int> pattern;
  final Set<int> marked = {};

  GridRound get settings => gridRounds[round.clamp(0, gridRounds.length - 1)];
  int get cleared => round;
  bool get won => round >= gridRounds.length;
  bool get over => won || misses >= lives;
  int get livesLeft => lives - misses;

  void _newPattern() {
    final s = settings;
    final squares = List.generate(s.size * s.size, (i) => i)
      ..shuffle(Random(seed * 101 + round * 13 + _attempt * 7919));
    pattern = squares.take(s.cells).toSet();
    marked.clear();
  }

  /// Marks or unmarks [square]. Returns the result once the last needed
  /// square is marked, so the check happens without a separate button.
  GridResult? toggle(int square) {
    if (over || marked.length >= settings.cells && !marked.contains(square)) {
      return null;
    }
    if (!marked.remove(square)) marked.add(square);
    if (marked.length < settings.cells) return null;
    if (marked.containsAll(pattern)) return GridResult.matched;
    misses++;
    return GridResult.missed;
  }

  /// After a check: on to a harder round if it matched, or a fresh pattern
  /// at the same size if it didn't.
  void advance({required bool matched}) {
    if (matched) {
      round++;
    } else {
      _attempt++;
    }
    if (!won) _newPattern();
  }
}
