/// The three learning sections. Keep the order stable across screens.
enum LearningSection {
  maths('Maths', 'Numbers, patterns and symmetry'),
  logic('Logic', 'Grids, clues and careful deduction'),
  thinking('Thinking', 'Evidence, claims and what follows from them');

  const LearningSection(this.title, this.description);
  final String title;
  final String description;
}

/// One game from each pool per calendar day, each pool holding the games
/// that best match what its section teaches.
const sectionRotation = <LearningSection, List<String>>{
  LearningSection.maths: ['squeeze', 'bridge', 'scale', 'sequence', 'mirror'],
  LearningSection.logic: ['crowns', 'whos_who', 'signal_grid', 'link_lab'],
  LearningSection.thinking: ['verdict', 'cascade'],
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
  final pool = sectionRotation[sectionForGame(id)]!;
  final appearance = (calendarDayNumber(date) / pool.length).floor();
  return DateTime.utc(2026, 1, 1 + appearance);
}

/// "Maths, Logic and Thinking". Every screen that names the
/// sections reads this, so the list can never disagree with the catalogue.
String get sectionNames {
  final titles = [for (final s in LearningSection.values) s.title];
  if (titles.length == 1) return titles.single;
  return '${titles.sublist(0, titles.length - 1).join(', ')} and ${titles.last}';
}

/// The game that is on every day. The other games rotate, one per section.
const anchorGameId = 'second_opinion';

/// How many games make up a day's set: the anchor plus one per section.
/// Every count in the UI reads this.
int get dailyGameCount => LearningSection.values.length + 1;
