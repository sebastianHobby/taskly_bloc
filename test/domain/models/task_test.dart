import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';

import '../../fixtures/test_data.dart';
import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('Task', () {
    group('construction', () {
      test('creates with required fields only', () {
        final now = DateTime.now();
        final task = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test Task',
          completed: false,
        );

        expect(task.id, 'task-1');
        expect(task.name, 'Test Task');
        expect(task.completed, false);
        expect(task.createdAt, now);
        expect(task.updatedAt, now);
      });

      test('creates with all optional fields', () {
        final now = DateTime.now();
        final deadline = now.add(const Duration(days: 7));
        final task = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Full Task',
          completed: true,
          description: 'A description',
          startDate: now,
          deadlineDate: deadline,
          projectId: 'project-1',
          priority: 1,
          repeatIcalRrule: 'FREQ=DAILY',
          repeatFromCompletion: true,
          seriesEnded: true,
          lastReviewedAt: now,
        );

        expect(task.description, 'A description');
        expect(task.startDate, now);
        expect(task.deadlineDate, deadline);
        expect(task.projectId, 'project-1');
        expect(task.priority, 1);
        expect(task.repeatIcalRrule, 'FREQ=DAILY');
        expect(task.repeatFromCompletion, true);
        expect(task.seriesEnded, true);
        expect(task.lastReviewedAt, now);
      });

      test('defaults values to empty list', () {
        final task = TestData.task();
        expect(task.values, isEmpty);
      });

      test('defaults repeatFromCompletion to false', () {
        final task = TestData.task();
        expect(task.repeatFromCompletion, false);
      });

      test('defaults seriesEnded to false', () {
        final task = TestData.task();
        expect(task.seriesEnded, false);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final now = DateTime(2025, 1, 15, 12);
        final task1 = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );
        final task2 = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );

        expect(task1, equals(task2));
        expect(task1.hashCode, equals(task2.hashCode));
      });

      test('not equal when id differs', () {
        final now = DateTime(2025, 1, 15, 12);
        final task1 = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );
        final task2 = Task(
          id: 'task-2',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          completed: false,
        );

        expect(task1, isNot(equals(task2)));
      });

      test('not equal when name differs', () {
        final now = DateTime(2025, 1, 15, 12);
        final task1 = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test A',
          completed: false,
        );
        final task2 = Task(
          id: 'task-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test B',
          completed: false,
        );

        expect(task1, isNot(equals(task2)));
      });

      test('handles null optional fields in equality', () {
        final task1 = TestData.task(id: 'same');
        final task2 = TestData.task(id: 'same');

        expect(task1.description, isNull);
        expect(task2.description, isNull);
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final task = TestData.task(name: 'Original');
        final copied = task.copyWith(name: 'Changed');

        expect(copied.name, 'Changed');
        expect(copied.id, task.id);
        expect(copied.completed, task.completed);
      });

      test('copies with new completed status', () {
        final task = TestData.task();
        final copied = task.copyWith(completed: true);

        expect(copied.completed, true);
        expect(copied.name, task.name);
      });

      test('copies with new priority', () {
        final task = TestData.task();
        final copied = task.copyWith(priority: 2);

        expect(copied.priority, 2);
      });

      test('copies with new values list', () {
        final task = TestData.task();
        final newValues = [TestData.value(name: 'New Value')];
        final copied = task.copyWith(values: newValues);

        expect(copied.values, hasLength(1));
        expect(copied.values.first.name, 'New Value');
      });

      test('preserves unchanged fields', () {
        final task = TestData.task(
          name: 'Test',
          description: 'Desc',
          priority: 1,
        );
        final copied = task.copyWith(name: 'New Name');

        expect(copied.description, 'Desc');
        expect(copied.priority, 1);
      });
    });

    group('computed properties', () {
      test('isOccurrenceInstance returns true when occurrence is set', () {
        final task = TestData.task().copyWith(
          occurrence: TestData.occurrenceData(),
        );
        expect(task.isOccurrenceInstance, true);
      });

      test('isOccurrenceInstance returns false when occurrence is null', () {
        final task = TestData.task();
        expect(task.isOccurrenceInstance, false);
      });

      test('isRepeating returns true when repeatIcalRrule is set', () {
        final task = TestData.task(repeatIcalRrule: 'FREQ=DAILY');
        expect(task.isRepeating, true);
      });

      test('isRepeating returns false when repeatIcalRrule is null', () {
        final task = TestData.task();
        expect(task.isRepeating, false);
      });

      test('isRepeating returns false when repeatIcalRrule is empty', () {
        final task = TestData.task(repeatIcalRrule: '');
        expect(task.isRepeating, false);
      });
    });

    group('priority', () {
      test('accepts P1 priority (1)', () {
        final task = TestData.task(priority: 1);
        expect(task.priority, 1);
      });

      test('accepts P4 priority (4)', () {
        final task = TestData.task(priority: 4);
        expect(task.priority, 4);
      });

      test('accepts null priority', () {
        final task = TestData.task();
        expect(task.priority, isNull);
      });
    });
  });
}
