import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/family_settings.dart';

class FamilyService {
  FamilyService({SupabaseClient? client})
    : _client =
          client ??
          (SupabaseConfig.isConfigured ? Supabase.instance.client : null);
  final SupabaseClient? _client;
  bool get isDemo => _client == null;
  String get _userId => _client!.auth.currentUser!.id;

  Future<FamilySettings> loadSettings() async {
    if (_client == null) {
      final raw = (await SharedPreferences.getInstance()).getString(
        'curio_demo_family',
      );
      return raw == null
          ? const FamilySettings()
          : FamilySettings.fromJson(jsonDecode(raw));
    }
    final data = await _client
        .from('family_settings')
        .select()
        .eq('parent_id', _userId)
        .single();
    return FamilySettings.fromJson(data);
  }

  Future<void> saveSettings(FamilySettings settings) async {
    if (_client == null) {
      await (await SharedPreferences.getInstance()).setString(
        'curio_demo_family',
        jsonEncode(settings.toJson()),
      );
      return;
    }
    await _client.from('family_settings').upsert({
      'parent_id': _userId,
      ...settings.toJson(),
      if (settings.consentVersion != null)
        'consent_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> notifications() async => _client == null
      ? []
      : await _client
            .from('notifications')
            .select()
            .eq('parent_id', _userId)
            .order('created_at', ascending: false)
            .limit(100);
  Future<List<Map<String, dynamic>>> reports() async => _client == null
      ? []
      : await _client
            .from('parent_reports')
            .select()
            .eq('parent_id', _userId)
            .order('week_start', ascending: false)
            .limit(52);
  Future<void> markRead(String id) async {
    await _client?.rpc(
      'mark_notification_read',
      params: {'notification_id': id},
    );
  }

  Future<String> exportData() async {
    final client = _client;
    if (client == null) throw StateError('Sign in to export account data.');
    final children = await client
        .from('child_profiles')
        .select()
        .eq('parent_id', _userId);
    final details = <Map<String, dynamic>>[];
    for (final child in children) {
      final id = child['id'];
      details.add({
        ...child,
        'activities': await client
            .from('activity_completions')
            .select()
            .eq('child_id', id),
        'discoveries': await client
            .from('unlocked_discoveries')
            .select()
            .eq('child_id', id),
        'skills': await client
            .from('skill_progress')
            .select()
            .eq('child_id', id),
      });
    }
    return const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'email': client.auth.currentUser?.email,
      'profile': await client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle(),
      'settings': (await loadSettings()).toJson(),
      'learners': details,
      'reports': await reports(),
      'notifications': await notifications(),
    });
  }

  Future<void> deleteAccount(String password) async {
    final client = _client;
    if (client == null) throw StateError('Sign in first.');
    final response = await client.functions.invoke(
      'delete-account',
      body: {'password': password},
    );
    if (response.status != 200)
      throw StateError('Account could not be deleted.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('curio_progress_$_userId');
    await prefs.remove('curio_pending_$_userId');
    await client.auth.signOut(scope: SignOutScope.local);
  }
}
