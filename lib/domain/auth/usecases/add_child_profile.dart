import '../entities/child_profile.dart';
import '../repositories/auth_repository.dart';

class AddChildProfile {
  const AddChildProfile(this._repository);

  final AuthRepository _repository;

  Future<ChildProfile> call({
    required String displayName,
    required String ageBand,
    required String preferredLanguage,
    String? avatarKey,
  }) async {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw const AuthFailure("Enter your child's name.");
    }
    if (ageBand.trim().isEmpty) {
      throw const AuthFailure("Choose your child's age band.");
    }

    return _repository.addChildProfile(
      displayName: trimmedName,
      ageBand: ageBand,
      preferredLanguage: preferredLanguage,
      avatarKey: avatarKey,
    );
  }
}
