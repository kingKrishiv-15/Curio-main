/// Which deployment target the app is configured for. Controlled at build
/// time via `--dart-define=ENVIRONMENT=dev|staging|prod` (defaults to dev),
/// never at runtime - this keeps a staging build from ever accidentally
/// reading prod config or vice versa.
enum AppEnvironment {
  dev,
  staging,
  prod;

  /// The per-environment dotenv file this environment loads its config from.
  /// See assets/env/.env.example for the template and README "Environment
  /// configuration" for how to set these up locally.
  String get envAssetPath => 'assets/env/.env.$name';

  static AppEnvironment fromDartDefine() {
    const raw = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    return AppEnvironment.values.firstWhere(
      (env) => env.name == raw,
      orElse: () => AppEnvironment.dev,
    );
  }
}
