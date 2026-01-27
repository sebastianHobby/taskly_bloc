@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/value_predicate.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/value_query.dart';

void main() {
  testSafe('ValueQuery.all uses default sort criteria', () async {
    final q = ValueQuery.all();
    expect(q.sortCriteria, hasLength(1));
    expect(q.sortCriteria.single.field, SortField.name);
    expect(q.sortCriteria.single.direction, SortDirection.ascending);
  });

  testSafe('ValueQuery JSON roundtrip', () async {
    final q = ValueQuery(
      filter: const QueryFilter<ValuePredicate>(
        shared: [
          ValueNamePredicate(
            value: 'x',
            operator: StringOperator.contains,
          ),
          ValueColorPredicate(colorHex: '#000000'),
        ],
      ),
    );

    final decoded = ValueQuery.fromJson(q.toJson());
    expect(decoded, equals(q));
  });

  testSafe('ValueQuery.copyWith replaces fields', () async {
    final base = ValueQuery();
    final updated = base.copyWith(
      sortCriteria: const [SortCriterion(field: SortField.name)],
    );

    expect(updated.filter, base.filter);
    expect(updated.sortCriteria, isNot(equals(base.sortCriteria)));
  });
}
