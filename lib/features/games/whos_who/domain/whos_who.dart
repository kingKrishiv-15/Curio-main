import 'dart:math';

/// Who's Who: a small logic-grid puzzle. A few children each have exactly one
/// pet and one favourite thing (a colour, a snack or a hobby). Nothing is
/// shared, and a handful of true clues pin down who has what.
///
/// Puzzles are generated, not authored. A random answer is picked, every true
/// clue about it is listed, and clues are added — negative and linked ones
/// first — until a solver that tries every way of handing things out
/// (3!×3! = 36 for three children, 4!×4! = 576 for four) finds exactly one
/// that fits. Then each clue is dropped in turn if the answer stays unique
/// without it, so every clue left is needed — and the puzzle is kept only if
/// ordinary logic-grid reasoning solves it, so it never needs guessing.
/// Tests run this over hundreds of seeds.
enum WhoCategory {
  pet('Pet', 'pet', [
    'cat',
    'dog',
    'fish',
    'rabbit',
    'parrot',
    'tortoise',
    'hamster',
  ]),
  colour('Colour', 'favourite colour', [
    'red',
    'blue',
    'green',
    'yellow',
    'purple',
    'orange',
  ]),
  snack('Snack', 'favourite snack', [
    'apples',
    'popcorn',
    'cheese',
    'grapes',
    'carrots',
    'pretzels',
  ]),
  hobby('Hobby', 'hobby', [
    'drawing',
    'chess',
    'swimming',
    'piano',
    'football',
    'baking',
  ]);

  const WhoCategory(this.label, this.noun, this.pool);

  /// Column heading: "Colour".
  final String label;

  /// As in "Ana’s favourite colour".
  final String noun;

  /// Everything a puzzle can draw from, in the order pickers list it.
  final List<String> pool;

  /// "Ana has the cat." / "Chen’s favourite colour isn’t red."
  String statement(String name, String item, {required bool positive}) =>
      switch (this) {
        pet =>
          positive ? '$name has the $item.' : '$name doesn’t have the $item.',
        _ => '$name’s $noun ${positive ? 'is' : 'isn’t'} $item.',
      };

  /// "The child with the fish" / "The child who loves chess".
  String subject(String item) => switch (this) {
    pet => 'The child with the $item',
    hobby => 'The child who loves $item',
    _ => 'The child whose $noun is $item',
  };

  /// "has the rabbit" / "likes green" / "loves popcorn".
  String predicate(String item, {required bool positive}) => switch (this) {
    pet => positive ? 'has the $item' : 'doesn’t have the $item',
    colour => positive ? 'likes $item' : 'doesn’t like $item',
    snack || hobby => positive ? 'loves $item' : 'doesn’t love $item',
  };
}

/// Short, varied names, each with its own first letter, so a puzzle's
/// children never share an initial.
const whoNames = [
  'Ana',
  'Ben',
  'Chen',
  'Dev',
  'Ella',
  'Femi',
  'Gita',
  'Hugo',
  'Isla',
  'Jay',
  'Kofi',
  'Lila',
  'Mo',
  'Nia',
  'Omar',
  'Pia',
];

enum WhoClueKind {
  /// "Ana has the cat."
  has,

  /// "Ben doesn’t have the dog."
  hasNot,

  /// "The child with the fish likes green."
  linked,

  /// "The child whose favourite colour is red doesn’t have the parrot."
  linkedNot,
}

/// One clue, as indexes into its puzzle's children, categories and items.
class WhoClue {
  /// [child] has [item] from [category].
  const WhoClue.has(this.child, this.category, this.item)
    : kind = WhoClueKind.has,
      otherCategory = -1,
      otherItem = -1;

  /// [child] doesn't have [item] from [category].
  const WhoClue.hasNot(this.child, this.category, this.item)
    : kind = WhoClueKind.hasNot,
      otherCategory = -1,
      otherItem = -1;

