@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  testSafe('TaskPredicate.fromJson throws on unknown type', () async {
    expect(
      () => TaskPredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
      throwsArgumentError,
    );
  });

  testSafe('TaskBoolPredicate json roundtrip and defaults', () async {
    const p = TaskBoolPredicate(
      field: TaskBoolField.completed,
      operator: BoolOperator.isTrue,
    );

    final decoded = TaskPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));

    final withDefaults = TaskBoolPredicate.fromJson(const <String, dynamic>{
      'type': 'bool',
    });

    expect(withDefaults.field, TaskBoolField.completed);
    expect(withDefaults.operator, BoolOperator.isFalse);
  });

  testSafe('TaskDatePredicate json roundtrip and relative fields', () async {
    final p = TaskDatePredicate(
      field: TaskDateField.deadlineDate,
      operator: DateOperator.relative,
      relativeComparison: RelativeComparison.onOrBefore,
      relativeDays: 2,
    );

    final decoded = TaskPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe(
    'TaskDatePredicate.fromJson uses defaults and parses dates',
    () async {
      final decoded = TaskDatePredicate.fromJson(const <String, dynamic>{
        'type': 'date',
        'date': '2026-01-01T12:34:56Z',
        'startDate': '2026-01-02',
        'endDate': '2026-01-03',
      });

      expect(decoded.field, TaskDateField.createdAt);
      expect(decoded.operator, DateOperator.isNotNull);
      expect(decoded.date, DateTime.parse('2026-01-01T12:34:56Z'));
      expect(decoded.startDate, DateTime.parse('2026-01-02'));
      expect(decoded.endDate, DateTime.parse('2026-01-03'));
    },
  );

  testSafe('TaskProjectPredicate json roundtrip', () async {
    const p = TaskProjectPredicate(
      operator: ProjectOperator.matchesAny,
      projectIds: ['p1', 'p2'],
    );

    final decoded = TaskPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('TaskProjectPredicate.fromJson uses defaults', () async {
    final decoded = TaskProjectPredicate.fromJson(const <String, dynamic>{
      'type': 'project',
    });

    expect(decoded.operator, ProjectOperator.isNotNull);
    expect(decoded.projectId, isNull);
    expect(decoded.projectIds, isEmpty);
  });

  testSafe('TaskValuePredicate json roundtrip', () async {
    const p = TaskValuePredicate(
      operator: ValueOperator.hasAll,
      valueIds: ['v1'],
      includeInherited: true,
    );

    final decoded = TaskPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('TaskValuePredicate.fromJson uses defaults', () async {
    final decoded = TaskValuePredicate.fromJson(const <String, dynamic>{
      'type': 'value',
    });

    expect(decoded.operator, ValueOperator.hasAny);
    expect(decoded.valueIds, isEmpty);
    expect(decoded.includeInherited, isFalse);
  });

  testSafe('TaskPredicateConverter delegates to TaskPredicate', () async {
    const converter = TaskPredicateConverter();
    const p = TaskBoolPredicate(
      field: TaskBoolField.completed,
      operator: BoolOperator.isTrue,
    );

    final json = converter.toJson(p);
    final decoded = converter.fromJson(json);

    expect(decoded, equals(p));
  });
}
