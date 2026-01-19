import '../helpers/test_imports.dart';

import 'package:taskly_core/logging.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException($message)';
}

class RepositoryValidationException implements Exception {
  RepositoryValidationException(this.message);
  final String message;

  @override
  String toString() => 'RepositoryValidationException($message)';
}

void main() {
  group('TalkerFailFastPolicy', () {
    testSafe('shouldFailFastForMessage matches configured prefixes', () async {
      const policy = TalkerFailFastPolicy(
        enabled: true,
        messagePrefixes: <String>['Database Error:', 'Operation Failed:'],
      );

      expect(policy.shouldFailFastForMessage('Database Error: insert'), isTrue);
      expect(policy.shouldFailFastForMessage('Operation Failed: save'), isTrue);
      expect(policy.shouldFailFastForMessage('Other: nope'), isFalse);
      expect(policy.shouldFailFastForMessage(''), isFalse);
      expect(policy.shouldFailFastForMessage(null), isFalse);
    });

    testSafe(
      'shouldFailFastFor allowlists specific error types by name',
      () async {
        const policy = TalkerFailFastPolicy(enabled: true);

        expect(policy.shouldFailFastFor(AuthException('x')), isFalse);
        expect(
          policy.shouldFailFastFor(RepositoryValidationException('x')),
          isFalse,
        );

        // Unrecognized errors should fail fast.
        expect(policy.shouldFailFastFor(StateError('boom')), isTrue);
      },
    );

    testSafe('fromEnvironment enables fail-fast in debug by default', () async {
      final policy = TalkerFailFastPolicy.fromEnvironment();
      // In tests we are in debug mode and kReleaseMode is false.
      // The environment default for FAIL_FAST_ERRORS is true.
      expect(policy.enabled, isTrue);
      expect(policy.messagePrefixes, isNotEmpty);
    });
  });
}
