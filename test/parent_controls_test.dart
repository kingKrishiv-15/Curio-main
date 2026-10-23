import 'dart:async';

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
  @override
  Session? get currentSession => active;
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
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Parent areas stay locked after wrong passwords and require a fresh password next time',
    (tester) async {
      final auth = _Auth()
        ..failure = const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        );
      await mountGate(tester, auth);
      expect(find.textContaining('What is'), findsNothing);
      expect(find.text('Private reports'), findsNothing);
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await tester.pumpAndSettle();
      expect(auth.attempts, 0);
      await tester.enterText(find.byKey(const Key('parent_password')), 'wrong');
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await tester.pumpAndSettle();
      expect(find.textContaining('didn’t match'), findsOneWidget);
      expect(find.text('Private reports'), findsNothing);
      auth.failure = null;
      await tester.enterText(
        find.byKey(const Key('parent_password')),
        'correct',
      );
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await tester.pumpAndSettle();
      expect(find.text('Private reports'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open parent dashboard'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('parent_password')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('parent_password')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Private reports'), findsNothing);
    },
  );

  testWidgets(
    'Changing accounts during password verification cannot unlock reports',
    (tester) async {
      final auth = _Auth()..pending = Completer<void>();
      await mountGate(tester, auth);
      await tester.enterText(
        find.byKey(const Key('parent_password')),
        'correct',
      );
      await tester.tap(find.byKey(const Key('parent_unlock')));
      await tester.pump();
      auth.active = session('parent-2');
      auth.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Private reports'), findsNothing);
      expect(find.textContaining('couldn’t verify'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
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
