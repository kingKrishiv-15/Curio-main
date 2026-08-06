import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_environment.dart';

/// Resolved, validated config for the app's current environment. Load once
/// in `bootstrap.dart` before anything else touches Supabase or Sentry.
class EnvConfig {
  const EnvConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.sentryDsn,
  });

  final AppEnvironment environment;
  final String supabaseUrl;

  /// Supabase's client-side API key (formerly "anon key" - Supabase renamed
  /// this to "publishable key" alongside "secret key" replacing "service
  /// role key"; supabase_flutter's `anonKey` param is now deprecated).
  final String supabasePublishableKey;

  /// Empty string means crash reporting is disabled for this environment
  /// (e.g. a developer left SENTRY_DSN blank in their local .env.dev).
  final String sentryDsn;

  static Future<EnvConfig> load() async {
    final environment = AppEnvironment.fromDartDefine();

    try {
      await dotenv.load(fileName: environment.envAssetPath);
    } catch (error) {
      throw StateError(
        'Could not load ${environment.envAssetPath}. Copy assets/env/.env.example '
        'to assets/env/.env.${environment.name} and fill in real values '
        '(see README "Environment configuration").\nUnderlying error: $error',
      );
    }

    return EnvConfig._(
      environment: environment,
      supabaseUrl: _require('SUPABASE_URL', environment),
      supabasePublishableKey: _require('SUPABASE_PUBLISHABLE_KEY', environment),
      sentryDsn: dotenv.env['SENTRY_DSN'] ?? '',
    );
  }

  static String _require(String key, AppEnvironment environment) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required "$key" in ${environment.envAssetPath}. '
        'See assets/env/.env.example.',
      );
    }
    return value;
  }
}
