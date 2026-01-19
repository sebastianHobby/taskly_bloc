import '../helpers/test_imports.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingObserver implements TalkerObserver {
  final List<String> logs = <String>[];
  final List<String> errors = <String>[];

  @override
  void onError(TalkerError err) {
    errors.add(err.message ?? '<null>');
  }

  @override
  void onException(TalkerException err) {
    errors.add(err.message ?? '<null>');
  }

  @override
  void onLog(TalkerData log) {
    logs.add('${log.title}:${log.message}');
  }
}

void main() {
  group('TasklyTalker helpers', () {
    testSafe('trace delegates to verbose in debug mode', () async {
      final obs = _RecordingObserver();
      final raw = Talker(observer: obs);
      final backend = TasklyTalker(raw);

      backend.trace('hello');

      // In debug mode, trace uses verbose(), which is still a log event.
      expect(obs.logs.join('\n'), contains('hello'));
    });

    testSafe('logFor uses debug when no error', () async {
      final obs = _RecordingObserver();
      final raw = Talker(observer: obs);
      final backend = TasklyTalker(
        raw,
        failFastPolicy: const TalkerFailFastPolicy(enabled: false),
      );

      backend.logFor('svc', 'msg');

      expect(obs.logs.join('\n'), contains('[svc] msg'));
      expect(obs.errors, isEmpty);
    });

    testSafe('logFor uses handle when error provided', () async {
      final obs = _RecordingObserver();
      final raw = Talker(observer: obs);
      final backend = TasklyTalker(
        raw,
        failFastPolicy: const TalkerFailFastPolicy(enabled: false),
      );

      backend.logFor('svc', 'msg', error: StateError('boom'));

      expect(obs.errors.isNotEmpty, isTrue);
    });

    testSafe(
      'api/database/operation helpers include correct prefixes',
      () async {
        final obs = _RecordingObserver();
        final raw = Talker(observer: obs);
        final backend = TasklyTalker(
          raw,
          failFastPolicy: const TalkerFailFastPolicy(enabled: false),
        );

        backend.apiError('/v1/x', StateError('e'));
        backend.databaseError('insert', StateError('e'));
        backend.operationFailed('save', StateError('e'));

        final joined = obs.errors.join('\n');
        expect(joined, contains('API Error: /v1/x'));
        expect(joined, contains('Database Error: insert'));
        expect(joined, contains('Operation Failed: save'));
      },
    );

    testSafe('TasklyLogRecord key and title are stable', () async {
      final record = TasklyLogRecord('m', category: 'db');
      expect(record.title, 'TASKLY');
      expect(record.key, 'taskly_db');
    });
  });
}
