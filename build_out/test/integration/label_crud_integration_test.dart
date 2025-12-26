import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/models/label.dart' as domain;

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Integration tests for Label CRUD operations using a real in-memory database.
///
/// These tests verify label management including task-label relationships
/// via the many-to-many junction table.
void main() {
  late AppDatabase db;
  late LabelRepository labelRepo;
  late TaskRepository taskRepo;

  setUp(() {
    db = createTestDb();
    labelRepo = LabelRepository(driftDb: db);
    taskRepo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('Label CRUD Operations', () {
    test('creates a label and retrieves it', () async {
      // Act
      await labelRepo.create(
        name: 'Urgent',
        color: '#FF0000',
        type: domain.LabelType.label,
      );

      // Assert
      final labels = await labelRepo.watchAll().first;
      expect(labels, hasLength(1));
      expect(labels.first.name, 'Urgent');
      expect(labels.first.color, '#FF0000');
    });

    test('creates multiple labels', () async {
      // Act
      await labelRepo.create(
        name: 'Bug',
        color: '#FF0000',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Feature',
        color: '#00FF00',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Documentation',
        color: '#0000FF',
        type: domain.LabelType.label,
      );

      // Assert
      final labels = await labelRepo.watchAll().first;
      expect(labels, hasLength(3));
      expect(
        labels.map((l) => l.name),
        containsAll(['Bug', 'Feature', 'Documentation']),
      );
    });

    test('updates a label', () async {
      // Arrange
      await labelRepo.create(
        name: 'Original',
        color: '#AABBCC',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelId = labels.first.id;

      // Act
      await labelRepo.update(
        id: labelId,
        name: 'Updated',
        color: '#112233',
        type: domain.LabelType.label,
      );

      // Assert
      final updated = await labelRepo.watchAll().first;
      expect(updated.first.name, 'Updated');
      expect(updated.first.color, '#112233');
    });

    test('deletes a label', () async {
      // Arrange
      await labelRepo.create(
        name: 'To Delete',
        color: '#000000',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelId = labels.first.id;

      // Act
      await labelRepo.delete(labelId);

      // Assert
      final afterDelete = await labelRepo.watchAll().first;
      expect(afterDelete, isEmpty);
    });
  });

  group('Task-Label Relationship', () {
    test('assigns labels to a task', () async {
      // Arrange - Create labels
      await labelRepo.create(
        name: 'High Priority',
        color: '#FF0000',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Backend',
        color: '#00FF00',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelIds = labels.map((l) => l.id).toList();

      // Create task with labels
      await taskRepo.create(name: 'API Task', labelIds: labelIds);

      // Act - Get task with labels
      final tasks = await taskRepo.watchAll().first;
      final task = tasks.first;

      // Assert
      expect(task.labels, hasLength(2));
      expect(
        task.labels.map((l) => l.name),
        containsAll(['High Priority', 'Backend']),
      );
    });

    test('updates task labels', () async {
      // Arrange - Create labels
      await labelRepo.create(
        name: 'Label A',
        color: '#111111',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Label B',
        color: '#222222',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Label C',
        color: '#333333',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelA = labels.firstWhere((l) => l.name == 'Label A');
      final labelB = labels.firstWhere((l) => l.name == 'Label B');
      final labelC = labels.firstWhere((l) => l.name == 'Label C');

      // Create task with Label A and B
      await taskRepo.create(
        name: 'Test Task',
        labelIds: [labelA.id, labelB.id],
      );
      final tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Act - Update to Label B and C
      await taskRepo.update(
        id: taskId,
        name: 'Test Task',
        completed: false,
        labelIds: [labelB.id, labelC.id],
      );

      // Assert
      final updated = await taskRepo.watchAll().first;
      final updatedTask = updated.first;
      expect(
        updatedTask.labels.map((l) => l.name),
        containsAll(['Label B', 'Label C']),
      );
      expect(updatedTask.labels.map((l) => l.name), isNot(contains('Label A')));
    });

    test('removes all labels from a task', () async {
      // Arrange
      await labelRepo.create(
        name: 'Temporary',
        color: '#444444',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final labelId = labels.first.id;

      await taskRepo.create(name: 'Labeled Task', labelIds: [labelId]);
      final tasks = await taskRepo.watchAll().first;
      final taskId = tasks.first.id;

      // Act - Update with empty labels
      await taskRepo.update(
        id: taskId,
        name: 'Labeled Task',
        completed: false,
        labelIds: [],
      );

      // Assert
      final updated = await taskRepo.watchAll().first;
      expect(updated.first.labels, isEmpty);
    });

    test('deleting a label removes it from tasks', () async {
      // Arrange
      await labelRepo.create(
        name: 'Doomed',
        color: '#555555',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Survivor',
        color: '#666666',
        type: domain.LabelType.label,
      );
      final labels = await labelRepo.watchAll().first;
      final doomedLabel = labels.firstWhere((l) => l.name == 'Doomed');
      final survivorLabel = labels.firstWhere((l) => l.name == 'Survivor');

      await taskRepo.create(
        name: 'Multi-label Task',
        labelIds: [doomedLabel.id, survivorLabel.id],
      );

      // Act - Delete one label
      await labelRepo.delete(doomedLabel.id);

      // Assert - Task should only have the survivor label
      final tasks = await taskRepo.watchAll().first;
      expect(tasks.first.labels, hasLength(1));
      expect(tasks.first.labels.first.name, 'Survivor');
    });
  });

  group('Label Count Operations', () {
    test('count returns correct number of labels', () async {
      await labelRepo.create(
        name: 'Label 1',
        color: '#111111',
        type: domain.LabelType.label,
      );
      await labelRepo.create(
        name: 'Label 2',
        color: '#222222',
        type: domain.LabelType.label,
      );

      final labels = await labelRepo.watchAll().first;
      expect(labels.length, 2);
    });
  });

  group('Label Stream Reactivity', () {
    test('watchAll emits updated list when label is added', () async {
      final emissions = <int>[];
      final subscription = labelRepo.watchAll().listen(
        (labels) => emissions.add(labels.length),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, 0);

      await labelRepo.create(
        name: 'Reactive Label',
        color: '#888888',
        type: domain.LabelType.label,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, 1);

      await subscription.cancel();
    });
  });
}
