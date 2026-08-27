class ProgressSnapshot {
  const ProgressSnapshot({
    required this.childName,
    required this.totalXp,
    required this.streak,
    required this.completedActivities,
    required this.collectedFacts,
    required this.skills,
  });

  final String childName;
  final int totalXp;
  final int streak;
  final Set<String> completedActivities;
  final Set<String> collectedFacts;
  final Map<String, double> skills;
}

abstract interface class ProgressStore {
  Future<ProgressSnapshot> load();
  Future<void> save(ProgressSnapshot snapshot);
}
