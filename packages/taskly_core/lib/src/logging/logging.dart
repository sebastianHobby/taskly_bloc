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
          observers: <TalkerObserver>[
            DebugFileLogObserver(
              includedTitles: const <String>{'ERROR', 'WARNING'},
              maxFileBytes: 1024 * 1024,
            ),
          ],
        )
      : null;

  final raw = TalkerFlutter.init(
    observer: observer,
    filter: TalkerFilter(
      enabledKeys: const <String>[
        TalkerKey.warning,
        TalkerKey.error,
        TalkerKey.exception,
        TalkerKey.critical,
      ],
    ),
  );
  _backend = TasklyTalker(raw);
  talker = _TasklyLogAdapter(_backend);
  _isInitialized = true;
}

/// Initialize logging for tests.
///
/// This disables fail-fast behavior.
@visibleForTesting
void initializeLoggingForTest() {
  final observer = MultiTalkerObserver(
    observers: <TalkerObserver>[
      DebugFileLogObserver(
        maxFileBytes: 1024 * 1024,
        supportDirectoryProvider: () async => Directory('build/test_logs'),
      ),
    ],
  );

  final raw = TalkerFlutter.init(observer: observer);
  _backend = TasklyTalker(raw, failFastPolicy: TalkerFailFastPolicy.forTests());
  talker = _TasklyLogAdapter(_backend);
  _isInitialized = true;
}

