@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/operators/value_comparison.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  testSafe('ValueComparison hasAny/hasAll membership', () async {
    final entity = <String>{'a', 'b'};

    expect(
      ValueComparison.evaluate(
        entityValueIds: entity,
        predicateValueIds: const ['b', 'x'],
        operator: ValueOperator.hasAny,
      ),
      isTrue,
    );

    expect(
      ValueComparison.evaluate(
        entityValueIds: entity,
        predicateValueIds: const ['a', 'b'],
        operator: ValueOperator.hasAll,
      ),
      isTrue,
    );
  });

  testSafe('ValueComparison null checks', () async {
    expect(
      ValueComparison.evaluate(
        entityValueIds: <String>{},
        predicateValueIds: const ['a'],
        operator: ValueOperator.isNull,
      ),
      isTrue,
    );

    expect(
      ValueComparison.evaluate(
        entityValueIds: <String>{'a'},
        predicateValueIds: const ['a'],
        operator: ValueOperator.isNotNull,
      ),
      isTrue,
    );
  });
}
