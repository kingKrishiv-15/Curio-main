import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:curio/core/config/supabase_config.dart';
import 'package:curio/core/models/family_settings.dart';
import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/theme/theme_controller.dart';
import 'package:curio/features/auth/presentation/auth_gate.dart';
import 'package:curio/features/auth/presentation/auth_page.dart';
import 'package:curio/features/auth/presentation/intro_page.dart';
import 'package:curio/features/auth/presentation/landing_page.dart';
import 'package:curio/features/auth/presentation/onboarding_page.dart';
import 'package:curio/features/auth/presentation/update_password_page.dart';
import 'package:curio/features/auth/presentation/verify_code_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final changes = StreamController<AuthState>.broadcast();
  Session? session;
  SignUpOutcome signUpOutcome = SignUpOutcome.codeSent;
  Object? signInError;
  Object? sendError;
  final verifyErrors = <Object>[];
  bool consentRecorded = true;
  bool failSave = false;
  bool onboardingNeeded = true;

  int signups = 0;
  final sent = <CodePurpose>[];
  final verified = <(CodePurpose, String)>[];
  String? savedName;
  FamilySettings? savedSettings;

  @override
  Session? get currentSession => session;
  @override
  Stream<AuthState> get authChanges => changes.stream;
  @override
  bool get hasRecordedConsent => consentRecorded;

  @override
  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
  }) async {
    signups++;
    return signUpOutcome;
  }

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return AuthResponse();
  }

  @override
  Future<void> sendCode(CodePurpose purpose, String email) async {
    if (sendError != null) throw sendError!;
    sent.add(purpose);
  }

  @override
  Future<void> verifyCode(
    CodePurpose purpose, {
    required String email,
    required String code,
  }) async {
    verified.add((purpose, code));
    if (verifyErrors.isNotEmpty) throw verifyErrors.removeAt(0);
  }

  @override
  Future<bool> needsOnboarding() async => onboardingNeeded;

  @override
  Future<void> completeOnboarding(
    String name, {
    FamilySettings? settings,
  }) async {
    if (failSave) throw Exception('offline');
    savedName = name.trim();
    savedSettings = settings;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}

Session fakeSession() => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: const User(
    id: 'parent-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-09-25T00:00:00Z',
  ),
);

