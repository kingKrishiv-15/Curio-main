/// A per-game streak. Each minigame keeps its own (Loophole's streak is not
/// Bridge's), stored server-side against `streak.streak_type`.
class MinigameStreak {
  const MinigameStreak({
    required this.currentCount,
    required this.longestCount,
    required this.lastQualifiedDate,
  });

  const MinigameStreak.empty() : currentCount = 0, longestCount = 0, lastQualifiedDate = null;

  final int currentCount;
  final int longestCount;
  final DateTime? lastQualifiedDate;
}