  /// Whoever has [item] from [category] also has [otherItem] from
  /// [otherCategory]. [category] is the sentence's subject.
  const WhoClue.linked(
    this.category,
    this.item,
    this.otherCategory,
    this.otherItem,
  ) : kind = WhoClueKind.linked,
      child = -1;

  /// Whoever has [item] from [category] doesn't have [otherItem] from
  /// [otherCategory].
  const WhoClue.linkedNot(
    this.category,
    this.item,
    this.otherCategory,
    this.otherItem,
  ) : kind = WhoClueKind.linkedNot,
      child = -1;

  final WhoClueKind kind;

  /// The child a plain clue is about; -1 for linked clues.
  final int child;
  final int category, item;

  /// The second half of a linked clue; -1 for plain ones.
  final int otherCategory, otherItem;

  bool get isLinked =>
      kind == WhoClueKind.linked || kind == WhoClueKind.linkedNot;

  bool holds(WhoAssignment a) => switch (kind) {
    WhoClueKind.has => a.items[category][child] == item,
    WhoClueKind.hasNot => a.items[category][child] != item,
    WhoClueKind.linked =>
      a.items[otherCategory][a.owners[category][item]] == otherItem,
    WhoClueKind.linkedNot =>
      a.items[otherCategory][a.owners[category][item]] != otherItem,
  };

  @override
  String toString() => switch (kind) {
    WhoClueKind.has ||
    WhoClueKind.hasNot => '${kind.name}(child $child, $category:$item)',
    _ => '${kind.name}($category:$item, $otherCategory:$otherItem)',
  };
}

/// One way of handing everything out: `items[category][child]` is the index
/// of the item that child has, and `owners[category][item]` the reverse.
class WhoAssignment {
  WhoAssignment(this.items) : owners = [for (final row in items) _invert(row)];

  final List<List<int>> items;
  final List<List<int>> owners;

  static List<int> _invert(List<int> row) {
    final out = List<int>.filled(row.length, 0);
    for (var child = 0; child < row.length; child++) {
      out[row[child]] = child;
    }
    return out;
  }
}

final _assignments = <(int, int), List<WhoAssignment>>{};

/// Every possible assignment for [size] children: one ordering per category,
/// so (size!)^categories of them.
List<WhoAssignment> whoAssignments(int size, {int categories = 2}) =>
    _assignments.putIfAbsent((size, categories), () {
      final orders = _permutations(size);
      var rows = <List<List<int>>>[[]];
      for (var c = 0; c < categories; c++) {
        rows = [
          for (final row in rows)
            for (final order in orders) [...row, order],
        ];
      }
      return [for (final row in rows) WhoAssignment(row)];
    });

List<List<int>> _permutations(int n) => n == 0
    ? [<int>[]]
    : [
        for (final rest in _permutations(n - 1))
          for (var at = 0; at <= rest.length; at++)
            [...rest.take(at), n - 1, ...rest.skip(at)],
      ];

/// How many assignments fit every clue, found by trying them all. Stops
/// counting once it reaches [stopAt].
int countSolutions(
  int size,
  Iterable<WhoClue> clues, {
  int categories = 2,
  int? stopAt,
}) {
  final list = clues.toList(growable: false);
  var count = 0;
  for (final a in whoAssignments(size, categories: categories)) {
    if (list.every((clue) => clue.holds(a)) && ++count == stopAt) break;
  }
  return count;
}

/// Every assignment that fits all the clues.
List<WhoAssignment> solveWho(
  int size,
  Iterable<WhoClue> clues, {
  int categories = 2,
}) {
  final list = clues.toList(growable: false);
  return [
    for (final a in whoAssignments(size, categories: categories))
      if (list.every((clue) => clue.holds(a))) a,
  ];
}

