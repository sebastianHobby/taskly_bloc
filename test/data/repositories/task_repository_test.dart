import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

import '../../helpers/test_db.dart';
import '../../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = createTestDb();
    repo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CRUD operations', () {
    test('creates task with required fields only', () async {
      await repo.create(name: 'Test Task');

      final tasks = await repo.watchAll().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, 'Test Task');
      expect(tasks.first.completed, isFalse);
      expect(tasks.first.description, isNull);
    });

    test('creates task with all fields', () async {
      final startDate = DateTime(2025);
      final deadline = DateTime(2025, 12, 31);

      await repo.create(
        name: 'Full Task',
        description: 'Complete description',
        completed: true,
        startDate: startDate,
        deadlineDate: deadline,
        repeatIcalRrule: 'FREQ=DAILY',
        repeatFromCompletion: true,
      );

      final tasks = await repo.watchAll().first;
      final task = tasks.first;
      expect(task.name, 'Full Task');
      expect(task.description, 'Complete description');
      expect(task.completed, isTrue);
      expect(task.repeatIcalRrule, 'FREQ=DAILY');
      expect(task.repeatFromCompletion, isTrue);
    });

    test('creates task with labels', () async {
      // Create labels first
      await db
          .into(db.labelTable)
          .insert(
            LabelTableCompanion.insert(
              id: 'label-1',
              name: 'Important',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.labelTable)
          .insert(
            LabelTableCompanion.insert(
              id: 'label-2',
              name: 'Urgent',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await repo.create(
        name: 'Task with Labels',
        labelIds: ['label-1', 'label-2'],
      );

      final tasks = await repo.watchAll().first;
      expect(tasks.first.labels, hasLength(2));
    });

    test('creates task with duplicate labels (deduplicated)', () async {
      await db
          .into(db.labelTable)
          .insert(
            LabelTableCompanion.insert(
              id: 'label-1',
              name: 'Test',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await repo.create(
        name: 'Task',
        labelIds: ['label-1', 'label-1', 'label-1'],
      );

      final tasks = await repo.watchAll().first;
      expect(tasks.first.labels, hasLength(1));
    });

    test('getById returns task when exists', () async {
      await repo.create(name: 'Test Task');
      final allTasks = await repo.watchAll().first;
      final taskId = allTasks.first.id;

      final result = await repo.getById(taskId);

      expect(result, isNotNull);
      expect(result!.name, 'Test Task');
    });

    test('getById returns null when not found', () async {
      final result = await repo.getById('non-existent-id');
      expect(result, isNull);
    });

    test('watchById emits task updates', () async {
      await repo.create(name: 'Watch Test');
      final allTasks = await repo.watchAll().first;
      final taskId = allTasks.first.id;

      final stream = repo.watchById(taskId);

      // First emission
      final initial = await stream.first;
      expect(initial?.name, 'Watch Test');

      // Update and check next emission
      await repo.update(
        id: taskId,
        name: 'Updated Name',
        completed: false,
      );

      final updated = await stream.first;
      expect(updated?.name, 'Updated Name');
    });

    test('updates task successfully', () async {
      await repo.create(name: 'Original');
      final tasks = await repo.watchAll().first;
      final taskId = tasks.first.id;

      await repo.update(
        id: taskId,
        name: 'Updated',
        completed: true,
        description: 'New description',
      );

      final updated = await repo.getById(taskId);
      expect(updated!.name, 'Updated');
      expect(updated.completed, isTrue);
      expect(updated.description, 'New description');
    });

    test(
      'update throws RepositoryNotFoundException for non-existent task',
      () async {
        expect(
          () => repo.update(
            id: 'non-existent',
            name: 'Test',
            completed: false,
          ),
          throwsA(isA<RepositoryNotFoundException>()),
        );
      },
    );

    test('updates task labels', () async {
      // Create labels
      await db
          .into(db.labelTable)
          .insert(
            LabelTableCompanion.insert(
              id: 'label-1',
              name: 'Label 1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await db
          .into(db.labelTable)
          .insert(
            LabelTableCompanion.insert(
              id: 'label-2',
              name: 'Label 2',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      // Create task with one label
      await repo.create(name: 'Task', labelIds: ['label-1']);
      final tasks = await repo.watchAll().first;
      final taskId = tasks.first.id;

      // Update to different label
      await repo.update(
        id: taskId,
        name: 'Task',
        completed: false,
        labelIds: ['label-2'],
      );

      final updated = await repo.getById(taskId);
      expect(updated!.labels, hasLength(1));
      expect(updated.labels.first.id, 'label-2');
    });

    test('deletes task successfully', () async {
      await repo.create(name: 'To Delete');
      final tasks = await repo.watchAll().first;
      final taskId = tasks.first.id;

      await repo.delete(taskId);

      final result = await repo.getById(taskId);
      expect(result, isNull);
    });

    test(
      'delete throws RepositoryNotFoundException for non-existent task',
      () async {
        expect(
          () => repo.delete('non-existent'),
          throwsA(isA<RepositoryNotFoundException>()),
        );
      },
    );
  });

  group('watchAll with queries', () {
    test('watchAll returns all tasks by default', () async {
      await repo.create(name: 'Task 1');
      await repo.create(name: 'Task 2');
      await repo.create(name: 'Task 3');

      final tasks = await repo.watchAll().first;
      expect(tasks, hasLength(3));
    });

    test('watchAll emits updated list on changes', () async {
      await repo.create(name: 'Initial');

      final stream = repo.watchAll();
      final first = await stream.first;
      expect(first, hasLength(1));

      await repo.create(name: 'Second');

      final second = await stream.first;
      expect(second, hasLength(2));
    });
  });

  group('count operations', () {
    test('count returns total task count', () async {
      await repo.create(name: 'Task 1');
      await repo.create(name: 'Task 2');

      final count = await repo.count();
      expect(count, equals(2));
    });

    test('count returns correct total', () async {
      await repo.create(name: 'Task 1');
      await repo.create(name: 'Task 2');
      await repo.create(name: 'Task 3');

      final count = await repo.count();

      expect(count, equals(3));
    });

    test('watchCount emits count updates', () async {
      final stream = repo.watchCount();

      final initial = await stream.first;
      expect(initial, equals(0));

      await repo.create(name: 'Task');

      final afterCreate = await stream.first;
      expect(afterCreate, equals(1));
    });
  });

  group('edge cases', () {
    test('handles null description', () async {
      await repo.create(name: 'Task');
      final tasks = await repo.watchAll().first;
      expect(tasks.first.description, isNull);
    });

    test('handles null dates', () async {
      await repo.create(
        name: 'Task',
      );
      final tasks = await repo.watchAll().first;
      expect(tasks.first.startDate, isNull);
      expect(tasks.first.deadlineDate, isNull);
    });

    test('handles empty label list', () async {
      await repo.create(name: 'Task', labelIds: []);
      final tasks = await repo.watchAll().first;
      expect(tasks.first.labels, isEmpty);
    });

    test('normalizes dates to dateOnly', () async {
      final dateWithTime = DateTime(2025, 1, 15, 14, 30, 45);
      await repo.create(
        name: 'Task',
        startDate: dateWithTime,
      );

      final tasks = await repo.watchAll().first;
      final startDate = tasks.first.startDate;
      expect(startDate?.hour, equals(0));
      expect(startDate?.minute, equals(0));
      expect(startDate?.second, equals(0));
    });
  });
}
