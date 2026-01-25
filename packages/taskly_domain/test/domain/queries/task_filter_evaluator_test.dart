@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/src/filtering/evaluation_context.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_filter_evaluator.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

void main() {
  final evaluator = TaskFilterEvaluator();

  Value value(String id) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'V$id',
    );
  }

  Task task({
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    Project? project,
    List<Value> values = const <Value>[],
    OccurrenceData? occurrence,
  }) {
    return Task(
      id: 't1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Task',
      completed: completed,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      project: project,
      values: values,
      occurrence: occurrence,
    );
  }

  final ctx = EvaluationContext(today: DateTime.utc(2026, 1, 18));

  testSafe('matches returns true for matchAll', () async {
    final t = task();
    const filter = QueryFilter<TaskPredicate>.matchAll();

    expect(evaluator.matches(t, filter, ctx), isTrue);
  });

  testSafe('shared predicates must all match', () async {
    final t = task(completed: false);
    const filter = QueryFilter<TaskPredicate>(
      shared: [
        TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        ),
      ],
    );

    expect(evaluator.matches(t, filter, ctx), isFalse);
  });

  testSafe('orGroups are evaluated as one-level OR of AND groups', () async {
    final t = task(projectId: 'p1', completed: false);

    final filter = QueryFilter<TaskPredicate>(
      shared: const [
        TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        ),
      ],
      orGroups: const [
        [
          TaskProjectPredicate(
            operator: ProjectOperator.matches,
            projectId: 'p1',
          ),
        ],
        [
          TaskProjectPredicate(
            operator: ProjectOperator.matches,
            projectId: 'p2',
          ),
        ],
      ],
    );

    expect(evaluator.matches(t, filter, ctx), isTrue);
  });

  testSafe('date relative uses ctx.today as pivot base', () async {
    final t = task(deadlineDate: DateTime.utc(2026, 1, 20, 12));

    final filter = QueryFilter<TaskPredicate>(
      shared: const [
        TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.on,
          relativeDays: 2,
        ),
      ],
    );

    expect(evaluator.matches(t, filter, ctx), isTrue);
  });

  testSafe(
    'value includeInherited uses project values when task has no overrides',
    () async {
      final p = Project(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        values: [value('v1')],
      );

      final t = task(projectId: 'p1', project: p, values: const <Value>[]);

      final filter = QueryFilter<TaskPredicate>(
        shared: const [
          TaskValuePredicate(
            operator: ValueOperator.hasAll,
            valueIds: ['v1'],
            includeInherited: true,
          ),
        ],
      );

      expect(evaluator.matches(t, filter, ctx), isTrue);
    },
  );

  testSafe(
    'value includeInherited treats project values and task tags as a union',
    () async {
      final v1 = value('v1');
      final v2 = value('v2');
      final p = Project(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        values: [v1],
        primaryValueId: 'v1',
      );

      final t = task(
        projectId: 'p1',
        project: p,
        values: [v2],
      );

      final filter = QueryFilter<TaskPredicate>(
        shared: const [
          TaskValuePredicate(
            operator: ValueOperator.hasAll,
            valueIds: ['v1', 'v2'],
            includeInherited: true,
          ),
        ],
      );

      expect(evaluator.matches(t, filter, ctx), isTrue);
    },
  );
}