/// Whether the clues (for two categories) can be solved the way a logic
/// grid is solved by hand, without guessing: mark what each clue says, then
/// keep applying "one per row and column", "only one left" and "Ana has the
/// cat and the cat's owner likes green, so Ana likes green" until nothing
/// changes. True when that fills in the whole table.
bool solvableByDeduction(int size, Iterable<WhoClue> clues) {
  // child × first category, child × second, first × second.
  // 1 = yes, -1 = no, 0 = not known yet.
  final grids = [
    for (var g = 0; g < 3; g++)
      [for (var r = 0; r < size; r++) List.filled(size, 0)],
  ];
  var changed = false;
  var contradiction = false;
  void mark(int g, int row, int col, int value) {
    final now = grids[g][row][col];
    if (now == 0) {
      grids[g][row][col] = value;
      changed = true;
    } else if (now != value) {
      contradiction = true;
    }
  }

  for (final clue in clues) {
    final yes = clue.kind == WhoClueKind.has || clue.kind == WhoClueKind.linked;
    if (!clue.isLinked) {
      mark(clue.category, clue.child, clue.item, yes ? 1 : -1);
    } else if (clue.category == 0) {
      mark(2, clue.item, clue.otherItem, yes ? 1 : -1);
    } else {
      mark(2, clue.otherItem, clue.item, yes ? 1 : -1);
    }
  }
  do {
    changed = false;
    for (var g = 0; g < grids.length; g++) {
      final grid = grids[g];
      for (var i = 0; i < size; i++) {
        for (var j = 0; j < size; j++) {
          if (grid[i][j] != 1) continue;
          for (var k = 0; k < size; k++) {
            if (k != j) mark(g, i, k, -1);
            if (k != i) mark(g, k, j, -1);
          }
        }
        final rowLeft = [
          for (var j = 0; j < size; j++)
            if (grid[i][j] != -1) j,
        ];
        if (rowLeft.length == 1) mark(g, i, rowLeft.single, 1);
        final columnLeft = [
          for (var j = 0; j < size; j++)
            if (grid[j][i] != -1) j,
        ];
        if (columnLeft.length == 1) mark(g, columnLeft.single, i, 1);
      }
    }
    // Two yeses make the third a yes; a yes and a no make the third a no.
    void infer(int g, int row, int col, int p, int q) {
      if (p == 1 && q == 1) {
        mark(g, row, col, 1);
      } else if (p != 0 && p + q == 0) {
        mark(g, row, col, -1);
      }
    }

    for (var child = 0; child < size; child++) {
      for (var x = 0; x < size; x++) {
        for (var y = 0; y < size; y++) {
          final a = grids[0][child][x], b = grids[1][child][y];
          final c = grids[2][x][y];
          infer(2, x, y, a, b);
          infer(0, child, x, b, c);
          infer(1, child, y, a, c);
        }
      }
    }
  } while (changed && !contradiction);
  return !contradiction &&
      grids.take(2).every((grid) => grid.every((row) => row.contains(1)));
}

class WhoPuzzle {
  const WhoPuzzle({
    required this.names,
    required this.categories,
    required this.items,
    required this.solution,
    required this.clues,
  });

  /// The children, in table order.
  final List<String> names;
  final List<WhoCategory> categories;

  /// The items in play for each category, in the order pickers list them.
  final List<List<String>> items;

  /// The answer: `solution[category][child]` indexes `items[category]`.
  final List<List<int>> solution;

  /// In the order they're shown and numbered.
  final List<WhoClue> clues;

  int get size => names.length;

  /// Plain "Ana has the cat." clues give a whole cell away, so a puzzle
  /// uses at most this many.
  static const maxPlainPositives = 1;

  /// How many clues a puzzle of [size] children should have.
  static ({int min, int max}) clueRange(int size) =>
      size <= 3 ? (min: 4, max: 6) : (min: 5, max: 8);

  /// A head start for each kind in the seeded order clues are tried in (on
  /// top of a random 0–99): linked clues and negatives make the player
  /// combine facts, while a plain positive gives a cell away. Four children
  /// still need their one positive to stay within eight clues, so it isn't
  /// pushed right to the back.
  static const _preference = {
    WhoClueKind.linked: 60,
    WhoClueKind.linkedNot: 40,
    WhoClueKind.hasNot: 40,
    WhoClueKind.has: 15,
  };

