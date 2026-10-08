import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/progress_store.dart';
import '../../../core/services/cached_progress_store.dart';
import '../../../core/services/supabase_progress_store.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../shell/presentation/main_shell.dart';
import 'auth_layout.dart';
import 'landing_page.dart';
import 'onboarding_page.dart';
import 'update_password_page.dart';

/// Decides what the app shows, from Supabase's auth state:
///
/// * no Supabase project → demo mode, straight to Home
/// * signed out → [LandingPage] (and whatever it pushes: intro, sign-in,
///   code entry)
/// * a password-reset code or link just verified → [UpdatePasswordPage]
/// * signed in → learner setup the first time, then Home
///
/// Signed-out screens are pushed on the root navigator, so whenever the
/// signed-in state flips the gate pops back to itself — a correct code
/// lands the parent in learner setup without each page navigating itself.
class AuthGate extends StatefulWidget {
  const AuthGate({this.authService, super.key});

  /// For tests; defaults to one backed by the initialised Supabase client.
  final AuthService? authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthService? _auth;
  StreamSubscription<AuthState>? _subscription;
  Session? _session;
  bool _recovering = false;

  @override
  void initState() {
    super.initState();
    if (widget.authService == null && !SupabaseConfig.isConfigured) return;
    final auth = _auth = widget.authService ?? AuthService();
    _session = auth.currentSession;
    _subscription = auth.authChanges.listen(_onAuthChange);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    if (!mounted) return;
    final wasSignedIn = _session != null;
    setState(() {
      _session = state.session;
      if (state.event == AuthChangeEvent.passwordRecovery) _recovering = true;
      if (state.session == null) _recovering = false;
    });
    if (wasSignedIn != (state.session != null) ||
        state.event == AuthChangeEvent.passwordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth == null) return const _CurioExperience();
    final session = _session;
    if (session == null) return LandingPage(authService: auth);
    if (_recovering) {
      return UpdatePasswordPage(
        authService: auth,
        onDone: () => setState(() => _recovering = false),
      );
    }
    return _LearnerGate(key: ValueKey(session.user.id), auth: auth);
  }
}

class _LearnerGate extends StatefulWidget {
  const _LearnerGate({required this.auth, super.key});
  final AuthService auth;
  @override
  State<_LearnerGate> createState() => _LearnerGateState();
}

class _LearnerGateState extends State<_LearnerGate> {
  late Future<bool> _needsOnboarding = widget.auth.needsOnboarding();
  bool _complete = false;
  @override
  Widget build(BuildContext context) {
    if (_complete) {
      return _CurioExperience(
        store: CachedProgressStore(
          remote: SupabaseProgressStore(),
          userId: widget.auth.currentSession!.user.id,
        ),
      );
    }
    return FutureBuilder<bool>(
      future: _needsOnboarding,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AuthLayout(
            child: Column(
              children: [
                const AuthNotice(
                  'We couldn’t load your learner profile. Check your connection and try again.',
                  error: true,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => setState(
                    () => _needsOnboarding = widget.auth.needsOnboarding(),
                  ),
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: widget.auth.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading your profile',
              ),
            ),
          );
        }
        if (snapshot.data!) {
          return OnboardingPage(
            authService: widget.auth,
            onComplete: () => setState(() => _complete = true),
          );
        }
        return _CurioExperience(
          store: CachedProgressStore(
            remote: SupabaseProgressStore(),
            userId: widget.auth.currentSession!.user.id,
          ),
        );
      },
    );
  }
}

class _CurioExperience extends StatefulWidget {
  const _CurioExperience({this.store});
  final ProgressStore? store;

  @override
  State<_CurioExperience> createState() => _CurioExperienceState();
}

class _CurioExperienceState extends State<_CurioExperience> {
  late final CurioState _state = CurioState(store: widget.store);

  @override
  void initState() {
    super.initState();
    _state.hydrate();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurioScope(
      notifier: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          if (_state.isLoading) {
            return Scaffold(
              backgroundColor: curioColor(
                context,
                CurioColors.canvas,
                CurioColorsLight.canvas,
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CurioBrand(),
                    const SizedBox(height: 22),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading your learning trail…',
                      style: TextStyle(
                        color: curioColor(
                          context,
                          CurioColors.inkMuted,
                          CurioColorsLight.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_state.loadFailed) {
            return AuthLayout(
              child: Column(
                children: [
                  const AuthNotice(
                    'Your learning trail could not be loaded. Please reconnect and try again.',
                    error: true,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _state.hydrate,
                    child: const Text('Retry loading'),
                  ),
                  TextButton(
                    onPressed: AuthService().signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            );
          }
          return const MainShell();
        },
      ),
    );
  }
}
