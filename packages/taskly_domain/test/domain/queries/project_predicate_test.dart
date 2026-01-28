@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/project_predicate.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, DateOperator, RelativeComparison, ValueOperator;

void main() {
  testSafe('ProjectPredicate.fromJson throws on unknown type', () async {
    expect(
      () => ProjectPredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
      throwsArgumentError,
    );
  });

  testSafe('ProjectIdPredicate JSON roundtrip', () async {
    const p = ProjectIdPredicate(id: 'p1');

    final decoded = ProjectPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ProjectBoolPredicate JSON roundtrip', () async {
    const p = ProjectBoolPredicate(
      field: ProjectBoolField.completed,
      operator: BoolOperator.isFalse,
    );

    final decoded = ProjectPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ProjectBoolPredicate JSON roundtrip (repeating)', () async {
    const p = ProjectBoolPredicate(
      field: ProjectBoolField.repeating,
      operator: BoolOperator.isTrue,
    );

    final decoded = ProjectPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ProjectBoolPredicate.fromJson uses defaults', () async {
    final decoded = ProjectBoolPredicate.fromJson(const <String, dynamic>{
      'type': 'bool',
    });

    expect(decoded.field, ProjectBoolField.completed);
    expect(decoded.operator, BoolOperator.isFalse);
  });

  testSafe('ProjectDatePredicate equality uses moment equality', () async {
    final a = DateTime.parse('2026-01-01T00:00:00Z');
    final b = DateTime.parse('2025-12-31T19:00:00-05:00');

    final p1 = ProjectDatePredicate(
      field: ProjectDateField.createdAt,
      operator: DateOperator.on,
      date: a,
    );
    final p2 = ProjectDatePredicate(
      field: ProjectDateField.createdAt,
      operator: DateOperator.on,
      date: b,
    );

    expect(p1, equals(p2));
    expect(p1.hashCode, equals(p2.hashCode));
  });

  testSafe('ProjectDatePredicate JSON roundtrip (relative)', () async {
    const p = ProjectDatePredicate(
      field: ProjectDateField.deadlineDate,
      operator: DateOperator.relative,
      relativeComparison: RelativeComparison.onOrAfter,
      relativeDays: 2,
    );

    final decoded = ProjectPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe(
    'ProjectDatePredicate.fromJson uses defaults and parses dates',
    () async {
      final decoded = ProjectDatePredicate.fromJson(const <String, dynamic>{
        'type': 'date',
        'date': '2026-01-01T10:20:30Z',
        'startDate': '2026-01-02',
        'endDate': '2026-01-03',
      });

      expect(decoded.field, ProjectDateField.createdAt);
      expect(decoded.operator, DateOperator.isNotNull);
      expect(decoded.date, DateTime.parse('2026-01-01T10:20:30Z'));
      expect(decoded.startDate, DateTime.parse('2026-01-02'));
      expect(decoded.endDate, DateTime.parse('2026-01-03'));
    },
  );

  testSafe('ProjectValuePredicate JSON roundtrip', () async {
    const p = ProjectValuePredicate(
      operator: ValueOperator.hasAll,
      valueIds: ['v1', 'v2'],
    );

    final decoded = ProjectPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ProjectValuePredicate.fromJson uses defaults', () async {
    final decoded = ProjectValuePredicate.fromJson(const <String, dynamic>{
      'type': 'value',
    });

    expect(decoded.operator, ValueOperator.hasAny);
    expect(decoded.valueIds, isEmpty);
  });
}
