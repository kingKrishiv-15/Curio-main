import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/auth/add_child_page.dart';
import '../presentation/auth/consent_page.dart';
import '../presentation/auth/sign_in_page.dart';
import '../presentation/auth/sign_up_page.dart';
import '../presentation/auth/verify_email_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/widgets/coming_soon_page.dart';
import 'providers.dart';

// UI sprint routes - fake data only, not wired to live Supabase.
const _platformRoutes = {'/home', '/curio-special', '/maths', '/sharpen'};

/// Each onboarding step navigates to the next one explicitly on success
/// (see the auth screens) rather than this router inferring "which step is
/// the user on" from server state - that inference needs a profile/child
/// existence query, which isn't built until a later phase. The one thing
/// this router does enforce declaratively is the auth gate: signed-out
/// users can't land on anything past sign-in/sign-up by typing a URL or
/// using back/forward.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // TODO(ui-sprint): temporarily starts at /home and exempts
    // _platformRoutes from the auth gate below, so these screens can be
    // built/demoed against fake data without a real Supabase backend to
    // sign in against. Revert initialLocation to '/' and drop the
    // _platformRoutes exemption once this sprint's screens get wired to
    // real auth + data.
    initialLocation: '/home',
    refreshListenable: _GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final isSignedIn = ref.read(supabaseClientProvider).auth.currentSession != null;
      final isOnAuthScreen = state.matchedLocation == '/sign-in' || state.matchedLocation == '/sign-up';
      final isOnSplash = state.matchedLocation == '/';
      final isOnPlatformRoute = _platformRoutes.contains(state.matchedLocation);

      if (!isSignedIn && !isOnAuthScreen && !isOnSplash && !isOnPlatformRoute) {
        return '/sign-in';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/sign-up', builder: (context, state) => const SignUpPage()),
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailPage()),
      GoRoute(path: '/onboarding/consent', builder: (context, state) => const ConsentPage()),
      GoRoute(path: '/onboarding/add-child', builder: (context, state) => const AddChildPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/curio-special', builder: (context, state) => const ComingSoonPage(title: 'Curio Special')),
      GoRoute(path: '/maths', builder: (context, state) => const ComingSoonPage(title: 'Maths')),
      GoRoute(path: '/sharpen', builder: (context, state) => const ComingSoonPage(title: 'IPM & MAT')),
    ],
  );
});

/// Bridges the authStateChangesProvider stream to something GoRouter's
/// `refreshListenable` can use, so a sign-in/sign-out re-evaluates the
/// redirect above immediately instead of only on the next navigation.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    _subscription = ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
