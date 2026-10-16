/// Evidence Detective: a short mystery, three clues, and one job — decide how
/// much each clue is worth before jumping to a conclusion.
///
/// - **Strong**: specific and checkable (measured, written down at the time,
///   or physical) and it points one way.
/// - **Weak**: probably true, but it fits lots of explanations, so it can't
///   settle the case on its own.
/// - **Misleading**: sounds convincing but points the wrong way — a rumour,
///   a guess about a person, a superstition.
///
/// Cases don't always hold one of each, so ranking can't be done by
/// elimination.
enum EvidenceRank { strong, weak, misleading }

extension EvidenceRankLabel on EvidenceRank {
  String get label => switch (this) {
    EvidenceRank.strong => 'Strong',
    EvidenceRank.weak => 'Weak',
    EvidenceRank.misleading => 'Misleading',
  };
}

class EvidenceClue {
  const EvidenceClue({
    required this.title,
    required this.detail,
    required this.rank,
    required this.why,
  });

  final String title;
  final String detail;
  final EvidenceRank rank;

  /// Shown after the case is closed: why the clue deserves its rank.
  final String why;
}

class EvidenceCase {
  const EvidenceCase({
    required this.number,
    required this.name,
    required this.question,
    required this.clues,
    required this.summary,
  });

  final int number;

  /// "THE LIBRARY BOOK"
  final String name;
  final String question;
  final List<EvidenceClue> clues;

  /// What the evidence shows, once every clue is weighed.
  final String summary;

  /// "CASE 004 · THE LIBRARY BOOK"
  String get heading => 'CASE ${number.toString().padLeft(3, '0')} · $name';

  /// How many of [ranks] (clue index → rank) are right.
  int score(Map<int, EvidenceRank> ranks) => [
    for (var i = 0; i < clues.length; i++) ranks[i] == clues[i].rank,
  ].where((right) => right).length;
}

/// Today's case, or for practice round [practice] (1, 2, 3…) a step back
/// through earlier days' cases — skipping today's and tomorrow's, so practice
/// never spoils a daily.
EvidenceCase evidenceCaseFor(int day, {int practice = 0}) {
  final d = practice <= 0
      ? day
      : day - 1 - (practice - 1) % (evidenceCases.length - 2);
  return evidenceCases[d % evidenceCases.length];
}

const _strong = EvidenceRank.strong;
const _weak = EvidenceRank.weak;
const _misleading = EvidenceRank.misleading;

