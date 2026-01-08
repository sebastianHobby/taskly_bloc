import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';

void main() {
  group('TaskEffectiveValuesX', () {
    test('uses explicit task values when present', () {
      final now = DateTime.utc(2026, 1, 1);

      const valueAId = 'value-a';
      const valueBId = 'value-b';

      final valueA = Value(
        id: valueAId,
        createdAt: now,
        updatedAt: now,
        name: 'Health',
        priority: ValuePriority.medium,
      );
      final valueB = Value(
        id: valueBId,
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
        values: [valueA],
        primaryValueId: valueAId,
      );

      final task = Task(
        id: 'task-1',
        createdAt: now,
        updatedAt: now,
        name: 'T1',
        completed: false,
        project: project,
        values: [valueB],
        primaryValueId: valueBId,
      );

      expect(task.isInheritingValues, isFalse);
      expect(task.effectiveValues, [valueB]);
      expect(task.effectivePrimaryValueId, valueBId);
      expect(task.effectivePrimaryValue, valueB);
      expect(task.effectiveSecondaryValues, isEmpty);
      expect(task.isEffectivelyValueless, isFalse);
    });

    test('inherits project values when task has none', () {
      final now = DateTime.utc(2026, 1, 1);

      const valueAId = 'value-a';
      const valueBId = 'value-b';

      final valueA = Value(
        id: valueAId,
        createdAt: now,
        updatedAt: now,
        name: 'Health',
        priority: ValuePriority.medium,
      );
      final valueB = Value(
        id: valueBId,
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
        values: [valueA, valueB],
        primaryValueId: valueAId,
      );

      final task = Task(
        id: 'task-1',
        createdAt: now,
        updatedAt: now,
        name: 'T1',
        completed: false,
        project: project,
        values: const [],
      );

      expect(task.isInheritingValues, isTrue);
      expect(task.effectiveValues, [valueA, valueB]);
      expect(task.effectivePrimaryValueId, valueAId);
      expect(task.effectivePrimaryValue, valueA);
      expect(task.effectiveSecondaryValues, [valueB]);
      expect(task.isEffectivelyValueless, isFalse);
    });

    test('is valueless when both task and project have none', () {
      final now = DateTime.utc(2026, 1, 1);

      final task = Task(
        id: 'task-1',
        createdAt: now,
        updatedAt: now,
        name: 'T1',
        completed: false,
        values: const [],
      );

      expect(task.isInheritingValues, isFalse);
      expect(task.effectiveValues, isEmpty);
      expect(task.effectivePrimaryValueId, isNull);
      expect(task.effectivePrimaryValue, isNull);
      expect(task.effectiveSecondaryValues, isEmpty);
      expect(task.isEffectivelyValueless, isTrue);
    });
  });
}
