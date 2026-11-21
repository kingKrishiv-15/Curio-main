/// The learning sections. Keep the order stable across screens.
enum LearningSection {
  maths('Maths', 'Numbers, patterns and symmetry'),
  logic('Logic', 'Grids, clues and careful deduction'),
  thinking('Thinking', 'Evidence, claims and what follows from them'),
  memory('Memory', 'Remember pictures, places and sequences'),
  english('English', 'Words, reading and stories');

  const LearningSection(this.title, this.description);
  final String title;
  final String description;
}

/// One game from each pool per calendar day, each pool holding the games
/// that best match what its section teaches.
const sectionRotation = <LearningSection, List<String>>{
  LearningSection.maths: [
    'squeeze',
    'bridge',
    'scale',
    'sequence',
    'mirror',
    'number_hunt',
    'pattern_forge',
  ],
  LearningSection.logic: [
    'crowns',
    'whos_who',
    'signal_grid',
    'link_lab',
    'odd_cluster',
  ],
  LearningSection.thinking: [
    'verdict',
    'cascade',
    'loophole',
    'evidence_garden',
  ],
  LearningSection.memory: ['memory_match', 'memory_trail', 'memory_grid'],
  LearningSection.english: ['word_wise', 'word_builder', 'word_trails'],
};

final _epoch = DateTime.utc(2026);

int calendarDayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

LearningSection sectionForGame(String id) {
  if (id == 'frostlands_night_1' || id == anchorGameId) {
    return LearningSection.thinking;
  }
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
  final section = sectionForGame(id);
  final pool = sectionRotation[section]!;
  // Thinking games have a regular slot and a possible spotlight slot on
  // alternating appearances. Reserve a different puzzle for each slot.
  final interval = section == LearningSection.thinking
      ? pool.length ~/ 2
      : pool.length;
  final appearance = (calendarDayNumber(date) / interval).floor();
  return DateTime.utc(2026, 1, 1 + appearance);
}

/// Every screen that names the
/// sections reads this, so the list can never disagree with the catalogue.
String get sectionNames {
  final titles = [for (final s in LearningSection.values) s.title];
  if (titles.length == 1) return titles.single;
  return '${titles.sublist(0, titles.length - 1).join(', ')} and ${titles.last}';
}

/// The server-validated challenge when a case is published for the day.
const anchorGameId = 'second_opinion';

int get dailyGameCount => LearningSection.values.length + 1;

/// A learner's goal is a daily habit. The full game set is available
/// regardless of the goal chosen in family settings.
const maxDailyGoal = 4;

List<String> dailyGameIds(DateTime date, {List<String>? serverIds}) {
  final thinking = sectionRotation[LearningSection.thinking]!;
  if (serverIds != null &&
      serverIds.length == dailyGameCount &&
      serverIds.toSet().length == dailyGameCount &&
      (serverIds.first == anchorGameId || thinking.contains(serverIds.first)) &&
      LearningSection.values.indexed.every(
        (entry) => sectionRotation[entry.$2]!.contains(serverIds[entry.$1 + 1]),
      )) {
    return serverIds;
  }

  final bonus =
      thinking[(calendarDayNumber(date) + thinking.length ~/ 2) %
          thinking.length];
  return [
    if (serverIds?.firstOrNull == anchorGameId) anchorGameId else bonus,
    for (final section in LearningSection.values)
      scheduledGameId(section, date),
  ];
}
