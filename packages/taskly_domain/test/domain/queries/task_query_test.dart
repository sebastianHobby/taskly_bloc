@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';
import 'package:taskly_domain/src/queries/value_match_mode.dart';

void main() {
  testSafe('TaskQuery.inbox builds expected shared predicates', () async {
    final q = TaskQuery.inbox();

    expect(q.filter.shared, hasLength(2));
    expect(q.filter.shared[0], isA<TaskBoolPredicate>());
    expect(q.filter.shared[1], isA<TaskProjectPredicate>());

    final boolP = q.filter.shared[0] as TaskBoolPredicate;
    expect(boolP.operator, BoolOperator.isFalse);

    final projectP = q.filter.shared[1] as TaskProjectPredicate;
    expect(projectP.operator, ProjectOperator.isNull);
  });

  testSafe('TaskQuery.today uses dateOnly(now) for onOrBefore', () async {
    final q = TaskQuery.today(now: DateTime.utc(2026, 1, 18, 10));

    final dateP = q.filter.shared.whereType<TaskDatePredicate>().single;
    expect(dateP.operator, DateOperator.onOrBefore);
    expect(dateP.date, DateTime.utc(2026, 1, 18));
  });

  testSafe(
    'TaskQuery.schedule builds OR groups and occurrenceExpansion',
    () async {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 31);

      final q = TaskQuery.schedule(rangeStart: start, rangeEnd: end);

      expect(q.filter.orGroups, hasLength(2));
      expect(q.occurrenceExpansion, isNotNull);
      expect(q.occurrenceExpansion!.rangeStart, start);
      expect(q.occurrenceExpansion!.rangeEnd, end);
    },
  );

  testSafe('TaskQuery JSON roundtrip', () async {
    final q = TaskQuery.incomplete();
    final decoded = TaskQuery.fromJson(q.toJson());

    expect(decoded, equals(q));
  });

  testSafe(
    'TaskQuery.upcoming requires incomplete + deadline isNotNull',
    () async {
      final q = TaskQuery.upcoming();

      expect(
        q.filter.shared.whereType<TaskBoolPredicate>().single.operator,
        BoolOperator.isFalse,
      );

      final dateP = q.filter.shared.whereType<TaskDatePredicate>().single;
      expect(dateP.field, TaskDateField.deadlineDate);
      expect(dateP.operator, DateOperator.isNotNull);
      expect(q.hasDateFilter, isTrue);
      expect(q.shouldExpandOccurrences, isFalse);
    },
  );

  testSafe('TaskQuery.forProject and byProject set hasProjectFilter', () async {
    final q1 = TaskQuery.forProject(projectId: 'p1');
    final q2 = TaskQuery.byProject('p1');

    expect(q1, equals(q2));
    expect(q1.hasProjectFilter, isTrue);

    final p = q1.filter.shared.whereType<TaskProjectPredicate>().single;
    expect(p.operator, ProjectOperator.matches);
    expect(p.projectId, 'p1');
  });

  testSafe('TaskQuery.forValue defaults includeInherited=true', () async {
    final q = TaskQuery.forValue(valueId: 'v1');

    final p = q.filter.shared.whereType<TaskValuePredicate>().single;
    expect(p.operator, ValueOperator.hasAll);
    expect(p.valueIds, ['v1']);
    expect(p.includeInherited, isTrue);
  });

  testSafe('TaskQuery.forValue supports includeInherited=false', () async {
    final q = TaskQuery.forValue(valueId: 'v1', includeInherited: false);

    final p = q.filter.shared.whereType<TaskValuePredicate>().single;
    expect(p.includeInherited, isFalse);
  });

  testSafe('TaskQuery.byValues maps match mode to ValueOperator', () async {
    final anyQ = TaskQuery.byValues(const ['a'], mode: ValueMatchMode.any);
    final allQ = TaskQuery.byValues(const ['a'], mode: ValueMatchMode.all);
    final noneQ = TaskQuery.byValues(const ['a'], mode: ValueMatchMode.none);

    expect(
      anyQ.filter.shared.whereType<TaskValuePredicate>().single.operator,
      ValueOperator.hasAny,
    );
    expect(
      allQ.filter.shared.whereType<TaskValuePredicate>().single.operator,
      ValueOperator.hasAll,
    );
    expect(
      noneQ.filter.shared.whereType<TaskValuePredicate>().single.operator,
      ValueOperator.isNull,
    );
  });

  testSafe('TaskQuery.dueToday uses between [today, today+1d)', () async {
    final today = DateTime.utc(2026, 1, 18);
    final q = TaskQuery.dueToday(todayDayKeyUtc: today);

    final p = q.filter.shared.whereType<TaskDatePredicate>().single;
    expect(p.operator, DateOperator.between);
    expect(p.startDate, today);
    expect(p.endDate, DateTime.utc(2026, 1, 19));
  });

  testSafe('TaskQuery.dueThisWeek aligns start to Monday', () async {
    // Wednesday.
    final today = DateTime.utc(2026, 1, 7);
    final q = TaskQuery.dueThisWeek(todayDayKeyUtc: today);

    final p = q.filter.shared.whereType<TaskDatePredicate>().single;
    expect(p.operator, DateOperator.between);
    expect(p.startDate, DateTime.utc(2026, 1, 5));
    expect(p.endDate, DateTime.utc(2026, 1, 12));
  });

  testSafe('TaskQuery.overdue uses before startOfDay and incomplete', () async {
    final today = DateTime.utc(2026, 1, 18);
    final q = TaskQuery.overdue(todayDayKeyUtc: today);

    final dateP = q.filter.shared.whereType<TaskDatePredicate>().single;
    expect(dateP.operator, DateOperator.before);
    expect(dateP.date, today);

    final boolP = q.filter.shared.whereType<TaskBoolPredicate>().single;
    expect(boolP.operator, BoolOperator.isFalse);
  });

  testSafe(
    'copyWith(clearOccurrenceExpansion) removes occurrenceExpansion',
    () async {
      final q = TaskQuery.schedule(
        rangeStart: DateTime.utc(2026, 1, 1),
        rangeEnd: DateTime.utc(2026, 1, 2),
      );
      expect(q.shouldExpandOccurrences, isTrue);

      final cleared = q.copyWith(clearOccurrenceExpansion: true);
      expect(cleared.shouldExpandOccurrences, isFalse);
    },
  );

  testSafe('withAdditionalPredicates appends to shared predicates', () async {
    final q = TaskQuery.incomplete().withAdditionalPredicates(
      const [
        TaskProjectPredicate(operator: ProjectOperator.isNotNull),
      ],
    );

    expect(q.filter.shared.whereType<TaskProjectPredicate>(), hasLength(1));
    expect(q.hasProjectFilter, isTrue);
  });
}
