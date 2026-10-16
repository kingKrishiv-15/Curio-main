import 'dart:async';

import 'package:flutter/material.dart';

import '../services/progress_store.dart';
import '../services/cached_progress_store.dart';
import '../services/family_service.dart';

class CurioState extends ChangeNotifier with WidgetsBindingObserver {
  CurioState({this.store, this.isGuest = false}) {
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
    if (state != AppLifecycleState.resumed || isLoading) return;
    // Coming back the next morning: "done today", the daily goal and the
    // streak are all date-based, so recompute rather than show yesterday.
    streak = calculateStreak(completedActivities, DateTime.now());
    notifyListeners();
    // Only resend when a save is actually waiting.
    if (store != null && syncError != null) unawaited(retrySync());
  }

  void setDailyGoal(int value) {
    dailyGoal = value;
    notifyListeners();
  }

  final ProgressStore? store;

  /// Playing without an account: progress lives only on this device.
  final bool isGuest;
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

  /// The best run of consecutive practice days ever — milestones use this,
  /// so a badge isn't taken away when a streak later breaks.
  int get longestStreak => calculateLongestStreak(completedActivities);
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
      // Recomputed from the activity dates rather than trusting the stored
      // number, which never decays on days the app isn't opened.
      streak = calculateStreak(completedActivities, DateTime.now());
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

  /// Discoveries earned by keeping practice going rather than by any one
  /// game: best run of consecutive days → fact. Mirrors the server's list in
  /// `sync_learning_progress` (202610080001_launch_hardening.sql).
  static const streakDiscoveries = <int, String>{
    3: 'octopus_hearts',
    7: 'shortest_war',
    14: 'diwali_light',
  };

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
    final best = longestStreak;
    for (final MapEntry(key: days, value: fact) in streakDiscoveries.entries) {
      if (best >= days) collectedFacts.add(fact);
    }
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

  static DateTime? _dateOf(String id) {
    final match = RegExp(r'_([0-9]{4})([0-9]{2})([0-9]{2})$').firstMatch(id);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static int calculateLongestStreak(Set<String> activities) {
    final days = activities.map(_dateOf).whereType<DateTime>().toSet().toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? previous;
    for (final day in days) {
      final next = previous == null
          ? null
          : DateTime(previous.year, previous.month, previous.day + 1);
      run = next == day ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  /// Adds activities finished elsewhere (e.g. as a guest on this device),
  /// then reloads so XP, skills and discoveries come from the server's own
  /// reward table rather than being recomputed here.
  Future<void> mergeActivities(Iterable<String> ids) async {
    completedActivities.addAll(ids);
    streak = calculateStreak(completedActivities, DateTime.now());
    notifyListeners();
    await _save();
    if (syncError == null) await hydrate();
  }

  /// Resolves once every queued save has finished — e.g. before erasing
  /// guest progress, so a late save can't bring it back.
  Future<void> flush() => _saveQueue;

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
