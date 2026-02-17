import '../helpers/test_imports.dart';

import 'package:flutter/material.dart';
import 'package:taskly_core/logging.dart';

void main() {
  group('AppLog', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      resetLoggingForTest();
      initializeLoggingForTest();

      // Put a deterministic route summary in place.
      appRouteObserver.didPush(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/test', arguments: 'args'),
          builder: (_) => const SizedBox.shrink(),
        ),
        null,
      );
    });

    testSafe('maskEmail masks local part', () async {
      expect(AppLog.maskEmail('john@example.com'), 'j***@example.com');
      expect(AppLog.maskEmail('a@domain.com'), 'a***@domain.com');
      expect(AppLog.maskEmail('invalid-email'), isNotEmpty);
    });

    testSafe('logging helpers are callable', () async {
      AppLog.routine('core', 'routine');
      AppLog.routine('core', 'routine with error', error: StateError('boom'));

      AppLog.routineStructured(
        'core',
        'structured',
        fields: <String, Object?>{'k': 'v', 'n': 1},
      );

      AppLog.info('core', 'info');
      AppLog.infoStructured(
        'core',
        'info structured',
        fields: <String, Object?>{'flag': true},
      );
      AppLog.warn('core', 'warn');
      AppLog.warnStructured(
        'core',
        'warn structured',
        fields: <String, Object?>{'a': null},
      );

      AppLog.error('core', 'error');
      AppLog.errorStructured(
        'core',
        'error structured',
        fields: <String, Object?>{'x': 'y'},
      );

      AppLog.handle('core', 'handle', StateError('boom'), StackTrace.empty);
      AppLog.handleStructured(
        'core',
        'handle structured',
        StateError('boom'),
        StackTrace.empty,
        <String, Object?>{'field': 'value'},
      );

      AppLog.routineThrottled(
        'key',
        const Duration(hours: 1),
        'core',
        'throttled',
      );
      AppLog.routineThrottled(
        'key',
        const Duration(hours: 1),
        'core',
        'throttled again (suppressed)',
      );

      AppLog.routineThrottledStructured(
        'key2',
        const Duration(hours: 1),
        'core',
        'throttled structured',
        fields: <String, Object?>{'k': 'v'},
      );
      AppLog.routineThrottledStructured(
        'key2',
        const Duration(hours: 1),
        'core',
        'throttled structured again (suppressed)',
        fields: <String, Object?>{'k': 'v'},
      );
    });
  });
}
