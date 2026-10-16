import 'dart:math';

/// Link Lab: the gentle grouping game. Sixteen tiles hide four groups of four,
/// each with a clear, kid-friendly link — no trick groups (Odd Cluster is the
/// tricky one). Hints are free and mistakes never end the game; they're
/// counted honestly and show up in the share grid.
///
/// The authoring rule: for each group's stated link, exactly four tiles on the
/// board fit it, so no tile could sensibly sit in two groups.
class LinkGroup {
  const LinkGroup({
    required this.title,
    required this.words,
    required this.why,
  });

  /// The link, as the player would say it ("Rocky planets").
  final String title;
  final List<String> words;

  /// Shown once the group is found: why these four belong together.
  final String why;
}

class LinkPuzzle {
  const LinkPuzzle(this.groups);
  final List<LinkGroup> groups;

  List<String> get words => [for (final g in groups) ...g.words];
}

enum LinkVerdict { found, oneAway, wrong, repeat }

/// A nudge: first the name of a hidden group, then — once every hidden group
/// has been named — one of its tiles.
class LinkHint {
  const LinkHint(this.group, [this.word]);
  final LinkGroup group;
  final String? word;
}

/// Which day's puzzle to play: today's, or for practice round [practice]
/// (1, 2, 3…) a step back through earlier days — cycling through every puzzle
/// except today's and tomorrow's, so practice never spoils a daily.
int linkLabDay(int today, {int practice = 0}) => practice <= 0
    ? today
    : today - 1 - (practice - 1) % (linkLabPuzzles.length - 2);

class LinkLabGame {
  LinkLabGame(this.puzzle, {int seed = 0})
    : _order = List.of(puzzle.words)..shuffle(Random(seed));

  /// The puzzle for a day number (see `DailyPick.dayNumber`), with the board
  /// shuffled the same way for everyone that day.
  factory LinkLabGame.forDay(int day) =>
      LinkLabGame(linkLabPuzzles[day % linkLabPuzzles.length], seed: day);

  static const squares = ['🟨', '🟩', '🟦', '🟪'];

  final LinkPuzzle puzzle;
  final List<String> _order;
  final List<LinkGroup> found = [];
  final Set<String> _tried = {};

  /// Groups whose link a hint has named, and tiles a hint has pointed at.
  final Set<LinkGroup> named = {};
  final Set<String> pointedAt = {};

  /// One row per guess: the group number (0–3) of each chosen tile.
  final List<List<int>> history = [];
  int mistakes = 0;
  int hints = 0;

  bool get won => found.length == puzzle.groups.length;

  /// Tiles still in play, in board order.
  List<String> get board {
    final done = {for (final g in found) ...g.words};
    return [
      for (final w in _order)
        if (!done.contains(w)) w,
    ];
  }

  /// 0–3: the group's colour and share square.
  int colourOf(LinkGroup group) => puzzle.groups.indexOf(group);

  LinkGroup groupOf(String word) =>
      puzzle.groups.firstWhere((g) => g.words.contains(word));

  void shuffle(Random random) {
    final remaining = board..shuffle(random);
    final done = _order.where((w) => !remaining.contains(w)).toList();
    _order
      ..clear()
      ..addAll([...done, ...remaining]);
  }

  LinkVerdict guess(Set<String> selection) {
    if (won) throw StateError('Every link is already found.');
    final live = board.toSet();
    if (selection.length != 4 || !live.containsAll(selection)) {
      throw ArgumentError('Pick four tiles that are still on the board.');
    }
    final key = (selection.toList()..sort()).join('|');
    if (!_tried.add(key)) return LinkVerdict.repeat;

    history.add([for (final w in selection) colourOf(groupOf(w))]);
    final unsolved = puzzle.groups.where((g) => !found.contains(g)).toList();
    for (final group in unsolved) {
      if (group.words.toSet().containsAll(selection)) {
        found.add(group);
        return LinkVerdict.found;
      }
    }
    mistakes++;
    final nearMiss = unsolved.any(
      (g) => g.words.where(selection.contains).length == 3,
    );
    return nearMiss ? LinkVerdict.oneAway : LinkVerdict.wrong;
  }

