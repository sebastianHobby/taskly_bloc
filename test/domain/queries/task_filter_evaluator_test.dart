import 'package:flutter_test/flutter_test.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('TaskFilterEvaluator', () {
    test('includeInherited only applies when task has no values', () {
      final now = DateTime.utc(2026, 1, 1);

      const projectValueId = 'value-project';
      const taskValueId = 'value-task';

      final projectValue = Value(
        id: projectValueId,
        createdAt: now,
        updatedAt: now,
        name: 'Health',
        priority: ValuePriority.medium,
      );
      final taskValue = Value(
        id: taskValueId,
        createdAt: now,
        updatedAt: now,
        name: 'Work',
        priority: ValuePriority.medium,
      );

      final project = Project(
        id: 'project-1',
        createdAt: now,
        updatedAt: now,
        name: 'P1',
        completed: false,
        values: [projectValue],
        primaryValueId: projectValueId,
      );

      final inheritingTask = Task(
        id: 'task-inherit',
        createdAt: now,
        updatedAt: now,
        name: 'Inherit',
        completed: false,
        project: project,
        values: const [],
      );

      final overridingTask = Task(
        id: 'task-override',
        createdAt: now,
        updatedAt: now,
        name: 'Override',
        completed: false,
        project: project,
        values: [taskValue],
        overridePrimaryValueId: taskValueId,
      );

      const evaluator = TaskFilterEvaluator();
      final ctx = EvaluationContext(today: now);

      final filter = QueryFilter<TaskPredicate>(
        shared: const [
          TaskValuePredicate(
            operator: ValueOperator.hasAll,
            valueIds: [projectValueId],
            includeInherited: true,
          ),
        ],
      );

      expect(evaluator.matches(inheritingTask, filter, ctx), isTrue);
      expect(evaluator.matches(overridingTask, filter, ctx), isFalse);
    });
  });
}
