import '../../helpers/test_imports.dart';

@Tags(['unit'])
import 'package:taskly_domain/src/errors/app_failure.dart';

void main() {
  testSafe('AppFailure.uiMessage uses provided message', () async {
    const failure = NetworkFailure(message: 'Custom message');

    expect(failure.uiMessage(), 'Custom message');
  });

  testSafe('AppFailure.uiMessage falls back per kind', () async {
    const failure = NotFoundFailure();

    expect(failure.uiMessage(), 'Not found');
  });

  testSafe('UnknownFailure reports as unexpected', () async {
    const failure = UnknownFailure();

    expect(failure.reportAsUnexpected, isTrue);
  });

  testSafe('AppFailure.toString includes kind and cause type', () async {
    final failure = AuthFailure(cause: StateError('boom'));

    expect(failure.toString(), contains('kind=AppFailureKind.auth'));
    expect(failure.toString(), contains('cause=StateError'));
  });
}
