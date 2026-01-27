@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/project_predicate.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, ValueOperator;
import 'package:taskly_domain/src/queries/value_match_mode.dart';

void main() {
  testSafe('ProjectQuery.all uses default sort criteria', () async {
    final q = ProjectQuery.all();
    expect(q.sortCriteria, hasLength(2));
    expect(q.sortCriteria[0].field, SortField.deadlineDate);
    expect(q.sortCriteria[1].field, SortField.name);
  });

  testSafe(
    'ProjectQuery.incomplete builds completed=false predicate',
    () async {
      final q = ProjectQuery.incomplete();

      final p = q.filter.shared.whereType<ProjectBoolPredicate>().single;
      expect(p.operator, BoolOperator.isFalse);
    },
  );

  testSafe('ProjectQuery.byValues maps match mode to ValueOperator', () async {
    final anyQ = ProjectQuery.byValues(const ['a'], mode: ValueMatchMode.any);
    final allQ = ProjectQuery.byValues(const ['a'], mode: ValueMatchMode.all);
    final noneQ = ProjectQuery.byValues(
      const ['a'],
      mode: ValueMatchMode.none,
    );

    expect(
      anyQ.filter.shared.whereType<ProjectValuePredicate>().single.operator,
      ValueOperator.hasAny,
    );
    expect(
      allQ.filter.shared.whereType<ProjectValuePredicate>().single.operator,
      ValueOperator.hasAll,
    );
    expect(
      noneQ.filter.shared.whereType<ProjectValuePredicate>().single.operator,
      ValueOperator.isNull,
    );
  });

  testSafe('ProjectQuery JSON roundtrip', () async {
    final q = ProjectQuery.incomplete();
    final decoded = ProjectQuery.fromJson(q.toJson());

    expect(decoded, equals(q));
  });

  testSafe('ProjectQuery.fromJson handles missing optional fields', () async {
    final decoded = ProjectQuery.fromJson(const <String, dynamic>{});
    expect(decoded.filter, const QueryFilter<ProjectPredicate>.matchAll());
    expect(decoded.sortCriteria, isEmpty);
    expect(decoded.occurrenceExpansion, isNull);
  });
}
