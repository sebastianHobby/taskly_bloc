@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/occurrence_expansion.dart';
import 'package:taskly_domain/src/queries/project_predicate.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, DateOperator, ValueOperator;
import 'package:taskly_domain/src/queries/value_match_mode.dart';

void main() {
  testSafe('ProjectQuery.byId builds id predicate', () async {
    final q = ProjectQuery.byId('p1');

    expect(q.filter.shared.single, equals(const ProjectIdPredicate(id: 'p1')));
    expect(q.hasDateFilter, isFalse);
    expect(q.shouldExpandOccurrences, isFalse);
  });

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

  testSafe('ProjectQuery.completed builds completed=true predicate', () async {
    final q = ProjectQuery.completed();

    final p = q.filter.shared.whereType<ProjectBoolPredicate>().single;
    expect(p.operator, BoolOperator.isTrue);
  });

  testSafe('ProjectQuery.active is an alias for incomplete', () async {
    expect(ProjectQuery.active(), equals(ProjectQuery.incomplete()));
  });

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

  testSafe(
    'ProjectQuery.schedule builds OR groups and occurrenceExpansion',
    () async {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 31);

      final q = ProjectQuery.schedule(rangeStart: start, rangeEnd: end);

      expect(q.filter.shared, hasLength(1));
      expect(q.filter.orGroups, hasLength(2));
      expect(q.shouldExpandOccurrences, isTrue);
      expect(q.hasDateFilter, isTrue);
      expect(
        q.occurrenceExpansion,
        equals(
          OccurrenceExpansion(
            rangeStart: start,
            rangeEnd: end,
          ),
        ),
      );

      final g0 = q.filter.orGroups[0].single as ProjectDatePredicate;
      expect(g0.field, ProjectDateField.startDate);
      expect(g0.operator, DateOperator.between);

      final g1 = q.filter.orGroups[1].single as ProjectDatePredicate;
      expect(g1.field, ProjectDateField.deadlineDate);
      expect(g1.operator, DateOperator.between);
    },
  );

  testSafe('ProjectQuery JSON roundtrip', () async {
    final q = ProjectQuery.byId('p1');
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
