import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift;
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/domain/models/label.dart' as domain;
import 'package:taskly_bloc/domain/models/project.dart' as domain;
import 'package:taskly_bloc/domain/models/task.dart' as domain;

import '../../helpers/test_db.dart';

void main() {
  const defaultColor = '#000000';
  final createdAt = DateTime(2025);
  final updatedAt = DateTime(2025, 1, 2);

  group('sortedLabelsFromMap', () {
    test('returns empty list for null or empty map', () {
      expect(sortedLabelsFromMap(null), isEmpty);
      expect(sortedLabelsFromMap({}), isEmpty);
    });

    test('sorts labels alphabetically', () {
      final map = <String, drift.LabelTableData>{
        'label-1': drift.LabelTableData(
          id: 'label-1',
          name: 'Zebra',
          type: drift.LabelType.label,
          color: defaultColor,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
        'label-2': drift.LabelTableData(
          id: 'label-2',
          name: 'apple',
          type: drift.LabelType.label,
          color: defaultColor,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
        'label-3': drift.LabelTableData(
          id: 'label-3',
          name: 'Mango',
          type: drift.LabelType.label,
          color: defaultColor,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      };

      final result = sortedLabelsFromMap(map);

      expect(
        result.map((label) => label.name).toList(),
        <String>['Mango', 'Zebra', 'apple'],
      );
    });

    test('converts to domain labels', () {
      final map = <String, drift.LabelTableData>{
        'label-1': drift.LabelTableData(
          id: 'label-1',
          name: 'Test Label',
          type: drift.LabelType.value,
          color: '#FF0000',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      };

      final result = sortedLabelsFromMap(map);

      expect(result, hasLength(1));
      expect(result.first, isA<domain.Label>());
      expect(result.first.id, 'label-1');
      expect(result.first.name, 'Test Label');
      expect(result.first.type, domain.LabelType.value);
    });
  });

  group('ProjectAggregation', () {
    late drift.AppDatabase db;

    setUp(() async {
      db = await createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('aggregates project without labels', () async {
      await db
          .into(db.projectTable)
          .insert(
            drift.ProjectTableCompanion.insert(
              id: const Value('proj-1'),
              name: 'Project 1',
              completed: false,
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      final rows = await db.select(db.projectTable).join([]).get();

      final aggregation = ProjectAggregation.fromRows(
        rows: rows,
        driftDb: db,
      );

      expect(aggregation.projectsById, hasLength(1));
      expect(aggregation.labelsByProject['proj-1'], isNull);

      final projects = aggregation.toProjects();
      expect(projects, hasLength(1));
      expect(projects.first, isA<domain.Project>());
      expect(projects.first.id, 'proj-1');
    });

    test('aggregates project with labels', () async {
      await db
          .into(db.projectTable)
          .insert(
            drift.ProjectTableCompanion.insert(
              id: const Value('proj-1'),
              name: 'Project 1',
              completed: false,
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      await db
          .into(db.labelTable)
          .insert(
            drift.LabelTableCompanion.insert(
              id: const Value('label-1'),
              name: 'Important',
              type: Value(drift.LabelType.label),
              color: defaultColor,
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      await db
          .into(db.projectLabelsTable)
          .insert(
            drift.ProjectLabelsTableCompanion(
              projectId: const Value('proj-1'),
              labelId: const Value('label-1'),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      final rows = await db.select(db.projectTable).join([
        leftOuterJoin(
          db.projectLabelsTable,
          db.projectLabelsTable.projectId.equalsExp(db.projectTable.id),
        ),
        leftOuterJoin(
          db.labelTable,
          db.labelTable.id.equalsExp(db.projectLabelsTable.labelId),
        ),
      ]).get();

      final aggregation = ProjectAggregation.fromRows(
        rows: rows,
        driftDb: db,
      );

      expect(aggregation.projectsById, hasLength(1));
      expect(aggregation.labelsByProject['proj-1'], isNotNull);
      expect(aggregation.labelsByProject['proj-1']!.keys, contains('label-1'));

      final projects = aggregation.toProjects();
      expect(projects.single.labels.single.id, 'label-1');
    });
  });

  group('TaskAggregation', () {
    late drift.AppDatabase db;

    setUp(() async {
      db = await createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('aggregates task with project and labels', () async {
      await db
          .into(db.projectTable)
          .insert(
            drift.ProjectTableCompanion.insert(
              id: const Value('proj-1'),
              name: 'Project 1',
              completed: false,
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      await db
          .into(db.taskTable)
          .insert(
            drift.TaskTableCompanion.insert(
              id: const Value('task-1'),
              name: 'Task 1',
              completed: const Value(false),
              projectId: const Value('proj-1'),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      await db
          .into(db.labelTable)
          .insert(
            drift.LabelTableCompanion.insert(
              id: const Value('label-1'),
              name: 'Important',
              type: Value(drift.LabelType.label),
              color: defaultColor,
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      await db
          .into(db.taskLabelsTable)
          .insert(
            drift.TaskLabelsTableCompanion(
              taskId: const Value('task-1'),
              labelId: const Value('label-1'),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      final rows = await db.select(db.taskTable).join([
        leftOuterJoin(
          db.projectTable,
          db.projectTable.id.equalsExp(db.taskTable.projectId),
        ),
        leftOuterJoin(
          db.taskLabelsTable,
          db.taskLabelsTable.taskId.equalsExp(db.taskTable.id),
        ),
        leftOuterJoin(
          db.labelTable,
          db.labelTable.id.equalsExp(db.taskLabelsTable.labelId),
        ),
      ]).get();

      final aggregation = TaskAggregation.fromRows(
        rows: rows,
        driftDb: db,
      );

      expect(aggregation.tasksById, hasLength(1));
      expect(aggregation.projectByTask['task-1']?.id, 'proj-1');
      expect(aggregation.labelsByTask['task-1']!.keys, contains('label-1'));

      final tasks = aggregation.toTasks();
      final task = tasks.single;
      expect(task, isA<domain.Task>());
      expect(task.project?.id, 'proj-1');
      expect(task.labels.single.id, 'label-1');
    });

    test('converts to tasks without project or labels', () async {
      await db
          .into(db.taskTable)
          .insert(
            drift.TaskTableCompanion.insert(
              id: const Value('task-1'),
              name: 'Task 1',
              completed: const Value(false),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
            ),
          );

      final rows = await db.select(db.taskTable).join([]).get();

      final aggregation = TaskAggregation.fromRows(
        rows: rows,
        driftDb: db,
      );

      final tasks = aggregation.toTasks();

      expect(tasks, hasLength(1));
      expect(tasks.first.project, isNull);
      expect(tasks.first.labels, isEmpty);
    });
  });
}
