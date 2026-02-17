import '../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingLog implements TasklyLog {
  final List<String> traces = <String>[];
  final List<String> infos = <String>[];
  final List<String> warnings = <String>[];
  final List<String> errors = <String>[];
  final List<String> handles = <String>[];

  @override
  TalkerFailFastPolicy get failFastPolicy =>
      const TalkerFailFastPolicy(enabled: false);

  @override
  void trace(String message) => traces.add(message);

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    infos.add(message);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    warnings.add(message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    errors.add(message);
  }

  @override
  void handle(Object exception, [StackTrace? stackTrace, String? msg]) {
    handles.add(msg ?? '<null>');
  }

  // Not used by these tests.
  @override
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {}

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
  group('AppLog behavior', () {
    late TasklyLog previousTalker;
    late _RecordingLog recorder;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      resetLoggingForTest();
      initializeLoggingForTest();
    });

    setUp(() {
      previousTalker = talker;
      recorder = _RecordingLog();
      talker = recorder;

      // Make route summary deterministic.
      appRouteObserver.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/unit', arguments: 'a1'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );
    });

    tearDown(() {
      talker = previousTalker;
    });

    testSafe('routine uses trace when no error', () async {
      AppLog.routine('core', 'hello');
      expect(recorder.traces.single, contains('[core] hello'));
      expect(recorder.traces.single, contains('route:'));
      expect(recorder.handles, isEmpty);
    });

    testSafe('routine uses handle when error is provided', () async {
      AppLog.routine('core', 'oops', error: StateError('boom'));
      expect(recorder.traces, isEmpty);
      expect(recorder.handles.single, contains('[core] oops'));
    });

    testSafe('structured methods append key=value fields', () async {
      AppLog.infoStructured(
        'core',
        'i',
        fields: <String, Object?>{'k': 'v', 'n': 1, 'nil': null},
      );
      AppLog.warnStructured(
        'core',
        'w',
        fields: <String, Object?>{'k': 'v', 'n': 1, 'nil': null},
      );

      final info = recorder.infos.single;
      expect(info, contains('[core] i |'));
      expect(info, contains('k=v'));
      expect(info, contains('n=1'));
      expect(info, contains('nil='));

      final msg = recorder.warnings.single;
      expect(msg, contains('[core] w |'));
      expect(msg, contains('k=v'));
      expect(msg, contains('n=1'));
      expect(msg, contains('nil='));
    });

    testSafe(
      'structured methods do not append when fields are empty',
      () async {
        AppLog.warnStructured('core', 'w', fields: const <String, Object?>{});

        expect(recorder.warnings.single, isNot(contains('|')));
      },
    );

    testSafe(
      'routineThrottled suppresses repeated logs for same key',
      () async {
        AppLog.routineThrottled(
          'k1',
          const Duration(hours: 1),
          'core',
          'first',
        );
        AppLog.routineThrottled(
          'k1',
          const Duration(hours: 1),
          'core',
          'second (suppressed)',
        );

        expect(recorder.traces.length, 1);
        expect(recorder.traces.single, contains('first'));
      },
    );

    testSafe('maskEmail truncates long invalid values', () async {
      final long = 'x' * 200;
      final masked = AppLog.maskEmail(long);
      expect(masked.length, lessThanOrEqualTo(121));
      expect(masked, contains('…'));
    });

    testSafe('maskEmail handles empty local part', () async {
      expect(AppLog.maskEmail('@example.com'), '***@example.com');
    });
  });
}
