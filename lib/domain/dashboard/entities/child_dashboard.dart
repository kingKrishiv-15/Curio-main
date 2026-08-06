/// Everything the Home screen needs about the active child. Pure Dart, no
/// Supabase/Drift types - mirrors `child` + a rollup of `streak` rows, but
/// the UI never knows or cares that's where it eventually comes from.
class ChildDashboard {
  const ChildDashboard({
    required this.childId,
    required this.displayName,
    required this.currentStreak,
    required this.longestStreak,
    required this.dragonStage,
    required this.totalXp,
  });

  final String childId;
  final String displayName;
  final int currentStreak;
  final int longestStreak;
  final int dragonStage;
  final int totalXp;
}
