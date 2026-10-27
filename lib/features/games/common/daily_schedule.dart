/// The four daily learning sections. Keep the order stable across screens.
enum LearningSection {
  maths('Maths', 'Numbers, patterns and problem solving'),
  memory('Memory', 'Remember pictures, places and sequences'),
  english('English', 'Words, reading and understanding clues'),
  logic('Logic', 'Puzzles, clues and careful reasoning');

  const LearningSection(this.title, this.description);
  final String title;
  final String description;
}

/// One game from each pool per calendar day, each pool holding the games
/// that best match what its section teaches.
const sectionRotation = <LearningSection, List<String>>{
  LearningSection.maths: [
    'squeeze',
    'number_hunt',
    'bridge',
    'scale',
    'sequence',
    'pattern_forge',
    'mirror',
  ],
  LearningSection.memory: ['memory_match', 'memory_trail', 'memory_grid'],
  LearningSection.english: [
    'word_wise',
    'word_builder',
    'word_trails',
    'loophole',
    'verdict',
  ],
  LearningSection.logic: [
    'crowns',
    'whos_who',
    'signal_grid',
    'odd_cluster',
    'link_lab',
    'cascade',
    'evidence_garden',
  ],
};

final _epoch = DateTime.utc(2026);

int calendarDayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

LearningSection sectionForGame(String id) {
  if (id == 'frostlands_night_1') return LearningSection.english;
  return sectionRotation.entries.firstWhere((e) => e.value.contains(id)).key;
}

String scheduledGameId(LearningSection section, DateTime date) {
  final pool = sectionRotation[section]!;
  return pool[calendarDayNumber(date) % pool.length];
}

/// Advance a game's puzzle on each *appearance*, rather than every calendar
/// day. Otherwise an eight-game rotation and an eight-puzzle bank would show
/// the very same puzzle every time that game returned.
DateTime puzzleDateForGame(String id, DateTime date) {
  final pool = sectionRotation[sectionForGame(id)]!;
  final appearance = (calendarDayNumber(date) / pool.length).floor();
  return DateTime.utc(2026, 1, 1 + appearance);
}
