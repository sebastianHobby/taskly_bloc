import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global Talker instance for the application.
///
/// Provides unified logging, error handling, and crash reporting.
/// Access via [talker] anywhere in the app.
///
/// Features:
/// - In-app log viewer via [TalkerScreen]
/// - Automatic BLoC logging via TalkerBlocObserver
/// - Route transition logging via TalkerRouteObserver
/// - Error/exception handling with stack traces
/// - Log history for debugging
late Talker talker;

bool _isInitialized = false;

/// Initialize the Talker logging system.
///
/// Call this once at app startup before any logging occurs.
/// Must be called before accessing [talker].
///
/// Can be called multiple times safely (for tests).
void initializeTalker() {
  if (!_isInitialized) {
    final observer = kDebugMode ? DebugFileLogObserver() : null;
    talker = TalkerFlutter.init(observer: observer);
    _isInitialized = true;
  }
}

/// Initialize talker for test environments.
///
/// Creates a fresh talker instance for each test.
@visibleForTesting
void initializeTalkerForTest() {
  talker = TalkerFlutter.init();
  _isInitialized = true;
}

/// Extension methods on Talker for consistent logging patterns.
extension TalkerExtensions on Talker {
  /// Log a trace message (finest detail).
  ///
  /// Use for very detailed debugging information.
  void trace(String message) {
    if (kDebugMode) {
      verbose(message);
    }
  }

  /// Log a message with component context.
  ///
  /// Provides hierarchical naming similar to the old AppLogger.
  /// Example: `talker.logFor('bloc.TaskDetail', 'Loading task')`
  void logFor(
    String component,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      handle(error, stackTrace, '[$component] $message');
    } else {
      debug('[$component] $message');
    }
  }

  /// Log a BLoC-related message.
  void blocLog(String blocName, String message) {
    debug('[bloc.$blocName] $message');
  }

  /// Log a service-related message.
  void serviceLog(String serviceName, String message) {
    debug('[service.$serviceName] $message');
  }

  /// Log a repository-related message.
  void repositoryLog(String repoName, String message) {
    debug('[repository.$repoName] $message');
  }

  /// Log an API error with context.
  void apiError(
    String endpoint,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'API Error: $endpoint');
  }

  /// Log a database error with context.
  void databaseError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'Database Error: $operation');
  }

  /// Log an operation failure with context.
  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'Operation Failed: $operation');
  }
}

/// Custom log type for Taskly-specific categories.
///
/// Example usage:
/// ```dart
/// talker.logCustom(TasklyLog('User completed onboarding', category: 'onboarding'));
/// ```
class TasklyLog extends TalkerLog {
  TasklyLog(
    super.message, {
    this.category = 'app',
  });

  final String category;

  @override
  String get title => 'TASKLY';

  @override
  String get key => 'taskly_$category';

  @override
  AnsiPen get pen => AnsiPen()..green();
}

/// Observer that writes warnings and errors to a file in debug mode.
///
/// Useful for debugging specific issues when console output is insufficient.
/// The log file is automatically cleared if it exceeds [maxFileSizeBytes].
///
/// Log file location: `{app_support_directory}/debug_errors.log` (debug mode only)
///
/// **Note:** File logging is only available on native platforms (Windows, macOS,
/// Linux, iOS, Android). On web, this observer does nothing since `dart:io`
/// is not available.
class DebugFileLogObserver extends TalkerObserver {
  DebugFileLogObserver({
    this.maxFileSizeBytes = 512 * 1024, // 512 KB default
  });

  /// Maximum file size before auto-clearing (default 512 KB).
  final int maxFileSizeBytes;

  File? _logFile;
  bool _isInitialized = false;
  bool _initStarted = false;

  /// Whether file logging is supported on the current platform.
  /// Web does not support dart:io file operations.
  static bool get isSupported => !kIsWeb;

  Future<void> _initFile() async {
    if (_initStarted) return;
    _initStarted = true;

    // File logging not supported on web
    if (!isSupported) {
      debugPrint('Debug file logging not available on web platform');
      return;
    }

    try {
      // Use app support directory for reliable cross-platform file access
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/debug_errors.log');
      _isInitialized = true;

      // Log the file path so user knows where to find it
      debugPrint('Debug log file: ${_logFile!.path}');

      // Check file size and clear if too large
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > maxFileSizeBytes) {
          await _logFile!.writeAsString(
            '--- Log cleared at ${DateTime.now()} (was ${size ~/ 1024} KB) ---\n',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize debug log file: $e');
    }
  }

  @override
  void onError(TalkerError err) {
    _ensureInitialized();
    _writeLog('ERROR', err.message, err.error, err.stackTrace);
  }

  @override
  void onException(TalkerException exception) {
    _ensureInitialized();
    _writeLog(
      'EXCEPTION',
      exception.message,
      exception.exception,
      exception.stackTrace,
    );
  }

  @override
  void onLog(TalkerData log) {
    _ensureInitialized();
    // Log all messages to file for debugging
    _writeLog(log.title ?? 'LOG', log.message, null, null);
  }

  /// Lazily initialize the file when first log is written.
  /// This ensures bindings are ready when we access path_provider.
  void _ensureInitialized() {
    if (!_initStarted) {
      _initFile();
    }
  }

  void _writeLog(
    String level,
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!_isInitialized || _logFile == null) return;

    try {
      final buffer = StringBuffer()
        ..writeln('[$level] ${DateTime.now().toIso8601String()}')
        ..writeln(message ?? 'No message');

      if (error != null) {
        buffer.writeln('Error: $error');
      }
      if (stackTrace != null) {
        buffer.writeln('StackTrace:\n$stackTrace');
      }
      buffer.writeln('---');

      _logFile!.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // Silently fail - don't crash the app for logging issues
      debugPrint('Failed to write to debug log: $e');
    }
  }

  /// Manually clear the log file.
  Future<void> clearLog() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString(
        '--- Log manually cleared at ${DateTime.now()} ---\n',
      );
    }
  }

  /// Get the path to the log file.
  String? get logFilePath => _logFile?.path;
}
