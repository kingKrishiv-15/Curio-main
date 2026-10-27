/// How close a guess landed to the secret number.
enum Heat {
  found('Found it'),
  sizzling('Sizzling'),
  hot('Hot'),
  warm('Warm'),
  cool('Cool'),
  cold('Cold');

  const Heat(this.label);
  final String label;

  static Heat of(int guess, int target) => switch ((guess - target).abs()) {
    0 => found,
    <= 10 => sizzling,
    <= 50 => hot,
    <= 150 => warm,
    <= 300 => cool,
    _ => cold,
  };
}

/// What a guess told the player.
enum Clue { found, higher, lower, outside, finished }

/// A secret number from 1 to 1,000, found by higher-or-lower clues. Ten
/// guesses is exactly enough if every guess halves what's left (2¹⁰ is
/// 1,024), so a careful hunter always wins.
class NumberHunt {
  NumberHunt(this.target) : assert(target >= low && target <= high);

  /// Today's number: everyone on the same date hunts the same one.
  factory NumberHunt.daily(int day) => NumberHunt(dailyTarget(day));

  static const low = 1, high = 1000, maxGuesses = 10;

  /// Scatters consecutive days across the range, so yesterday's number
  /// says nothing about today's.
  static int dailyTarget(int day) =>
      (day * 2654435761 + 40503) % 0x100000000 % high + low;

  final int target;
  final List<int> guesses = [];

  /// The smallest and largest numbers the clues still allow.
  int floor = low, ceiling = high;

  bool get found => guesses.isNotEmpty && guesses.last == target;
  bool get over => found || guesses.length >= maxGuesses;
  int get left => maxGuesses - guesses.length;

  /// A guess outside what the clues allow isn't counted — the clue says so
  /// instead, which is the lesson.
  Clue guess(int value) {
    if (over) return Clue.finished;
    if (value < floor || value > ceiling) return Clue.outside;
    guesses.add(value);
    if (value == target) return Clue.found;
    if (value < target) {
      floor = value + 1;
      return Clue.higher;
    }
    ceiling = value - 1;
    return Clue.lower;
  }
}
