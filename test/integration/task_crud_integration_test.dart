@Tags(['integration', 'repository'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Integration tests for Task CRUD operations using a real in-memory database.
///
/// These tests verify the complete flow from repository methods through
/// to database persistence, ensuring data integrity across operations.
///
/// Coverage:
/// - ? Create task with required fields
/// - ? Create task with all optional fields
/// - ? Update task name and completion status
/// - ? Delete task
/// - ? Multiple task operations
/// - ? Stream reactivity (watchAll, watchById)
/// - ? Count operations (count, watchCount)
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;

  setUp(() {
    db = createTestDb();
    taskRepo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpanderContract(),
      occurrenceWriteHelper: MockOccurrenceWriteHelperContract(),
    );
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('Task CRUD Operations', () {
    test('creates a task and retrieves it by ID', () async {
      // Act
      await taskRepo.create(name: 'Buy groceries');

      // Assert
      final tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, 'Buy groceries');
      expect(tasks.first.completed, isFalse);

      // Verify getById also works
      final fetched = await taskRepo.getById(tasks.first.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Buy groceries');
    });

    test('creates a task with all optional fields', () async {
      final startDate = DateTime(2025, 1, 15);
      final deadlineDate = DateTime(2025, 1, 20);

      // Act
      await taskRepo.create(
        name: 'Complete report',
        description: 'Quarterly financial report',
        startDate: startDate,
        deadlineDate: deadlineDate,
      );

      // Assert
      final tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(1));
      final task = tasks.first;
      expect(task.name, 'Complete report');
      expect(task.description, 'Quarterly financial report');
      expect(task.startDate, DateTime.utc(2025, 1, 15));
      expect(task.deadlineDate, DateTime.utc(2025, 1, 20));
    });

    test('updates a task name and completion status', () async {
      // Arrange
      await taskRepo.create(name: 'Original name');
      final tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Act
      await taskRepo.update(
        id: taskId,
        name: 'Updated name',
        completed: true,
      );

      // Assert
      final updated = await taskRepo.getById(taskId);
      expect(updated!.name, 'Updated name');
      expect(updated.completed, isTrue);
    });

    test('deletes a task', () async {
      // Arrange
      await taskRepo.create(name: 'Task to delete');
      final tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Act
      await taskRepo.delete(taskId);

      // Assert
      final afterDelete = await taskRepo.watchAll().first;
      expect(afterDelete, isEmpty);

      final deleted = await taskRepo.getById(taskId);
      expect(deleted, isNull);
    });

    test('creates multiple tasks and retrieves all', () async {
      // Act
      await taskRepo.create(name: 'Task 1');
      await taskRepo.create(name: 'Task 2');
      await taskRepo.create(name: 'Task 3');

      // Assert
      final tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(3));
      expect(
        tasks.map((t) => t.name),
        containsAll(['Task 1', 'Task 2', 'Task 3']),
      );
    });
  });

  group('Task Stream Reactivity', () {
    test('watchAll emits updates when tasks change', () async {
      // Arrange
      final emissions = <List<Task>>[];
      final subscription = taskRepo.watchAll().listen(emissions.add);

      // Wait for initial empty emission
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      // Act - Create a task
      await taskRepo.create(name: 'Reactive task');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert - Should have emitted the new task
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.name, 'Reactive task');

      await subscription.cancel();
    });

    test('watchById emits updates for specific task', () async {
      // Arrange
      await taskRepo.create(name: 'Watched task');
      final tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      final emissions = <Task?>[];
      final subscription = taskRepo.watchById(taskId).listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Act - Update the task
      await taskRepo.update(
        id: taskId,
        name: 'Updated watched task',
        completed: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(emissions.last!.name, 'Updated watched task');
      expect(emissions.last!.completed, isTrue);

      await subscription.cancel();
    });
  });

  group('Task Count Operations', () {
    test('count returns correct number of tasks', () async {
      // Arrange
      await taskRepo.create(name: 'Task 1');
      await taskRepo.create(name: 'Task 2');

      // Act
      final count = await taskRepo.count();

      // Assert
      expect(count, 2);
    });

    test('watchCount emits updates when tasks added or removed', () async {
      final counts = <int>[];
      final subscription = taskRepo.watchCount().listen(counts.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Initial count
      expect(counts.last, 0);

      // Add tasks
      await taskRepo.create(name: 'Task 1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counts.last, 1);

      await taskRepo.create(name: 'Task 2');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counts.last, 2);

      // Delete a task
      final tasks = await taskRepo.watchAll().first;
      await taskRepo.delete(tasks.first.id);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counts.last, 1);

      await subscription.cancel();
    });
  });
}
