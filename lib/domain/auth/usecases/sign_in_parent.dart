import '../repositories/auth_repository.dart';

class SignInParent {
  const SignInParent(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthFailure('Enter your email and password.');
    }

    await _repository.signIn(email: trimmedEmail, password: password);
  }
}
