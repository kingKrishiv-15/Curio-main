/// The privacy/parental-consent terms the app is currently asking parents
/// to agree to. Bumping [currentPolicyVersion] is how a future change to
/// the terms gets tracked against `consent_record.policy_version` - it's a
/// deliberate, single place to change, not a string copy-pasted into a
/// screen.
class ConsentPolicy {
  ConsentPolicy._();

  static const consentType = 'privacy_and_parental_consent';
  static const currentPolicyVersion = '2026-08-06.1';
}
