@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:drift/drift.dart';
import 'package:taskly_data/src/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_domain/queries.dart';

void main() {
  testSafe('boolComparison supports true/false operators', () async {
    final column = const Constant(true);

    final whenTrue = SqlComparisonBuilder.boolComparison(
      column,
      BoolOperator.isTrue,
    );
    final whenFalse = SqlComparisonBuilder.boolComparison(
      column,
      BoolOperator.isFalse,
    );

    expect(whenTrue, isA<Expression<bool>>());
    expect(whenFalse, isA<Expression<bool>>());
  });

  testSafe('dateTimeComparison handles all non-relative operators', () async {
    final Expression<DateTime> column = Variable<DateTime>(
      DateTime.utc(2026, 1, 1),
    );
    final date = DateTime.utc(2026, 1, 2);

    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.on,
        date: date,
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.before,
        date: date,
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.after,
        date: date,
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.onOrBefore,
        date: date,
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.onOrAfter,
        date: date,
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(
        column,
        DateOperator.between,
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 1, 3),
      ),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(column, DateOperator.isNull),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(column, DateOperator.isNotNull),
      isA<Expression<bool>>(),
    );
    expect(
      SqlComparisonBuilder.dateTimeComparison(column, DateOperator.relative),
      isA<Constant<bool>>(),
    );
  });

  testSafe(
    'textDate builders support absolute and relative comparisons',
    () async {
      final column = const Constant('2026-01-01');
      final pivot = DateTime.utc(2026, 1, 2);

      expect(
        SqlComparisonBuilder.textDateComparison(
          column,
          DateOperator.on,
          date: '2026-01-01',
        ),
        isA<Expression<bool>>(),
      );
      expect(
        SqlComparisonBuilder.textDateComparison(
          column,
          DateOperator.between,
          startDate: '2026-01-01',
          endDate: '2026-01-03',
        ),
        isA<Expression<bool>>(),
      );
      expect(
        SqlComparisonBuilder.textDateComparison(column, DateOperator.relative),
        isA<Constant<bool>>(),
      );
      expect(
        SqlComparisonBuilder.relativeTextDateComparison(
          column,
          RelativeComparison.onOrAfter,
          '2026-01-02',
        ),
        isA<Expression<bool>>(),
      );
      expect(
        SqlComparisonBuilder.textDateComparisonFromDateTime(
          column,
          DateOperator.onOrBefore,
          date: pivot,
        ),
        isA<Expression<bool>>(),
      );
      expect(
        SqlComparisonBuilder.relativeTextDateComparisonFromDateTime(
          column,
          RelativeComparison.before,
          pivot,
        ),
        isA<Expression<bool>>(),
      );
    },
  );
}
