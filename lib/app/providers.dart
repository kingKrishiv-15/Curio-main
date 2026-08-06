import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth/entities/child_profile.dart';
import '../domain/auth/repositories/auth_repository.dart';
import '../domain/auth/usecases/accept_consent_and_create_profile.dart';
import '../domain/auth/usecases/add_child_profile.dart';
import '../domain/auth/usecases/sign_in_parent.dart';
import '../domain/auth/usecases/sign_up_parent.dart';
import '../repository/auth/supabase_auth_repository.dart';

/// The Riverpod provider graph for Phase 0. Each later phase adds its own
/// providers near the feature that needs them - this file stays just the
/// auth/session wiring that the router and auth screens depend on.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Emits whenever Supabase's auth state changes (sign in, sign out, token
/// refresh). The router watches this to decide which screen to show.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final signUpParentProvider = Provider((ref) {
  return SignUpParent(ref.watch(authRepositoryProvider));
});

final signInParentProvider = Provider((ref) {
  return SignInParent(ref.watch(authRepositoryProvider));
});

final acceptConsentAndCreateProfileProvider = Provider((ref) {
  return AcceptConsentAndCreateProfile(ref.watch(authRepositoryProvider));
});

final addChildProfileProvider = Provider((ref) {
  return AddChildProfile(ref.watch(authRepositoryProvider));
});

/// The child profile just created during onboarding, held in memory so the
/// "new child becomes the active profile" step (behavioral spec, step 4)
/// has somewhere to live without a round-trip back to the server. Reset on
/// sign-out.
final activeChildProvider = StateProvider<ChildProfile?>((ref) => null);
