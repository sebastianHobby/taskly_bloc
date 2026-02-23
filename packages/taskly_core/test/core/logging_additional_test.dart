import '../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingObserver implements TalkerObserver {
  final List<String> logs = <String>[];

  @override
  void onError(TalkerError err) {}

  @override
  void onException(TalkerException err) {}

  @override
  void onLog(TalkerData log) {
    logs.add('${log.title}:${log.message}');
  }
}

void main() {
  group('logging additional coverage', () {
    testSafe('TasklyTalker.logCustom writes custom records', () async {
      final observer = _RecordingObserver();
      final raw = Talker(observer: observer);
      final backend = TasklyTalker(raw);

      backend.logCustom(TasklyLogRecord('custom-message', category: 'core'));

      expect(observer.logs.join('\n'), contains('custom-message'));
    });

    testSafe(
      'AppRouteObserver treats blank route names as unnamed routes',
      () async {
        final observer = AppRouteObserver();
        observer.didPush(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '   '),
            builder: (_) => const SizedBox.shrink(),
          ),
          null,
        );

        expect(observer.currentRouteSummary, contains('MaterialPageRoute'));
      },
    );

    testSafe(
      'AppRouteObserver replace with null routes results in <null>',
      () async {
        final observer = AppRouteObserver();
        observer.didReplace(newRoute: null, oldRoute: null);

        expect(observer.currentRouteSummary, '<null>');
      },
    );
  });
}
