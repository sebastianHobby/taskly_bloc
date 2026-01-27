import 'dart:collection';

import 'package:characters/characters.dart';

import 'package:taskly_core/logging_internal.dart';

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
  static void routine(
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = _format(category, message);
    if (error != null) {
      talker.handle(error, stackTrace, text);
      return;
    }

    talker.trace(text);
  }

  /// Logs routine, high-volume diagnostics with structured fields.
  ///
  /// Prefer [routineThrottledStructured] when the call site can be noisy.
  static void routineStructured(
    String category,
    String message, {
    required Map<String, Object?> fields,
  }) {
    talker.trace(_format(category, _withFields(message, fields)));
  }

  /// Logs a user/dev-relevant milestone.
  static void info(String category, String message) {
    talker.info(_format(category, message));
  }

  /// Logs a recoverable issue or degraded behavior.
  static void warn(String category, String message) {
    talker.warning(_format(category, message));
  }

  /// Logs a recoverable issue with structured fields.
  ///
  /// This is a lightweight step toward standardized structured logging.
  /// Fields are appended in a stable `key=value` schema so logs remain readable
  /// in plain text sinks.
  static void warnStructured(
    String category,
    String message, {
    required Map<String, Object?> fields,
  }) {
    talker.warning(_format(category, _withFields(message, fields)));
  }

  /// Emits a structured warning at most once per [interval] for a [key].
  static void warnThrottledStructured(
    String key,
    Duration interval,
    String category,
    String message, {
    required Map<String, Object?> fields,
  }) {
    if (!_shouldEmit(key, interval)) return;
    warnStructured(category, message, fields: fields);
  }

  /// Logs an error without a stack trace.
  static void error(String category, String message) {
    talker.error(_format(category, message));
  }

  /// Logs an error with structured fields.
  static void errorStructured(
    String category,
    String message, {
    required Map<String, Object?> fields,
  }) {
    talker.error(_format(category, _withFields(message, fields)));
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

  /// Logs an exception/error with stack trace and structured fields.
  static void handleStructured(
    String category,
    String message,
    Object error, [
    StackTrace? stackTrace,
    Map<String, Object?> fields = const <String, Object?>{},
  ]) {
    final formatted = _format(category, _withFields(message, fields));
    talker.handle(error, stackTrace, formatted);
  }

  /// Emits a routine log at most once per [interval] for a [key].
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

  /// Emits a structured routine log at most once per [interval] for a [key].
  static void routineThrottledStructured(
    String key,
    Duration interval,
    String category,
    String message, {
    required Map<String, Object?> fields,
  }) {
    if (!_shouldEmit(key, interval)) return;
    routineStructured(category, message, fields: fields);
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
    return '[$category] $message (route: $route)';
  }

  static String _withFields(String message, Map<String, Object?> fields) {
    if (fields.isEmpty) return message;

    final encoded = fields.entries
        .map((e) => '${e.key}=${e.value ?? ''}')
        .join(' ');
    return '$message | $encoded';
  }

  /// Masks an email address for logs.
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return _truncate(email);

    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty) return '***@$domain';

    final visible = local.characters.take(1).toString();
    return '$visible***@$domain';
  }

  static String _truncate(String value, {int max = 120}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}
