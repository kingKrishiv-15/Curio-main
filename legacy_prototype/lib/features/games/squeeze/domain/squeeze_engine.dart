class SqueezeEngine {
  SqueezeEngine({int? target}) : target = target ?? _dailyTarget();

  static const maxGuesses = 7;
  final int target;
  final List<int> guesses = <int>[];
  int minimum = 1;
  int maximum = 100;

  bool get solved => guesses.isNotEmpty && guesses.last == target;
  bool get finished => solved || guesses.length >= maxGuesses;
  int get guessesLeft => maxGuesses - guesses.length;

  static int _dailyTarget() {
    final now = DateTime.now();
    final seed = now.year * 372 + now.month * 31 + now.day;
    return ((seed * 47 + 23) % 100) + 1;
  }

  String guess(int value) {
    if (finished) return 'Today\'s hunt is already complete.';
    if (value < minimum || value > maximum) {
      return 'Keep your guess between $minimum and $maximum.';
    }
    guesses.add(value);
    if (value == target) {
      return 'You found it! $target was hiding in the range.';
    }
    if (value < target) {
      minimum = value + 1;
      return '$value is too low. Squeeze the floor upward!';
    }
    maximum = value - 1;
    return '$value is too high. Bring the ceiling down!';
  }

  String get numberFact {
    if (target % 10 == 0) {
      return 'Clue: the number lands exactly on a group of ten.';
    }
    if (target % 2 == 0) {
      return 'Clue: the number is even, so it can split into pairs.';
    }
    if (target % 5 == 0) {
      return 'Clue: five divides this number without leftovers.';
    }
    if (_isPrime(target)) {
      return 'Clue: this number is prime—it only shares with 1 and itself.';
    }
    return 'Clue: the digits add up to ${target.toString().split('').fold<int>(0, (sum, digit) => sum + int.parse(digit))}.';
  }

  static bool _isPrime(int value) {
    if (value < 2) return false;
    for (var factor = 2; factor * factor <= value; factor++) {
      if (value % factor == 0) return false;
    }
    return true;
  }
}