@visibleForTesting
void resetLoggingForTest() {
  _isInitialized = false;
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
  TasklyTalker(this._raw, {TalkerFailFastPolicy? failFastPolicy})
    : failFastPolicy = failFastPolicy ?? TalkerFailFastPolicy.fromEnvironment();

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

  void databaseError(String operation, Object error, [StackTrace? stackTrace]) {
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
  TasklyLogRecord(super.message, {this.category = 'app'});

  final String category;

  @override
  String get title => 'TASKLY';

  @override
  String get key => 'taskly_$category';

  @override
  AnsiPen get pen => AnsiPen()..green();
}

class MultiTalkerObserver extends TalkerObserver {
  MultiTalkerObserver({required List<TalkerObserver> observers})
    : _observers = observers;

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
    this.dedupeWindow = const Duration(seconds: 2),
    this.maxStackTraceLines = 60,
    this.maxFileBytes = 1024 * 1024,
    Future<Directory> Function()? supportDirectoryProvider,
    this.includedTitles,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  /// Optional allowlist of `TalkerData.title` values to write.
  ///
  /// When null, all log titles are written.
  final Set<String>? includedTitles;

  /// Suppress identical log entries that repeat within this window.
  final Duration dedupeWindow;

  /// Limits stack trace verbosity written to file.
  final int maxStackTraceLines;

  /// Maximum size for `debug_errors.log` before it is truncated.
  ///
  /// This keeps the file high-signal and bounded, while still allowing a
  /// developer to share the most recent context for a crash or hard-to-repro.
  final int maxFileBytes;

  final Future<Directory> Function() _supportDirectoryProvider;

  File? _logFile;
  _AppendFileWriter? _writer;

  final Map<String, _DedupeEntry> _dedupe = <String, _DedupeEntry>{};
  bool _isInitialized = false;
  Future<void>? _initFuture;

  static bool get isSupported => !kIsWeb;

  Future<void> _initFile() {
    return _initFuture ??= _initFileImpl();
  }

  Future<void> _initFileImpl() async {
    if (!isSupported) {
      debugPrint('Debug file logging not available on web platform');
      return;
    }

    try {
      final dir = await _supportDirectoryProvider();
      _logFile = File('${dir.path}/debug_errors.log');
      _writer = _AppendFileWriter(
        file: _logFile!,
        headerLabel: 'Log',
        maxBytes: maxFileBytes,
      );
      _isInitialized = true;

      debugPrint('Debug log file: ${_logFile!.path}');

      await _writer!.init();
    } catch (e) {
      debugPrint('Failed to initialize debug log file: $e');
    }
  }

  @visibleForTesting
  Future<void> ensureInitializedForTest() => _initFile();

  @override
  void onError(TalkerError err) {
    _ensureInitialized();
    _writeLog('ERROR', err.message, err.error, err.stackTrace);
  }

  @override
  void onException(TalkerException err) {
    _ensureInitialized();
    _writeLog('EXCEPTION', err.message, err.exception, err.stackTrace);
  }

  @override
  void onLog(TalkerData log) {
    _ensureInitialized();

    final title = (log.title ?? 'LOG').toUpperCase();
    final allowlist = includedTitles;
    if (allowlist != null && !allowlist.contains(title)) return;

    _writeLog(title, log.message, null, null);
  }

  void _ensureInitialized() {
    _initFile();
  }

  void _writeLog(
    String level,
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (!_isInitialized || _writer == null) return;

    try {
      final dedupeKey = _buildDedupeKey(
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
      );

      final now = DateTime.now();
      final previous = _dedupe[dedupeKey];
      if (previous != null) {
        final elapsed = now.difference(previous.lastWrittenAt);
        if (elapsed < dedupeWindow) {
          previous.suppressedCount++;
          _pruneDedupe(now);
          return;
        }

        if (previous.suppressedCount > 0) {
          _writer!.write(
            _formatSuppressionLine(
              level: level,
              suppressedCount: previous.suppressedCount,
              since: previous.lastWrittenAt,
            ),
          );
          previous.suppressedCount = 0;
        }
        previous.lastWrittenAt = now;
      } else {
        _dedupe[dedupeKey] = _DedupeEntry(lastWrittenAt: now);
      }

      final buffer = StringBuffer()
        ..writeln('[$level] ${DateTime.now().toIso8601String()}')
        ..writeln(message ?? 'No message');

      if (error != null) {
        buffer.writeln('Error: $error');
      }
      if (stackTrace != null) {
        final stack = _truncateStackTrace(
          stackTrace,
          maxLines: maxStackTraceLines,
        );
        buffer.writeln('StackTrace:\n$stack');
      }
      buffer.writeln('---');

      _writer!.write(buffer.toString());
      _pruneDedupe(now);
    } catch (e) {
      debugPrint('Failed to write to debug log: $e');
    }
  }

  Future<void> clearLog() async {
    final writer = _writer;
    if (writer == null) return;
    await writer.clear('Log manually cleared at ${DateTime.now()}');
  }

  String? get logFilePath => _logFile?.path;

  String _buildDedupeKey({
    required String level,
    required String? message,
    required Object? error,
    required StackTrace? stackTrace,
  }) {
    final m = message ?? '';
    final e = error?.toString() ?? '';
    final s = stackTrace == null
        ? ''
        : stackTrace.toString().split('\n').take(3).join('\n');
    return '$level\n$m\n$e\n$s';
  }

  String _formatSuppressionLine({
    required String level,
    required int suppressedCount,
    required DateTime since,
  }) {
    return '[${level.toUpperCase()}] ${DateTime.now().toIso8601String()}\n'
        'Suppressed $suppressedCount duplicate entries since '
        '${since.toIso8601String()}\n---\n';
  }

  void _pruneDedupe(DateTime now) {
    if (_dedupe.length <= 500) return;
    final cutoff = now.subtract(const Duration(minutes: 10));
    _dedupe.removeWhere((_, e) => e.lastWrittenAt.isBefore(cutoff));
  }
}

class _DedupeEntry {
  _DedupeEntry({required this.lastWrittenAt});

  DateTime lastWrittenAt;
  int suppressedCount = 0;
}

class _AppendFileWriter {
  _AppendFileWriter({
    required File file,
    required String headerLabel,
    required int maxBytes,
  }) : _file = file,
       _headerLabel = headerLabel,
       _maxBytes = maxBytes;

  final File _file;
  final String _headerLabel;
  final int _maxBytes;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (!await _file.exists()) {
        await _file.create(recursive: true);
      }
      _initialized = true;

      await _truncateIfOversized(
        reason: 'max size exceeded ($_maxBytes bytes)',
      );

      await _file.writeAsString(
        '--- $_headerLabel started at ${DateTime.now()} ---\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  void write(String text) {
    if (!_initialized) return;
    try {
      _truncateIfOversizedSync(reason: 'max size exceeded ($_maxBytes bytes)');
      _file.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> clear(String reason) async {
    if (!_initialized) return;
    try {
      final header =
          '--- $_headerLabel cleared at ${DateTime.now()} ($reason) ---\n';
      await _file.writeAsString(header, mode: FileMode.write);
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _truncateIfOversized({required String reason}) async {
    try {
      if (_maxBytes <= 0) return;
      final size = await _file.length();
      if (size <= _maxBytes) return;
      final header =
          '--- $_headerLabel cleared at ${DateTime.now()} ($reason) ---\n';
      await _file.writeAsString(header, mode: FileMode.write);
    } catch (_) {
      // Best-effort only.
    }
  }

  void _truncateIfOversizedSync({required String reason}) {
    try {
      if (_maxBytes <= 0) return;
      if (!_file.existsSync()) return;
      final size = _file.lengthSync();
      if (size <= _maxBytes) return;
      final header =
          '--- $_headerLabel cleared at ${DateTime.now()} ($reason) ---\n';
      _file.writeAsStringSync(header, mode: FileMode.write, flush: true);
    } catch (_) {
      // Best-effort only.
    }
  }
}

String _truncateStackTrace(StackTrace stackTrace, {required int maxLines}) {
  if (maxLines <= 0) return '<omitted>';
  final lines = stackTrace.toString().split('\n');
  if (lines.length <= maxLines) return stackTrace.toString();
  final kept = lines.take(maxLines).join('\n');
  return '$kept\n… (${lines.length - maxLines} more lines)';
}

class AppRouteObserver extends NavigatorObserver {
  static const bool _logRouteArgs = bool.fromEnvironment(
    'LOG_ROUTE_ARGS',
    defaultValue: false,
  );

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
    final rawName = settings.name?.trim();
    final routeName = (rawName == null || rawName.isEmpty)
        ? route.runtimeType.toString()
        : rawName;

    if (!_logRouteArgs || !kDebugMode) return routeName;

    final args = settings.arguments;
    return '$routeName args=${_formatArgs(args)}';
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
