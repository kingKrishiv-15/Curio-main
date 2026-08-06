import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase's default session persistence goes through SharedPreferences,
/// which is plain, unencrypted storage. This swaps that out for
/// flutter_secure_storage (Keychain on iOS, Keystore-backed
/// EncryptedSharedPreferences on Android) - auth tokens never touch plain
/// SharedPreferences. Wired in via `Supabase.initialize(authOptions:
/// FlutterAuthClientOptions(localStorage: SecureTokenStorage()))` in
/// bootstrap.dart.
class SecureTokenStorage extends LocalStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'curio.supabase.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: _sessionKey)) != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}
