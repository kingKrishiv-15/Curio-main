import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_store.dart';

/// Whether this device is playing as a guest: no account, progress kept on
/// the device only. Remembered across launches so a guest isn't sent back
/// to the landing page every time they open the app.
class GuestSession extends ChangeNotifier {
  GuestSession._();
  static final instance = GuestSession._();

  static const _activeKey = 'curio_guest_active';

  bool _active = false;
  bool get isActive => _active;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _active = prefs.getBool(_activeKey) ?? false;
    } catch (_) {
      _active = false;
    }
    notifyListeners();
  }

  /// Starts (or resumes) guest play. [name] renames the explorer when given.
  Future<void> start({String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    final cleaned = name?.trim() ?? '';
    if (cleaned.isNotEmpty) {
      final store = LocalProgressStore();
      final snapshot = await store.load();
      await store.save(snapshot.copyWith(childName: cleaned));
    }
    _active = true;
    notifyListeners();
  }

  /// Leaves guest mode. Progress stays on the device for next time unless
  /// [erase] is true.
  Future<void> end({bool erase = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, false);
    if (erase) await prefs.remove(LocalProgressStore.key);
    _active = false;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetActive(bool value) {
    _active = value;
    notifyListeners();
  }
}

/// Guest progress, saved on this device with SharedPreferences.
class LocalProgressStore implements ProgressStore {
  static const key = 'curio_progress_guest';

  static const fresh = ProgressSnapshot(
    childName: 'Explorer',
    totalXp: 0,
    streak: 0,
    completedActivities: {},
    collectedFacts: {},
    skills: {'Number sense': 0, 'Patterns': 0, 'Evidence': 0, 'Reasoning': 0},
  );

  @override
  Future<ProgressSnapshot> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return fresh;
    try {
      return ProgressSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fresh; // A corrupt save shouldn't lock a child out of the app.
    }
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(snapshot.toJson()))) {
      throw StateError('Device storage is unavailable.');
    }
  }
}
