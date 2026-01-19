@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/queries.dart';

void main() {
  testSafe(
    'EvaluationContext normalizes today to date-only UTC midnight',
    () async {
      final ctx = EvaluationContext(today: DateTime(2026, 1, 18, 23, 59));

      expect(ctx.today, DateTime.utc(2026, 1, 18));
      expect(ctx.today.isUtc, isTrue);
    },
  );

  testSafe(
    'EvaluationContext.forDate produces equivalent normalization',
    () async {
      final ctx = EvaluationContext.forDate(DateTime(2026, 1, 18, 1, 2, 3));

      expect(ctx.today, DateTime.utc(2026, 1, 18));
    },
  );
}
