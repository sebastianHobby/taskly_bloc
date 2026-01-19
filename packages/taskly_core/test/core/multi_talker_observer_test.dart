import '../helpers/test_imports.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

final class _RecordingObserver implements TalkerObserver {
  int logs = 0;
  int errors = 0;
  int exceptions = 0;

  @override
  void onError(TalkerError err) {
    errors++;
  }

  @override
  void onException(TalkerException err) {
    exceptions++;
  }

  @override
  void onLog(TalkerData log) {
    logs++;
  }
}

void main() {
  testSafe('MultiTalkerObserver forwards to all observers', () async {
    final a = _RecordingObserver();
    final b = _RecordingObserver();

    final observer = MultiTalkerObserver(observers: [a, b]);

    observer.onLog(TalkerData('m', title: 'INFO'));
    observer.onError(TalkerError(StateError('boom')));
    observer.onException(TalkerException(Exception('e')));

    expect(a.logs, 1);
    expect(a.errors, 1);
    expect(a.exceptions, 1);

    expect(b.logs, 1);
    expect(b.errors, 1);
    expect(b.exceptions, 1);
  });
}
