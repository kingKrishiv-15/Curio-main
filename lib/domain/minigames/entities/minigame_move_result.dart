/// The server's verdict on one submitted move.
///
/// The payload is intentionally untyped at this layer: "correct" means
/// something different in each game (a tapped token, four grouped tiles, a
/// predicted number), and each game reads the keys it cares about out of
/// [data]. What matters here is what is *absent* - the server never puts the
/// answer in this payload, only the outcome of comparing against it.
class MinigameMoveResult {
  const MinigameMoveResult(this.data);

  final Map<String, dynamic> data;

  bool get isCorrect => data['correct'] == true;

  /// True when the move ended the puzzle either way, so the UI knows to
  /// switch to the result/share screen.
  bool get isTerminal => data['finished'] == true;
}
