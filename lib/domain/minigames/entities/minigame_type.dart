/// The five daily minigames. [wireValue] is the `daily_puzzle.puzzle_type`
/// string, which is also the `streak.streak_type` for that game's streak and
/// the suffix of its server-side `validate_<type>_move` function - one name
/// tying the whole vertical together.
enum MinigameType {
  loophole('loophole', 'Loophole'),
  oddCluster('odd_cluster', 'Odd Cluster'),
  sequence('sequence', 'Sequence'),
  cascade('cascade', 'Cascade'),
  bridge('bridge', 'Bridge');

  const MinigameType(this.wireValue, this.displayName);

  final String wireValue;
  final String displayName;

  static MinigameType fromWire(String value) {
    return MinigameType.values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () => throw ArgumentError('Unknown minigame type: $value'),
    );
  }
}
