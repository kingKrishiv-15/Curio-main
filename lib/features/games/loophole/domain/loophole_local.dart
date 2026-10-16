import '../../common/game_kit.dart';
import 'loophole_bank.dart';

/// Plays Loophole on the device, for guests and whenever the server can't be
/// reached. It mirrors the server validator (`validate_loophole_move`) move
/// for move — two guesses per statement, 2 points for a first-guess catch,
/// 1 for a second — and answers in the same shape, so the page renders both
/// identically.
class LoopholeLocalGame {
  LoopholeLocalGame(this.rounds);

  /// Today's three statements (or another day's, for practice).
  factory LoopholeLocalGame.forDay({DateTime? date, int shift = 0}) =>
      LoopholeLocalGame(
        loopholeDays[DailyPick.index(loopholeDays.length, date: date, shift: shift)],
      );

  final List<LoopholeRound> rounds;
  final List<int> marks = [];
  int _round = 0;
  int _guesses = 0;

  static const guessesPerRound = 2;

  bool get finished => marks.length == rounds.length;
  int get score => marks.fold(0, (sum, mark) => sum + mark);

  /// Everything the board may show: statements and tokens, never targets.
  Map<String, dynamic> get publicConfig => {
    'rounds': [
      for (final r in rounds) {'statement': r.statement, 'tokens': r.tokens},
    ],
  };

  Map<String, dynamic> submit({required int round, required int tokenIndex}) {
    if (finished || round != _round) {
      throw StateError('Move for round $round, but the game is on $_round.');
    }
    final current = rounds[round];
    if (tokenIndex < 0 || tokenIndex >= current.tokens.length) {
      throw RangeError.index(tokenIndex, current.tokens, 'tokenIndex');
    }
    _guesses++;
    final correct = tokenIndex == current.target;
    final roundOver = correct || _guesses >= guessesPerRound;
    if (roundOver) {
      marks.add(correct ? guessesPerRound - _guesses + 1 : 0);
      _round++;
    }
    final guessesUsed = _guesses;
    if (roundOver) _guesses = 0;
    return {
      'correct': correct,
      'round_over': roundOver,
      'finished': finished,
      'guesses_used': guessesUsed,
      'marks': List.of(marks),
      if (roundOver) 'target': current.target,
      if (roundOver) 'explanation': current.explanation,
      if (finished) 'score': score,
    };
  }
}
