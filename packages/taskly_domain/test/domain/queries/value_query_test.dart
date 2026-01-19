@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/value_predicate.dart';
import 'package:taskly_domain/src/queries/value_query.dart';

void main() {
  testSafe('ValueQuery.all uses default sort criteria', () async {
    final q = ValueQuery.all();
    expect(q.sortCriteria, hasLength(1));
    expect(q.sortCriteria.single.field, SortField.name);
    expect(q.sortCriteria.single.direction, SortDirection.ascending);
  });

  testSafe('ValueQuery.byId hasIdFilter and builds shared predicate', () async {
    final q = ValueQuery.byId('v1');

    expect(q.hasIdFilter, isTrue);
    expect(
      q.filter.shared.single,
      equals(const ValueIdPredicate(valueId: 'v1')),
    );
  });

  testSafe('ValueQuery.byIds builds ids predicate and hasIdFilter', () async {
    final q = ValueQuery.byIds(const ['a', 'b']);

    expect(q.hasIdFilter, isTrue);
    expect(
      q.filter.shared.single,
      equals(const ValueIdsPredicate(valueIds: ['a', 'b'])),
    );
  });

  testSafe('ValueQuery.search builds name contains predicate', () async {
    final q = ValueQuery.search('foo');

    final p = q.filter.shared.whereType<ValueNamePredicate>().single;
    expect(p.operator, StringOperator.contains);
    expect(p.value, 'foo');
  });

  testSafe('ValueQuery.byColor builds color predicate', () async {
    final q = ValueQuery.byColor('#000000');

    expect(
      q.filter.shared.single,
      equals(const ValueColorPredicate(colorHex: '#000000')),
    );
  });

  testSafe('ValueQuery JSON roundtrip', () async {
    final q = ValueQuery.search('x').addPredicate(
      const ValueColorPredicate(colorHex: '#000000'),
    );

    final decoded = ValueQuery.fromJson(q.toJson());
    expect(decoded, equals(q));
  });

  testSafe('ValueQuery.copyWith replaces fields', () async {
    final base = ValueQuery.byId('v1');
    final updated = base.copyWith(
      sortCriteria: const [SortCriterion(field: SortField.name)],
    );

    expect(updated.filter, base.filter);
    expect(updated.sortCriteria, isNot(equals(base.sortCriteria)));
  });
}
