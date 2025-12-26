import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';

void main() {
  group('Task', () {
    final now = DateTime(2025, 12, 26);

    test('creates instance with required fields', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.id, 'task-1');
      expect(task.name, 'Test Task');
      expect(task.completed, isFalse);
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
      expect(task.startDate, isNull);
      expect(task.deadlineDate, isNull);
      expect(task.description, isNull);
      expect(task.projectId, isNull);
      expect(task.repeatIcalRrule, isNull);
      expect(task.repeatFromCompletion, isFalse);
      expect(task.seriesEnded, isFalse);
      expect(task.project, isNull);
      expect(task.labels, isEmpty);
      expect(task.occurrence, isNull);
    });

    test('creates instance with all fields', () {
      final startDate = DateTime(2025, 12, 25);
      final deadlineDate = DateTime(2025, 12, 31);
      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );
      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final occurrence = OccurrenceData(
        date: deadlineDate,
        deadline: deadlineDate,
        originalDate: startDate,
        isRescheduled: true,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: true,
        createdAt: now,
        updatedAt: now,
        startDate: startDate,
        deadlineDate: deadlineDate,
        description: 'Test description',
        projectId: 'project-1',
        repeatIcalRrule: 'FREQ=DAILY',
        repeatFromCompletion: true,
        seriesEnded: true,
        project: project,
        labels: labels,
        occurrence: occurrence,
      );

      expect(task.startDate, startDate);
      expect(task.deadlineDate, deadlineDate);
      expect(task.description, 'Test description');
      expect(task.projectId, 'project-1');
      expect(task.repeatIcalRrule, 'FREQ=DAILY');
      expect(task.repeatFromCompletion, isTrue);
      expect(task.seriesEnded, isTrue);
      expect(task.project, project);
      expect(task.labels, labels);
      expect(task.occurrence, occurrence);
    });

    test('isOccurrenceInstance returns false when occurrence is null', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isOccurrenceInstance, isFalse);
    });

    test('isOccurrenceInstance returns true when occurrence is set', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        occurrence: OccurrenceData(
          date: now,
          originalDate: now,
          isRescheduled: false,
        ),
      );

      expect(task.isOccurrenceInstance, isTrue);
    });

    test('isRepeating returns false when repeatIcalRrule is null', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task.isRepeating, isFalse);
    });

    test('isRepeating returns false when repeatIcalRrule is empty', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        repeatIcalRrule: '',
      );

      expect(task.isRepeating, isFalse);
    });

    test('isRepeating returns true when repeatIcalRrule is set', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        repeatIcalRrule: 'FREQ=WEEKLY',
      );

      expect(task.isRepeating, isTrue);
    });

    test('copyWith creates new instance with updated fields', () {
      final task = Task(
        id: 'task-1',
        name: 'Original Name',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(
        name: 'Updated Name',
        completed: true,
        description: 'New description',
      );

      expect(updated.id, task.id);
      expect(updated.name, 'Updated Name');
      expect(updated.completed, isTrue);
      expect(updated.description, 'New description');
      expect(updated.createdAt, task.createdAt);
      expect(updated.updatedAt, task.updatedAt);
    });

    test('copyWith preserves unchanged fields', () {
      final startDate = DateTime(2025, 12, 25);
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        startDate: startDate,
        description: 'Original description',
      );

      final updated = task.copyWith(name: 'Updated Name');

      expect(updated.name, 'Updated Name');
      expect(updated.description, task.description);
      expect(updated.startDate, task.startDate);
      expect(updated.completed, task.completed);
    });

    test('equality compares all fields', () {
      final task1 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task1, equals(task2));
    });

    test('equality returns false for different tasks', () {
      final task1 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task1, isNot(equals(task2)));
    });

    test('equality considers labels', () {
      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final task1 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
        labels: labels,
      );

      final task2 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task1, isNot(equals(task2)));
    });

    test('hashCode is consistent with equality', () {
      final task1 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('copyWith updates project', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final project = Project(
        id: 'project-1',
        name: 'Test Project',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(project: project);

      expect(updated.project, equals(project));
    });

    test('copyWith updates labels', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final labels = [
        Label(
          id: 'label-1',
          name: 'Important',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final updated = task.copyWith(labels: labels);

      expect(updated.labels, equals(labels));
    });

    test('copyWith updates occurrence', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final occurrence = OccurrenceData(
        date: now.add(const Duration(days: 7)),
        originalDate: now,
        isRescheduled: true,
      );

      final updated = task.copyWith(occurrence: occurrence);

      expect(updated.occurrence, equals(occurrence));
    });

    test('copyWith with repeatFromCompletion', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(repeatFromCompletion: true);

      expect(updated.repeatFromCompletion, isTrue);
    });

    test('copyWith with seriesEnded', () {
      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(seriesEnded: true);

      expect(updated.seriesEnded, isTrue);
    });
  });
}
