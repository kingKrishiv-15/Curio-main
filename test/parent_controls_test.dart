import 'dart:async';

import 'package:curio/features/family/presentation/change_email_page.dart';
import 'package:curio/core/models/family_settings.dart';
import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/services/family_service.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/widgets/parental_gate.dart';
import 'package:curio/features/family/presentation/weekly_email_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session session(String id) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: id,
    email: 'parent@example.com',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-23T00:00:00Z',
  ),
);

class _Auth extends AuthService {
  _Auth()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  Session? active = session('parent-1');
  Object? failure;
  Completer<void>? pending;
  int attempts = 0;
  int codesSent = 0;
  final codes = <String>[];
  @override
  Session? get currentSession => active;
  @override
  String? get currentEmail => 'parent@example.com';
  @override
  Future<void> sendParentCode() async => codesSent++;
  @override
  Future<void> verifyParentCode(String code) async {
    attempts++;
    codes.add(code);
    if (failure != null) throw failure!;
    if (pending != null) await pending!.future;
  }

  final emailChecks = <(String, String)>[];
  String? requestedEmail;
  @override
  Future<void> requestEmailChange(String newEmail) async =>
      requestedEmail = newEmail;
  @override
  Future<bool> verifyEmailChange({
    required String email,
    required String code,
    required String newEmail,
  }) async {
    if (failure != null) throw failure!;
    emailChecks.add((email, code));
    return emailChecks.length == 2;
  }

  @override
  Future<void> verifyParentPassword(String password) async {
    attempts++;
    if (failure != null) throw failure!;
    if (pending != null) await pending!.future;
  }
}

class _Family extends FamilyService {
  FamilySettings settings = const FamilySettings(
    dailyGoal: 2,
    timezone: 'Asia/Kolkata',
    remindersEnabled: true,
    consentVersion: '2026-09',
  );
  bool fail = false;
  final changes = <bool>[];
  @override
  bool get isDemo => false;
  @override
  String? get parentEmail => 'parent@example.com';
  @override
  Future<FamilySettings> loadSettings() async => settings;
  @override
  Future<void> setWeeklyEmailEnabled(bool enabled) async {
    if (fail) throw StateError('offline');
    changes.add(enabled);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The code boxes' cursor blinks forever, so pumpAndSettle never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> mountGate(WidgetTester tester, _Auth auth) async {
    final state = CurioState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: CurioTheme.light,
        home: CurioScope(
          notifier: state,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ParentalGate.open(
                  context,
                  const Scaffold(body: Text('Private reports')),
                  authService: auth,
                ),
                child: const Text('Open parent dashboard'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open parent dashboard'));
    await settle(tester);
  }

  testWidgets(
    'Parent areas need a fresh emailed code each time and stay locked after a wrong one',
    (tester) async {
      final auth = _Auth()
        ..failure = const AuthException(
          'Token has expired or is invalid',
          code: 'otp_expired',
        );
      await mountGate(tester, auth);
      expect(auth.codesSent, 1, reason: 'opening the gate emails a code');
      expect(find.textContaining('parent@example.com'), findsOneWidget);
      expect(find.text('Private reports'), findsNothing);
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await settle(tester);
      expect(auth.attempts, 0, reason: 'nothing to check without a code');
      await tester.enterText(find.byKey(const Key('otp_input')), '111111');
      await tester.pump();
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await settle(tester);
      expect(find.textContaining('isn’t right or has expired'), findsOneWidget);
      expect(find.text('Private reports'), findsNothing);
      auth.failure = null;
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await settle(tester);
      expect(auth.codes.last, '123456');
      expect(find.text('Private reports'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await settle(tester);
      await tester.tap(find.text('Open parent dashboard'));
      await settle(tester);
      expect(auth.codesSent, 2, reason: 'no cached unlock');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('otp_input')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(find.text('Private reports'), findsNothing);
    },
  );

  testWidgets('Accounts with a password can unlock with it instead', (
    tester,
  ) async {
    final auth = _Auth()
      ..failure = const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );
    await mountGate(tester, auth);
    await tester.tap(find.byKey(const Key('parent_use_password')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('parent_password')), 'wrong');
    await tester.pump();
    await tester.tap(find.byKey(const Key('parent_unlock')));
    await settle(tester);
    expect(find.textContaining('didn’t match'), findsOneWidget);
    auth.failure = null;
    await tester.enterText(find.byKey(const Key('parent_password')), 'right');
    await tester.pump();
    await tester.tap(find.byKey(const Key('parent_unlock')));
    await settle(tester);
    expect(find.text('Private reports'), findsOneWidget);
  });

  testWidgets(
    'Changing accounts during code verification cannot unlock reports',
    (tester) async {
      final auth = _Auth()..pending = Completer<void>();
      await mountGate(tester, auth);
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await tester.pump();
      auth.active = session('parent-2');
      auth.pending!.complete();
      await settle(tester);
      expect(find.text('Private reports'), findsNothing);
      expect(find.textContaining('account changed'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    },
  );

  testWidgets(
    'Changing email needs a code from the new and the current address',
    (tester) async {
      final auth = _Auth();
      await tester.pumpWidget(
        MaterialApp(
          theme: CurioTheme.light,
          home: ChangeEmailPage(authService: auth),
        ),
      );
      await settle(tester);
      expect(find.textContaining('parent@example.com'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('change_email_input')),
        'parent@example.com',
      );
      await tester.tap(find.byKey(const Key('change_email_send')));
      await settle(tester);
      expect(find.textContaining('already your account email'), findsOneWidget);
      expect(auth.requestedEmail, isNull);

      await tester.enterText(
        find.byKey(const Key('change_email_input')),
        'new@example.com',
      );
      await tester.tap(find.byKey(const Key('change_email_send')));
      await settle(tester);
      expect(auth.requestedEmail, 'new@example.com');
      expect(find.text('Check your new inbox'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('otp_input')), '111111');
      await tester.pump();
      await tester.tap(find.byKey(const Key('change_email_verify')));
      await settle(tester);
      expect(find.text('Now check your current inbox'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('otp_input')), '222222');
      await tester.pump();
      await tester.tap(find.byKey(const Key('change_email_verify')));
      await settle(tester);
      expect(auth.emailChecks, [
        ('new@example.com', '111111'),
        ('parent@example.com', '222222'),
      ]);
      expect(find.text('Email changed'), findsOneWidget);
    },
  );

  testWidgets(
    'Weekly report opt-in saves explicitly and leaves its prior value on failure',
    (tester) async {
      final family = _Family();
      await tester.pumpWidget(
        MaterialApp(
          theme: CurioTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyEmailCard(service: family),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sent to parent@example.com'), findsOneWidget);
      expect(family.changes, isEmpty);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('weekly_email_toggle')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('weekly_email_toggle')));
      await tester.pumpAndSettle();
      expect(family.changes, [true]);
      family.fail = true;
      await tester.tap(find.byKey(const Key('weekly_email_toggle')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('weekly_email_toggle')),
            )
            .value,
        isTrue,
      );
      expect(find.textContaining('wasn’t changed'), findsOneWidget);
      expect(family.settings.dailyGoal, 2);
      expect(family.settings.remindersEnabled, isTrue);
      family.fail = false;
      await tester.tap(find.byKey(const Key('weekly_email_toggle')));
      await tester.pumpAndSettle();
      expect(family.changes, [true, false]);
      expect(tester.takeException(), isNull);
    },
  );
}
