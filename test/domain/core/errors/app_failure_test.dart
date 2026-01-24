@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_domain/errors.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AppFailure', () {
    testSafe('uiMessage prefers explicit message', () async {
      const failure = AuthFailure(message: 'Sign in failed');

      expect(failure.uiMessage(), 'Sign in failed');
    });

    testSafe('uiMessage falls back by kind when message is empty', () async {
      const failure = InputValidationFailure(message: '  ');

      expect(failure.uiMessage(), 'Please check your input');
    });

    testSafe('unknown failures report as unexpected', () async {
      const failure = UnknownFailure();

      expect(failure.reportAsUnexpected, isTrue);
    });

    testSafe('toString includes kind and code', () async {
      const failure = NetworkFailure(code: 'offline');

      expect(failure.toString(), contains('AppFailureKind.network'));
      expect(failure.toString(), contains('code=offline'));
    });
  });
}
