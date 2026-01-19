import '../helpers/test_imports.dart';

import 'package:taskly_core/logging.dart';

void main() {
  testSafe('initializeLoggingForTest sets up globals', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    resetLoggingForTest();
    initializeLoggingForTest();

    expect(talker.failFastPolicy.enabled, isFalse);

    // Exercise the public adapters (coverage).
    talker.debug('debug');
    talker.info('info');
    talker.warning('warning');
    talker.error('error');

    log.debug('log debug');
    log.info('log info');

    talkerRaw.debug('raw debug');
  });
}
