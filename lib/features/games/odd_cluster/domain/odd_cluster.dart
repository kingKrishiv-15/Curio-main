import 'dart:math';

/// Odd Cluster: sixteen tiles hiding four groups of four. Groups are about
/// knowledge, not wordplay, and every puzzle has one easy group, two medium
/// and one sneaky group whose tiles look like they belong somewhere easier.
///
/// The authoring rule that keeps it fair: for each group's stated rule,
/// exactly four tiles on the board fit it. A tile can *look* like it belongs
/// elsewhere (that's the trap) but never truly does, so a thoughtful player
/// is never right-but-marked-wrong.
class ClusterGroup {
  const ClusterGroup({
    required this.title,
    required this.words,
    required this.tier,
    required this.explanation,
  });

  final String title;
  final List<String> words;

  /// 0 easy · 1 and 2 medium · 3 sneaky.
  final int tier;

  /// Shown once the group is found or revealed: why these four belong.
  final String explanation;
}

class ClusterPuzzle {
  const ClusterPuzzle(this.groups);
  final List<ClusterGroup> groups;

  List<String> get words => [for (final g in groups) ...g.words];
}

enum ClusterVerdict { found, oneAway, wrong, repeat }

class OddClusterGame {
  OddClusterGame(this.puzzle, {int seed = 0})
    : _order = List.of(puzzle.words)..shuffle(Random(seed));

  static const maxMistakes = 4;

  final ClusterPuzzle puzzle;
  final List<String> _order;
  final List<ClusterGroup> found = [];
  final List<ClusterGroup> revealed = [];
  final Set<String> _tried = {};

  /// One row per guess, each the tiers of the four chosen tiles — enough
  /// for a spoiler-free share grid.
  final List<List<int>> history = [];
  int mistakes = 0;

  bool get won => found.length == puzzle.groups.length;
  bool get lost => mistakes >= maxMistakes && !won;
  bool get finished => won || lost;
  int get mistakesLeft => maxMistakes - mistakes;

  /// Tiles still in play, in board order.
  List<String> get board {
    final done = {for (final g in [...found, ...revealed]) ...g.words};
    return [for (final w in _order) if (!done.contains(w)) w];
  }

  ClusterGroup groupOf(String word) =>
      puzzle.groups.firstWhere((g) => g.words.contains(word));

  void shuffle(Random random) {
    final remaining = board..shuffle(random);
    final done = _order.where((w) => !remaining.contains(w)).toList();
    _order
      ..clear()
      ..addAll([...done, ...remaining]);
  }

  ClusterVerdict guess(Set<String> selection) {
    if (finished) throw StateError('The puzzle is already over.');
    final live = board.toSet();
    if (selection.length != 4 || !live.containsAll(selection)) {
      throw ArgumentError('Pick four tiles that are still on the board.');
    }
    final key = (selection.toList()..sort()).join('|');
    if (!_tried.add(key)) return ClusterVerdict.repeat;

    history.add([for (final w in selection) groupOf(w).tier]);
    final unsolved = puzzle.groups.where((g) => !found.contains(g));
    for (final group in unsolved) {
      if (group.words.toSet().containsAll(selection)) {
        found.add(group);
        return ClusterVerdict.found;
      }
    }
    mistakes++;
    final nearMiss = unsolved.any(
      (g) => g.words.where(selection.contains).length == 3,
    );
    if (lost) {
      revealed.addAll(unsolved.where((g) => !found.contains(g)));
    }
    return nearMiss ? ClusterVerdict.oneAway : ClusterVerdict.wrong;
  }

  /// "🟨🟨🟨🟨" rows, coloured by group difficulty, never naming a tile.
  String shareGrid() {
    const squares = ['🟨', '🟩', '🟦', '🟪'];
    return history.map((row) => row.map((t) => squares[t]).join()).join('\n');
  }
}

