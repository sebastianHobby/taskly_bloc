import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Primary logging interface exposed to other packages.
///
/// This keeps call sites stable even if the underlying backend changes.
abstract interface class TasklyLog {
  TalkerFailFastPolicy get failFastPolicy;

  void verbose(String message, [Object? error, StackTrace? stackTrace]);
  void debug(String message, [Object? error, StackTrace? stackTrace]);
  void info(String message, [Object? error, StackTrace? stackTrace]);
  void warning(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);

  void handle(Object exception, [StackTrace? stackTrace, String? msg]);

  void perf(String message, {String category = 'general'});
  void trace(String message);

  void logFor(
    String component,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void blocLog(String blocName, String message);
  void serviceLog(String serviceName, String message);
  void repositoryLog(String repoName, String message);

  void apiError(String endpoint, Object error, [StackTrace? stackTrace]);
  void databaseError(String operation, Object error, [StackTrace? stackTrace]);
  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]);
}

/// High-level log access used across the repo.
///
/// Note: many call sites historically use `talker.*`; keeping the name stable
/// avoids churn while still allowing the backend to evolve.
late TasklyLog talker;

/// Alias for callers that prefer `log.*` naming.
TasklyLog get log => talker;

/// Escape hatch for UI/integration packages that need access to Talker.
///
/// Prefer using the [TasklyLog] API for application and domain/data code.
Talker get talkerRaw => _backend.raw;

/// Tracks the most recently observed route so crash logs can include context.
final AppRouteObserver appRouteObserver = AppRouteObserver();

bool _isInitialized = false;
late TasklyTalker _backend;

/// Initialize the logging system.
///
/// Call this once at app startup before any logging occurs.
void initializeLogging() {
  if (_isInitialized) return;

  final observer = kDebugMode
      ? MultiTalkerObserver(
          observers: [
            DebugFileLogObserver(),
            DebugPerfFileLogObserver(),
          ],
        )
      : null;

  final raw = TalkerFlutter.init(observer: observer);
  _backend = TasklyTalker(raw);
  talker = _TasklyLogAdapter(_backend);
  _isInitialized = true;
}

/// Initialize logging for tests.
///
/// This disables fail-fast behavior.
@visibleForTesting
void initializeLoggingForTest() {
  final raw = TalkerFlutter.init();
  _backend = TasklyTalker(raw, failFastPolicy: TalkerFailFastPolicy.forTests());
  talker = _TasklyLogAdapter(_backend);
  _isInitialized = true;
}

class _TasklyLogAdapter implements TasklyLog {
  _TasklyLogAdapter(this._backend);

  final TasklyTalker _backend;

  @override
  TalkerFailFastPolicy get failFastPolicy => _backend.failFastPolicy;

  @override
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    _backend.verbose(message, error, stackTrace);
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _backend.debug(message, error, stackTrace);
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _backend.info(message, error, stackTrace);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _backend.warning(message, error, stackTrace);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _backend.error(message, error, stackTrace);
  }

  @override
  void handle(Object exception, [StackTrace? stackTrace, String? msg]) {
    _backend.handle(exception, stackTrace, msg);
  }

  @override
  void perf(String message, {String category = 'general'}) {
    _backend.perf(message, category: category);
  }

  @override
  void trace(String message) {
    _backend.trace(message);
  }

  @override
  void logFor(
    String component,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _backend.logFor(component, message, error: error, stackTrace: stackTrace);
  }

  @override
  void blocLog(String blocName, String message) {
    _backend.blocLog(blocName, message);
  }

  @override
  void serviceLog(String serviceName, String message) {
    _backend.serviceLog(serviceName, message);
  }

  @override
  void repositoryLog(String repoName, String message) {
    _backend.repositoryLog(repoName, message);
  }

  @override
  void apiError(String endpoint, Object error, [StackTrace? stackTrace]) {
    _backend.apiError(endpoint, error, stackTrace);
  }

  @override
  void databaseError(String operation, Object error, [StackTrace? stackTrace]) {
    _backend.databaseError(operation, error, stackTrace);
  }

  @override
  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _backend.operationFailed(operation, error, stackTrace);
  }
}

