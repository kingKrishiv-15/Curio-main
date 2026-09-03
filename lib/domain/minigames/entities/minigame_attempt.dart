enum MinigameStatus {
  inProgress('in_progress'),
  won('won'),
  lost('lost'),
  abandoned('abandoned');

  const MinigameStatus(this.wireValue);

  final String wireValue;

  bool get isFinished => this != MinigameStatus.inProgress;

  static MinigameStatus fromWire(String value) {
    return MinigameStatus.values.firstWhere(
      (status) => status.wireValue == value,
      orElse: () => throw ArgumentError('Unknown attempt status: $value'),
    );
  }
}

/// A child's run at one puzzle. [state] is the server's record of how far
/// they've got - which groups are solved, how many numbers are revealed,
/// which statement they're on - so closing the app mid-puzzle and coming
/// back resumes exactly where they left off rather than restarting.
class MinigameAttempt {
  const MinigameAttempt({
    required this.id,
    required this.puzzleId,
    required this.status,
    required this.state,
    required this.score,
    required this.startedAt,
    required this.completedAt,
  });

  final String id;
  final String puzzleId;
  final MinigameStatus status;
  final Map<String, dynamic> state;
  final int? score;
  final DateTime startedAt;
  final DateTime? completedAt;
}