  /// The next hint, or null when there's nothing left to give.
  LinkHint? hint() {
    if (won) return null;
    final unsolved = puzzle.groups.where((g) => !found.contains(g));
    for (final group in unsolved) {
      if (named.add(group)) {
        hints++;
        return LinkHint(group);
      }
    }
    for (final group in unsolved) {
      for (final word in group.words) {
        if (pointedAt.add(word)) {
          hints++;
          return LinkHint(group, word);
        }
      }
    }
    return null;
  }

  /// "🟨🟨🟩🟨" rows, one per guess, never naming a tile.
  String shareGrid() => history
      .map((row) => (List.of(row)..sort()).map((g) => squares[g]).join())
      .join('\n');
}

/// The bank: clear categories a curious 8–12-year-old can reason about.
/// Each tile fits exactly one group's link.
const linkLabPuzzles = <LinkPuzzle>[
  LinkPuzzle([
    LinkGroup(
      title: 'Rocky planets',
      words: ['MERCURY', 'VENUS', 'EARTH', 'MARS'],
      why:
          'The four planets closest to the Sun all have solid, rocky surfaces.',
    ),
    LinkGroup(
      title: 'String instruments',
      words: ['VIOLIN', 'VIOLA', 'CELLO', 'HARP'],
      why: 'Each one makes its sound from vibrating strings, bowed or plucked.',
    ),
    LinkGroup(
      title: 'Gemstones',
      words: ['RUBY', 'SAPPHIRE', 'EMERALD', 'OPAL'],
      why: 'Precious stones, cut and polished for their colour and sparkle.',
    ),
    LinkGroup(
      title: 'Famous rivers',
      words: ['NILE', 'THAMES', 'GANGES', 'YANGTZE'],
      why:
          'The Nile flows through Africa, the Thames through England, and the Ganges and Yangtze through Asia.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Baby animals',
      words: ['FOAL', 'LAMB', 'CALF', 'CUB'],
      why:
          'A foal is a young horse, a lamb a young sheep, a calf a young cow and a cub a young bear, lion or fox.',
    ),
    LinkGroup(
      title: 'Animal homes',
      words: ['NEST', 'BURROW', 'KENNEL', 'STABLE'],
      why:
          'Birds build nests, rabbits dig burrows, dogs can sleep in kennels and horses live in stables.',
    ),
    LinkGroup(
      title: 'Animal groups',
      words: ['HERD', 'FLOCK', 'PACK', 'SWARM'],
      why:
          'A herd of cows, a flock of sheep, a pack of wolves and a swarm of bees.',
    ),
    LinkGroup(
      title: 'Animal sounds',
      words: ['NEIGH', 'QUACK', 'HOOT', 'OINK'],
      why: 'Horses neigh, ducks quack, owls hoot and pigs oink.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Organs',
      words: ['HEART', 'LUNGS', 'BRAIN', 'STOMACH'],
      why:
          'Each organ has a big job: pumping blood, breathing, thinking and digesting food.',
    ),
    LinkGroup(
      title: 'Senses',
      words: ['SIGHT', 'HEARING', 'TASTE', 'SMELL'],
      why: 'Four of your five senses. The fifth is touch.',
    ),
    LinkGroup(
      title: 'Bones',
      words: ['FEMUR', 'RIB', 'SKULL', 'KNEECAP'],
      why:
          'The femur in your thigh is your longest bone, ribs guard your heart and lungs, the skull protects your brain and the kneecap shields your knee.',
    ),
    LinkGroup(
      title: 'Parts of the eye',
      words: ['PUPIL', 'IRIS', 'LENS', 'RETINA'],
      why:
          'Light goes in through the pupil, the iris changes its size, the lens focuses it and the retina senses the picture.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Flat shapes',
      words: ['TRIANGLE', 'SQUARE', 'PENTAGON', 'HEXAGON'],
      why: 'Flat shapes with 3, 4, 5 and 6 straight sides.',
    ),
    LinkGroup(
      title: 'Solid shapes',
      words: ['CUBE', 'SPHERE', 'CONE', 'CYLINDER'],
      why:
          '3D shapes you could hold: think of a dice, a ball, a party hat and a tin can.',
    ),
    LinkGroup(
      title: 'Units of length',
      words: ['METRE', 'MILE', 'INCH', 'KILOMETRE'],
      why: 'Ways to measure how long or how far something is.',
    ),
    LinkGroup(
      title: 'Units of time',
      words: ['SECOND', 'MINUTE', 'HOUR', 'DECADE'],
      why: 'Ways to measure time. A decade is ten years.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Kitchen tools',
      words: ['WHISK', 'LADLE', 'SIEVE', 'GRATER'],
      why:
          'A whisk mixes, a ladle scoops soup, a sieve sifts flour and a grater shreds cheese.',
    ),
    LinkGroup(
      title: 'Dairy foods',
      words: ['MILK', 'CHEESE', 'BUTTER', 'YOGHURT'],
      why: 'Milk and foods made from it, usually from cows, goats or sheep.',
    ),
    LinkGroup(
      title: 'Grains',
      words: ['RICE', 'WHEAT', 'OATS', 'BARLEY'],
      why:
          'Seeds of grass plants that feed much of the world. Wheat is ground into flour for bread.',
    ),
    LinkGroup(
      title: 'Vegetables that grow underground',
      words: ['CARROT', 'POTATO', 'BEETROOT', 'PARSNIP'],
      why:
          'Carrots, beetroots and parsnips are roots, and potatoes are swollen underground stems.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Boats',
      words: ['CANOE', 'KAYAK', 'FERRY', 'YACHT'],
      why: 'Ways to travel on water, paddled, powered or sailed.',
    ),
    LinkGroup(
      title: 'Aircraft',
      words: ['AEROPLANE', 'GLIDER', 'HELICOPTER', 'AIRSHIP'],
      why:
          'They all fly: wings, spinning blades or a giant bag of gas lift them up.',
    ),
    LinkGroup(
      title: 'Parts of a bike',
      words: ['PEDAL', 'SADDLE', 'CHAIN', 'SPOKE'],
      why:
          'You push the pedals and sit on the saddle; the chain turns the back wheel and spokes keep each wheel in shape.',
    ),
    LinkGroup(
      title: 'Places journeys start',
      words: ['AIRPORT', 'HARBOUR', 'STATION', 'HELIPAD'],
      why:
          'Where travellers get on and off planes, boats, trains and helicopters.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Rainbow colours',
      words: ['ORANGE', 'YELLOW', 'INDIGO', 'VIOLET'],
      why:
          'Four of the seven: red, orange, yellow, green, blue, indigo and violet.',
    ),
    LinkGroup(
      title: 'Percussion instruments',
      words: ['DRUM', 'CYMBAL', 'TAMBOURINE', 'XYLOPHONE'],
      why: 'You hit, shake or tap them to make a sound.',
    ),
    LinkGroup(
      title: 'Wind instruments',
      words: ['FLUTE', 'TRUMPET', 'RECORDER', 'TUBA'],
      why: 'You blow into them to make the sound.',
    ),
    LinkGroup(
      title: 'A painter’s kit',
      words: ['EASEL', 'PALETTE', 'BRUSH', 'CANVAS'],
      why:
          'The easel holds the canvas, and the palette holds paint for the brush.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Trees',
      words: ['OAK', 'BIRCH', 'MAPLE', 'WILLOW'],
      why:
          'Oaks grow from acorns, and maple leaves turn red and gold in autumn.',
    ),
    LinkGroup(
      title: 'Flowers',
      words: ['DAISY', 'TULIP', 'POPPY', 'SUNFLOWER'],
      why:
          'Garden and meadow flowers. A sunflower can grow taller than a grown-up.',
    ),
    LinkGroup(
      title: 'Shapes of the land',
      words: ['VALLEY', 'VOLCANO', 'ISLAND', 'CANYON'],
      why:
          'Landforms. A canyon is a deep valley with steep sides, often carved by a river.',
    ),
    LinkGroup(
      title: 'Bodies of water',
      words: ['LAKE', 'POND', 'OCEAN', 'LAGOON'],
      why:
          'From a tiny pond to the vast ocean. A lagoon is shallow water cut off from the sea.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Ball sports',
      words: ['TENNIS', 'NETBALL', 'RUGBY', 'GOLF'],
      why:
          'All played with a ball, from a tiny golf ball to an oval rugby ball.',
    ),
    LinkGroup(
      title: 'Water sports',
      words: ['SWIMMING', 'ROWING', 'SURFING', 'SAILING'],
      why: 'Sports you do in or on the water.',
    ),
    LinkGroup(
      title: 'Board games',
      words: ['CHESS', 'DRAUGHTS', 'LUDO', 'BACKGAMMON'],
      why:
          'Games played by moving pieces around a board. Chess and draughts are hundreds of years old.',
    ),
    LinkGroup(
      title: 'In the playground',
      words: ['SWING', 'SLIDE', 'SEESAW', 'SANDPIT'],
      why: 'Things you’d find in a playground.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Seasons',
      words: ['SPRING', 'SUMMER', 'AUTUMN', 'WINTER'],
      why: 'The four seasons of the year.',
    ),
    LinkGroup(
      title: 'Compass points',
      words: ['NORTH', 'SOUTH', 'EAST', 'WEST'],
      why:
          'The four main points on a compass. Its needle swings to point north.',
    ),
    LinkGroup(
      title: 'Times of day',
      words: ['DAWN', 'NOON', 'DUSK', 'MIDNIGHT'],
      why:
          'Dawn is first light, noon is midday, dusk is when it gets dark and midnight is 12 at night.',
    ),
    LinkGroup(
      title: 'Falls from clouds',
      words: ['RAIN', 'HAIL', 'SLEET', 'SNOW'],
      why:
          'Water falling from clouds: rain is liquid, snow and hail are frozen, and sleet is half-melted snow.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Reptiles',
      words: ['LIZARD', 'SNAKE', 'TORTOISE', 'CROCODILE'],
      why: 'Reptiles have dry, scaly skin, and most lay eggs on land.',
    ),
    LinkGroup(
      title: 'Birds',
      words: ['OWL', 'ROBIN', 'PARROT', 'EAGLE'],
      why: 'Every bird has feathers and hatches from an egg.',
    ),
    LinkGroup(
      title: 'Insects',
      words: ['ANT', 'BEE', 'BEETLE', 'BUTTERFLY'],
      why:
          'Insects have six legs and three body parts: head, thorax and abdomen.',
    ),
    LinkGroup(
      title: 'Mammals',
      words: ['TIGER', 'RABBIT', 'ELEPHANT', 'GIRAFFE'],
      why: 'Mammals have hair or fur and feed their babies milk.',
    ),
  ]),
  LinkPuzzle([
    LinkGroup(
      title: 'Rooms',
      words: ['KITCHEN', 'BEDROOM', 'BATHROOM', 'HALLWAY'],
      why: 'Rooms in a home, each with its own job.',
    ),
    LinkGroup(
      title: 'Furniture',
      words: ['SOFA', 'TABLE', 'WARDROBE', 'BOOKCASE'],
      why: 'Things in a home to sit on, eat at or keep things in.',
    ),
    LinkGroup(
      title: 'Tools for fixing',
      words: ['HAMMER', 'SAW', 'DRILL', 'SPANNER'],
      why: 'Tools for building and mending. A spanner tightens nuts and bolts.',
    ),
    LinkGroup(
      title: 'Clothes',
      words: ['SCARF', 'JUMPER', 'GLOVES', 'SOCKS'],
      why: 'Things you wear — handy when it’s cold outside.',
    ),
  ]),
];