  /// One day's pair (or a practice pair, from another seed): three children
  /// with a pet and a favourite colour, then four new children with a pet
  /// and a favourite snack or a hobby, taking turns day by day.
  static List<WhoPuzzle> dailySet(int seed) {
    final first = WhoPuzzle.generate(seed, size: 3, second: WhoCategory.colour);
    final second = WhoPuzzle.generate(
      seed,
      size: 4,
      second: seed.isEven ? WhoCategory.snack : WhoCategory.hobby,
      avoidNames: first.names.toSet(),
    );
    return [first, second];
  }

  /// The same arguments always give the same puzzle. Attempts that land
  /// outside [clueRange], or that would need guessing, are thrown away and
  /// the next one is tried.
  factory WhoPuzzle.generate(
    int seed, {
    required int size,
    required WhoCategory second,
    Set<String> avoidNames = const {},
  }) {
    assert(second != WhoCategory.pet, 'The pet is always the first category');
    assert(size >= 2 && size <= 6, 'Pools hold six or seven items');
    assert(whoNames.length - avoidNames.length >= size, 'Not enough names');
    final random = Random(seed * 100 + size * 10 + second.index);
    final range = clueRange(size);
    while (true) {
      final puzzle = _attempt(random, size, [
        WhoCategory.pet,
        second,
      ], avoidNames);
      final count = puzzle.clues.length;
      if (count >= range.min &&
          count <= range.max &&
          solvableByDeduction(size, puzzle.clues)) {
        return puzzle;
      }
    }
  }

  static WhoPuzzle _attempt(
    Random random,
    int size,
    List<WhoCategory> categories,
    Set<String> avoidNames,
  ) {
    final names = <String>[];
    for (final name in List.of(whoNames)..shuffle(random)) {
      if (names.length < size &&
          !avoidNames.contains(name) &&
          names.every((n) => n[0] != name[0])) {
        names.add(name);
      }
    }
    final items = [
      for (final category in categories) _pick(category.pool, size, random),
    ];
    final solution = [
      for (final _ in categories)
        List.generate(size, (i) => i)..shuffle(random),
    ];
    final truth = WhoAssignment(solution);

    // Try the clues in a seeded order that favours linked and negative ones.
    final pool = _trueClues(truth, size, categories.length, random);
    final ranked =
        [
          for (var i = 0; i < pool.length; i++)
            (
              clue: pool[i],
              rank: random.nextInt(100) + _preference[pool[i].kind]!,
              index: i,
            ),
        ]..sort((a, b) {
          final byRank = b.rank.compareTo(a.rank);
          return byRank != 0 ? byRank : a.index.compareTo(b.index);
        });

    var candidates = whoAssignments(size, categories: categories.length);
    final chosen = <WhoClue>[];
    var positives = 0;
    for (final entry in ranked) {
      final clue = entry.clue;
      if (candidates.length == 1) break;
      if (clue.kind == WhoClueKind.has && positives >= maxPlainPositives) {
        continue;
      }
      final remaining = candidates.where(clue.holds).toList();
      // A clue that rules nothing out yet would only be noise.
      if (remaining.length == candidates.length) continue;
      chosen.add(clue);
      if (clue.kind == WhoClueKind.has) positives++;
      candidates = remaining;
    }

    // Every clue must earn its place: drop any the answer doesn't need.
    for (final clue in List.of(chosen)) {
      final without = [...chosen]..remove(clue);
      final count = countSolutions(
        size,
        without,
        categories: categories.length,
        stopAt: 2,
      );
      if (count == 1) chosen.remove(clue);
    }
    chosen.shuffle(random);

    return WhoPuzzle(
      names: names,
      categories: categories,
      items: items,
      solution: solution,
      clues: chosen,
    );
  }

