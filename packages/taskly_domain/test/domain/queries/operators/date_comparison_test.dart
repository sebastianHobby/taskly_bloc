@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/operators/date_comparison.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  testSafe('DateComparison handles null checks', () async {
    expect(
      DateComparison.evaluate(
        fieldValue: null,
        operator: DateOperator.isNull,
      ),
      isTrue,
    );

    expect(
      DateComparison.evaluate(
        fieldValue: DateTime.utc(2026, 1, 1),
        operator: DateOperator.isNotNull,
      ),
      isTrue,
    );
  });

  testSafe('DateComparison on/before/after use date-only semantics', () async {
    final v = DateTime.utc(2026, 1, 10, 23, 59);

    expect(
      DateComparison.evaluate(
        fieldValue: v,
        operator: DateOperator.on,
        date: DateTime.utc(2026, 1, 10, 0, 1),
      ),
      isTrue,
    );

    expect(
      DateComparison.evaluate(
        fieldValue: v,
        operator: DateOperator.before,
        date: DateTime.utc(2026, 1, 11),
      ),
      isTrue,
    );

    expect(
      DateComparison.evaluate(
        fieldValue: v,
        operator: DateOperator.after,
        date: DateTime.utc(2026, 1, 9),
      ),
      isTrue,
    );
  });

  testSafe('DateComparison between is inclusive', () async {
    final v = DateTime.utc(2026, 1, 10);

    expect(
      DateComparison.evaluate(
        fieldValue: v,
        operator: DateOperator.between,
        startDate: DateTime.utc(2026, 1, 10),
        endDate: DateTime.utc(2026, 1, 10, 23, 59),
      ),
      isTrue,
    );
  });

  testSafe('DateComparison.evaluateRelative compares to pivot day', () async {
    expect(
      DateComparison.evaluateRelative(
        fieldValue: DateTime.utc(2026, 1, 10, 9),
        comparison: RelativeComparison.onOrAfter,
        pivot: DateTime.utc(2026, 1, 10, 23, 59),
      ),
      isTrue,
    );

    expect(
      DateComparison.evaluateRelative(
        fieldValue: null,
        comparison: RelativeComparison.on,
        pivot: DateTime.utc(2026, 1, 10),
      ),
      isFalse,
    );
  });
}
