@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/model/occurrence_data.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/src/filtering/evaluation_context.dart';
import 'package:taskly_domain/src/queries/project_filter_evaluator.dart';
import 'package:taskly_domain/src/queries/project_predicate.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, DateOperator, RelativeComparison, ValueOperator;

void main() {
  Project baseProject({
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime? completedAt,
    List<Value> values = const <Value>[],
  }) {
    return Project(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'P',
      completed: completed,
      startDate: startDate,
      deadlineDate: deadlineDate,
      values: values,
      occurrence: completedAt == null
          ? null
          : OccurrenceData(
              date: DateTime.utc(2026, 1, 3),
              isRescheduled: false,
              completionId: 'c1',
              completedAt: completedAt,
            ),
    );
  }

  testSafe('matches returns true for matchAll', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final ok = evaluator.matches(
      baseProject(),
      const QueryFilter<ProjectPredicate>.matchAll(),
      ctx,
    );
    expect(ok, isTrue);
  });

  testSafe('shared predicates must all match', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isTrue,
        ),
      ],
    );

    final ok = evaluator.matches(baseProject(completed: false), filter, ctx);
    expect(ok, isFalse);
  });

  testSafe('orGroups are evaluated as one-level OR of AND groups', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 1, 31);

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectBoolPredicate(
          field: ProjectBoolField.completed,
          operator: BoolOperator.isFalse,
        ),
      ],
      orGroups: [
        [
          ProjectDatePredicate(
            field: ProjectDateField.startDate,
            operator: DateOperator.between,
            startDate: start,
            endDate: end,
          ),
        ],
        [
          ProjectDatePredicate(
            field: ProjectDateField.deadlineDate,
            operator: DateOperator.between,
            startDate: start,
            endDate: end,
          ),
        ],
      ],
    );

    final ok = evaluator.matches(
      baseProject(
        completed: false,
        startDate: DateTime.utc(2025, 12, 1),
        deadlineDate: DateTime.utc(2026, 1, 20),
      ),
      filter,
      ctx,
    );

    expect(ok, isTrue);
  });

  testSafe('date relative requires comparison and days', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.relative,
        ),
      ],
    );

    final ok = evaluator.matches(
      baseProject(deadlineDate: DateTime.utc(2026, 1, 12)),
      filter,
      ctx,
    );

    expect(ok, isFalse);
  });

  testSafe('completedAt uses occurrence.completedAt', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectDatePredicate(
          field: ProjectDateField.completedAt,
          operator: DateOperator.isNotNull,
        ),
      ],
    );

    final ok = evaluator.matches(
      baseProject(completedAt: DateTime.utc(2026, 1, 10, 12)),
      filter,
      ctx,
    );

    expect(ok, isTrue);
  });

  testSafe('value predicate evaluates membership', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: ['v1', 'v2'],
        ),
      ],
    );

    final ok = evaluator.matches(
      baseProject(
        values: [
          Value(
            id: 'v1',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            name: 'V1',
          ),
          Value(
            id: 'v2',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            name: 'V2',
          ),
        ],
      ),
      filter,
      ctx,
    );

    expect(ok, isTrue);
  });

  testSafe('relative date uses ctx.today as pivot base', () async {
    const evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext.forDate(DateTime.utc(2026, 1, 10));

    final filter = QueryFilter<ProjectPredicate>(
      shared: const [
        ProjectDatePredicate(
          field: ProjectDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.on,
          relativeDays: 2,
        ),
      ],
    );

    final ok = evaluator.matches(
      baseProject(deadlineDate: DateTime.utc(2026, 1, 12)),
      filter,
      ctx,
    );

    expect(ok, isTrue);
  });
}
