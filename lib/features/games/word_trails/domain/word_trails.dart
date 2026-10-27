import 'dart:math';

/// A word hidden in the trail: its meaning, and two that aren't.
class TrailWord {
  const TrailWord(this.answer, this.meaning, this.wrong, {this.key = false});

  final String answer;
  final String meaning;
  final List<String> wrong;

  /// The story's theme word, traced in gold.
  final bool key;
}

/// A tiny story whose blanks ({0}, {1}…) are the trail's words, in order.
class TrailStory {
  const TrailStory(this.title, this.story, this.words);

  final String title;
  final String story;
  final List<TrailWord> words;
}

const trailStories = <TrailStory>[
  TrailStory(
    'The windy day',
    'A {0} wind lifted my {1} high above the {2} {3}.',
    [
      TrailWord('STRONG', 'Having lots of power', [
        'Very quiet and still',
        'Soft and fluffy',
      ]),
      TrailWord('KITE', 'A toy that flies on a string', [
        'A small boat',
        'A kind of fruit',
      ], key: true),
      TrailWord('GREEN', 'The colour of grass', [
        'The colour of snow',
        'Very old',
      ]),
      TrailWord('TREES', 'Tall plants with trunks', [
        'Small stones',
        'Pieces of paper',
      ]),
    ],
  ),
  TrailStory('Picnic time', 'We {0} a {1} of {2} for the sunny {3}.', [
    TrailWord('PACKED', 'Put things into a bag or box', [
      'Threw things away',
      'Painted something',
    ]),
    TrailWord('BASKET', 'A container woven from strips', [
      'A kind of hat',
      'A tall ladder',
    ], key: true),
    TrailWord('APPLES', 'Round fruits that grow on trees', [
      'Small birds',
      'Warm coats',
    ]),
    TrailWord('PARK', 'An outdoor place with grass to play on', [
      'A room in a school',
      'A deep river',
    ]),
  ]),
  TrailStory(
    'The brave puppy',
    'The {0} {1} {2} across the {3} to save the {4}.',
    [
      TrailWord('BRAVE', 'Ready to face danger', [
        'Very sleepy',
        'Easily scared',
      ]),
      TrailWord('PUPPY', 'A young dog', [
        'A baby cat',
        'A small horse',
      ], key: true),
      TrailWord('SWAM', 'Moved through water', [
        'Flew through the air',
        'Climbed a tree',
      ]),
      TrailWord('POND', 'A small area of still water', [
        'A tall mountain',
        'A busy road',
      ]),
      TrailWord('DUCK', 'A water bird with a flat beak', [
        'A striped insect',
        'A forest animal with antlers',
      ]),
    ],
  ),
  TrailStory('Night sky', 'At {0} we saw the {1} {2} and a {3} star.', [
    TrailWord('NIGHT', 'The dark time after sunset', [
      'Early in the morning',
      'The middle of lunch',
    ]),
    TrailWord('BRIGHT', 'Giving out lots of light', [
      'Very heavy',
      'Dull and grey',
    ]),
    TrailWord('MOON', 'The round light in the night sky', [
      'A kind of cloud',
      'A big ocean wave',
    ], key: true),
    TrailWord('SHOOTING', 'Moving very fast', [
      'Standing still',
      'Growing slowly',
    ]),
  ]),
  TrailStory('Baking day', 'Mum and I {0} {1} and {2} to {3} a cake.', [
    TrailWord('MIXED', 'Stirred things together', [
      'Cut into pieces',
      'Kept apart',
    ]),
    TrailWord('FLOUR', 'Powder made from ground grain', [
      'A colourful bloom',
      'A kind of juice',
    ]),
    TrailWord('SUGAR', 'A sweet powder', ['A salty drink', 'A sour fruit']),
    TrailWord('BAKE', 'Cook in an oven', [
      'Wash in water',
      'Freeze in ice',
    ], key: true),
  ]),
  TrailStory('In the garden', 'The {0} watered the {1} so the {2} would {3}.', [
    TrailWord('GARDENER', 'A person who looks after plants', [
      'A person who fixes cars',
      'A person who writes books',
    ]),
    TrailWord('SEEDS', 'Tiny parts that grow into plants', [
      'Small shiny coins',
      'Drops of rain',
    ]),
    TrailWord('FLOWERS', 'Colourful parts of plants', [
      'Kinds of insects',
      'Pieces of wood',
    ], key: true),
    TrailWord('GROW', 'Get bigger', ['Get smaller', 'Fall asleep']),
  ]),
  TrailStory('Rainy walk', 'We wore our {0} {1} to {2} in the {3}.', [
    TrailWord('YELLOW', 'The colour of the sun', [
      'The colour of the night',
      'Very wet',
    ]),
    TrailWord('BOOTS', 'Strong shoes that cover the ankle', [
      'Warm hats',
      'Long scarves',
    ]),
    TrailWord('SPLASH', 'Make water fly about', [
      'Whisper quietly',
      'Sit very still',
    ]),
    TrailWord('PUDDLES', 'Small pools of water on the ground', [
      'Piles of leaves',
      'Tall towers',
    ], key: true),
  ]),
  TrailStory('At the library', 'I {0} a {1} {2} from the {3}.', [
    TrailWord('BORROWED', 'Took something to give back later', [
      'Bought something',
      'Lost something',
    ]),
    TrailWord('FUNNY', 'Making people laugh', [
      'Making people cry',
      'Very boring',
    ]),
    TrailWord('BOOK', 'Pages of words fixed together', [
      'A kind of shoe',
      'A loud noise',
    ], key: true),
    TrailWord('LIBRARY', 'A place where you can borrow books', [
      'A place to buy food',
      'A place to swim',
    ]),
  ]),
];

