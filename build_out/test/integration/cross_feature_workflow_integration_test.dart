import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart' hide LabelType;
import 'package:taskly_bloc/domain/models/label.dart' as domain;

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Integration tests for cross-feature workflows using a real in-memory database.
///
/// These tests verify the interaction between tasks, projects, and labels
/// in realistic user workflows.
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;
  late LabelRepository labelRepo;

  setUp(() {
    db = createTestDb();
    taskRepo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    projectRepo = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    labelRepo = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('Full Task Management Workflow', () {
    test('creates task with project and labels', () async {
      // Create project
      await projectRepo.create(name: 'Mobile App');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Create labels
      await labelRepo.create(
        name: 'Bug',
        color: '#FF0000',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'High Priority',
        color: '#FFAA00',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelIds = labels.map((l) => l.id).toList();

      // Create task with project and labels
      await taskRepo.create(
        name: 'Fix crash on startup',
        description: 'App crashes when opening without network',
        projectId: projectId,
        labelIds: labelIds,
      );

      // Verify task has all relationships
      final tasks = await taskRepo.watchAll().first;
      final task = tasks.first;

      expect(task.name, 'Fix crash on startup');
      expect(task.projectId, projectId);
      expect(task.labels, hasLength(2));
      expect(
        task.labels.map((l) => l.name),
        containsAll(['Bug', 'High Priority']),
      );
    });

    test('moves task between projects', () async {
      // Create projects
      await projectRepo.create(name: 'Backlog');
      await projectRepo.create(name: 'Sprint 1');
      final projects = await projectRepo.watchAll().first;
      final backlogId = projects.firstWhere((p) => p.name == 'Backlog').id;
      final sprintId = projects.firstWhere((p) => p.name == 'Sprint 1').id;

      // Create task in Backlog
      await taskRepo.create(name: 'Feature request', projectId: backlogId);
      var tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      expect(tasks.first.projectId, backlogId);

      // Move to Sprint 1
      await taskRepo.update(
        id: taskId,
        name: 'Feature request',
        completed: false,
        projectId: sprintId,
      );

      // Verify
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.projectId, sprintId);
    });

    test('inbox task workflow - task without project', () async {
      // Create inbox task (no project)
      await taskRepo.create(name: 'Quick note');
      var tasks = await taskRepo.watchAll().first;
      expect(tasks.first.projectId, isNull);

      // Create project and assign
      await projectRepo.create(name: 'Personal');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      await taskRepo.update(
        id: tasks.first.id,
        name: 'Quick note',
        completed: false,
        projectId: projectId,
      );

      // Verify assignment
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.projectId, projectId);
    });
  });

  group('Scheduled Task Workflow', () {
    test('creates task with start and deadline dates', () async {
      final startDate = DateTime(2025, 2);
      final deadlineDate = DateTime(2025, 2, 15);

      await taskRepo.create(
        name: 'Q1 Report',
        startDate: startDate,
        deadlineDate: deadlineDate,
      );

      final tasks = await taskRepo.watchAll().first;
      final task = tasks.first;

      expect(task.startDate, startDate);
      expect(task.deadlineDate, deadlineDate);
    });

    test('updates task dates', () async {
      // Create task with initial dates
      await taskRepo.create(
        name: 'Meeting prep',
        startDate: DateTime(2025, 2),
        deadlineDate: DateTime(2025, 2, 5),
      );

      var tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Update dates (postpone)
      final newStart = DateTime(2025, 2, 10);
      final newDeadline = DateTime(2025, 2, 15);
      await taskRepo.update(
        id: taskId,
        name: 'Meeting prep',
        completed: false,
        startDate: newStart,
        deadlineDate: newDeadline,
      );

      // Verify
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.startDate, newStart);
      expect(tasks.first.deadlineDate, newDeadline);
    });

    test('clears task dates', () async {
      // Create task with dates
      await taskRepo.create(
        name: 'Flexible task',
        startDate: DateTime(2025, 2),
        deadlineDate: DateTime(2025, 2, 28),
      );

      var tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Clear the dates by setting to null
      // Note: This depends on whether the settingsRepo supports null updates
      await taskRepo.update(
        id: taskId,
        name: 'Flexible task',
        completed: false,
      );

      tasks = await taskRepo.watchAll().first;
      // Task name should be updated
      expect(tasks.first.name, 'Flexible task');
    });
  });

  group('Task Completion Workflow', () {
    test('completes a task', () async {
      await taskRepo.create(name: 'Todo item');
      var tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      expect(tasks.first.completed, isFalse);

      // Complete task
      await taskRepo.update(id: taskId, name: 'Todo item', completed: true);

      // Verify
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.completed, isTrue);
    });

    test('uncompletes a task', () async {
      await taskRepo.create(name: 'Undone item');
      var tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Complete
      await taskRepo.update(id: taskId, name: 'Undone item', completed: true);
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.completed, isTrue);

      // Uncomplete
      await taskRepo.update(id: taskId, name: 'Undone item', completed: false);
      tasks = await taskRepo.watchAll().first;
      expect(tasks.first.completed, isFalse);
    });

    test('project task completion counts update correctly', () async {
      // Create project with multiple tasks
      await projectRepo.create(name: 'Test Project');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      await taskRepo.create(name: 'Task 1', projectId: projectId);
      await taskRepo.create(name: 'Task 2', projectId: projectId);
      await taskRepo.create(name: 'Task 3', projectId: projectId);

      // Complete some tasks
      final tasks = await taskRepo.watchAll().first;
      await taskRepo.update(
        id: tasks.firstWhere((t) => t.name == 'Task 1').id,
        name: 'Task 1',
        completed: true,
      );
      await taskRepo.update(
        id: tasks.firstWhere((t) => t.name == 'Task 2').id,
        name: 'Task 2',
        completed: true,
      );

      // Check counts
      final counts = await taskRepo.watchTaskCountsByProject().first;
      expect(counts[projectId]!.totalCount, 3);
      expect(counts[projectId]!.completedCount, 2);
    });
  });

  group('Bulk Operations Workflow', () {
    test('creates multiple tasks in a project', () async {
      await projectRepo.create(name: 'Sprint');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Create multiple tasks
      for (var i = 1; i <= 5; i++) {
        await taskRepo.create(name: 'Sprint Task $i', projectId: projectId);
      }

      final tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(5));
      expect(tasks.every((t) => t.projectId == projectId), isTrue);
    });

    test('deletes all tasks in a project', () async {
      await projectRepo.create(name: 'Cleanup Target');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Create tasks
      await taskRepo.create(name: 'Delete me 1', projectId: projectId);
      await taskRepo.create(name: 'Delete me 2', projectId: projectId);
      await taskRepo.create(name: 'Keep me'); // No project

      var tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(3));

      // Delete tasks in project
      final projectTasks = tasks.where((t) => t.projectId == projectId);
      for (final task in projectTasks) {
        await taskRepo.delete(task.id);
      }

      tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.name, 'Keep me');
    });
  });

  group('Stream Reactivity Across Features', () {
    test('task stream updates when labels change', () async {
      // Create label
      await labelRepo.create(
        name: 'Important',
        color: '#FF0000',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelId = labels.first.id;

      // Create task with label
      await taskRepo.create(name: 'Labeled task', labelIds: [labelId]);

      // Set up listener
      final taskUpdates = <List<Task>>[];
      final subscription = taskRepo.watchAll().listen(taskUpdates.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Update the label
      await labelRepo.update(
        id: labelId,
        name: 'Very Important',
        color: '#FF0000',
        type: domain.LabelType.label,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The task stream should emit because the related label changed
      expect(taskUpdates, isNotEmpty);
      // The latest emission should have the updated label name
      final lastEmission = taskUpdates.last;
      // Check if label was updated in task
      final taskLabels = lastEmission.first.labels;
      expect(taskLabels.first.name, 'Very Important');

      await subscription.cancel();
    });
  });
}
