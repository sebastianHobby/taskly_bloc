import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

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
late TasklyTalker talker;

/// Controls whether to fail fast after logging errors.
///
/// This is primarily intended for debug builds to surface issues early.
///
/// Configure via `--dart-define=FAIL_FAST_ERRORS=true|false`.
///
/// Notes:
/// - Forced off in release mode.
/// - Forced off in tests via [initializeTalkerForTest].
class TalkerFailFastPolicy {
  const TalkerFailFastPolicy({
    required this.enabled,
    this.messagePrefixes = const <String>[
      'Database Error:',
      'Operation Failed:',
      '[repository.',
      'Bootstrap failed',
      'Uncaught platform error',
    ],
  });

  factory TalkerFailFastPolicy.fromEnvironment() {
    const fromEnv = bool.fromEnvironment(
      'FAIL_FAST_ERRORS',
      defaultValue: true,
    );
    const enabled = kDebugMode && !kReleaseMode && fromEnv;
    return TalkerFailFastPolicy(enabled: enabled);
  }

  /// Override for tests.
  factory TalkerFailFastPolicy.forTests() {
    return const TalkerFailFastPolicy(enabled: false);
  }

  /// When true, certain logging calls will rethrow after logging.
  final bool enabled;

  /// Fail fast only when the log message starts with one of these prefixes.
  ///
  /// This keeps debug fail-fast high-signal (e.g. repository/db failures)
  /// without crashing the app for expected UI/auth/network errors.
  final List<String> messagePrefixes;

  bool shouldFailFastForMessage(String? message) {
    final m = message;
    if (m == null || m.isEmpty) return false;
    return messagePrefixes.any(m.startsWith);
  }

  bool shouldFailFastFor(Object error) {
    // Avoid turning common, expected user/validation issues into crashes.
    // For repository invariants and unexpected exceptions, we prefer fail-fast.
    if (error is RepositoryValidationException) return false;

    // Avoid direct imports for external package exceptions; use type name.
    final typeName = error.runtimeType.toString();
    const allowlistedTypeNames = <String>{
      'AuthException',
      'PostgrestException',
      'SocketException',
      'TimeoutException',
    };
    if (allowlistedTypeNames.contains(typeName)) return false;

    return true;
  }
}

/// App-level Talker wrapper.
///
/// Keeps the existing logging API surface (`debug/info/warning/error/handle`)
/// while enabling a debug-only fail-fast mode to surface errors early.
class TasklyTalker {
  TasklyTalker(
    this._raw, {
    TalkerFailFastPolicy? failFastPolicy,
  }) : _failFastPolicy =
           failFastPolicy ?? TalkerFailFastPolicy.fromEnvironment();

  final Talker _raw;
  TalkerFailFastPolicy _failFastPolicy;

  /// Access to the underlying Talker instance.
  ///
  /// Use this when a package API requires `Talker` directly (e.g. TalkerScreen).
  Talker get raw => _raw;

  TalkerFailFastPolicy get failFastPolicy => _failFastPolicy;
  set failFastPolicy(TalkerFailFastPolicy value) => _failFastPolicy = value;

  // Basic logging passthroughs used across the app.
  void verbose(String message, [Object? error, StackTrace? stackTrace]) =>
      _raw.verbose(message, error, stackTrace);

  void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      _raw.debug(message, error, stackTrace);

  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _raw.info(message, error, stackTrace);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _raw.warning(message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _raw.error(message, error, stackTrace);

    // Fail-fast on error-level logs when they include an exception.
    if (_failFastPolicy.enabled &&
        _failFastPolicy.shouldFailFastForMessage(message) &&
        error != null &&
        _failFastPolicy.shouldFailFastFor(error)) {
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
    }
  }

  void handle(Object exception, [StackTrace? stackTrace, String? msg]) {
    _raw.handle(exception, stackTrace, msg);

    // Fail-fast for handled exceptions in debug.
    if (_failFastPolicy.enabled &&
        _failFastPolicy.shouldFailFastForMessage(msg) &&
        _failFastPolicy.shouldFailFastFor(exception)) {
      Error.throwWithStackTrace(exception, stackTrace ?? StackTrace.current);
    }
  }

  void logCustom(TalkerLog log) => _raw.logCustom(log);

  void trace(String message) {
    if (kDebugMode) {
      verbose(message);
    }
  }

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

  void blocLog(String blocName, String message) {
    trace('[bloc.$blocName] $message');
  }

  void serviceLog(String serviceName, String message) {
    trace('[service.$serviceName] $message');
  }

  void repositoryLog(String repoName, String message) {
    trace('[repository.$repoName] $message');
  }

  void apiError(String endpoint, Object error, [StackTrace? stackTrace]) {
    handle(error, stackTrace, 'API Error: $endpoint');
  }

  void databaseError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'Database Error: $operation');
  }

  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'Operation Failed: $operation');
  }
}

/// Tracks the most recently observed route so crash logs can include context.
///
/// This is intentionally lightweight (no throttling/deduping) and safe to use
/// outside of a BuildContext (e.g. in `FlutterError.onError`).
final AppRouteObserver appRouteObserver = AppRouteObserver();

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
    final raw = TalkerFlutter.init(observer: observer);
    talker = TasklyTalker(raw);
    _isInitialized = true;
  }
}

/// Initialize talker for test environments.
///
/// Creates a fresh talker instance for each test.
@visibleForTesting
void initializeTalkerForTest() {
  final raw = TalkerFlutter.init();
  talker = TasklyTalker(raw, failFastPolicy: TalkerFailFastPolicy.forTests());
  _isInitialized = true;
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
    Set<String>? includedTitles,
  }) : includedTitles =
           includedTitles ?? const {'WARNING', 'ERROR', 'EXCEPTION'};

  /// Talker "titles" that should be persisted to file.
  ///
  /// We intentionally keep the file log small and high-signal.
  /// Console / in-app Talker UI can still show debug/info verbosity.
  final Set<String> includedTitles;

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
  // ignore: avoid_renaming_method_parameters, Clearer name than 'err'
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

    final title = (log.title ?? 'LOG').toUpperCase();
    if (!includedTitles.contains(title)) return;

    _writeLog(title, log.message, null, null);
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

/// Navigator observer that records the current route for diagnostics.
///
/// GoRouter installs its own Navigator; this observer is attached via the
/// router's `observers` list.
class AppRouteObserver extends NavigatorObserver {
  String? _currentRoute;

  String get currentRouteSummary => _currentRoute ?? '<unknown>';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _currentRoute = _describeRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _currentRoute = _describeRoute(newRoute ?? oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _currentRoute = _describeRoute(previousRoute);
  }

  String _describeRoute(Route<dynamic>? route) {
    if (route == null) return '<null>';

    final settings = route.settings;
    final name = settings.name;
    final args = settings.arguments;

    return '${route.runtimeType}(name=${name ?? "<null>"}, args=${_formatArgs(args)})';
  }

  String _formatArgs(Object? args) {
    if (args == null) return '<null>';

    // Avoid dumping large objects or PII-heavy structures into logs.
    final typeName = args.runtimeType.toString();
    final text = args.toString();
    const maxLen = 240;
    final truncated = text.length <= maxLen
        ? text
        : '${text.substring(0, maxLen)}…';
    return '$typeName:$truncated';
  }
}
