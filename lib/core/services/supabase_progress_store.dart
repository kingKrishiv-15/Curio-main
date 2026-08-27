import 'package:supabase_flutter/supabase_flutter.dart';

import 'progress_store.dart';

class SupabaseProgressStore implements ProgressStore {
  SupabaseProgressStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? _childId;

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
            .insert({'parent_id': _userId, 'name': 'Explorer'})
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

    await _client
        .from('child_profiles')
        .update({
          'name': snapshot.childName,
          'total_xp': snapshot.totalXp,
          'streak': snapshot.streak,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', childId);

    if (snapshot.completedActivities.isNotEmpty) {
      await _client
          .from('activity_completions')
          .upsert(
            snapshot.completedActivities
                .map((id) => {'child_id': childId, 'activity_id': id})
                .toList(),
            onConflict: 'child_id,activity_id',
          );
    }
    if (snapshot.collectedFacts.isNotEmpty) {
      await _client
          .from('unlocked_discoveries')
          .upsert(
            snapshot.collectedFacts
                .map((id) => {'child_id': childId, 'discovery_id': id})
                .toList(),
            onConflict: 'child_id,discovery_id',
          );
    }
    if (snapshot.skills.isNotEmpty) {
      await _client
          .from('skill_progress')
          .upsert(
            snapshot.skills.entries
                .map(
                  (entry) => {
                    'child_id': childId,
                    'skill_key': entry.key,
                    'mastery': entry.value,
                    'updated_at': DateTime.now().toUtc().toIso8601String(),
                  },
                )
                .toList(),
            onConflict: 'child_id,skill_key',
          );
    }
  }
}
