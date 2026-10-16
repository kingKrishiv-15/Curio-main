/// Frostlands, Night 1: three scenes, three choices each. Every choice is
/// careful, brave or kind, and the trait chosen most decides how the night
/// ends — with a fourth ending for a path that used all three.
enum StoryTrait { careful, brave, kind }

extension StoryTraitLabel on StoryTrait {
  String get label => switch (this) {
    StoryTrait.careful => 'Careful',
    StoryTrait.brave => 'Brave',
    StoryTrait.kind => 'Kind',
  };
}

class StoryChoice {
  const StoryChoice(this.label, this.trait, this.outcome);

  final String label;
  final StoryTrait trait;

  /// What happened because of it — shown at the start of the next scene.
  final String outcome;
}

class StoryScene {
  const StoryScene(this.title, this.body, this.choices);
  final String title;
  final String body;
  final List<StoryChoice> choices;
}

class StoryEnding {
  const StoryEnding(this.title, this.body);
  final String title;
  final String body;
}

const frostlandsScenes = <StoryScene>[
  StoryScene(
    'The frozen signal',
    'Ash, a young Arctic fox, stops at the edge of a frozen lake. A blue light flickers beyond the trees, a small voice is calling for help, and the ice is starting to crack.',
    [
      StoryChoice(
        'Test the ice with a branch',
        StoryTrait.careful,
        'Ash tapped the ice before every step. It creaked, but Ash found the thickest path and crossed safely.',
      ),
      StoryChoice(
        'Follow the blue light into the trees',
        StoryTrait.brave,
        'Ash slipped into the dark trees and followed the flickering light — straight to an old lantern, still glowing.',
      ),
      StoryChoice(
        'Find the small voice first',
        StoryTrait.kind,
        'Ash followed the voice and found a lost hare, shivering. Ash curled round it until it was warm enough to walk.',
      ),
    ],
  ),
  StoryScene(
    'Tracks in the snow',
    'Small tracks circle an abandoned pack. One trail is fresh; the other is already filling with snow, and the wind is getting stronger.',
    [
      StoryChoice(
        'Look inside the pack for clues',
        StoryTrait.careful,
        'Inside was a map with a cave marked on it, and a note: “Gone for firewood. Back soon.”',
      ),
      StoryChoice(
        'Follow the fresh trail into the storm',
        StoryTrait.brave,
        'Ash pushed through the swirling snow, nose down, following every print until a glow appeared ahead.',
      ),
      StoryChoice(
        'Call out for the pack’s owner',
        StoryTrait.kind,
        'Ash called again and again. Far away, a tired voice called back.',
      ),
    ],
  ),
  StoryScene(
    'The warm cave',
    'In a cave, a traveller shelters beside a crystal that glows with warmth. They offer to guide Ash home — if Ash can spare some food.',
    [
      StoryChoice(
        'Ask how they know the way',
        StoryTrait.careful,
        'The traveller unfolded a worn map and showed Ash every safe path, one by one.',
      ),
      StoryChoice(
        'Offer to lead the way instead',
        StoryTrait.brave,
        'Ash picked up the glowing crystal and led everyone out into the night.',
      ),
      StoryChoice(
        'Share food and hear their story',
        StoryTrait.kind,
        'The traveller ate gratefully and told Ash about the lights that dance over the ice.',
      ),
    ],
  ),
];

const frostlandsEndings = <String, StoryEnding>{
  'careful': StoryEnding(
    'The safe path',
    'Step by careful step, Ash brought everyone home without a single slip. Checking first made the wild Frostlands feel a little less wild — and from the safe path, the aurora shimmered green overhead.',
  ),
  'brave': StoryEnding(
    'The bold route',
    'Ash raced home under a sky full of green and purple light. Bold choices led the way to the best view of the aurora in all the Frostlands.',
  ),
  'kind': StoryEnding(
    'The warm welcome',
    'Ash came home with new friends trotting alongside. Kindness turned strangers into a travelling party, and together they watched the aurora ripple across the sky.',
  ),
  'balanced': StoryEnding(
    'The wise way',
    'A little care, a little courage and a lot of heart: Ash found a way home that used all three. The aurora lit the snow as if to say well done.',
  ),
};

/// How many times each trait was chosen.
Map<StoryTrait, int> traitTally(List<StoryTrait> path) => {
  for (final t in StoryTrait.values) t: path.where((p) => p == t).length,
};

/// The trait chosen most decides the ending; a path with one of each gets
/// the balanced ending.
StoryEnding frostlandsEnding(List<StoryTrait> path) {
  final tally = traitTally(path);
  final best = tally.values.reduce((a, b) => a > b ? a : b);
  final leaders = [
    for (final MapEntry(key: t, value: n) in tally.entries)
      if (n == best) t,
  ];
  return leaders.length == 1
      ? frostlandsEndings[leaders.single.name]!
      : frostlandsEndings['balanced']!;
}
