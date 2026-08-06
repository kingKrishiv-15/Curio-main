import '../repositories/auth_repository.dart';

/// Basic RFC-5322-ish check - good enough to catch typos before hitting the
/// network. Supabase Auth is still the source of truth for real validation.
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class SignUpParent {
  const SignUpParent(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) async {
    final trimmedEmail = email.trim();

    if (!_emailPattern.hasMatch(trimmedEmail)) {
      throw const AuthFailure('Enter a valid email address.');
    }
    if (password.length < 8) {
      throw const AuthFailure('Password must be at least 8 characters.');
    }

    await _repository.signUp(email: trimmedEmail, password: password);
  }
}
