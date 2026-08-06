import '../consent_policy.dart';
import '../entities/parent_profile.dart';
import '../repositories/auth_repository.dart';

class AcceptConsentAndCreateProfile {
  const AcceptConsentAndCreateProfile(this._repository);

  final AuthRepository _repository;

  Future<ParentProfile> call({
    required String displayName,
    required String preferredLanguage,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const AuthFailure('Enter your name.');
    }

    return _repository.acceptConsentAndCreateProfile(
      displayName: trimmedName,
      preferredLanguage: preferredLanguage,
      consentType: ConsentPolicy.consentType,
      policyVersion: ConsentPolicy.currentPolicyVersion,
    );
  }
}