  /// [count] items from [pool], listed in pool order.
  static List<String> _pick(List<String> pool, int count, Random random) {
    final picked = (List.of(pool)..shuffle(random)).take(count).toSet();
    return [
      for (final item in pool)
        if (picked.contains(item)) item,
    ];
  }

  /// Every clue that's true of [truth].
  static List<WhoClue> _trueClues(
    WhoAssignment truth,
    int size,
    int categoryCount,
    Random random,
  ) {
    final clues = <WhoClue>[];
    for (var c = 0; c < categoryCount; c++) {
      for (var child = 0; child < size; child++) {
        for (var item = 0; item < size; item++) {
          clues.add(
            item == truth.items[c][child]
                ? WhoClue.has(child, c, item)
                : WhoClue.hasNot(child, c, item),
          );
        }
      }
    }
    for (var c = 0; c < categoryCount; c++) {
      for (var other = c + 1; other < categoryCount; other++) {
        for (var item = 0; item < size; item++) {
          for (var otherItem = 0; otherItem < size; otherItem++) {
            final same =
                truth.owners[c][item] == truth.owners[other][otherItem];
            if (!same) {
              clues.add(WhoClue.linkedNot(other, otherItem, c, item));
            } else if (random.nextBool()) {
              clues.add(WhoClue.linked(c, item, other, otherItem));
            } else {
              clues.add(WhoClue.linked(other, otherItem, c, item));
            }
          }
        }
      }
    }
    return clues;
  }

  /// The item [child] really has in [category].
  String answer(int child, int category) =>
      items[category][solution[category][child]];

  /// The clue as a sentence: "The child with the fish likes green."
  String sentence(WhoClue clue) {
    switch (clue.kind) {
      case WhoClueKind.has || WhoClueKind.hasNot:
        return categories[clue.category].statement(
          names[clue.child],
          items[clue.category][clue.item],
          positive: clue.kind == WhoClueKind.has,
        );
      case WhoClueKind.linked || WhoClueKind.linkedNot:
        final positive = clue.kind == WhoClueKind.linked;
        var (subject, subjectItem) = (clue.category, clue.item);
        var (object, objectItem) = (clue.otherCategory, clue.otherItem);
        // "Not" links read best ending on the pet: "…doesn’t have the dog."
        final petFirst =
            categories[subject] == WhoCategory.pet &&
            categories[object] != WhoCategory.pet;
        if (!positive && petFirst) {
          (subject, subjectItem, object, objectItem) = (
            object,
            objectItem,
            subject,
            subjectItem,
          );
        }
        final start = categories[subject].subject(items[subject][subjectItem]);
        final end = categories[object].predicate(
          items[object][objectItem],
          positive: positive,
        );
        return '$start $end.';
    }
  }

  List<String> get clueTexts => [for (final clue in clues) sentence(clue)];
}

/// A table cell: one child's item in one category.
typedef WhoCell = ({int child, int category});

/// What "Check answers" found.
class WhoCheck {
  const WhoCheck({required this.right, required this.total, this.empty = 0});

  final int right, total;

  /// Cells still blank. A check with blanks isn't marked or charged.
  final int empty;

  bool get solved => empty == 0 && right == total;
}

/// A player's working table for one puzzle, and its score.
class WhoRound {
  WhoRound(this.puzzle)
    : picks = [
        for (final _ in puzzle.categories) List<int?>.filled(puzzle.size, null),
      ];

  static const startPoints = 100;
  static const hintCost = 25;
  static const wrongCheckCost = 15;
  static const minPoints = 20;

  final WhoPuzzle puzzle;

  /// `picks[category][child]`: the chosen item's index, or null.
  final List<List<int?>> picks;

  /// Cells the last check found wrong, until they're changed.
  final Set<WhoCell> wrong = {};

  /// Cells filled by a hint. They're right, so they're locked.
  final Set<WhoCell> hinted = {};

  /// Clues the player has crossed off.
  final Set<int> usedClues = {};

