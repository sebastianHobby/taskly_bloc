import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Integration tests for Project CRUD operations using a real in-memory database.
///
/// These tests verify project management including the relationship
/// between projects and tasks.
void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late TaskRepository taskRepo;

  setUp(() {
    db = createTestDb();
    projectRepo = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    taskRepo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('Project CRUD Operations', () {
    test('creates a project and retrieves it', () async {
      // Act
      await projectRepo.create(name: 'Work Project');

      // Assert
      final projects = await projectRepo.watchAll().first;
      expect(projects, hasLength(1));
      expect(projects.first.name, 'Work Project');
      expect(projects.first.completed, isFalse);
    });

    test('creates a project with all optional fields', () async {
      final startDate = DateTime(2025, 2);
      final deadlineDate = DateTime(2025, 3, 31);

      // Act
      await projectRepo.create(
        name: 'Q1 Goals',
        description: 'First quarter objectives',
        startDate: startDate,
        deadlineDate: deadlineDate,
      );

      // Assert
      final projects = await projectRepo.watchAll().first;
      final project = projects.first;
      expect(project.name, 'Q1 Goals');
      expect(project.description, 'First quarter objectives');
      expect(project.startDate, startDate);
      expect(project.deadlineDate, deadlineDate);
    });

    test('updates a project', () async {
      // Arrange
      await projectRepo.create(name: 'Original Project');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Act
      await projectRepo.update(
        id: projectId,
        name: 'Renamed Project',
        completed: true,
      );

      // Assert
      final updated = await projectRepo.get(projectId);
      expect(updated!.name, 'Renamed Project');
      expect(updated.completed, isTrue);
    });

    test('deletes a project', () async {
      // Arrange
      await projectRepo.create(name: 'Project to delete');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Act
      await projectRepo.delete(projectId);

      // Assert
      final afterDelete = await projectRepo.watchAll().first;
      expect(afterDelete, isEmpty);
    });
  });

  group('Project-Task Relationship', () {
    test('tasks can be assigned to a project', () async {
      // Arrange - Create project
      await projectRepo.create(name: 'My Project');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      // Act - Create tasks in the project
      await taskRepo.create(name: 'Project Task 1', projectId: projectId);
      await taskRepo.create(name: 'Project Task 2', projectId: projectId);
      await taskRepo.create(name: 'Inbox Task'); // No project

      // Assert
      final allTasks = await taskRepo.watchAll().first;
      expect(allTasks, hasLength(3));

      final projectTasks = allTasks
          .where((t) => t.projectId == projectId)
          .toList();
      expect(projectTasks, hasLength(2));
      expect(
        projectTasks.map((t) => t.name),
        containsAll(['Project Task 1', 'Project Task 2']),
      );
    });

    test('watchTaskCountsByProject returns correct counts', () async {
      // Arrange
      await projectRepo.create(name: 'Project A');
      await projectRepo.create(name: 'Project B');
      final projects = await projectRepo.watchAll().first;
      final projectAId = projects.firstWhere((p) => p.name == 'Project A').id;
      final projectBId = projects.firstWhere((p) => p.name == 'Project B').id;

      // Create tasks in projects
      await taskRepo.create(name: 'A Task 1', projectId: projectAId);
      await taskRepo.create(name: 'A Task 2', projectId: projectAId);
      await taskRepo.create(name: 'B Task 1', projectId: projectBId);

      // Complete one task
      final tasks = await taskRepo.watchAll().first;
      final aTask1 = tasks.firstWhere((t) => t.name == 'A Task 1');
      await taskRepo.update(id: aTask1.id, name: aTask1.name, completed: true);

      // Act
      final counts = await taskRepo.watchTaskCountsByProject().first;

      // Assert
      expect(counts[projectAId]!.totalCount, 2);
      expect(counts[projectAId]!.completedCount, 1);
      expect(counts[projectBId]!.totalCount, 1);
      expect(counts[projectBId]!.completedCount, 0);
    });

    test('deleting project does not delete tasks (orphans them)', () async {
      // Arrange
      await projectRepo.create(name: 'Temp Project');
      final projects = await projectRepo.watchAll().first;
      final projectId = projects.first.id;

      await taskRepo.create(name: 'Orphaned Task', projectId: projectId);

      // Act - Delete the project
      await projectRepo.delete(projectId);

      // Assert - Task should still exist but without project
      final tasks = await taskRepo.watchAll().first;
      expect(tasks, hasLength(1));
      // Note: The actual behavior depends on foreign key configuration
      // This test documents the expected behavior
    });
  });

  group('Project Count Operations', () {
    test('count returns correct number of projects', () async {
      await projectRepo.create(name: 'Project 1');
      await projectRepo.create(name: 'Project 2');
      await projectRepo.create(name: 'Project 3');

      final count = await projectRepo.count();
      expect(count, 3);
    });

    test('watchCount emits updates', () async {
      final counts = <int>[];
      final subscription = projectRepo.watchCount().listen(counts.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(counts.last, 0);

      await projectRepo.create(name: 'New Project');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(counts.last, 1);

      await subscription.cancel();
    });
  });
}
