import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/auth/entities/child_profile.dart';
import '../../domain/auth/entities/parent_profile.dart';
import '../../domain/auth/repositories/auth_repository.dart';

/// The only class in the app that both knows about Supabase's client types
/// AND the domain's entity types - it translates between them so nothing
/// else has to.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<bool> isEmailVerified() async {
    // Supabase doesn't push email-confirmation updates to an already-loaded
    // session, so refresh it before checking.
    final response = await _client.auth.refreshSession();
    return response.user?.emailConfirmedAt != null;
  }

  @override
  Future<ParentProfile> acceptConsentAndCreateProfile({
    required String displayName,
    required String preferredLanguage,
    required String consentType,
    required String policyVersion,
  }) async {
    try {
      final row = await _client.rpc(
        'create_parent_profile',
        params: {
          'p_display_name': displayName,
          'p_preferred_language': preferredLanguage,
          'p_consent_type': consentType,
          'p_policy_version': policyVersion,
        },
      );
      return _parentProfileFromRow(row as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<ChildProfile> addChildProfile({
    required String displayName,
    required String ageBand,
    required String preferredLanguage,
    String? avatarKey,
  }) async {
    try {
      final row = await _client.rpc(
        'add_child_profile',
        params: {
          'p_display_name': displayName,
          'p_avatar_key': avatarKey,
          'p_age_band': ageBand,
          'p_preferred_language': preferredLanguage,
        },
      );
      return _childProfileFromRow(row as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  ParentProfile _parentProfileFromRow(Map<String, dynamic> row) {
    return ParentProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      preferredLanguage: row['preferred_language'] as String,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  ChildProfile _childProfileFromRow(Map<String, dynamic> row) {
    return ChildProfile(
      id: row['id'] as String,
      parentId: row['parent_id'] as String,
      displayName: row['display_name'] as String,
      avatarKey: row['avatar_key'] as String?,
      ageBand: row['age_band'] as String,
      preferredLanguage: row['preferred_language'] as String,
      totalXp: row['total_xp'] as int,
      dragonStage: row['dragon_stage'] as int,
      active: row['active'] as bool,
    );
  }
}