const oddClusterPuzzles = <ClusterPuzzle>[
  ClusterPuzzle([
    ClusterGroup(
      title: 'Birds that can’t fly',
      words: ['PENGUIN', 'OSTRICH', 'EMU', 'KIWI'],
      tier: 0,
      explanation:
          'Penguins swim, ostriches and emus run, and kiwis forage at night — none of them can fly.',
    ),
    ClusterGroup(
      title: 'Exactly 1,000 of something',
      words: ['MILLENNIUM', 'KILOGRAM', 'KILOMETRE', 'LITRE'],
      tier: 1,
      explanation:
          'A millennium is 1,000 years, a kilogram 1,000 grams, a kilometre 1,000 metres and a litre 1,000 millilitres.',
    ),
    ClusterGroup(
      title: 'Big cities that aren’t the national capital',
      words: ['SYDNEY', 'TORONTO', 'ISTANBUL', 'MUMBAI'],
      tier: 2,
      explanation:
          'Famous and busy — but the national capitals are Canberra, Ottawa, Ankara and New Delhi.',
    ),
    ClusterGroup(
      title: 'Capitals that aren’t the biggest city',
      words: ['CANBERRA', 'OTTAWA', 'BRASILIA', 'ANKARA'],
      tier: 3,
      explanation:
          'Each runs its country, yet a different city is bigger: Sydney, Toronto, São Paulo and Istanbul. The trap was pairing cities by country.',
    ),
  ]),
  ClusterPuzzle([
    ClusterGroup(
      title: 'Prime numbers',
      words: ['2', '13', '29', '41'],
      tier: 0,
      explanation:
          'Each can only be divided evenly by 1 and itself. 2 is the only even prime.',
    ),
    ClusterGroup(
      title: 'Square numbers',
      words: ['16', '36', '49', '100'],
      tier: 1,
      explanation: '4 × 4, 6 × 6, 7 × 7 and 10 × 10.',
    ),
    ClusterGroup(
      title: 'Cube numbers',
      words: ['8', '125', '216', '343'],
      tier: 2,
      explanation: '2 × 2 × 2, 5 × 5 × 5, 6 × 6 × 6 and 7 × 7 × 7.',
    ),
    ClusterGroup(
      title: 'Palindromes in binary',
      words: ['15', '21', '33', '45'],
      tier: 3,
      explanation:
          'Written in binary they read the same both ways: 1111, 10101, 100001 and 101101. They look like the 3 times table — but so do 36 and 216.',
    ),
  ]),
  ClusterPuzzle([
    ClusterGroup(
      title: 'Rocky planets',
      words: ['MERCURY', 'VENUS', 'EARTH', 'MARS'],
      tier: 0,
      explanation:
          'The four planets closest to the Sun all have solid, rocky surfaces.',
    ),
    ClusterGroup(
      title: 'Moons',
      words: ['TITAN', 'EUROPA', 'PHOBOS', 'TRITON'],
      tier: 1,
      explanation:
          'Titan circles Saturn, Europa circles Jupiter, Phobos circles Mars and Triton circles Neptune.',
    ),
    ClusterGroup(
      title: 'Missions and spacecraft',
      words: ['VOYAGER', 'APOLLO', 'HUBBLE', 'CHANDRAYAAN'],
      tier: 2,
      explanation:
          'The Voyager probes reached interstellar space, Apollo landed people on the Moon, Hubble photographs deep space and Chandrayaan is India’s Moon programme.',
    ),
    ClusterGroup(
      title: 'Planets with rings',
      words: ['SATURN', 'JUPITER', 'URANUS', 'NEPTUNE'],
      tier: 3,
      explanation:
          'All four giant planets have rings — Saturn’s are just the brightest. They looked like they belonged with the rocky planets.',
    ),
  ]),
  ClusterPuzzle([
    ClusterGroup(
      title: 'Insects',
      words: ['ANT', 'BEE', 'BEETLE', 'BUTTERFLY'],
      tier: 0,
      explanation: 'Six legs and three body parts: head, thorax and abdomen.',
    ),
    ClusterGroup(
      title: 'Mammals that live in the sea',
      words: ['DOLPHIN', 'WHALE', 'SEAL', 'WALRUS'],
      tier: 1,
      explanation:
          'They breathe air and feed their young milk, even though they live in water.',
    ),
    ClusterGroup(
      title: 'Real fish',
      words: ['SHARK', 'SALMON', 'TUNA', 'SEAHORSE'],
      tier: 2,
      explanation:
          'A seahorse is a fish, and so is a shark — they breathe through gills and have backbones.',
    ),
    ClusterGroup(
      title: 'Not fish at all',
      words: ['STARFISH', 'JELLYFISH', 'CUTTLEFISH', 'SHELLFISH'],
      tier: 3,
      explanation:
          'Despite the names: starfish are related to sea urchins, jellyfish to corals, cuttlefish are molluscs like octopuses, and shellfish are molluscs or crustaceans.',
    ),
  ]),
  ClusterPuzzle([
    ClusterGroup(
      title: 'Metals',
      words: ['IRON', 'COPPER', 'GOLD', 'ZINC'],
      tier: 0,
      explanation: 'Pure metal elements — each is a single kind of atom.',
    ),
    ClusterGroup(
      title: 'Gemstones',
      words: ['RUBY', 'EMERALD', 'SAPPHIRE', 'DIAMOND'],
      tier: 1,
      explanation:
          'Minerals prized for colour and sparkle. A diamond is pure carbon.',
    ),
    ClusterGroup(
      title: 'Noble gases',
      words: ['HELIUM', 'NEON', 'ARGON', 'XENON'],
      tier: 2,
      explanation:
          'Gases that barely react with anything — which is why party balloons use helium instead of flammable hydrogen.',
    ),
    ClusterGroup(
      title: 'Alloys (mixtures, not elements)',
      words: ['BRONZE', 'BRASS', 'STEEL', 'PEWTER'],
      tier: 3,
      explanation:
          'They look like metals, but each is a mix: bronze is copper and tin, brass is copper and zinc, steel is iron and carbon, pewter is mostly tin.',
    ),
  ]),
  ClusterPuzzle([
    ClusterGroup(
      title: 'Fruits we eat as fruit',
      words: ['MANGO', 'APPLE', 'BANANA', 'CHERRY'],
      tier: 0,
      explanation: 'Sweet fruits, usually eaten as a snack or dessert.',
    ),
    ClusterGroup(
      title: 'Vegetables from roots, leaves and stems',
      words: ['CARROT', 'SPINACH', 'POTATO', 'ONION'],
      tier: 1,
      explanation:
          'A carrot is a root, spinach is leaves, a potato is a swollen underground stem and an onion is a bulb.',
    ),
    ClusterGroup(
      title: 'Spices',
      words: ['CINNAMON', 'TURMERIC', 'GINGER', 'SAFFRON'],
      tier: 2,
      explanation:
          'Cinnamon is tree bark, turmeric and ginger are underground stems, and saffron comes from a flower.',
    ),
    ClusterGroup(
      title: 'Secretly fruits',
      words: ['TOMATO', 'CUCUMBER', 'PUMPKIN', 'AUBERGINE'],
      tier: 3,
      explanation:
          'Cooked like vegetables, but to a botanist they’re fruits: they grow from a flower and carry seeds.',
    ),
  ]),
];
