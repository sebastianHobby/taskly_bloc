import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:taskly_core/logging.dart';

import 'package:taskly_core/src/env/env_config.dart';

/// Environment configuration.
///
/// Values are treated as build-time configuration and must be provided by the
/// app entrypoint (for example `lib/main_local.dart`, `lib/main_prod.dart`).
class Env {
  static bool _initialized = false;
  static EnvConfig? _config;

  /// Configures build-time environment values.
  ///
  /// This is intended to be called from the app entrypoint (e.g.
  /// `lib/main_local.dart`, `lib/main_prod.dart`) before calling `bootstrap()`.
  static EnvConfig? get config => _config;

  static set config(EnvConfig value) {
    _config = value;
  }

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
    _config = null;
  }

  /// Initializes environment.
  ///
  /// Kept async so bootstrap can `await Env.load()`.
  static Future<void> load() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Supabase project URL
  static String get supabaseUrl {
    return _requireConfig().supabaseUrl;
  }

  /// Human-readable environment name (for example: local/prod).
  static String get name {
    return _requireConfig().name;
  }

  /// Supabase anonymous/public key
  static String get supabasePublishableKey {
    return _requireConfig().supabasePublishableKey;
  }

  /// PowerSync instance URL
  static String get powersyncUrl {
    return _requireConfig().powersyncUrl;
  }

  /// Auth redirect URL for sign-up callbacks in web environments.
  static String get authSignUpWebRedirectUrl {
    return _requireConfig().authSignUpWebRedirectUrl;
  }

  /// Auth redirect URL for password recovery callbacks in web environments.
  static String get authPasswordRecoveryWebRedirectUrl {
    return _requireConfig().authPasswordRecoveryWebRedirectUrl;
  }

  /// Auth redirect URL for sign-up callbacks in native environments.
  static String get authSignUpAppRedirectUrl {
    return _requireConfig().authSignUpAppRedirectUrl;
  }

  /// Auth redirect URL for password recovery callbacks in native environments.
  static String get authPasswordRecoveryAppRedirectUrl {
    return _requireConfig().authPasswordRecoveryAppRedirectUrl;
  }

  /// App version used for telemetry metadata.
  ///
  /// Uses configured value when provided, otherwise falls back to build-time
  /// define `APP_VERSION`, and then `unknown`.
  static String get appVersion {
    final configured = _requireConfig().appVersion.trim();
    if (configured.isNotEmpty) return configured;
    return const String.fromEnvironment('APP_VERSION', defaultValue: 'unknown');
  }

  /// Build SHA used for telemetry metadata.
  ///
  /// Uses configured value when provided, otherwise falls back to build-time
  /// define `BUILD_SHA`, and then `unknown`.
  static String get buildSha {
    final configured = _requireConfig().buildSha.trim();
    if (configured.isNotEmpty) return configured;
    return const String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown');
  }

  /// Logs a short summary of environment configuration sources.
  ///
  /// Does not print secrets (keys/passwords are masked).
  static void logDiagnostics() {
    if (!kDebugMode) return;

    final url = _supabaseUrlWithSource();
    final anonKey = _supabasePublishableKeyWithSource();
    final powersync = _powersyncUrlWithSource();

    talker.debug(
      '[env] SUPABASE_URL source=${url.source}, empty=${url.value.trim().isEmpty}, value=${_formatUrl(url.value)}',
    );
    talker.debug(
      '[env] SUPABASE_PUBLISHABLE_KEY source=${anonKey.source}, empty=${anonKey.value.trim().isEmpty}, value=${_maskSecret(anonKey.value)}',
    );
    talker.debug(
      '[env] POWERSYNC_URL source=${powersync.source}, empty=${powersync.value.trim().isEmpty}, value=${_formatUrl(powersync.value)}',
    );
  }

  static ({String value, String source}) _supabaseUrlWithSource() {
    final configured = _config;
    if (configured != null) {
      return (
        value: configured.supabaseUrl,
        source: 'entrypoint:${configured.name}',
      );
    }

    return (value: '', source: '<unset>');
  }

  static ({String value, String source}) _supabasePublishableKeyWithSource() {
    final configured = _config;
    if (configured != null) {
      return (
        value: configured.supabasePublishableKey,
        source: 'entrypoint:${configured.name}',
      );
    }

    return (value: '', source: '<unset>');
  }

  static ({String value, String source}) _powersyncUrlWithSource() {
    final configured = _config;
    if (configured != null) {
      return (
        value: configured.powersyncUrl,
        source: 'entrypoint:${configured.name}',
      );
    }

    return (value: '', source: '<unset>');
  }

  static EnvConfig _requireConfig() {
    final configured = _config;
    if (configured != null) return configured;

    throw StateError(
      'Env is not configured. Run the app via a configured entrypoint '
      '(for example lib/main_local.dart or lib/main_prod.dart) that calls '
      'Env.config = ...',
    );
  }

  static String _maskSecret(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '<empty>';
    if (trimmed.length <= 8) return '***';
    return '${trimmed.substring(0, 4)}...${trimmed.substring(trimmed.length - 4)}';
  }

  static String _formatUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '<empty>';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return '<invalid>';
    return '${uri.scheme}://${uri.host}';
  }

  static void validateRequired() {
    final configured = _config;
    if (configured == null) {
      const hint = 'Run via lib/main_local.dart or lib/main_prod.dart.';
      talker.error('[env] Env not configured. $hint');
      throw StateError('Env not configured. $hint');
    }

    final missing = <String>[];
    if (configured.supabaseUrl.trim().isEmpty) missing.add('SUPABASE_URL');
    if (configured.supabasePublishableKey.trim().isEmpty) {
      missing.add('SUPABASE_PUBLISHABLE_KEY');
    }
    if (configured.powersyncUrl.trim().isEmpty) missing.add('POWERSYNC_URL');

    if (missing.isNotEmpty) {
      talker.error(
        '[env] Missing required configuration in entrypoint:${configured.name}: '
        '${missing.join(', ')}',
      );

      throw StateError(
        'Missing required configuration in entrypoint:${configured.name}: '
        '${missing.join(', ')}',
      );
    }

    validateAuthRedirectUrls();
  }

  /// Validates configured auth redirect URLs for sign-up and password recovery.
  ///
  /// Web URLs must be absolute `http(s)` URLs.
  /// App URLs must be absolute URLs with a scheme and either host or path.
  static void validateAuthRedirectUrls() {
    final configured = _requireConfig();
    _validateRedirectUrl(
      field: 'AUTH_SIGN_UP_WEB_REDIRECT_URL',
      value: configured.authSignUpWebRedirectUrl,
      allowCustomScheme: false,
    );
    _validateRedirectUrl(
      field: 'AUTH_PASSWORD_RECOVERY_WEB_REDIRECT_URL',
      value: configured.authPasswordRecoveryWebRedirectUrl,
      allowCustomScheme: false,
    );
    _validateRedirectUrl(
      field: 'AUTH_SIGN_UP_APP_REDIRECT_URL',
      value: configured.authSignUpAppRedirectUrl,
      allowCustomScheme: true,
    );
    _validateRedirectUrl(
      field: 'AUTH_PASSWORD_RECOVERY_APP_REDIRECT_URL',
      value: configured.authPasswordRecoveryAppRedirectUrl,
      allowCustomScheme: true,
    );
  }

  static void _validateRedirectUrl({
    required String field,
    required String value,
    required bool allowCustomScheme,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      talker.error(
        '[env] Invalid $field "$trimmed". Expected an absolute URL with a scheme.',
      );
      throw StateError(
        'Invalid $field "$trimmed". Expected an absolute URL with a scheme.',
      );
    }

    if (!allowCustomScheme) {
      final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
      if (!isHttp || uri.host.isEmpty) {
        talker.error(
          '[env] Invalid $field "$trimmed". Expected an absolute http(s) URL.',
        );
        throw StateError(
          'Invalid $field "$trimmed". Expected an absolute http(s) URL.',
        );
      }
      return;
    }

    if (uri.host.isEmpty && uri.path.isEmpty) {
      talker.error(
        '[env] Invalid $field "$trimmed". Expected a URL with host or path.',
      );
      throw StateError(
        'Invalid $field "$trimmed". Expected a URL with host or path.',
      );
    }
  }
}
