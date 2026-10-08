class ProgressSnapshot {
  const ProgressSnapshot({
    required this.childName,
    required this.totalXp,
    required this.streak,
    required this.completedActivities,
    required this.collectedFacts,
    required this.skills,
  });

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      ProgressSnapshot(
        childName: json['childName'] as String,
        totalXp: json['totalXp'] as int,
        streak: json['streak'] as int,
        completedActivities: Set<String>.from(
          json['completedActivities'] as List,
        ),
        collectedFacts: Set<String>.from(json['collectedFacts'] as List),
        skills: (json['skills'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
  Map<String, dynamic> toJson() => {
    'childName': childName,
    'totalXp': totalXp,
    'streak': streak,
    'completedActivities': completedActivities.toList(),
    'collectedFacts': collectedFacts.toList(),
    'skills': skills,
  };

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
