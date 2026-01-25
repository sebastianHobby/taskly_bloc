@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_data/src/repositories/repository_helpers.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('sortedValuesFromMap', () {
    testSafe('returns empty for null/empty', () async {
      expect(sortedValuesFromMap(null), isEmpty);
      expect(sortedValuesFromMap(<String, ValueTableData>{}), isEmpty);
    });

    testSafe('sorts by name ascending', () async {
      final now = DateTime.utc(2025, 1, 1);
      final a = ValueTableData(
        id: 'v_a',
        name: 'A',
        color: '#000000',
        iconName: null,
        createdAt: now,
        updatedAt: now,
        userId: null,
        priority: null,
        psMetadata: null,
      );
      final b = ValueTableData(
        id: 'v_b',
        name: 'B',
        color: '#000000',
        iconName: null,
        createdAt: now,
        updatedAt: now,
        userId: null,
        priority: null,
        psMetadata: null,
      );

      final values = sortedValuesFromMap(<String, ValueTableData>{
        b.id: b,
        a.id: a,
      });

      expect(values.map((v) => v.id).toList(), equals(['v_a', 'v_b']));
      expect(values.map((v) => v.name).toList(), equals(['A', 'B']));
    });
  });

  group('ProjectAggregation', () {
    testSafe('hydrates values via join aliases and sorts them', () async {
      final db = autoTearDown(
        AppDatabase(NativeDatabase.memory()),
        (d) async => d.close(),
      );

      await db
          .into(db.valueTable)
          .insert(
            ValueTableCompanion.insert(id: 'v1', name: 'B', color: '#111111'),
          );
      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const Value('p1'),
              name: 'Project',
              completed: false,
              primaryValueId: const Value('v1'),
            ),
          );

      final primary = db.valueTable.createAlias('primary_value');

      final query = db.select(db.projectTable).join([
        leftOuterJoin(
          primary,
          primary.id.equalsExp(db.projectTable.primaryValueId),
        ),
      ])..where(db.projectTable.id.equals('p1'));

      final rows = await query.get();

      final agg = ProjectAggregation.fromRows(
        rows: rows,
        driftDb: db,
        primaryValueTable: primary,
      );

      final project = agg.toSingleProject();
      expect(project, isNot(equals(null)));

      final p = project!;
      expect(p.id, equals('p1'));
      expect(p.primaryValueId, equals('v1'));

      // sortedValuesFromMap sorts by value name.
      expect(p.values.map((v) => v.name).toList(), equals(['B']));
      expect(p.values.map((v) => v.id).toList(), equals(['v1']));
      expect(p.primaryValue?.id, equals('v1'));
    });
  });

  group('TaskAggregation', () {
    testSafe('hydrates project values and task override values', () async {
      final db = autoTearDown(
        AppDatabase(NativeDatabase.memory()),
        (d) async => d.close(),
      );

      await db
          .into(db.valueTable)
          .insert(
            ValueTableCompanion.insert(
              id: 'vp1',
              name: 'ProjectB',
              color: '#111111',
            ),
          );
      await db
          .into(db.valueTable)
          .insert(
            ValueTableCompanion.insert(
              id: 'vo1',
              name: 'OverrideA',
              color: '#333333',
            ),
          );
      await db
          .into(db.valueTable)
          .insert(
            ValueTableCompanion.insert(
              id: 'vo2',
              name: 'OverrideB',
              color: '#444444',
            ),
          );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const Value('p1'),
              name: 'Project',
              completed: false,
              primaryValueId: const Value('vp1'),
            ),
          );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const Value('t1'),
              name: 'Task',
              completed: const Value(false),
              projectId: const Value('p1'),
              overridePrimaryValueId: const Value('vo1'),
              overrideSecondaryValueId: const Value('vo2'),
            ),
          );

      final projectPrimary = db.valueTable.createAlias('project_primary_value');
      final overridePrimary = db.valueTable.createAlias('override_primary');
      final overrideSecondary = db.valueTable.createAlias('override_secondary');

      final rows = await db.select(db.taskTable).join([
        leftOuterJoin(
          db.projectTable,
          db.projectTable.id.equalsExp(db.taskTable.projectId),
        ),
        leftOuterJoin(
          projectPrimary,
          projectPrimary.id.equalsExp(db.projectTable.primaryValueId),
        ),
        leftOuterJoin(
          overridePrimary,
          overridePrimary.id.equalsExp(db.taskTable.overridePrimaryValueId),
        ),
        leftOuterJoin(
          overrideSecondary,
          overrideSecondary.id.equalsExp(db.taskTable.overrideSecondaryValueId),
        ),
      ]).get();

      final agg = TaskAggregation.fromRows(
        rows: rows,
        driftDb: db,
        projectPrimaryValueTable: projectPrimary,
        overridePrimaryValueTable: overridePrimary,
        overrideSecondaryValueTable: overrideSecondary,
      );

      final task = agg.toSingleTask();
      expect(task, isNot(equals(null)));

      final t = task!;
      expect(t.id, equals('t1'));

      // Override values become task.values (not project values).
      expect(t.values.map((v) => v.id).toList(), equals(['vo1', 'vo2']));

      // Project exists and has its own sorted values list.
      final p = t.project;
      expect(p, isNot(equals(null)));
      expect(p!.values.map((v) => v.name).toList(), equals(['ProjectB']));
    });

    testSafe('does not duplicate override values when ids match', () async {
      final db = autoTearDown(
        AppDatabase(NativeDatabase.memory()),
        (d) async => d.close(),
      );

      await db
          .into(db.valueTable)
          .insert(
            ValueTableCompanion.insert(
              id: 'vo1',
              name: 'Override',
              color: '#333333',
            ),
          );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const Value('t1'),
              name: 'Task',
              completed: const Value(false),
              overridePrimaryValueId: const Value('vo1'),
              overrideSecondaryValueId: const Value('vo1'),
            ),
          );

      final projectPrimary = db.valueTable.createAlias('project_primary_value');
      final overridePrimary = db.valueTable.createAlias('override_primary');
      final overrideSecondary = db.valueTable.createAlias('override_secondary');

      final rows = await db.select(db.taskTable).join([
        leftOuterJoin(
          db.projectTable,
          db.projectTable.id.equalsExp(db.taskTable.projectId),
        ),
        leftOuterJoin(
          projectPrimary,
          projectPrimary.id.equalsExp(db.projectTable.primaryValueId),
        ),
        leftOuterJoin(
          overridePrimary,
          overridePrimary.id.equalsExp(db.taskTable.overridePrimaryValueId),
        ),
        leftOuterJoin(
          overrideSecondary,
          overrideSecondary.id.equalsExp(db.taskTable.overrideSecondaryValueId),
        ),
      ]).get();

      final agg = TaskAggregation.fromRows(
        rows: rows,
        driftDb: db,
        projectPrimaryValueTable: projectPrimary,
        overridePrimaryValueTable: overridePrimary,
        overrideSecondaryValueTable: overrideSecondary,
      );

      final task = agg.toSingleTask();
      expect(task, isNot(equals(null)));
      expect(task!.values.map((v) => v.id).toList(), equals(['vo1']));
    });
  });
}