Future<void> phone(
  WidgetTester tester, [
  Size size = const Size(390, 844),
]) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget app(Widget home, {bool dark = false, ThemeController? reading}) {
  Widget materialApp() => MaterialApp(
    theme: dark ? CurioTheme.dark : CurioTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(reading?.readingScale ?? 1),
      ),
      child: child!,
    ),
    home: home,
  );
  if (reading == null) return materialApp();
  return CurioThemeScope(
    controller: reading,
    child: ListenableBuilder(
      listenable: reading,
      builder: (_, _) => materialApp(),
    ),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Lets looping illustration animations run without pumpAndSettle timing
/// out on them.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget calm(Widget child) => child;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Landing → intro → sign-up, and the intro only shows once', (
    tester,
  ) async {
    await phone(tester);
    final auth = FakeAuth();
    await tester.pumpWidget(calm(app(LandingPage(authService: auth))));
    await settle(tester);
    expect(find.textContaining('into a daily adventure'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('landing_get_started')));
    expect(find.text('Five minutes.\nOne big idea.'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('intro_next')));
    expect(find.text('Every win unlocks a discovery.'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('intro_next')));
    expect(find.text('You’ll see the growth, too.'), findsOneWidget);
    await tapVisible(tester, find.text('Create a family account'));
    expect(find.text('Create your family account'), findsOneWidget);
    expect(await IntroPage.hasBeenSeen(), isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('landing_get_started')));
    expect(find.text('Create your family account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sign-up checks email, password rules and consent, then asks for the code',
    (tester) async {
      await phone(tester);
      final auth = FakeAuth();
      await tester.pumpWidget(
        calm(app(AuthPage(authService: auth, mode: AuthMode.signUp))),
      );
      await tapVisible(tester, find.byKey(const Key('auth_submit')));
      expect(auth.signups, 0);
      expect(
        find.textContaining('Enter a valid email address'),
        findsOneWidget,
      );
      expect(find.textContaining('confirm you’re a parent'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'parent@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tapVisible(tester, find.byKey(const Key('auth_submit')));
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'abcdefgh');
      await tapVisible(tester, find.byKey(const Key('auth_submit')));
      expect(
        find.text('Include at least one letter and one number.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'curious123');
      await tapVisible(tester, find.byKey(const Key('auth_consent')));
      await tapVisible(tester, find.byKey(const Key('auth_submit')));
      expect(auth.signups, 1);
      expect(find.text('Confirm your email'), findsOneWidget);
      expect(find.text('parent@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Signing up with a registered email switches to sign-in', (
    tester,
  ) async {
    await phone(tester);
    final auth = FakeAuth()..signUpOutcome = SignUpOutcome.alreadyRegistered;
    await tester.pumpWidget(
      calm(app(AuthPage(authService: auth, mode: AuthMode.signUp))),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'curious123');
    await tapVisible(tester, find.byKey(const Key('auth_consent')));
    await tapVisible(tester, find.byKey(const Key('auth_submit')));
    expect(find.text('Good to see you again.'), findsOneWidget);
    expect(find.textContaining('already a Curio account'), findsOneWidget);
    expect(find.text('parent@example.com'), findsOneWidget);
  });

  testWidgets('Signing in before confirming sends a fresh code and opens it', (
    tester,
  ) async {
    await phone(tester);
    final auth = FakeAuth()
      ..signInError = const AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );
    await tester.pumpWidget(calm(app(AuthPage(authService: auth))));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'curious123');
    await tapVisible(tester, find.byKey(const Key('auth_submit')));
    expect(auth.sent, [CodePurpose.signUp]);
    expect(find.text('Confirm your email'), findsOneWidget);
    expect(find.textContaining('isn’t confirmed yet'), findsOneWidget);
  });

  testWidgets('Wrong password shows a friendly message', (tester) async {
    await phone(tester);
    final auth = FakeAuth()
      ..signInError = const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );
    await tester.pumpWidget(calm(app(AuthPage(authService: auth))));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'nope1234');
    await tapVisible(tester, find.byKey(const Key('auth_submit')));
    expect(find.textContaining('don’t match'), findsOneWidget);
  });

  testWidgets(
    'Code verification preserves the full code, recovers from an error, and paces resends',
    (tester) async {
      await phone(tester);
      final auth = FakeAuth()
        ..verifyErrors.add(
          const AuthException(
            'Token has expired or is invalid',
            code: 'otp_expired',
          ),
        );
      await tester.pumpWidget(
        calm(
          app(
            VerifyCodePage(
              authService: auth,
              purpose: CodePurpose.signUp,
              email: 'parent@example.com',
              codeLength: 6,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('send a new code in 1:00'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.pump();
      expect(
        auth.verified,
        isEmpty,
        reason: 'six digits may be only the beginning of an eight-digit code',
      );
      await tapVisible(tester, find.byKey(const Key('verify_submit')));
      expect(auth.verified, [(CodePurpose.signUp, '123456')]);
      expect(find.textContaining('isn’t right or has expired'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('otp_input')))
            .controller!
            .text,
        '123456',
      );
      await tester.enterText(find.byKey(const Key('otp_input')), '01 23-4567');
      await tester.pump();
      expect(auth.verified.length, 1);
      await tapVisible(tester, find.byKey(const Key('verify_submit')));
      expect(auth.verified.last, (CodePurpose.signUp, '01234567'));
      await tester.pump(const Duration(seconds: 61));
      await tapVisible(tester, find.byKey(const Key('verify_resend')));
      expect(auth.sent, [CodePurpose.signUp]);
      expect(find.textContaining('A new code is on its way'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final purpose in CodePurpose.values) {
    for (final length in [6, 8, 10]) {
      testWidgets(
        'Verification accepts $length digits for $purpose even with six configured boxes',
        (tester) async {
          await phone(tester, const Size(320, 640));
          final auth = FakeAuth();
          await tester.pumpWidget(
            calm(
              app(
                VerifyCodePage(
                  authService: auth,
                  purpose: purpose,
                  email: 'parent@example.com',
                  codeLength: 6,
                ),
              ),
            ),
          );
          final code = '0123456789'.substring(0, length);
          await tester.enterText(
            find.byKey(const Key('otp_input')),
            code.substring(0, 6),
          );
          await tester.pump();
          expect(auth.verified, isEmpty);
          await tester.enterText(find.byKey(const Key('otp_input')), code);
          await tester.pump();
          expect(auth.verified, isEmpty);
          await tapVisible(tester, find.byKey(const Key('verify_submit')));
          expect(auth.verified, [(purpose, code)]);
          expect(
            tester
                .widget<TextField>(find.byKey(const Key('otp_input')))
                .controller!
                .text,
            code,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('Forgot password sends a recovery code', (tester) async {
    await phone(tester);
    final auth = FakeAuth();
    await tester.pumpWidget(calm(app(AuthPage(authService: auth))));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'parent@example.com',
    );
    await tapVisible(tester, find.text('Forgot password?'));
    expect(find.text('Forgot your password?'), findsOneWidget);
    // The email carries over from the sign-in form.
    expect(find.text('parent@example.com'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('code_request_send')));
    expect(auth.sent, [CodePurpose.recovery]);
    expect(find.textContaining('If there’s a Curio account'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Code sign-in explains when no account exists', (tester) async {
    await phone(tester);
    final auth = FakeAuth()
      ..sendError = const AuthException(
        'Signups not allowed for otp',
        code: 'otp_disabled',
      );
    await tester.pumpWidget(calm(app(AuthPage(authService: auth))));
    await tapVisible(tester, find.text('Email me a sign-in code'));
    await tester.enterText(find.byType(TextFormField), 'nobody@example.com');
    await tapVisible(tester, find.byKey(const Key('code_request_send')));
    expect(
      find.textContaining('couldn’t find a Curio account'),
      findsOneWidget,
    );
  });

  testWidgets('Learner setup keeps choices through back and a failed save', (
    tester,
  ) async {
    await phone(tester);
    final auth = FakeAuth()
      ..failSave = true
      ..consentRecorded = false;
    var complete = false;
    final reading = ThemeController();
    addTearDown(reading.dispose);
    await tester.pumpWidget(
      calm(
        app(
          OnboardingPage(authService: auth, onComplete: () => complete = true),
          dark: true,
          reading: reading,
        ),
      ),
    );
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(find.text('Add a nickname to continue.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(find.text('How much play a day?'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('goal_2')));
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(find.text('Make it comfortable.'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('reading_1.4')));
    await tapVisible(tester, find.byKey(const Key('onboarding_reduce_motion')));
    expect(reading.readingScale, 1.4);
    expect(reading.reduceMotion, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getDouble('curio_reading_scale'), 1.4);
    expect(preferences.getBool('curio_reduce_motion'), isTrue);
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(find.text('How should we keep you posted?'), findsOneWidget);
    await tapVisible(tester, find.text('Back'));
    await tapVisible(tester, find.text('Back'));
    await tapVisible(tester, find.text('Back'));
    expect(find.text('Alex'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    }
    expect(find.text('Welcome, Alex!'), findsOneWidget);
    expect(find.text('2 games a day'), findsOneWidget);
    expect(find.text('140%'), findsOneWidget);
    expect(find.text('Gentler'), findsOneWidget);

    // Signed up another way, so consent is asked for here.
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(find.textContaining('Please confirm'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('onboarding_consent')));
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(complete, isFalse);
    expect(find.textContaining('We couldn’t save'), findsOneWidget);

    auth.failSave = false;
    await tapVisible(tester, find.byKey(const Key('onboarding_continue')));
    expect(complete, isTrue);
    expect(auth.savedName, 'Alex');
    expect(auth.savedSettings?.dailyGoal, 2);
    expect(
      auth.savedSettings?.consentVersion,
      FamilySettings.currentConsentVersion,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The gate follows Supabase: landing → setup, and reset → new password',
    (tester) async {
      await phone(tester);
      final auth = FakeAuth();
      await tester.pumpWidget(calm(app(AuthGate(authService: auth))));
      await settle(tester);
      expect(find.byType(LandingPage), findsOneWidget);

      // Deep in the signed-out flow when the code is accepted…
      await tapVisible(tester, find.byKey(const Key('landing_sign_in')));
      expect(find.byType(AuthPage), findsOneWidget);
      auth.session = fakeSession();
      auth.changes.add(AuthState(AuthChangeEvent.signedIn, auth.session));
      await settle(tester);
      // …the pushed pages are cleared and setup begins.
      expect(find.byType(AuthPage), findsNothing);
      expect(find.byType(OnboardingPage), findsOneWidget);

      auth.changes.add(
        AuthState(AuthChangeEvent.passwordRecovery, auth.session),
      );
      await settle(tester);
      expect(find.byType(UpdatePasswordPage), findsOneWidget);
      // A token refresh mid-reset must not skip the new-password step.
      auth.changes.add(AuthState(AuthChangeEvent.tokenRefreshed, auth.session));
      await settle(tester);
      expect(find.byType(UpdatePasswordPage), findsOneWidget);

      auth.session = null;
      auth.changes.add(const AuthState(AuthChangeEvent.signedOut, null));
      await settle(tester);
      expect(find.byType(LandingPage), findsOneWidget);
      await auth.changes.close();
    },
  );

  test('Time zone guess prefers the name and falls back to the offset', () {
    expect(
      FamilySettings.guessTimezone(
        name: 'India Standard Time',
        offset: const Duration(hours: 5, minutes: 30),
      ),
      'Asia/Kolkata',
    );
    expect(
      FamilySettings.guessTimezone(
        name: 'Australian Eastern Standard Time',
        offset: const Duration(hours: 10),
      ),
      'Australia/Sydney',
    );
    expect(
      FamilySettings.guessTimezone(
        name: 'PDT',
        offset: const Duration(hours: -7),
      ),
      'America/Los_Angeles',
    );
    expect(
      FamilySettings.guessTimezone(
        name: 'GMT+05:30',
        offset: const Duration(hours: 5, minutes: 30),
      ),
      'Asia/Kolkata',
    );
    expect(
      FamilySettings.guessTimezone(
        name: 'XYZ',
        offset: const Duration(hours: 3),
      ),
      'UTC',
    );
  });

  group('Supabase config', () {
    test(
      'a plain `flutter run` picks up the bundled config/supabase.json',
      () async {
        final values = await SupabaseConfig.resolve(
          bundle: _FakeBundle({
            SupabaseConfig.configAsset: jsonEncode({
              'SUPABASE_URL': 'https://abc.supabase.co',
              'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_123',
            }),
          }),
        );
        expect(values?['SUPABASE_URL'], 'https://abc.supabase.co');
      },
    );

    test('placeholders or a missing file fall back to demo mode', () async {
      expect(await SupabaseConfig.resolve(bundle: _FakeBundle({})), isNull);
      expect(
        await SupabaseConfig.resolve(
          bundle: _FakeBundle({
            SupabaseConfig.configAsset: jsonEncode({
              'SUPABASE_URL': 'https://YOUR_PROJECT_REF.supabase.co',
              'SUPABASE_PUBLISHABLE_KEY': 'YOUR_PUBLISHABLE_KEY',
            }),
          }),
        ),
        isNull,
      );
    });

    test(
      'accepts a local `supabase start` stack but not other http URLs',
      () async {
        Future<Map<String, String>?> tryUrl(String url) =>
            SupabaseConfig.resolve(
              bundle: _FakeBundle({
                SupabaseConfig.configAsset: jsonEncode({
                  'SUPABASE_URL': url,
                  'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_123',
                }),
              }),
            );
        expect(await tryUrl('http://127.0.0.1:54321'), isNotNull);
        expect(await tryUrl('http://10.0.2.2:54321'), isNotNull);
        expect(await tryUrl('http://example.com'), isNull);
      },
    );

    test('refuses to start with a secret key in the bundled file', () {
      expect(
        SupabaseConfig.resolve(
          bundle: _FakeBundle({
            SupabaseConfig.configAsset: jsonEncode({
              'SUPABASE_URL': 'https://abc.supabase.co',
              'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_123',
              'SUPABASE_SECRET_KEY': 'sb_secret_456',
            }),
          }),
        ),
        throwsStateError,
      );
    });

    testWidgets('config/supabase.json is really in the asset bundle', (
      tester,
    ) async {
      if (!File('config/supabase.json').existsSync()) return;
      final values = await tester.runAsync(SupabaseConfig.resolve);
      expect(values?['SUPABASE_URL'], startsWith('https://'));
    });
  });

  test('The bundled Supabase config never carries a secret key', () {
    expect(
      SupabaseConfig.leakedSecretKeys({
        'SUPABASE_URL': 'https://x.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_abc',
        'SUPABASE_SECRET_KEY': 'sb_secret_abc',
        'SERVICE_ROLE': 'eyJ...',
        'OTHER': 'sb_secret_xyz',
      }),
      ['SUPABASE_SECRET_KEY', 'SERVICE_ROLE', 'OTHER'],
    );
    // Guards the real, git-ignored file too: it ships inside the app.
    for (final path in [
      'config/supabase.json',
      'config/supabase.example.json',
    ]) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final values = (jsonDecode(file.readAsStringSync()) as Map).map(
        (key, value) => MapEntry('$key', '$value'),
      );
      expect(
        SupabaseConfig.leakedSecretKeys(values),
        isEmpty,
        reason: '$path must only contain the URL and publishable key',
      );
    }
  });

  for (final size in [
    const Size(375, 667),
    const Size(812, 375),
    const Size(1280, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Signed-out screens fit $size dark=$dark with large text', (
        tester,
      ) async {
        await phone(tester, size);
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          previousErrorHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        final auth = FakeAuth();
        final screens = <Widget>[
          LandingPage(authService: auth),
          IntroPage(authService: auth),
          AuthPage(authService: auth, mode: AuthMode.signUp),
          AuthPage(authService: auth),
          VerifyCodePage(
            authService: auth,
            purpose: CodePurpose.recovery,
            email: 'a.very.long.parent.address@example.com',
            codeLength: 6,
          ),
          OnboardingPage(authService: auth, onComplete: () {}),
          UpdatePasswordPage(authService: auth, onDone: () {}),
        ];
        for (final screen in screens) {
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
              home: screen,
            ),
          );
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at $size',
          );
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
