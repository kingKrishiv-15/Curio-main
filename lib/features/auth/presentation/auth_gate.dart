import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/progress_store.dart';
import '../../../core/services/supabase_progress_store.dart';
import '../../../core/state/curio_state.dart';
import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/widgets/curio_ui.dart';
import '../../shell/presentation/main_shell.dart';
import 'login_page.dart';
import 'update_password_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const _CurioExperience();
    }

    final auth = AuthService();
    return StreamBuilder<AuthState>(
      stream: auth.authChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return LoginPage(authService: auth);
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return UpdatePasswordPage(authService: auth);
        }
        return _CurioExperience(
          key: ValueKey(session.user.id),
          store: SupabaseProgressStore(),
        );
      },
    );
  }
}

class _CurioExperience extends StatefulWidget {
  const _CurioExperience({this.store, super.key});
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
          return const MainShell();
        },
      ),
    );
  }
}
