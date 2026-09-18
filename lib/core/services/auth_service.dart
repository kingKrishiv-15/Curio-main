import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> createAccount({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<bool> needsOnboarding() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in to continue.');
    if (user.userMetadata?['onboarding_complete'] == true) return false;
    final child = await _client
        .from('child_profiles')
        .select('id')
        .eq('parent_id', user.id)
        .limit(1)
        .maybeSingle();
    // Keep existing families on their established learning trail.
    return child == null;
  }

  Future<void> completeOnboarding(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in to continue.');
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 18) {
      throw ArgumentError('Use a nickname of 1–18 characters.');
    }
    final existing = await _client
        .from('child_profiles')
        .select('id')
        .eq('parent_id', user.id)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    if (existing == null) {
      await _client.from('child_profiles').insert({
        'parent_id': user.id,
        'name': cleaned,
        'total_xp': 0,
        'streak': 0,
      });
    } else {
      await _client
          .from('child_profiles')
          .update({'name': cleaned})
          .eq('id', existing['id']);
    }
    await _client.auth.updateUser(
      UserAttributes(data: {'onboarding_complete': true}),
    );
  }

  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;
    await _client.auth.signOut();
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('curio_progress_$userId');
      await prefs.remove('curio_pending_$userId');
    }
  }
}
