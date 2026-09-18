import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/auth/presentation/login_page.dart';
import 'package:curio/features/auth/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuth extends AuthService {
  FakeAuth()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  int signups = 0;
  int resets = 0;
  bool failSave = true;
  String? savedName;
  @override
  Future<AuthResponse> createAccount({
    required String email,
    required String password,
  }) async {
    signups++;
    return AuthResponse();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resets++;
  }

  @override
  Future<void> completeOnboarding(String name) async {
    if (failSave) throw Exception('offline');
    savedName = name.trim();
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Signup validates and shows confirmation; recovery validates email',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuth();
      await tester.pumpWidget(
        MaterialApp(
          theme: CurioTheme.light,
          home: LoginPage(authService: auth),
        ),
      );
      await tapVisible(tester, find.text('Create account'));
      await tapVisible(tester, find.text('Create my account'));
      expect(auth.signups, 0);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'parent@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'curious123');
      await tester.enterText(find.byType(TextFormField).at(2), 'mismatch');
      await tapVisible(tester, find.text('Create my account'));
      expect(find.text('The passwords don’t match.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), 'curious123');
      await tapVisible(tester, find.text('Create my account'));
      expect(auth.signups, 1);
      expect(find.text('Check your inbox.'), findsOneWidget);
      await tapVisible(tester, find.text('Back to sign in'));
      await tapVisible(tester, find.text('Forgot password?'));
      await tapVisible(tester, find.text('Send reset link'));
      expect(auth.resets, 1);
      expect(find.textContaining('a reset link is on its way'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Onboarding retains nickname through back and failed save, retries successfully',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuth();
      bool complete = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: CurioTheme.dark,
          home: OnboardingPage(
            authService: auth,
            onComplete: () => complete = true,
          ),
        ),
      );
      await tapVisible(tester, find.text('Let’s get started'));
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('Add a nickname to continue.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Alex');
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('Welcome, Alex!'), findsOneWidget);
      await tapVisible(tester, find.text('Back'));
      expect(find.text('Alex'), findsOneWidget);
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Start exploring'));
      expect(complete, isFalse);
      expect(find.textContaining('We couldn’t save'), findsOneWidget);
      auth.failSave = false;
      await tapVisible(tester, find.text('Start exploring'));
      expect(complete, isTrue);
      expect(auth.savedName, 'Alex');
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(375, 812),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Auth responsive $size dark=$dark with large text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? CurioTheme.dark : CurioTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: LoginPage(authService: FakeAuth()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
