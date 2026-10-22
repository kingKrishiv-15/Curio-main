import 'package:curio/core/services/cached_progress_store.dart';
import 'package:curio/core/services/guest_session.dart';
import 'package:curio/core/services/progress_store.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Remote implements ProgressStore {
  bool available = false;
  ProgressSnapshot snapshot = LocalProgressStore.fresh;
  @override
  Future<ProgressSnapshot> load() async {
    if (!available) throw StateError('Offline');
    return snapshot;
  }

  @override
  Future<void> save(ProgressSnapshot value) async {
    if (!available) throw StateError('Offline');
    snapshot = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline rewards survive restart and sync once after reconnecting',
    () async {
      SharedPreferences.setMockInitialValues({});
      final remote = _Remote()..available = true;
      final cache = CachedProgressStore(remote: remote, userId: 'test-family');
      final state = CurioState(store: cache);
      await state.hydrate();
      remote.available = false;
      state.completeActivity(
        id: CurioState.dailyActivityId('memory_match'),
        xp: 80,
        skill: 'Memory',
        factId: 'memory_pairs',
      );
      await state.flush();
      expect(state.totalXp, 80);
      expect(state.syncError, isNotNull);
      final restarted = CurioState(
        store: CachedProgressStore(remote: remote, userId: 'test-family'),
      );
      await restarted.hydrate();
      expect(restarted.loadFailed, isFalse);
      expect(restarted.totalXp, 80);
      expect(restarted.collectedFacts, contains('memory_pairs'));
      expect(restarted.syncError, isNotNull);
      remote.available = true;
      await restarted.retrySync();
      expect(restarted.syncError, isNull);
      expect(remote.snapshot.totalXp, 80);
      expect(remote.snapshot.completedActivities.length, 1);
      final reloaded = await CachedProgressStore(
        remote: remote,
        userId: 'test-family',
      ).load();
      expect(reloaded.totalXp, 80);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'curio_pending_test-family',
        ),
        isFalse,
      );
      state.dispose();
      restarted.dispose();
    },
  );
}
