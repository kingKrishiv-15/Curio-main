import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/guest_session.dart';
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
///   code entry), or straight into the app for a guest
///   ([GuestSession]: no account, progress on this device only)
/// * a password-reset code or link just verified → [UpdatePasswordPage]
/// * signed in → learner setup the first time, then Home
///
/// Signed-out screens are pushed on the root navigator, so whenever the
/// signed-in state flips the gate pops back to itself — a correct code
/// lands the parent in learner setup without each page navigating itself.
class AuthGate extends StatefulWidget {
  const AuthGate({this.authService, this.guest, super.key});

  /// For tests; defaults to one backed by the initialised Supabase client.
  final AuthService? authService;

  /// For tests; defaults to [GuestSession.instance].
  final GuestSession? guest;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthService? _auth;
  StreamSubscription<AuthState>? _subscription;
  Session? _session;
  bool _recovering = false;
  late final GuestSession _guest = widget.guest ?? GuestSession.instance;

  @override
  void initState() {
    super.initState();
    if (widget.authService == null && !SupabaseConfig.isConfigured) return;
    _guest.addListener(_onGuestChange);
    final auth = _auth = widget.authService ?? AuthService();
    _session = auth.currentSession;
    _subscription = auth.authChanges.listen(_onAuthChange);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _guest.removeListener(_onGuestChange);
    super.dispose();
  }

  void _popToRoot() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _onGuestChange() {
    if (!mounted) return;
    setState(() {});
    _popToRoot();
  }

  void _onAuthChange(AuthState state) {
    if (!mounted) return;
    final wasSignedIn = _session != null;
    setState(() {
      _session = state.session;
      if (state.event == AuthChangeEvent.passwordRecovery) _recovering = true;
      if (state.session == null) _recovering = false;
    });
    // A real account replaces guest play.
    if (state.session != null && _guest.isActive) _guest.end();
    if (wasSignedIn != (state.session != null) ||
        state.event == AuthChangeEvent.passwordRecovery) {
      _popToRoot();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth;
    if (auth == null) return const _CurioExperience();
    final session = _session;
    if (session == null) {
      if (_guest.isActive) {
        return _CurioExperience(
          key: const ValueKey('guest'),
          store: LocalProgressStore(),
          isGuest: true,
        );
      }
      return LandingPage(authService: auth);
    }
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
  const _CurioExperience({this.store, this.isGuest = false, super.key});
  final ProgressStore? store;
  final bool isGuest;

  @override
  State<_CurioExperience> createState() => _CurioExperienceState();
}

class _CurioExperienceState extends State<_CurioExperience> {
  late final CurioState _state = CurioState(
    store: widget.store,
    isGuest: widget.isGuest,
  );

  @override
  void initState() {
    super.initState();
    _state.startDailyClock();
    _state.hydrate().then((_) => _offerGuestProgress());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  /// A parent who played as a guest on this device and then signed in can
  /// bring those games into the account. Only activity ids move; the server
  /// works out XP, skills and discoveries from its own reward table.
  Future<void> _offerGuestProgress() async {
    if (widget.isGuest || widget.store == null || _state.loadFailed) return;
    final guest = await LocalProgressStore().load();
    final fresh = guest.completedActivities.difference(
      _state.completedActivities,
    );
    if (fresh.isEmpty || !mounted) return;
    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bring your guest progress?'),
        content: Text(
          '${guest.childName} played ${fresh.length} '
          '${fresh.length == 1 ? 'game' : 'games'} as a guest on this device. '
          'Add them to this family account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add to account'),
          ),
        ],
      ),
    );
    if (add != true || !mounted) return;
    await _state.mergeActivities(fresh);
    if (_state.syncError == null) await GuestSession.instance.end(erase: true);
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
                    onPressed: widget.isGuest
                        ? () => GuestSession.instance.end()
                        : AuthService().signOut,
                    child: Text(
                      widget.isGuest ? 'Leave guest mode' : 'Sign out',
                    ),
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
