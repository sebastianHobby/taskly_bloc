import '../helpers/test_imports.dart';

import 'package:flutter/foundation.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingLog implements TasklyLog {
  final List<String> debugMessages = <String>[];
  final List<String> errorMessages = <String>[];

  @override
  TalkerFailFastPolicy get failFastPolicy =>
      const TalkerFailFastPolicy(enabled: false);

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
    if (msg != null) {
      errorMessages.add(msg);
    }
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void trace(String message) {}

  @override
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void logFor(
    String component,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void blocLog(String blocName, String message) {}

  @override
  void serviceLog(String serviceName, String message) {}

  @override
  void repositoryLog(String repoName, String message) {}

  @override
  void apiError(String endpoint, Object error, [StackTrace? stackTrace]) {}

  @override
  void databaseError(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {}

  @override
  void operationFailed(
    String operation,
    Object error, [
    StackTrace? stackTrace,
  ]) {}
}

void main() {
  group('Env additional coverage', () {
    setUpAll(() {
      resetLoggingForTest();
      initializeLoggingForTest();
    });

    tearDown(Env.resetForTest);

    testSafe('name getter returns configured entrypoint name', () async {
      Env.config = const EnvConfig(
        name: 'local',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'pubkey',
        powersyncUrl: 'https://example.powersync.dev',
      );

      expect(Env.name, 'local');
    });

    testSafe(
      'appVersion/buildSha use configured values when non-empty',
      () async {
        Env.config = const EnvConfig(
          name: 'local',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'pubkey',
          powersyncUrl: 'https://example.powersync.dev',
          appVersion: '1.2.3',
          buildSha: 'abc123',
        );

        expect(Env.appVersion, '1.2.3');
        expect(Env.buildSha, 'abc123');
      },
    );

    testSafe(
      'appVersion/buildSha fall back when configured values are empty',
      () async {
        Env.config = const EnvConfig(
          name: 'local',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'pubkey',
          powersyncUrl: 'https://example.powersync.dev',
          appVersion: ' ',
          buildSha: '',
        );

        expect(Env.appVersion, 'unknown');
        expect(Env.buildSha, 'unknown');
      },
    );

    testSafe(
      'logDiagnostics reports <unset> sources when config is missing',
      () async {
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
        Env.logDiagnostics();

        final joined = recorder.debugMessages.join('\n');
        expect(joined, contains('source=<unset>'));
        expect(joined, contains('value=<empty>'));
      },
    );
  });
}
