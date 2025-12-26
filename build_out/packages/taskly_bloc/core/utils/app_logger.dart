import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logging utility for the application.
///
/// Provides structured logging with proper severity levels and context.
/// Uses both dart:developer for debug builds and the logging package
/// for production-ready structured logging.
class AppLogger {
  AppLogger(this.name) : _logger = Logger(name);

  /// Creates a logger for a specific feature or component.
  factory AppLogger.forFeature(String featureName) {
    return AppLogger('app.$featureName');
  }

  /// Creates a logger for a BLoC.
  factory AppLogger.forBloc(String blocName) {
    return AppLogger('bloc.$blocName');
  }

  /// Creates a logger for a repository.
  factory AppLogger.forRepository(String repositoryName) {
    return AppLogger('repository.$repositoryName');
  }

  /// Creates a logger for a service.
  factory AppLogger.forService(String serviceName) {
    return AppLogger('service.$serviceName');
  }

  final String name;
  final Logger _logger;

  /// Initialize the logging system.
  ///
  /// Call this once at app startup before any logging occurs.
  static void initialize({LogLevel minimumLevel = LogLevel.info}) {
    Logger.root.level = _toLoggingLevel(minimumLevel);

    Logger.root.onRecord.listen((record) {
      // In debug mode, also log to developer console for DevTools integration
      if (kDebugMode) {
        developer.log(
          record.message,
          time: record.time,
          sequenceNumber: record.sequenceNumber,
          level: _toDeveloperLevel(record.level),
          name: record.loggerName,
          zone: record.zone,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }

      // Also output to console with formatted text for easier reading
      // Format specially for Flutter Log Viewer compatibility
      final formattedLog = _formatLogRecord(record);
      // ignore: avoid_print
      print(formattedLog);

      // If there's a stack trace, print it separately for Flutter Log Viewer
      if (record.stackTrace != null && kDebugMode) {
        // ignore: avoid_print
        print(_formatStackTrace(record.stackTrace!));
      }
    });
  }

  /// Log a trace message (finest detail).
  ///
  /// Use for very detailed debugging information.
  void trace(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.finest(message, error, stackTrace);
  }

  /// Log a debug message.
  ///
  /// Use for general debugging information during development.
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  /// Log an info message.
  ///
  /// Use for general informational messages about app state or flow.
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  /// Log a warning message.
  ///
  /// Use for potentially problematic situations that should be investigated.
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  /// Log an error message.
  ///
  /// Use for error conditions that affect functionality but allow recovery.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  /// Log a critical/fatal error.
  ///
  /// Use for severe errors that may cause app instability or data loss.
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.shout(message, error, stackTrace);
  }

  /// Log when catching and handling an expected exception.
  ///
  /// Use this when you catch an exception you know how to handle gracefully.
  void caughtException(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    warning('Exception caught in $context', error, stackTrace);
  }

  /// Log when catching an unexpected exception.
  ///
  /// Use this when you catch an exception you didn't anticipate.
  void unexpectedException(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    this.error('Unexpected exception in $context', error, stackTrace);
  }

  /// Log a failed operation with details.
  void operationFailed(
    String operation, {
    String? reason,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final message = reason != null
        ? 'Operation failed: $operation - $reason'
        : 'Operation failed: $operation';
    this.error(message, error, stackTrace);
  }

  /// Log a network/API error.
  void apiError(
    String endpoint,
    int? statusCode, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final message = statusCode != null
        ? 'API error at $endpoint (Status: $statusCode)'
        : 'API error at $endpoint';
    this.error(message, error, stackTrace);
  }

  /// Log a database error.
  void databaseError(
    String operation, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    this.error('Database error during $operation', error, stackTrace);
  }

  static String _formatLogRecord(LogRecord record) {
    final level = record.level.name.toUpperCase().padRight(7);
    final time = record.time.toString().substring(11, 23); // HH:MM:SS.mmm
    final name = record.loggerName;

    final buffer = StringBuffer()
      ..write('[$time] ')
      ..write('[$level] ')
      ..write('[$name] ')
      ..write(record.message);

    if (record.error != null) {
      buffer
        ..write(' | Error: ')
        ..write(record.error.toString());
    }

    return buffer.toString();
  }

  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final relevantLines = lines.take(10).map((line) => '  â†’ $line');
    return relevantLines.join('\n');
  }

  static Level _toLoggingLevel(LogLevel level) {
    return switch (level) {
      LogLevel.all => Level.ALL,
      LogLevel.trace => Level.FINEST,
      LogLevel.debug => Level.FINE,
      LogLevel.info => Level.INFO,
      LogLevel.warning => Level.WARNING,
      LogLevel.error => Level.SEVERE,
      LogLevel.critical => Level.SHOUT,
      LogLevel.off => Level.OFF,
    };
  }

  static int _toDeveloperLevel(Level level) {
    if (level >= Level.SHOUT) return 2000; // CRITICAL
    if (level >= Level.SEVERE) return 1000; // ERROR
    if (level >= Level.WARNING) return 900; // WARNING
    if (level >= Level.INFO) return 800; // INFO
    if (level >= Level.FINE) return 500; // DEBUG
    return 300; // TRACE
  }
}

/// Log levels for filtering.
enum LogLevel {
  all,
  trace,
  debug,
  info,
  warning,
  error,
  critical,
  off,
}
