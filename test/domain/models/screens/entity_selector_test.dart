import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('EntityType', () {
    test('task type exists', () {
      expect(EntityType.task.name, 'task');
    });

    test('project type exists', () {
      expect(EntityType.project.name, 'project');
    });

    test('value type exists', () {
      expect(EntityType.value.name, 'value');
    });

    test('goal type exists', () {
      expect(EntityType.goal.name, 'goal');
    });

    test('journal type exists', () {
      expect(EntityType.journal.name, 'journal');
    });

    test('tracker type exists', () {
      expect(EntityType.tracker.name, 'tracker');
    });

    test('enum has 6 values', () {
      expect(EntityType.values, hasLength(6));
    });
  });

  group('EntitySelector', () {
    group('construction', () {
      test('creates with required entityType', () {
        final selector = EntitySelector(entityType: EntityType.task);

        expect(selector.entityType, EntityType.task);
      });

      test('taskFilter defaults to null', () {
        final selector = EntitySelector(entityType: EntityType.task);

        expect(selector.taskFilter, isNull);
      });

      test('projectFilter defaults to null', () {
        final selector = EntitySelector(entityType: EntityType.project);

        expect(selector.projectFilter, isNull);
      });

      test('specificIds defaults to null', () {
        final selector = EntitySelector(entityType: EntityType.task);

        expect(selector.specificIds, isNull);
      });

      test('creates with specificIds', () {
        final ids = ['id-1', 'id-2', 'id-3'];
        final selector = EntitySelector(
          entityType: EntityType.task,
          specificIds: ids,
        );

        expect(selector.specificIds, ids);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final selector1 = EntitySelector(
          entityType: EntityType.project,
          specificIds: ['a', 'b'],
        );
        final selector2 = EntitySelector(
          entityType: EntityType.project,
          specificIds: ['a', 'b'],
        );

        expect(selector1, equals(selector2));
        expect(selector1.hashCode, equals(selector2.hashCode));
      });

      test('not equal when entityType differs', () {
        final selector1 = EntitySelector(entityType: EntityType.task);
        final selector2 = EntitySelector(entityType: EntityType.project);

        expect(selector1, isNot(equals(selector2)));
      });

      test('not equal when specificIds differ', () {
        final selector1 = EntitySelector(
          entityType: EntityType.task,
          specificIds: ['a'],
        );
        final selector2 = EntitySelector(
          entityType: EntityType.task,
          specificIds: ['b'],
        );

        expect(selector1, isNot(equals(selector2)));
      });
    });

    group('copyWith', () {
      test('copies with new entityType', () {
        final selector = EntitySelector(entityType: EntityType.task);
        final copied = selector.copyWith(entityType: EntityType.value);

        expect(copied.entityType, EntityType.value);
      });

      test('copies with new specificIds', () {
        final selector = EntitySelector(entityType: EntityType.task);
        final copied = selector.copyWith(specificIds: ['id-1']);

        expect(copied.specificIds, ['id-1']);
        expect(copied.entityType, EntityType.task);
      });

      test('preserves unchanged fields', () {
        final selector = EntitySelector(
          entityType: EntityType.project,
          specificIds: ['a', 'b'],
        );
        final copied = selector.copyWith(entityType: EntityType.value);

        expect(copied.specificIds, ['a', 'b']);
      });
    });

    group('JSON serialization', () {
      test('fromJson with all null optional fields', () {
        final json = {'entity_type': 'task'};
        final selector = EntitySelector.fromJson(json);

        expect(selector.entityType, EntityType.task);
        expect(selector.taskFilter, isNull);
        expect(selector.projectFilter, isNull);
        expect(selector.specificIds, isNull);
      });

      test('toJson/fromJson roundtrip with specificIds', () {
        final selector = EntitySelector(
          entityType: EntityType.project,
          specificIds: ['id-1', 'id-2'],
        );

        final json = selector.toJson();
        final restored = EntitySelector.fromJson(json);

        expect(restored.entityType, selector.entityType);
        expect(restored.specificIds, selector.specificIds);
      });
    });
  });

  group('TaskQueryFilterConverter', () {
    const converter = TaskQueryFilterConverter();

    test('fromJson returns null for null input', () {
      final result = converter.fromJson(null);

      expect(result, isNull);
    });

    test('toJson returns null for null input', () {
      final result = converter.toJson(null);

      expect(result, isNull);
    });

    test('fromJson parses valid task filter', () {
      final json = {
        'shared': [
          {
            'type': 'bool',
            'field': 'completed',
            'operator': 'isFalse',
          },
        ],
        'orGroups': <List<Map<String, dynamic>>>[],
      };

      final result = converter.fromJson(json);

      expect(result, isNotNull);
      expect(result!.shared, hasLength(1));
      expect(result.shared.first, isA<TaskBoolPredicate>());
    });

    test('toJson serializes task filter', () {
      const filter = QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      );

      final result = converter.toJson(filter);

      expect(result, isNotNull);
      expect(result!['shared'], hasLength(1));
      expect(result['orGroups'], isEmpty);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const filter = QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isTrue,
          ),
        ],
        orGroups: [
          [
            TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        ],
      );

      final json = converter.toJson(filter);
      final restored = converter.fromJson(json);

      expect(restored!.shared, hasLength(filter.shared.length));
      expect(restored.orGroups, hasLength(filter.orGroups.length));
    });
  });

  group('ProjectQueryFilterConverter', () {
    const converter = ProjectQueryFilterConverter();

    test('fromJson returns null for null input', () {
      final result = converter.fromJson(null);

      expect(result, isNull);
    });

    test('toJson returns null for null input', () {
      final result = converter.toJson(null);

      expect(result, isNull);
    });

    test('fromJson parses valid project filter', () {
      final json = {
        'shared': [
          {
            'type': 'bool',
            'field': 'completed',
            'operator': 'isFalse',
          },
        ],
        'orGroups': <List<Map<String, dynamic>>>[],
      };

      final result = converter.fromJson(json);

      expect(result, isNotNull);
      expect(result!.shared, hasLength(1));
      expect(result.shared.first, isA<ProjectBoolPredicate>());
    });

    test('toJson serializes project filter', () {
      const filter = QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      );

      final result = converter.toJson(filter);

      expect(result, isNotNull);
      expect(result!['shared'], hasLength(1));
      expect(result['orGroups'], isEmpty);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const filter = QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isTrue,
          ),
        ],
        orGroups: [
          [
            ProjectIdPredicate(id: 'project-123'),
          ],
        ],
      );

      final json = converter.toJson(filter);
      final restored = converter.fromJson(json);

      expect(restored!.shared, hasLength(filter.shared.length));
      expect(restored.orGroups, hasLength(filter.orGroups.length));
    });
  });
}
