import '../helpers/test_imports.dart';

import 'package:taskly_core/logging.dart';

void main() {
  testSafe('initializeLogging is idempotent and sets up globals', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    resetLoggingForTest();
    initializeLogging();

    // Second call should be a no-op.
    initializeLogging();

    expect(talker, isA<TasklyLog>());

    // Should be safe to log.
    talker.info('hello');
    talker.error('oops', StateError('boom'), StackTrace.empty);
  });
}
