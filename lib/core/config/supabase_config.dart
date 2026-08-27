import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const mobileRedirectUrl = 'io.curio.app://login-callback/';
  static const enableGoogleAuth = bool.fromEnvironment(
    'ENABLE_GOOGLE_AUTH',
    defaultValue: false,
  );

  static bool get isConfigured =>
      url.startsWith('https://') &&
      publishableKey.isNotEmpty &&
      !publishableKey.contains('YOUR_');

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static String? get authRedirectUrl => kIsWeb ? null : mobileRedirectUrl;
}
