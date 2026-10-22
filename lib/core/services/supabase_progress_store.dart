import 'package:supabase_flutter/supabase_flutter.dart';

import 'progress_store.dart';
import '../../features/games/common/game_rewards.dart';

class SupabaseProgressStore implements ProgressStore {
  SupabaseProgressStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? _childId;
  final Set<String> _verifiedRewards = {};

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('A signed-in user is required.');
    return id;
  }

  Future<Map<String, dynamic>> _child() async {
    if (_childId != null) {
      return await _client
          .from('child_profiles')
          .select()
          .eq('id', _childId!)
          .single();
    }

    final existing = await _client
        .from('child_profiles')
        .select()
        .eq('parent_id', _userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    final child =
        existing ??
        await _client
            .from('child_profiles')
            .insert({
              'parent_id': _userId,
              'name': 'Explorer',
              'total_xp': 0,
              'streak': 0,
            })
            .select()
            .single();
    _childId = child['id'] as String;
    return child;
  }

  @override
  Future<ProgressSnapshot> load() async {
    final child = await _child();
    final childId = child['id'] as String;
    final results = await Future.wait([
      _client
          .from('activity_completions')
          .select('activity_id')
          .eq('child_id', childId),
      _client
          .from('unlocked_discoveries')
          .select('discovery_id')
          .eq('child_id', childId),
      _client
          .from('skill_progress')
          .select('skill_key, mastery')
          .eq('child_id', childId),
    ]);

    final activities = (results[0] as List)
        .map((row) => (row as Map<String, dynamic>)['activity_id'] as String)
        .toSet();
    final facts = (results[1] as List)
        .map((row) => (row as Map<String, dynamic>)['discovery_id'] as String)
        .toSet();
    final skills = <String, double>{
      for (final row in results[2] as List)
        (row as Map<String, dynamic>)['skill_key'] as String:
            ((row['mastery'] as num).toDouble()),
    };

    return ProgressSnapshot(
      childName: child['name'] as String,
      totalXp: child['total_xp'] as int,
      streak: child['streak'] as int,
      completedActivities: activities,
      collectedFacts: facts,
      skills: skills,
    );
  }

  @override
  Future<void> save(ProgressSnapshot snapshot) async {
    final child = await _child();
    final childId = child['id'] as String;

    // Older databases silently ignore activities absent from their reward
    // table. Keep the durable outbox pending until the migration is applied,
    // rather than reporting success and losing the child's new-game XP.
    final unverified = snapshot.completedActivities
        .map(activityGame)
        .where(gameRewards.containsKey)
        .toSet()
        .difference(_verifiedRewards);
    if (unverified.isNotEmpty) {
      final rows = await _client
          .from('activity_rewards')
          .select('activity')
          .inFilter('activity', unverified.toList());
      _verifiedRewards.addAll(rows.map((row) => row['activity'] as String));
      if (!unverified.every(_verifiedRewards.contains)) {
        throw StateError('The game reward catalogue needs a database update.');
      }
    }

    await _client.rpc(
      'sync_learning_progress',
      params: {
        'child_id': childId,
        'learner_name': snapshot.childName,
        'activities': snapshot.completedActivities.toList(),
      },
    );
  }
}
