import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration with dual loading strategy:
/// - Local development (debug mode): Loads from .env file for convenience
/// - Production/CI (release mode): Uses --dart-define compile-time constants
///
/// This ensures secrets are never bundled in production builds while
/// providing a seamless developer experience.
class Env {
  static bool _initialized = false;

  /// Initialize environment variables.
  ///
  /// In debug mode on non-web platforms, attempts to load .env from filesystem.
  /// This file should be gitignored and never committed.
  ///
  /// In release mode or on web, relies on --dart-define values provided at
  /// compile time.
  static Future<void> load() async {
    if (_initialized) return;

    // Only load .env in debug mode on platforms that support File I/O
    if (kDebugMode && !kIsWeb) {
      try {
        final file = File('.env');
        if (await file.exists()) {
          final content = await file.readAsString();
          dotenv.testLoad(fileInput: content);
        }
      } catch (e) {
        // Silently fail - not having a .env file is acceptable
        // as all values can be provided via --dart-define
      }
    }

    _initialized = true;
  }

  /// Supabase project URL
  static String get supabaseUrl {
    if (kDebugMode && !kIsWeb && dotenv.maybeGet('SUPABASE_URL') != null) {
      return dotenv.get('SUPABASE_URL');
    }
    return const String.fromEnvironment('SUPABASE_URL');
  }

  /// Supabase anonymous/public key
  static String get supabasePublishableKey {
    if (kDebugMode &&
        !kIsWeb &&
        dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') != null) {
      return dotenv.get('SUPABASE_PUBLISHABLE_KEY');
    }
    return const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  }

  /// PowerSync instance URL
  static String get powersyncUrl {
    if (kDebugMode && !kIsWeb && dotenv.maybeGet('POWERSYNC_URL') != null) {
      return dotenv.get('POWERSYNC_URL');
    }
    return const String.fromEnvironment('POWERSYNC_URL');
  }

  /// Development/test username
  static String get devUsername {
    if (kDebugMode && !kIsWeb && dotenv.maybeGet('DEV_USERNAME') != null) {
      return dotenv.get('DEV_USERNAME');
    }
    return const String.fromEnvironment('DEV_USERNAME');
  }

  /// Development/test password
  static String get devPassword {
    if (kDebugMode && !kIsWeb && dotenv.maybeGet('DEV_PASSWORD') != null) {
      return dotenv.get('DEV_PASSWORD');
    }
    return const String.fromEnvironment('DEV_PASSWORD');
  }
}
