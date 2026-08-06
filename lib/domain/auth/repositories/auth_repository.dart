import '../entities/child_profile.dart';
import '../entities/parent_profile.dart';

/// What the presentation layer depends on. The implementation (in
/// repository/auth/) is the only place that knows this is backed by
/// Supabase - nothing in domain/ or presentation/ imports supabase_flutter
/// directly.
abstract class AuthRepository {
  /// Step 1 of onboarding: create the Supabase Auth user. Throws
  /// [AuthFailure] on failure (e.g. email already registered).
  Future<void> signUp({required String email, required String password});

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Whether the current session's email has been verified yet. Used to
  /// decide whether to show the "check your email" screen.
  Future<bool> isEmailVerified();

  /// The signed-in user's id (Supabase auth.uid()), or null if signed out.
  String? get currentUserId;

  /// Step 2 of onboarding: atomically create the parent's profile and
  /// consent record (calls the create_parent_profile RPC). Throws
  /// [AuthFailure] if either half fails - see the RPC's rollback guarantee.
  Future<ParentProfile> acceptConsentAndCreateProfile({
    required String displayName,
    required String preferredLanguage,
    required String consentType,
    required String policyVersion,
  });

  /// Step 3 of onboarding: atomically create a child profile and its
  /// baseline skill rows (calls the add_child_profile RPC).
  Future<ChildProfile> addChildProfile({
    required String displayName,
    required String ageBand,
    required String preferredLanguage,
    String? avatarKey,
  });
}

/// Thrown by [AuthRepository] methods on any failure - the presentation
/// layer shows [message] directly, it's never a raw Supabase/Postgres error.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}
