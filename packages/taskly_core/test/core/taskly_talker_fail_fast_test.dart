import '../helpers/test_imports.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException($message)';
}

void main() {
  group('TasklyTalker fail-fast', () {
    testSafe('throws for configured prefix + non-allowlisted error', () async {
      final raw = Talker();
      const policy = TalkerFailFastPolicy(
        enabled: true,
        messagePrefixes: <String>['Operation Failed:'],
      );
      final backend = TasklyTalker(raw, failFastPolicy: policy);

      expect(
        () => backend.error(
          'Operation Failed: save',
          StateError('boom'),
          StackTrace.empty,
        ),
        throwsA(isA<StateError>()),
      );
    });

    testSafe('does not throw when message prefix does not match', () async {
      final raw = Talker();
      const policy = TalkerFailFastPolicy(
        enabled: true,
        messagePrefixes: <String>['Database Error:'],
      );
      final backend = TasklyTalker(raw, failFastPolicy: policy);

      expect(
        () => backend.error(
          'Operation Failed: save',
          StateError('boom'),
          StackTrace.empty,
        ),
        returnsNormally,
      );
    });

    testSafe('does not throw for allowlisted error types', () async {
      final raw = Talker();
      const policy = TalkerFailFastPolicy(
        enabled: true,
        messagePrefixes: <String>['Operation Failed:'],
      );
      final backend = TasklyTalker(raw, failFastPolicy: policy);

      expect(
        () => backend.error(
          'Operation Failed: save',
          AuthException('nope'),
          StackTrace.empty,
        ),
        returnsNormally,
      );
    });

    testSafe('handle() uses same fail-fast conditions', () async {
      final raw = Talker();
      const policy = TalkerFailFastPolicy(
        enabled: true,
        messagePrefixes: <String>['Database Error:'],
      );
      final backend = TasklyTalker(raw, failFastPolicy: policy);

      expect(
        () => backend.handle(
          StateError('boom'),
          StackTrace.empty,
          'Database Error: tx',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
