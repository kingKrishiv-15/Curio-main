import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where Curio finds its Supabase project, in priority order:
///
/// 1. `--dart-define` / `--dart-define-from-file` values (CI, release builds,
///    or pointing a run at a different project).
/// 2. `config/supabase.json`, bundled as an asset — so a plain `flutter run`
///    connects to the same project without any extra flags.
/// 3. Neither → demo mode (an on-device profile, no login).
///
/// Demo mode can also be forced with `--dart-define=CURIO_DEMO=true`, which
/// is handy for design work that shouldn't touch a real account.
abstract final class SupabaseConfig {
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _definedGoogle = String.fromEnvironment('ENABLE_GOOGLE_AUTH');
  static const _definedOtpLength = String.fromEnvironment('OTP_LENGTH');

  static const forceDemo = bool.fromEnvironment('CURIO_DEMO');
  static const configAsset = 'config/supabase.json';
  static const mobileRedirectUrl = 'io.curio.app://login-callback/';

  static bool _ready = false;
  static String _url = '';
  static bool _enableGoogleAuth = false;
  static int _otpLength = 6;

  /// True once a Supabase client has been initialised. Everything that
  /// talks to the backend checks this rather than the raw config, so tests
  /// and demo runs (which never call [initialize]) stay offline.
  static bool get isConfigured => _ready;
  static String get url => _url;
  static bool get enableGoogleAuth => _enableGoogleAuth;

  /// Digits in an emailed code. Must match Supabase → Authentication →
  /// Sign In / Providers → Email → "Email OTP Length".
  static int get otpLength => _otpLength;

  static Future<void> initialize({AssetBundle? bundle}) async {
    if (forceDemo) {
      debugPrint('Curio: CURIO_DEMO=true — running in demo mode.');
      return;
    }
    final values = await resolve(bundle: bundle);
    if (values == null) {
      debugPrint(
        'Curio: no Supabase project configured — running in demo mode. '
        'Copy config/supabase.example.json to config/supabase.json '
        '(see SUPABASE_SETUP.md).',
      );
      return;
    }
    _url = values['SUPABASE_URL']!;
    _enableGoogleAuth = values['ENABLE_GOOGLE_AUTH'] == 'true';
    _otpLength = (int.tryParse(values['OTP_LENGTH'] ?? '') ?? 6).clamp(6, 10);
    await Supabase.initialize(
      url: _url,
      publishableKey: values['SUPABASE_PUBLISHABLE_KEY']!,
    );
    _ready = true;
  }

  /// The merged configuration (dart-defines over the bundled file), or null
  /// when there isn't a usable project URL and publishable key.
  @visibleForTesting
  static Future<Map<String, String>?> resolve({AssetBundle? bundle}) async {
    var values = <String, String>{
      if (_definedUrl.isNotEmpty) 'SUPABASE_URL': _definedUrl,
      if (_definedKey.isNotEmpty) 'SUPABASE_PUBLISHABLE_KEY': _definedKey,
      if (_definedGoogle.isNotEmpty) 'ENABLE_GOOGLE_AUTH': _definedGoogle,
      if (_definedOtpLength.isNotEmpty) 'OTP_LENGTH': _definedOtpLength,
    };
    if (!_isUsable(values)) {
      values = {...await _readBundledConfig(bundle ?? rootBundle), ...values};
    }
    return _isUsable(values) ? values : null;
  }

  static bool _isUsable(Map<String, String> values) {
    final url = values['SUPABASE_URL'] ?? '';
    final key = values['SUPABASE_PUBLISHABLE_KEY'] ?? '';
    // https for hosted projects; plain http only for a local `supabase
    // start` stack (10.0.2.2 is the host machine from an Android emulator).
    final local = RegExp(
      r'^http://(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?$',
    ).hasMatch(url);
    return (url.startsWith('https://') || local) &&
        !url.contains('YOUR_') &&
        key.isNotEmpty &&
        !key.contains('YOUR_');
  }

  static Future<Map<String, String>> _readBundledConfig(
    AssetBundle bundle,
  ) async {
    final String raw;
    try {
      raw = await bundle.loadString(configAsset, cache: false);
    } catch (_) {
      return const {};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      // Fail loudly: silently dropping to demo mode is what makes a typo
      // here look like "login disappeared".
      throw StateError('$configAsset is not valid JSON: ${error.message}');
    }
    if (decoded is! Map) return const {};
    final values = {
      for (final entry in decoded.entries)
        '${entry.key}': '${entry.value}'.trim(),
    };
    final leaked = leakedSecretKeys(values);
    if (leaked.isNotEmpty) {
      // This file ships inside the app. A secret/service-role key in it
      // would give anyone who unzips the app full, RLS-bypassing access.
      throw StateError(
        '$configAsset contains ${leaked.join(', ')}. Secret keys must never '
        'be in the app — remove them and rotate the key in Supabase → '
        'Project Settings → API Keys.',
      );
    }
    return values;
  }

  /// Keys that look like server-only credentials. Shared with the test that
  /// guards the config file.
  @visibleForTesting
  static List<String> leakedSecretKeys(Map<String, String> values) => [
    for (final MapEntry(:key, :value) in values.entries)
      if (key.toUpperCase().contains('SECRET') ||
          key.toUpperCase().contains('SERVICE_ROLE') ||
          value.startsWith('sb_secret_'))
        key,
  ];

  static String? get authRedirectUrl => kIsWeb ? null : mobileRedirectUrl;
}
