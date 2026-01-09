import 'dart:collection';

import 'package:characters/characters.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';

/// Centralized logging facade for the app.
///
/// Use this instead of calling `talker.*` directly in most places.
/// It standardizes:
/// - what is considered routine vs important
/// - formatting and category prefixes
/// - basic redaction helpers
/// - optional dedupe/throttling for noisy logs
abstract final class AppLog {
  static final Map<String, DateTime> _lastLogAt = HashMap();

  /// Logs routine, high-volume diagnostics.
  ///
  /// These are suppressed in release and should be used for:
  /// - navigation breadcrumbs
  /// - polling/stream updates
  /// - verbose repository/service flow
  static void routine(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = _format(category, message);
    if (error != null) {
      // Still include stack traces when provided.
      talker.handle(error, stackTrace, text);
      return;
    }

    // Uses Talker "verbose" under the hood (gated behind debug).
    talker.trace(text);
  }

  /// Logs a user/dev-relevant milestone.
  static void info(String category, String message) {
    talker.info(_format(category, message));
  }

  /// Logs a recoverable issue or degraded behavior.
  static void warn(String category, String message) {
    talker.warning(_format(category, message));
  }

  /// Logs an error without a stack trace.
  static void error(String category, String message) {
    talker.error(_format(category, message));
  }

  /// Logs an exception/error with stack trace.
  static void handle(
    String category,
    String message,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    talker.handle(error, stackTrace, _format(category, message));
  }

  /// Emits a routine log at most once per [interval] for a [key].
  ///
  /// Helpful for stream/polling loops where the same message repeats.
  static void routineThrottled(
    String key,
    Duration interval,
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldEmit(key, interval)) return;
    routine(category, message, error: error, stackTrace: stackTrace);
  }

  static bool _shouldEmit(String key, Duration interval) {
    final now = DateTime.now();
    final last = _lastLogAt[key];
    if (last != null && now.difference(last) < interval) return false;
    _lastLogAt[key] = now;
    return true;
  }

  static String _format(String category, String message) {
    final route = appRouteObserver.currentRouteSummary;
    // Keep this short: route context is often enough without dumping objects.
    return '[$category] $message (route: $route)';
  }

  /// Masks an email address for logs.
  ///
  /// Example: `m***@example.com`.
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return _truncate(email);

    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return '***@$domain';

    final visible = local.characters.take(1).toString();
    return '$visible***@$domain';
  }

  /// Truncates potentially large values to keep logs readable.
  static String _truncate(String value, {int max = 120}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}
