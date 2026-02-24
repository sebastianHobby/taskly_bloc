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

  /// Auth redirect URL for web callbacks.
  static String get authWebRedirectUrl {
    return _requireConfig().authWebRedirectUrl;
  }

  /// Auth redirect URL for native deep-link callbacks.
  static String get authAppRedirectUrl {
    return _requireConfig().authAppRedirectUrl;
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

    if (missing.isEmpty) return;

    talker.error(
      '[env] Missing required configuration in entrypoint:${configured.name}: '
      '${missing.join(', ')}',
    );

    throw StateError(
      'Missing required configuration in entrypoint:${configured.name}: '
      '${missing.join(', ')}',
    );
  }
}
