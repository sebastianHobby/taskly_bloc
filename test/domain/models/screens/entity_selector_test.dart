import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';

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

    test('label type exists', () {
      expect(EntityType.label.name, 'label');
    });

    test('goal type exists', () {
      expect(EntityType.goal.name, 'goal');
    });

    test('enum has 4 values', () {
      expect(EntityType.values, hasLength(4));
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
        final copied = selector.copyWith(entityType: EntityType.label);

        expect(copied.entityType, EntityType.label);
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
        final copied = selector.copyWith(entityType: EntityType.label);

        expect(copied.specificIds, ['a', 'b']);
      });
    });
  });
}
