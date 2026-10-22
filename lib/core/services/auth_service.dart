import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/family_settings.dart';
import 'family_service.dart';

/// Why a verification code was emailed. Each maps to a Supabase email
/// template and verification type.
enum CodePurpose {
  /// "Confirm signup" template — proves a new parent owns the address.
  signUp,

  /// "Magic Link" template — password-free sign-in for an existing account.
  signIn,

  /// "Reset Password" template — leads to choosing a new password.
  recovery,
}

/// What happened when a parent tried to create an account.
enum SignUpOutcome {
  /// A code is on its way; the account activates once it's entered.
  codeSent,

  /// Email confirmation is switched off in Supabase, so they're signed in.
  signedIn,

  /// The address already belongs to a confirmed account. Supabase doesn't
  /// send anything in this case (to avoid revealing who has an account).
  alreadyRegistered,
}

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

  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
      data: {
        'consent_version': FamilySettings.currentConsentVersion,
        'consent_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    if (response.session != null) return SignUpOutcome.signedIn;
    // With confirmations on, an already-confirmed address comes back as a
    // placeholder user with no identities, and no email is sent.
    if (response.user?.identities?.isEmpty ?? false) {
      return SignUpOutcome.alreadyRegistered;
    }
    return SignUpOutcome.codeSent;
  }

  /// Emails a fresh code. For [CodePurpose.signUp] this re-sends the
  /// confirmation; the others start their flow.
  Future<void> sendCode(CodePurpose purpose, String email) async {
    final address = email.trim();
    switch (purpose) {
      case CodePurpose.signUp:
        await _client.auth.resend(
          type: OtpType.signup,
          email: address,
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        );
      case CodePurpose.signIn:
        await _client.auth.signInWithOtp(
          email: address,
          shouldCreateUser: false,
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        );
      case CodePurpose.recovery:
        await _client.auth.resetPasswordForEmail(
          address,
          redirectTo: SupabaseConfig.authRedirectUrl,
        );
    }
  }

  /// Checks an emailed code. On success Supabase signs the parent in and
  /// the [AuthGate] moves on by itself — `signedIn` for sign-up/sign-in,
  /// `passwordRecovery` for a reset.
  Future<void> verifyCode(
    CodePurpose purpose, {
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      // `email` checks both confirmation and sign-in codes; recovery must be
      // explicit so the SDK raises the passwordRecovery event.
      type: purpose == CodePurpose.recovery ? OtpType.recovery : OtpType.email,
      email: email.trim(),
      token: code,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  /// Whether this parent agreed to the current privacy notice when they
  /// signed up. Accounts made another way (e.g. Google) confirm it during
  /// learner setup instead.
  bool get hasRecordedConsent =>
      _client.auth.currentUser?.userMetadata?['consent_version'] != null;

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

  Future<void> completeOnboarding(
    String name, {
    FamilySettings? settings,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in to continue.');
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 18) {
      throw ArgumentError('Use a nickname of 1–18 characters.');
    }
    if (settings != null) {
      await FamilyService(client: _client).saveSettings(settings);
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
      // Account-scoped pending rewards must survive signing out while offline.
      if (prefs.getBool('curio_pending_$userId') != true) {
        await prefs.remove('curio_progress_$userId');
        await prefs.remove('curio_pending_$userId');
      }
    }
  }
}