  int hints = 0;
  int wrongChecks = 0;
  bool solved = false;

  /// What solving it is worth now (and what it scored, once solved).
  int get points => max(
    minPoints,
    startPoints - hintCost * hints - wrongCheckCost * wrongChecks,
  );

  /// Every cell, row by row: each child's categories in turn.
  List<WhoCell> get cells => [
    for (var child = 0; child < puzzle.size; child++)
      for (var category = 0; category < puzzle.categories.length; category++)
        (child: child, category: category),
  ];

  int? pickAt(WhoCell cell) => picks[cell.category][cell.child];

  bool isRight(WhoCell cell) =>
      pickAt(cell) == puzzle.solution[cell.category][cell.child];

  int get emptyCount => cells.where((cell) => pickAt(cell) == null).length;

  /// The child who has [item] from [category] in the table, if anyone.
  int? ownerOf(int category, int item) {
    final child = picks[category].indexOf(item);
    return child < 0 ? null : child;
  }

  /// Whether [item] can go in [cell]: not over a hint, and not taken from a
  /// hint elsewhere.
  bool canChoose(WhoCell cell, int item) {
    if (solved || hinted.contains(cell)) return false;
    final owner = ownerOf(cell.category, item);
    return owner == null ||
        owner == cell.child ||
        !hinted.contains((child: owner, category: cell.category));
  }

  /// Puts [item] in [cell], moving it from whoever had it (each item
  /// belongs to one child). Null clears the cell. False if nothing changed.
  bool choose(WhoCell cell, int? item) {
    if (solved || hinted.contains(cell)) return false;
    if (item == pickAt(cell)) return false;
    if (item != null) {
      if (!canChoose(cell, item)) return false;
      final owner = ownerOf(cell.category, item);
      if (owner != null) {
        picks[cell.category][owner] = null;
        wrong.remove((child: owner, category: cell.category));
      }
    }
    picks[cell.category][cell.child] = item;
    wrong.remove(cell);
    return true;
  }

  /// Marks wrong cells without saying what's right. A full table that's
  /// wrong costs points; one with blanks is only counted.
  WhoCheck check() {
    final total = cells.length;
    if (solved) return WhoCheck(right: total, total: total);
    final empty = emptyCount;
    if (empty > 0) {
      final right = cells.where((c) => pickAt(c) != null && isRight(c)).length;
      return WhoCheck(right: right, total: total, empty: empty);
    }
    final mistakes = [
      for (final cell in cells)
        if (!isRight(cell)) cell,
    ];
    if (mistakes.isEmpty) {
      solved = true;
      wrong.clear();
    } else {
      wrongChecks++;
      wrong
        ..clear()
        ..addAll(mistakes);
    }
    return WhoCheck(right: total - mistakes.length, total: total);
  }

  /// Fills one cell with its answer — a ✕ cell first, then a blank one, then
  /// any other mistake — and locks it. Returns that cell, or null when every
  /// cell was already right. Solves the puzzle once the table is all right.
  WhoCell? hint() {
    if (solved) return null;
    final open = [
      for (final cell in cells)
        if (!isRight(cell)) cell,
    ];
    WhoCell? target;
    if (open.isNotEmpty) {
      target = open.firstWhere(
        wrong.contains,
        orElse: () => open.firstWhere(
          (cell) => pickAt(cell) == null,
          orElse: () => open.first,
        ),
      );
      final answer = puzzle.solution[target.category][target.child];
      final owner = ownerOf(target.category, answer);
      if (owner != null) {
        picks[target.category][owner] = null;
        wrong.remove((child: owner, category: target.category));
      }
      picks[target.category][target.child] = answer;
      wrong.remove(target);
      hinted.add(target);
      hints++;
    }
    if (cells.every(isRight)) {
      solved = true;
      wrong.clear();
    }
    return target;
  }

  void toggleClue(int index) {
    if (!usedClues.remove(index)) usedClues.add(index);
  }
}
