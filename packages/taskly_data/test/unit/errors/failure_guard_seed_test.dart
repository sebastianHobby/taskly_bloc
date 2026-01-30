@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('FailureGuard maps exceptions into AppFailure', () async {
    final context = systemOperationContext(
      feature: 'seed',
      intent: 'seed_failure_guard',
      operation: 'data.failureGuard.seed',
    );

    await expectLater(
      () => FailureGuard.run<void>(
        () async => throw RepositoryValidationException('bad input'),
        area: 'data.seed',
        opName: 'create',
        context: context,
      ),
      throwsA(isA<InputValidationFailure>()),
    );
  });

  testSafe('FailureGuard passes through AppFailure', () async {
    await expectLater(
      () => FailureGuard.run<void>(
        () async => throw const NotFoundFailure(message: 'missing'),
        area: 'data.seed',
        opName: 'delete',
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