/// A board square: its letter, and which word it belongs to (null for a
/// blank square).
typedef TrailSquare = ({String letter, int? word});

/// A story laid out on a 5×5 board. Its words run one after another along
/// a snaking path — left to right, then right to left — so every letter
/// belongs to exactly one word and neighbouring letters always touch.
class WordTrail {
  WordTrail(this.story) {
    final route = [
      for (var r = 0; r < size; r++)
        for (var i = 0; i < size; i++) r * size + (r.isEven ? i : size - 1 - i),
    ];
    var at = 0;
    for (final (w, word) in story.words.indexed) {
      final path = route.sublist(at, at + word.answer.length);
      for (final (i, square) in path.indexed) {
        squares[square] = (letter: word.answer[i], word: w);
      }
      paths.add(path);
      at += word.answer.length;
    }
  }

  factory WordTrail.daily(int day) =>
      WordTrail(trailStories[day % trailStories.length]);

  static const size = 5;
  final TrailStory story;
  final List<TrailSquare> squares = List.filled(size * size, (
    letter: '',
    word: null,
  ));

  /// Each word's squares, first letter to last.
  final List<List<int>> paths = [];

  final Set<int> solved = {};

  bool get finished => solved.length == story.words.length;

  static bool touching(int a, int b) =>
      a != b &&
      (a ~/ size - b ~/ size).abs() <= 1 &&
      (a % size - b % size).abs() <= 1;

  /// The unsolved word [traced] spells, forwards or backwards.
  int? wordFor(List<int> traced) {
    for (final (w, path) in paths.indexed) {
      if (solved.contains(w) || path.length != traced.length) continue;
      var forward = true, backward = true;
      for (var i = 0; i < path.length; i++) {
        forward &= traced[i] == path[i];
        backward &= traced[i] == path[path.length - 1 - i];
      }
      if (forward || backward) return w;
    }
    return null;
  }

  /// The longest word still hidden, so a trace that's grown past it can be
  /// cleared.
  int get longestLeft => [
    for (final (w, word) in story.words.indexed)
      if (!solved.contains(w)) word.answer.length,
  ].fold(0, max);

  /// The meaning and its two decoys, in an order that doesn't give it away.
  List<String> choicesFor(int w) {
    final word = story.words[w];
    return [word.meaning, ...word.wrong]
      ..shuffle(Random(word.answer.codeUnits.fold<int>(0, (a, b) => a + b)));
  }
}
