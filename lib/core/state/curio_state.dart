import 'package:flutter/material.dart';

class CurioState extends ChangeNotifier {
  String childName = 'Explorer';
  int totalXp = 360;
  int streak = 4;
  final Set<String> completedActivities = <String>{};
  final Set<String> collectedFacts = <String>{
    'octopus_hearts',
    'shortest_war',
    'diwali_light',
  };
  final Map<String, double> skills = <String, double>{
    'Number sense': 0.62,
    'Patterns': 0.35,
    'Evidence': 0.18,
    'Reasoning': 0.42,
  };

  int get companionStage => (totalXp ~/ 250) + 1;
  int get xpIntoStage => totalXp % 250;
  int get activitiesCompleted => completedActivities.length;
  int get dailyGoalCompleted {
    final suffix = _dateKey(DateTime.now());
    return completedActivities
        .where((id) => id.endsWith(suffix))
        .length
        .clamp(0, 3);
  }

  bool completedToday(String activity) {
    return completedActivities.contains(
      '${activity}_${_dateKey(DateTime.now())}',
    );
  }

  static String dailyActivityId(String activity, [DateTime? date]) {
    return '${activity}_${_dateKey(date ?? DateTime.now())}';
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }

  void completeActivity({
    required String id,
    required int xp,
    required String skill,
    String? factId,
  }) {
    final isFirstCompletion = completedActivities.add(id);
    if (!isFirstCompletion) return;
    totalXp += xp;
    skills[skill] = ((skills[skill] ?? 0) + 0.12).clamp(0, 1);
    if (factId != null) collectedFacts.add(factId);
    notifyListeners();
  }

  void renameChild(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    childName = cleaned;
    notifyListeners();
  }
}

class CurioScope extends InheritedNotifier<CurioState> {
  const CurioScope({
    required CurioState notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static CurioState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurioScope>();
    assert(scope != null, 'CurioScope was not found in this context');
    return scope!.notifier!;
  }
}