/// Controls whether to fail fast after logging errors.
///
/// Configure via `--dart-define=FAIL_FAST_ERRORS=true|false`.
///
/// Notes:
/// - Forced off in release mode.
/// - Forced off in tests via [initializeLoggingForTest].
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

  factory TalkerFailFastPolicy.forTests() {
    return const TalkerFailFastPolicy(enabled: false);
  }

  final bool enabled;

  final List<String> messagePrefixes;

  bool shouldFailFastForMessage(String? message) {
    final m = message;
    if (m == null || m.isEmpty) return false;
    return messagePrefixes.any(m.startsWith);
  }

  bool shouldFailFastFor(Object error) {
    final typeName = error.runtimeType.toString();
    if (typeName == 'RepositoryValidationException') return false;
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

/// Backend wrapper around Talker.
class TasklyTalker {
  TasklyTalker(
    this._raw, {
    TalkerFailFastPolicy? failFastPolicy,
  }) : failFastPolicy =
           failFastPolicy ?? TalkerFailFastPolicy.fromEnvironment();

  final Talker _raw;

  TalkerFailFastPolicy failFastPolicy;

  Talker get raw => _raw;

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

    if (failFastPolicy.enabled &&
        failFastPolicy.shouldFailFastForMessage(message) &&
        error != null &&
        failFastPolicy.shouldFailFastFor(error)) {
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
    }
  }

  void handle(Object exception, [StackTrace? stackTrace, String? msg]) {
    _raw.handle(exception, stackTrace, msg);

    if (failFastPolicy.enabled &&
        failFastPolicy.shouldFailFastForMessage(msg) &&
        failFastPolicy.shouldFailFastFor(exception)) {
      Error.throwWithStackTrace(exception, stackTrace ?? StackTrace.current);
    }
  }

  void logCustom(TalkerLog log) => _raw.logCustom(log);

  void perf(
    String message, {
    String category = 'general',
  }) {
    if (kReleaseMode) return;
    logCustom(PerfLog(message, category: category));
  }

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

class TasklyLogRecord extends TalkerLog {
  TasklyLogRecord(
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

class PerfLog extends TalkerLog {
  PerfLog(
    super.message, {
    this.category = 'general',
  });

  final String category;

  @override
  String get title => 'PERF';

  @override
  String get key => 'perf_$category';

  @override
  AnsiPen get pen => AnsiPen()..cyan();
}

class MultiTalkerObserver extends TalkerObserver {
  MultiTalkerObserver({
    required List<TalkerObserver> observers,
  }) : _observers = observers;

  final List<TalkerObserver> _observers;

  @override
  void onError(TalkerError err) {
    for (final o in _observers) {
      o.onError(err);
    }
  }

  @override
  void onException(TalkerException err) {
    for (final o in _observers) {
      o.onException(err);
    }
  }

  @override
  void onLog(TalkerData log) {
    for (final o in _observers) {
      o.onLog(log);
    }
  }
}

class DebugFileLogObserver extends TalkerObserver {
  DebugFileLogObserver({
    this.maxFileSizeBytes = 512 * 1024,
    Set<String>? includedTitles,
  }) : includedTitles =
           includedTitles ?? const {'WARNING', 'ERROR', 'EXCEPTION'};

  final Set<String> includedTitles;

  final int maxFileSizeBytes;

  File? _logFile;
  bool _isInitialized = false;
  bool _initStarted = false;

  static bool get isSupported => !kIsWeb;

  Future<void> _initFile() async {
    if (_initStarted) return;
    _initStarted = true;

    if (!isSupported) {
      debugPrint('Debug file logging not available on web platform');
      return;
    }

    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/debug_errors.log');
      _isInitialized = true;

      debugPrint('Debug log file: ${_logFile!.path}');

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
  void onException(TalkerException err) {
    _ensureInitialized();
    _writeLog(
      'EXCEPTION',
      err.message,
      err.exception,
      err.stackTrace,
    );
  }

  @override
  void onLog(TalkerData log) {
    _ensureInitialized();

    final title = (log.title ?? 'LOG').toUpperCase();
    if (!includedTitles.contains(title)) return;

    _writeLog(title, log.message, null, null);
  }

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
      debugPrint('Failed to write to debug log: $e');
    }
  }

  Future<void> clearLog() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString(
        '--- Log manually cleared at ${DateTime.now()} ---\n',
      );
    }
  }

  String? get logFilePath => _logFile?.path;
}

class DebugPerfFileLogObserver extends TalkerObserver {
  DebugPerfFileLogObserver({
    this.maxFileSizeBytes = 1024 * 1024,
  });

  final int maxFileSizeBytes;

  File? _logFile;
  bool _isInitialized = false;
  bool _initStarted = false;

  static bool get isSupported => !kIsWeb;

  Future<void> _initFile() async {
    if (_initStarted) return;
    _initStarted = true;

    if (!isSupported) {
      debugPrint('Debug perf file logging not available on web platform');
      return;
    }

    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/debug_perf.log');
      _isInitialized = true;

      debugPrint('Debug perf log file: ${_logFile!.path}');

      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > maxFileSizeBytes) {
          await _logFile!.writeAsString(
            '--- Perf log cleared at ${DateTime.now()} (was ${size ~/ 1024} KB) ---\n',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize debug perf log file: $e');
    }
  }

  @override
  void onLog(TalkerData log) {
    _ensureInitialized();

    final title = (log.title ?? 'LOG').toUpperCase();
    if (title != 'PERF') return;

    _writeLog('PERF', log.message);
  }

  void _ensureInitialized() {
    if (!_initStarted) {
      _initFile();
    }
  }

  void _writeLog(String level, String? message) {
    if (!_isInitialized || _logFile == null) return;

    try {
      final buffer = StringBuffer()
        ..writeln('[$level] ${DateTime.now().toIso8601String()}')
        ..writeln(message ?? 'No message')
        ..writeln('---');

      _logFile!.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Failed to write to debug perf log: $e');
    }
  }

  String? get logFilePath => _logFile?.path;
}

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

    final typeName = args.runtimeType.toString();
    final text = args.toString();
    const maxLen = 240;
    final truncated = text.length <= maxLen
        ? text
        : '${text.substring(0, maxLen)}…';
    return '$typeName:$truncated';
  }
}
