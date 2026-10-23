import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/family_settings.dart';

class FamilyService {
  FamilyService({SupabaseClient? client})
    : _client =
          client ??
          // Guests (Supabase configured, nobody signed in) use the on-device
          // settings, same as demo mode.
          (SupabaseConfig.isConfigured &&
                  Supabase.instance.client.auth.currentUser != null
              ? Supabase.instance.client
              : null);
  final SupabaseClient? _client;
  bool get isDemo => _client == null;
  String? get parentEmail => _client?.auth.currentUser?.email;
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
    final cacheKey = 'curio_family_$_userId';
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await _client
          .from('family_settings')
          .select()
          .eq('parent_id', _userId)
          .maybeSingle();
      final settings = data == null
          ? const FamilySettings()
          : FamilySettings.fromJson(data);
      await prefs.setString(cacheKey, jsonEncode(settings.toJson()));
      return settings;
    } catch (_) {
      // Offline: the last settings we saw beat silently falling back to the
      // defaults (which would show the wrong daily goal).
      final cached = prefs.getString(cacheKey);
      if (cached == null) rethrow;
      return FamilySettings.fromJson(jsonDecode(cached));
    }
  }

  Future<void> saveSettings(FamilySettings settings) async {
    if (_client == null) {
      await (await SharedPreferences.getInstance()).setString(
        'curio_demo_family',
        jsonEncode(settings.toJson()),
      );
      return;
    }
    // consent_at is stamped by the database when the version changes, and an
    // ordinary save can't clear an agreed version (202610080001).
    await _client.from('family_settings').upsert({
      'parent_id': _userId,
      ...settings.toJson(),
    });
    await (await SharedPreferences.getInstance()).setString(
      'curio_family_$_userId',
      jsonEncode(settings.toJson()),
    );
  }

  /// Patch only the email opt-in so a dashboard toggle cannot overwrite
  /// another device's goal, timezone, reminders or recorded consent.
  Future<void> setWeeklyEmailEnabled(bool enabled) async {
    if (_client == null) throw StateError('A family account is required.');
    final settings = await _client
        .from('family_settings')
        .update({'weekly_email_enabled': enabled})
        .eq('parent_id', _userId)
        .select()
        .single();
    try {
      await (await SharedPreferences.getInstance()).setString(
        'curio_family_$_userId',
        jsonEncode(settings),
      );
    } catch (_) {
      // The server saved the preference; local caching is best effort.
    }
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
    if (response.status != 200) {
      throw StateError('Account could not be deleted.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('curio_progress_$_userId');
    await prefs.remove('curio_pending_$_userId');
    await prefs.remove('curio_family_$_userId');
    await client.auth.signOut(scope: SignOutScope.local);
  }
}