const evidenceCases = <EvidenceCase>[
  EvidenceCase(
    number: 1,
    name: 'THE GARDEN',
    question:
        'The school garden was damaged overnight. Which evidence should we trust?',
    clues: [
      EvidenceClue(
        title: 'Weather station log',
        detail: 'Heavy rain and strong wind were recorded between 1 and 3 a.m.',
        rank: _strong,
        why:
            'Measured by an instrument, timestamped and independent — and wind and rain can flatten plants.',
      ),
      EvidenceClue(
        title: 'A muddy footprint',
        detail: 'One shoe print appears beside the broken tomato plants.',
        rank: _weak,
        why:
            'Someone walked there, but gardeners walk there every day. One print can’t explain all the damage.',
      ),
      EvidenceClue(
        title: 'A dramatic post',
        detail: '“A monster attacked the garden!” says an anonymous account.',
        rank: _misleading,
        why:
            'No name, no proof, and written to grab attention rather than to explain.',
      ),
    ],
    summary:
        'The weather log is measured, timed and independent, so it explains the flattened plants best. The footprint is worth noting, but it can’t explain the whole night by itself.',
  ),
  EvidenceCase(
    number: 2,
    name: 'THE MISSING LUNCHBOX',
    question:
        'Priya’s lunchbox has vanished before lunch. Where is it most likely to be?',
    clues: [
      EvidenceClue(
        title: 'A playground rumour',
        detail:
            'Someone says Max must have taken it because he was hungry at break.',
        rank: _misleading,
        why:
            'Being hungry isn’t evidence. Blaming a person without proof is unfair, and it points away from the real answer.',
      ),
      EvidenceClue(
        title: 'The office log',
        detail:
            'At 8:50, a blue lunchbox with a star sticker was handed in, found on the bench by the school gate.',
        rank: _strong,
        why:
            'It matches Priya’s lunchbox exactly — colour, sticker and time — and it was written down when it happened.',
      ),
      EvidenceClue(
        title: 'Sam’s memory',
        detail: 'Sam thinks he saw “a lunchbox” in the cloakroom earlier.',
        rank: _weak,
        why:
            'Lots of children have lunchboxes, and Sam can’t say which one. Worth a look, but it settles nothing.',
      ),
    ],
    summary:
        'The office log matches Priya’s lunchbox exactly, so it was most likely left by the gate on the way in. The rumour about Max was only a guess — and guesses about people can hurt.',
  ),
  EvidenceCase(
    number: 3,
    name: 'THE BROKEN FLOWERPOT',
    question:
        'A flowerpot has fallen off the classroom windowsill and smashed. What happened?',
    clues: [
      EvidenceClue(
        title: 'Last to leave',
        detail: 'Leo was the last person to leave the classroom.',
        rank: _misleading,
        why:
            'Being last to leave doesn’t mean you broke something. It points the blame at a person with no evidence.',
      ),
      EvidenceClue(
        title: 'The tangled curtain',
        detail:
            'The window was open on a very windy afternoon, and the curtain is caught around the pot’s broken saucer.',
        rank: _strong,
        why:
            'Two things you can check, and they fit together: the wind blew in, and the curtain was wrapped around the pot.',
      ),
      EvidenceClue(
        title: 'An old saying',
        detail: 'Someone says broken pots always come in threes.',
        rank: _misleading,
        why:
            'That’s a superstition — a made-up rule. It says nothing about how this pot fell.',
      ),
    ],
    summary:
        'The open window, the windy afternoon and the tangled curtain all fit together: a gust most likely flapped the curtain and dragged the pot off. The other clues pointed at a person and a superstition, not at what happened.',
  ),
  EvidenceCase(
    number: 4,
    name: 'THE LIBRARY BOOK',
    question:
        'The class library book about volcanoes has vanished from the reading corner. Who has it?',
    clues: [
      EvidenceClue(
        title: 'A gap on the shelf',
        detail: 'There’s an empty space where the science books go.',
        rank: _weak,
        why:
            'It shows a book is missing — which we already knew — but not who has it.',
      ),
      EvidenceClue(
        title: 'A red cover',
        detail:
            'Mia remembers seeing a book with a red cover in someone’s bag.',
        rank: _weak,
        why:
            'Lots of books have red covers, and Mia doesn’t know whose bag it was.',
      ),
      EvidenceClue(
        title: 'The sign-out sheet',
        detail:
            'The sheet shows Jay borrowed the volcano book on Tuesday and hasn’t signed it back in.',
        rank: _strong,
        why:
            'A written record made at the time, naming the book and the borrower. Start by asking Jay.',
      ),
    ],
    summary:
        'The sign-out sheet is the strongest clue: it was written down when it happened and names the book. The other two are true, but they could fit lots of different stories.',
  ),
  EvidenceCase(
    number: 5,
    name: 'THE MUDDY PAWPRINTS',
    question:
        'Muddy pawprints cross the kitchen floor. The family cat, Biscuit, was home — but so was the neighbour’s dog, out in the garden. Who came in?',
    clues: [
      EvidenceClue(
        title: 'The open door',
        detail: 'The back door was left open for a few minutes this morning.',
        rank: _weak,
        why:
            'It shows how an animal could have got in, but not which animal — or whether one did.',
      ),
      EvidenceClue(
        title: 'A guilty look',
        detail: 'Biscuit is hiding under the table, looking guilty.',
        rank: _misleading,
        why:
            'We can’t read guilt on a cat’s face — that’s us imagining. Cats hide for all sorts of reasons.',
      ),
      EvidenceClue(
        title: 'Claw marks',
        detail:
            'Each print is as wide as your palm, with a claw mark in front of every toe.',
        rank: _strong,
        why:
            'Cats usually keep their claws tucked in as they walk, so their prints rarely show claws. Dog prints usually do — and these are big.',
      ),
    ],
    summary:
        'Big prints with claw marks point to the dog, not Biscuit, and the open door explains how it got in. Biscuit’s “guilty look” was never evidence.',
  ),
  EvidenceCase(
    number: 6,
    name: 'THE MELTED SNOWMAN',
    question:
        'The playground snowman has slumped into a heap by lunchtime. Some children think it was knocked over. What really happened?',
    clues: [
      EvidenceClue(
        title: 'The thermometer',
        detail: 'The school weather station read 9 °C at 11 a.m.',
        rank: _strong,
        why:
            'A measured, timed reading. Snow melts above 0 °C, and 9 °C is well above that.',
      ),
      EvidenceClue(
        title: 'Seen nearby',
        detail: 'Some older children were playing near the snowman at break.',
        rank: _misleading,
        why:
            'Being nearby isn’t the same as doing something — and the weather explains it all.',
      ),
      EvidenceClue(
        title: 'Melting everywhere',
        detail: 'The snow on the field and on the shed roof has melted too.',
        rank: _strong,
        why:
            'If only the snowman had changed, someone might have knocked it. Melting everywhere points to the weather.',
      ),
    ],
    summary:
        'Two clues agree: a warm reading and melting all around point to a thaw. Being nearby doesn’t prove anyone did anything.',
  ),
  EvidenceCase(
    number: 7,
    name: 'THE TAPPING WALL',
    question:
        'Early every morning there’s a tapping sound inside the bedroom wall. What’s making it?',
    clues: [
      EvidenceClue(
        title: 'Right on time',
        detail:
            'The tapping starts at 6 a.m. every day — exactly when the heating switches on.',
        rank: _strong,
        why:
            'It happens at the same moment each day, and you can test it again tomorrow. Metal pipes tick as they warm up and stretch a tiny bit.',
      ),
      EvidenceClue(
        title: 'Birds on the roof',
        detail: 'Pigeons sometimes sit on the roof above the bedroom.',
        rank: _weak,
        why:
            'Possible, but the sound is inside the wall, and nobody has checked whether birds are there when it taps.',
      ),
      EvidenceClue(
        title: 'A spooky story',
        detail: 'A friend says old houses always have ghosts.',
        rank: _misleading,
        why:
            'A story isn’t evidence, and it can’t explain why the tapping starts at the same minute every day.',
      ),
    ],
    summary:
        'The tapping matches the heating timer to the minute, which you can test again. Warming pipes stretch slightly and can tick. The ghost story was just a story.',
  ),
  EvidenceCase(
    number: 8,
    name: 'THE DROOPY SUNFLOWER',
    question: 'The class sunflower is drooping. What’s wrong with it?',
    clues: [
      EvidenceClue(
        title: 'A cloudy week',
        detail: 'It has been cloudy all week.',
        rank: _weak,
        why:
            'Less sunshine can slow a plant’s growth, but it doesn’t usually make it droop within a few days.',
      ),
      EvidenceClue(
        title: 'Dry soil and an empty chart',
        detail:
            'The soil is dry and crumbly, and the watering chart has no ticks since Friday.',
        rank: _strong,
        why:
            'Two checks that agree: soil you can touch and a written record. Plants droop when they’re short of water.',
      ),
      EvidenceClue(
        title: 'The Monday rule',
        detail: 'Someone says plants always droop on Mondays.',
        rank: _misleading,
        why: 'A made-up rule with nothing to back it up.',
      ),
    ],
    summary:
        'The dry soil and the empty watering chart agree: the sunflower needs a drink. Cloudy days don’t explain drooping on their own, and there’s no Monday rule.',
  ),
  EvidenceCase(
    number: 9,
    name: 'THE SHED VISITOR',
    question: 'Is a fox living under the garden shed?',
    clues: [
      EvidenceClue(
        title: 'Night-time rustling',
        detail: 'Someone heard rustling near the shed after dark.',
        rank: _weak,
        why:
            'Hedgehogs, cats, birds and the wind all rustle. It fits a fox, but it fits lots of other things too.',
      ),
      EvidenceClue(
        title: 'A video online',
        detail: 'A video shows a fox living under a shed in a different town.',
        rank: _misleading,
        why:
            'It’s real, but it’s about a different shed. It tells us nothing about this one.',
      ),
      EvidenceClue(
        title: 'A nibbled apple',
        detail: 'A half-eaten apple was found by the shed door.',
        rank: _weak,
        why:
            'Many animals nibble fallen apples — and so do people. It can’t point to a fox on its own.',
      ),
    ],
    summary:
        'No clue here is strong, so the honest answer is “we don’t know yet”. A good detective would look for tracks in soft mud or set up a camera — and wait for better evidence.',
  ),
];
