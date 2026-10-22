import 'dart:math';

class MemoryMatchGame {
  MemoryMatchGame(int seed) {
    final symbols = List.generate(12, (i) => i)..shuffle(Random(seed));
    cards = [...symbols.take(6), ...symbols.take(6)]
      ..shuffle(Random(seed + 41));
  }

  late final List<int> cards;
  final Set<int> matched = {};
  final List<int> flipped = [];
  int moves = 0;
  bool get finished => matched.length == cards.length;
  bool get needsReset => flipped.length == 2;
  bool visible(int index) => matched.contains(index) || flipped.contains(index);

  bool flip(int index) {
    if (index < 0 ||
        index >= cards.length ||
        finished ||
        needsReset ||
        visible(index)) {
      return false;
    }
    flipped.add(index);
    if (flipped.length == 2) {
      moves++;
      if (cards[flipped[0]] == cards[flipped[1]]) {
        matched.addAll(flipped);
        flipped.clear();
      }
    }
    return true;
  }

  void hideUnmatched() => flipped.clear();
}

class MemoryTrailGame {
  MemoryTrailGame(int seed)
    : trails = [
        for (var round = 0; round < 5; round++)
          (List.generate(
            12,
            (i) => i,
          )..shuffle(Random(seed * 31 + round))).take(3 + round).toList(),
      ];

  final List<List<int>> trails;
  int round = 0, position = 0, score = 0;
  bool studying = true, answered = false;
  bool? correct;
  List<int> get trail => trails[round];
  bool get isLast => round == trails.length - 1;

  void startRecall() {
    if (!answered) studying = false;
  }

  bool choose(int symbol) {
    if (studying || answered || symbol < 0 || symbol >= 12) return false;
    if (symbol != trail[position]) {
      answered = true;
      correct = false;
    } else if (++position == trail.length) {
      answered = true;
      correct = true;
      score++;
    }
    return true;
  }

  void next() {
    if (!answered || isLast) return;
    round++;
    position = 0;
    studying = true;
    answered = false;
    correct = null;
  }
}
