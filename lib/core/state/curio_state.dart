import 'dart:async';

import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../services/cached_progress_store.dart';
import '../services/family_service.dart';

class CurioState extends ChangeNotifier with WidgetsBindingObserver {
  CurioState({this.store}) {
    WidgetsBinding.instance.addObserver(this);
  }
  bool _disposed = false;
  Future<void> _saveQueue = Future.value();
  bool loadFailed = false;
  int dailyGoal = 3;
  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && store != null && !isLoading) {
      unawaited(retrySync());
    }
  }

  void setDailyGoal(int value) {
    dailyGoal = value;
    notifyListeners();
  }

  final ProgressStore? store;
  bool isLoading = false;
  bool isSyncing = false;
  String? syncError;

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
        .clamp(0, dailyGoal);
  }

  bool completedToday(String activity) {
    return completedActivities.contains(
      '${activity}_${_dateKey(DateTime.now())}',
    );
  }

  Future<void> hydrate() async {
    if (store == null) return;
    loadFailed = false;
    isLoading = true;
    syncError = null;
    notifyListeners();
    try {
      final snapshot = await store!.load();
      try {
        dailyGoal = (await FamilyService().loadSettings()).dailyGoal;
      } catch (_) {
        /* Settings can be retried separately. */
      }
      if (store is CachedProgressStore &&
          (store as CachedProgressStore).offline) {
        syncError = 'Offline — showing progress saved on this device.';
      }
      childName = snapshot.childName;
      totalXp = snapshot.totalXp;
      streak = snapshot.streak;
      completedActivities
        ..clear()
        ..addAll(snapshot.completedActivities);
      collectedFacts
        ..clear()
        ..addAll(snapshot.collectedFacts);
      skills
        ..clear()
        ..addAll({
          'Number sense': 0,
          'Patterns': 0,
          'Evidence': 0,
          'Reasoning': 0,
        })
        ..addAll(snapshot.skills);
    } catch (_) {
      loadFailed = true;
      syncError = 'Could not load your learning trail.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    streak = calculateStreak(completedActivities, DateTime.now());
    notifyListeners();
    _persist();
  }

  void renameChild(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty || cleaned.length > 18) return;
    childName = cleaned;
    notifyListeners();
    _persist();
  }

  Future<void> retrySync() async {
    syncError = null;
    notifyListeners();
    await _save();
  }

  void _persist() {
    if (store == null) return;
    unawaited(_save());
  }

  static int calculateStreak(Set<String> activities, DateTime now) {
    final days = activities
        .where((id) => RegExp(r'_[0-9]{8}$').hasMatch(id))
        .map((id) => id.substring(id.length - 8))
        .toSet();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(_dateKey(day)))
      day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (days.contains(_dateKey(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  Future<void> _save() {
    final progressStore = store;
    if (progressStore == null || loadFailed) return Future.value();
    final snapshot = ProgressSnapshot(
      childName: childName,
      totalXp: totalXp,
      streak: streak,
      completedActivities: Set.of(completedActivities),
      collectedFacts: Set.of(collectedFacts),
      skills: Map.of(skills),
    );
    _saveQueue = _saveQueue.then((_) async {
      isSyncing = true;
      notifyListeners();
      try {
        await progressStore.save(snapshot);
        syncError = null;
      } catch (_) {
        syncError = 'Sync is pending. Reconnect and tap to retry.';
      } finally {
        isSyncing = false;
        notifyListeners();
      }
    });
    return _saveQueue;
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
