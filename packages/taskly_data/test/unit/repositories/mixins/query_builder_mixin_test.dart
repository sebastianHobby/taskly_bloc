@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:drift/drift.dart';
import 'package:taskly_data/src/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_domain/queries.dart';

import '../../../helpers/fixed_clock.dart';

final class _Harness with QueryBuilderMixin {
  _Harness({required this.clock});

  @override
  final FixedClock clock;

  Expression<bool> toExpr(bool value) => Constant(value);
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('QueryBuilderMixin', () {
    testSafe('whereExpressionFromFilter returns null for matchAll', () async {
      final h = _Harness(clock: FixedClock(DateTime(2025, 1, 1)));
      final expr = h.whereExpressionFromFilter<bool>(
        filter: const QueryFilter<bool>.matchAll(),
        predicateToExpression: h.toExpr,
      );

      expect(expr, equals(null));
    });

    testSafe(
      'whereExpressionFromFilter combines shared AND (orGroups OR)',
      () async {
        final h = _Harness(clock: FixedClock(DateTime(2025, 1, 1)));

        final expr = h.whereExpressionFromFilter<bool>(
          filter: const QueryFilter<bool>(
            shared: [true],
            orGroups: [
              [true, true],
              [false],
            ],
          ),
          predicateToExpression: h.toExpr,
        );

        expect(expr, isNot(equals(null)));
      },
    );

    testSafe(
      'relativeToAbsolute uses injected Clock and normalizes to midnight',
      () async {
        final h = _Harness(clock: FixedClock(DateTime(2025, 1, 15, 18, 30)));

        final today = h.relativeToAbsolute(0);
        final next = h.relativeToAbsolute(1);

        expect(today, equals(DateTime(2025, 1, 15)));
        expect(next, equals(DateTime(2025, 1, 16)));
      },
    );
  });
}
