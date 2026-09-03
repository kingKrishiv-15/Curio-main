import 'minigame_attempt.dart';

/// One past day in a game's archive. [status] is null when this child has
/// never opened that day's puzzle - which is what the archive list uses to
/// show "unplayed" rather than a result.
class MinigameArchiveEntry {
  const MinigameArchiveEntry({
    required this.puzzleId,
    required this.puzzleDate,
    required this.status,
    required this.score,
  });

  final String puzzleId;
  final DateTime puzzleDate;
  final MinigameStatus? status;
  final int? score;

  bool get isPlayed => status != null;
}
