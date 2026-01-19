@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/operators/bool_comparison.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  testSafe('BoolComparison evaluates isTrue/isFalse', () async {
    expect(
      BoolComparison.evaluate(fieldValue: true, operator: BoolOperator.isTrue),
      isTrue,
    );
    expect(
      BoolComparison.evaluate(fieldValue: true, operator: BoolOperator.isFalse),
      isFalse,
    );
  });
}
