import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_environment.dart';
import '../core/config/env_config.dart';
import '../secure/secure_token_storage.dart';
import 'curio_app.dart';

/// Everything that has to happen before the widget tree exists: load env
/// config, init Supabase, init Sentry (if a DSN is configured for this
/// environment), then run the app. Called from main.dart.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = await EnvConfig.load();

  await Supabase.initialize(
    url: env.supabaseUrl,
    publishableKey: env.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureTokenStorage()),
  );

  if (env.sentryDsn.isEmpty) {
    // No DSN configured for this environment (e.g. a developer left
    // SENTRY_DSN blank in .env.dev) - run without crash reporting rather
    // than failing to start.
    runApp(const ProviderScope(child: CurioApp()));
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = env.sentryDsn;
    options.environment = env.environment.name;
    // Phase 0 default: capture everything in dev/staging, dial back for
    // prod once there's real traffic to budget against (see README
    // "Monitoring").
    options.tracesSampleRate = env.environment == AppEnvironment.prod ? 0.2 : 1.0;
  }, appRunner: () => runApp(const ProviderScope(child: CurioApp())));
}
