import '../helpers/test_imports.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingLog implements TasklyLog {
  final List<String> debugMessages = <String>[];
  final List<String> errorMessages = <String>[];
  final List<String> traceMessages = <String>[];
  final List<String> infoMessages = <String>[];
  final List<String> warningMessages = <String>[];
  final List<String> verboseMessages = <String>[];

  int handleCalls = 0;

  @override
  TalkerFailFastPolicy get failFastPolicy => const TalkerFailFastPolicy(
    enabled: false,
  );

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    debugMessages.add(message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    errorMessages.add(message);
  }

  @override
  void handle(Object exception, [StackTrace? stackTrace, String? msg]) {
    handleCalls++;
    if (msg != null) {
      errorMessages.add(msg);
    }
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    infoMessages.add(message);
  }

  @override
  void trace(String message) {
    traceMessages.add(message);
  }

  @override
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    verboseMessages.add(message);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    warningMessages.add(message);
  }

  @override
  void logFor(
    String component,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debug('[$component] $message', error, stackTrace);
  }

  @override
  void blocLog(String blocName, String message) {
    trace('[bloc.$blocName] $message');
  }

  @override
  void serviceLog(String serviceName, String message) {
    trace('[service.$serviceName] $message');
  }

  @override
  void repositoryLog(String repoName, String message) {
    trace('[repository.$repoName] $message');
  }

  @override
  void apiError(String endpoint, Object error, [StackTrace? stackTrace]) {
    handle(error, stackTrace, 'API Error: $endpoint');
  }

  @override
  void databaseError(String operation, Object error, [StackTrace? stackTrace]) {
    handle(error, stackTrace, 'Database Error: $operation');
  }

  @override
  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    handle(error, stackTrace, 'Operation Failed: $operation');
  }
}

void main() {
  group('Env diagnostics', () {
    testSafe('logDiagnostics masks secrets and formats urls', () async {
      if (!kDebugMode) {
        // In non-debug configurations this is a no-op.
        return;
      }

      final previous = talker;
      final recorder = _RecordingLog();
      talker = recorder;
      addTearDown(() {
        talker = previous;
      });

      // Ensure dotenv is initialized with a mix of valid/invalid/empty values.
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=not-a-url\n'
            'SUPABASE_PUBLISHABLE_KEY=supersecretkeyvalue\n'
            'POWERSYNC_URL=\n'
            'DEV_USERNAME=\n'
            'DEV_PASSWORD=short\n',
      );

      Env.logDiagnostics();

      final joined = recorder.debugMessages.join('\n');

      // URLs get formatted to scheme/host or <invalid>/<empty>.
      expect(joined, contains('SUPABASE_URL'));
      expect(joined, contains('<invalid>'));
      expect(joined, contains('POWERSYNC_URL'));
      expect(joined, contains('<empty>'));

      // Secrets should be masked.
      expect(joined, contains('SUPABASE_PUBLISHABLE_KEY'));
      expect(joined, isNot(contains('supersecretkeyvalue')));
      expect(joined, contains('DEV_PASSWORD'));
    });

    testSafe('validateRequired logs and throws with missing keys', () async {
      if (!kDebugMode) {
        return;
      }

      final previous = talker;
      final recorder = _RecordingLog();
      talker = recorder;
      addTearDown(() {
        talker = previous;
      });

      Env.resetForTest();
      dotenv.testLoad(fileInput: '');

      expect(Env.validateRequired, throwsA(isA<StateError>()));

      // It should have emitted a helpful error message.
      final joined = recorder.errorMessages.join('\n');
      expect(joined, contains('Missing required configuration'));
      expect(joined, contains('SUPABASE_URL'));
      expect(joined, contains('SUPABASE_PUBLISHABLE_KEY'));
      expect(joined, contains('POWERSYNC_URL'));
    });
  });
}
