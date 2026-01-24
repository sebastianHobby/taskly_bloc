@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_domain/errors.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('FailureGuard', () {
    testSafe('returns result on success', () async {
      final result = await FailureGuard.run(
        () async => 42,
        area: 'data.test',
        opName: 'noop',
      );

      expect(result, equals(42));
    });

    testSafe('maps repository validation to InputValidationFailure', () async {
      expect(
        () => FailureGuard.run(
          () async => throw RepositoryValidationException('bad'),
          area: 'data.test',
          opName: 'validate',
        ),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('maps unknown errors to UnknownFailure', () async {
      expect(
        () => FailureGuard.run(
          () async => throw StateError('boom'),
          area: 'data.test',
          opName: 'explode',
        ),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
