// Pure domain-layer tests - no Flutter widgets, no Supabase, no Drift.
// This is the point of Clean Architecture's domain layer: business rules
// (email/password/name validation here) are testable without spinning up
// any framework at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:curio/domain/auth/entities/child_profile.dart';
import 'package:curio/domain/auth/entities/parent_profile.dart';
import 'package:curio/domain/auth/repositories/auth_repository.dart';
import 'package:curio/domain/auth/usecases/accept_consent_and_create_profile.dart';
import 'package:curio/domain/auth/usecases/add_child_profile.dart';
import 'package:curio/domain/auth/usecases/sign_in_parent.dart';
import 'package:curio/domain/auth/usecases/sign_up_parent.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  group('SignUpParent', () {
    test('rejects an invalid email without calling the repository', () async {
      final useCase = SignUpParent(repository);

      expect(
        () => useCase(email: 'not-an-email', password: 'password123'),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(() => repository.signUp(email: any(named: 'email'), password: any(named: 'password')));
    });

    test('rejects a password under 8 characters', () async {
      final useCase = SignUpParent(repository);

      expect(
        () => useCase(email: 'parent@example.com', password: 'short'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('trims the email and delegates to the repository when valid', () async {
      when(() => repository.signUp(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async {});
      final useCase = SignUpParent(repository);

      await useCase(email: '  parent@example.com  ', password: 'password123');

      verify(() => repository.signUp(email: 'parent@example.com', password: 'password123')).called(1);
    });
  });

  group('SignInParent', () {
    test('rejects empty email or password', () {
      final useCase = SignInParent(repository);

      expect(() => useCase(email: '', password: 'password123'), throwsA(isA<AuthFailure>()));
      expect(() => useCase(email: 'parent@example.com', password: ''), throwsA(isA<AuthFailure>()));
    });
  });

  group('AcceptConsentAndCreateProfile', () {
    test('rejects an empty display name without calling the repository', () {
      final useCase = AcceptConsentAndCreateProfile(repository);

      expect(
        () => useCase(displayName: '   ', preferredLanguage: 'en'),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(
        () => repository.acceptConsentAndCreateProfile(
          displayName: any(named: 'displayName'),
          preferredLanguage: any(named: 'preferredLanguage'),
          consentType: any(named: 'consentType'),
          policyVersion: any(named: 'policyVersion'),
        ),
      );
    });

    test('passes the current consent policy constants to the repository', () async {
      final profile = ParentProfile(
        id: 'parent-1',
        displayName: 'Parent',
        preferredLanguage: 'en',
        status: 'active',
        createdAt: DateTime(2026),
      );
      when(
        () => repository.acceptConsentAndCreateProfile(
          displayName: any(named: 'displayName'),
          preferredLanguage: any(named: 'preferredLanguage'),
          consentType: any(named: 'consentType'),
          policyVersion: any(named: 'policyVersion'),
        ),
      ).thenAnswer((_) async => profile);
      final useCase = AcceptConsentAndCreateProfile(repository);

      final result = await useCase(displayName: 'Parent', preferredLanguage: 'en');

      expect(result, profile);
      final captured = verify(
        () => repository.acceptConsentAndCreateProfile(
          displayName: 'Parent',
          preferredLanguage: 'en',
          consentType: captureAny(named: 'consentType'),
          policyVersion: captureAny(named: 'policyVersion'),
        ),
      ).captured;
      expect(captured, hasLength(2));
      expect(captured[0], isNotEmpty);
      expect(captured[1], isNotEmpty);
    });
  });

  group('AddChildProfile', () {
    test('rejects an empty name or age band', () {
      final useCase = AddChildProfile(repository);

      expect(
        () => useCase(displayName: '', ageBand: '8-10', preferredLanguage: 'en'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => useCase(displayName: 'Kid', ageBand: '', preferredLanguage: 'en'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('delegates to the repository when valid', () async {
      const child = ChildProfile(
        id: 'child-1',
        parentId: 'parent-1',
        displayName: 'Kid',
        avatarKey: null,
        ageBand: '8-10',
        preferredLanguage: 'en',
        totalXp: 0,
        dragonStage: 1,
        active: true,
      );
      when(
        () => repository.addChildProfile(
          displayName: any(named: 'displayName'),
          ageBand: any(named: 'ageBand'),
          preferredLanguage: any(named: 'preferredLanguage'),
          avatarKey: any(named: 'avatarKey'),
        ),
      ).thenAnswer((_) async => child);
      final useCase = AddChildProfile(repository);

      final result = await useCase(displayName: 'Kid', ageBand: '8-10', preferredLanguage: 'en');

      expect(result, child);
    });
  });
}
