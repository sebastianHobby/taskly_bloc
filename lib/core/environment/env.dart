/// Environment configuration using compile-time constants.
///
/// Values are provided via --dart-define flags at build/run time.
/// For local development, use .vscode/launch.json or a helper script.
class Env {
  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  /// Supabase anonymous/public key
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// PowerSync instance URL
  static const String powersyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
  );

  /// Development/test username
  static const String devUsername = String.fromEnvironment(
    'DEV_USERNAME',
  );

  /// Development/test password
  static const String devPassword = String.fromEnvironment(
    'DEV_PASSWORD',
  );
}
