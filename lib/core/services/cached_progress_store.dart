import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_store.dart';

/// A per-account durable outbox. Failed cloud writes remain on disk; retrying
/// replays the snapshot through the server's idempotent progress RPC.
class CachedProgressStore implements ProgressStore {
  CachedProgressStore({required this.remote, required this.userId});
  final ProgressStore remote;
  final String userId;
  bool offline = false;
  String get _cache => 'curio_progress_$userId';
  String get _pending => 'curio_pending_$userId';

  @override
  Future<ProgressSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cache);
    try {
      if (prefs.getBool(_pending) == true && cached != null) {
        await remote.save(ProgressSnapshot.fromJson(jsonDecode(cached)));
        await prefs.setBool(_pending, false);
      }
      final snapshot = await remote.load();
      await prefs.setString(_cache, jsonEncode(snapshot.toJson()));
      offline = false;
      return snapshot;
    } catch (_) {
      offline = true;
      if (cached == null) rethrow;
      return ProgressSnapshot.fromJson(jsonDecode(cached));
    }
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_cache, jsonEncode(snapshot.toJson()))) {
      throw StateError('Device storage is unavailable.');
    }
    await prefs.setBool(_pending, true);
    try {
      await remote.save(snapshot);
      await prefs.setBool(_pending, false);
      offline = false;
    } catch (_) {
      offline = true;
      rethrow;
    }
  }
}
