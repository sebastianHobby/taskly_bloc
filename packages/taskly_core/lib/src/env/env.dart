import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taskly_core/logging.dart';

/// Environment configuration with dual loading strategy:
/// - Local development (debug mode): Loads from .env file for convenience
/// - Production/CI (release mode): Uses --dart-define compile-time constants
///
/// This ensures secrets are never bundled in production builds while
/// providing a seamless developer experience.
class Env {
  static bool _initialized = false;

  static bool _boolFromString(String? raw, {required bool defaultValue}) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return defaultValue;
    if (value == 'true' || value == '1' || value == 'yes' || value == 'y') {
      return true;
    }
    if (value == 'false' || value == '0' || value == 'no' || value == 'n') {
      return false;
    }
    return defaultValue;
  }

  /// Initialize environment variables.
  ///
  /// In debug mode on non-web platforms, loads .env file from filesystem.
  /// On web, .env files are not supported - use --dart-define instead.
  ///
  /// In release mode, always uses --dart-define compile-time constants.
  static Future<void> load() async {
    if (_initialized) return;

    // Load .env in debug mode on non-web platforms only
    // Web doesn't support .env files - must use --dart-define
    if (kDebugMode && !kIsWeb) {
      try {
        final file = File('.env');
        if (await file.exists()) {
          final content = await file.readAsString();
          dotenv.testLoad(fileInput: content);
          talker.debug(
            '[env] Loaded .env from filesystem (dotenv initialized=${dotenv.isInitialized})',
          );
        }
      } catch (_) {
        // Silently fail - not having a .env file is acceptable
        // as all values can be provided via --dart-define
      }
    }

    _initialized = true;
  }

  /// Supabase project URL
  static String get supabaseUrl {
    if (kDebugMode && dotenv.isInitialized) {
      final envValue = dotenv.maybeGet('SUPABASE_URL');
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    }
    return const String.fromEnvironment('SUPABASE_URL');
  }

  /// Supabase anonymous/public key
  static String get supabasePublishableKey {
    if (kDebugMode && dotenv.isInitialized) {
      final value = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY');
      if (value != null && value.isNotEmpty) return value;
    }
    return const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  }

  /// PowerSync instance URL
  static String get powersyncUrl {
    if (kDebugMode && dotenv.isInitialized) {
      final value = dotenv.maybeGet('POWERSYNC_URL');
      if (value != null && value.isNotEmpty) return value;
    }
    return const String.fromEnvironment('POWERSYNC_URL');
  }

  /// Development/test username
  static String get devUsername {
    if (kDebugMode && dotenv.isInitialized) {
      final value = dotenv.maybeGet('DEV_USERNAME');
      if (value != null && value.isNotEmpty) return value;
    }
    return const String.fromEnvironment('DEV_USERNAME');
  }

  /// Development/test password
  static String get devPassword {
    if (kDebugMode && dotenv.isInitialized) {
      final value = dotenv.maybeGet('DEV_PASSWORD');
      if (value != null && value.isNotEmpty) return value;
    }
    return const String.fromEnvironment('DEV_PASSWORD');
  }

  /// Enables the MVP (non-USM) My Day route.
  ///
  /// Set via `.env` in debug (`ENABLE_MVP_MY_DAY=true`) or via
  /// `--dart-define=ENABLE_MVP_MY_DAY=true`.
  static bool get enableMvpMyDay {
    const key = 'ENABLE_MVP_MY_DAY';

    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet(key);
      return _boolFromString(v, defaultValue: false);
    }

    return _boolFromString(
      const String.fromEnvironment(key),
      defaultValue: false,
    );
  }

  /// Logs a short summary of environment configuration sources.
  ///
  /// This helps debug issues where web builds accidentally run with empty
  /// `--dart-define` values and Supabase defaults to localhost.
  ///
  /// Does not print secrets (keys/passwords are masked).
  static void logDiagnostics() {
    if (!kDebugMode) return;

    final url = _supabaseUrlWithSource();
    final anonKey = _supabasePublishableKeyWithSource();
    final powersync = _powersyncUrlWithSource();
    final devUser = _devUsernameWithSource();
    final devPass = _devPasswordWithSource();

    talker.debug(
      '[env] SUPABASE_URL source=${url.source}, empty=${url.value.trim().isEmpty}, value=${_formatUrl(url.value)}',
    );
    talker.debug(
      '[env] SUPABASE_PUBLISHABLE_KEY source=${anonKey.source}, empty=${anonKey.value.trim().isEmpty}, value=${_maskSecret(anonKey.value)}',
    );
    talker.debug(
      '[env] POWERSYNC_URL source=${powersync.source}, empty=${powersync.value.trim().isEmpty}, value=${_formatUrl(powersync.value)}',
    );
    talker.debug(
      '[env] DEV_USERNAME source=${devUser.source}, empty=${devUser.value.trim().isEmpty}, value=${_maskSecret(devUser.value)}',
    );
    talker.debug(
      '[env] DEV_PASSWORD source=${devPass.source}, empty=${devPass.value.trim().isEmpty}, value=${_maskSecret(devPass.value)}',
    );

    talker.debug('[env] ENABLE_MVP_MY_DAY value=$enableMvpMyDay');
  }

  static ({String value, String source}) _supabaseUrlWithSource() {
    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet('SUPABASE_URL');
      if (v != null && v.isNotEmpty) return (value: v, source: '.env');
    }
    return (
      value: const String.fromEnvironment('SUPABASE_URL'),
      source: '--dart-define',
    );
  }

  static ({String value, String source}) _supabasePublishableKeyWithSource() {
    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY');
      if (v != null && v.isNotEmpty) return (value: v, source: '.env');
    }
    return (
      value: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      source: '--dart-define',
    );
  }

  static ({String value, String source}) _powersyncUrlWithSource() {
    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet('POWERSYNC_URL');
      if (v != null && v.isNotEmpty) return (value: v, source: '.env');
    }
    return (
      value: const String.fromEnvironment('POWERSYNC_URL'),
      source: '--dart-define',
    );
  }

  static ({String value, String source}) _devUsernameWithSource() {
    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet('DEV_USERNAME');
      if (v != null && v.isNotEmpty) return (value: v, source: '.env');
    }
    return (
      value: const String.fromEnvironment('DEV_USERNAME'),
      source: '--dart-define',
    );
  }

  static ({String value, String source}) _devPasswordWithSource() {
    if (kDebugMode && dotenv.isInitialized) {
      final v = dotenv.maybeGet('DEV_PASSWORD');
      if (v != null && v.isNotEmpty) return (value: v, source: '.env');
    }
    return (
      value: const String.fromEnvironment('DEV_PASSWORD'),
      source: '--dart-define',
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

  /// Validates that required configuration is present.
  ///
  /// This fails fast to prevent web builds from silently defaulting to
  /// localhost when `--dart-define` values are missing.
  static void validateRequired() {
    final missing = <String>[];

    final supabaseUrlValue = supabaseUrl.trim();
    if (supabaseUrlValue.isEmpty) missing.add('SUPABASE_URL');

    final supabaseKeyValue = supabasePublishableKey.trim();
    if (supabaseKeyValue.isEmpty) missing.add('SUPABASE_PUBLISHABLE_KEY');

    final powersyncUrlValue = powersyncUrl.trim();
    if (powersyncUrlValue.isEmpty) missing.add('POWERSYNC_URL');

    if (missing.isEmpty) return;

    const hint = kIsWeb
        ? 'Web cannot read .env. Run with --dart-define or --dart-define-from-file=dart_defines.json.'
        : 'Create a .env file (see ENVIRONMENT_SETUP.md) or pass values via --dart-define.';

    talker.error(
      '[env] Missing required configuration: ${missing.join(', ')}. $hint',
    );

    throw StateError(
      'Missing required configuration: ${missing.join(', ')}. $hint',
    );
  }
}
