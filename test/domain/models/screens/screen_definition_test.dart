import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

void main() {
  group('ScreenDefinition', () {
    final now = DateTime.now();

    group('construction', () {
      test('creates with required fields', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.id, 'screen-1');
        expect(screen.screenKey, 'inbox');
        expect(screen.name, 'Inbox');
        expect(screen.screenType, ScreenType.list);
      });

      test('uses default values for optional fields', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'test',
          name: 'Test',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.sections, isEmpty);
        expect(screen.supportBlocks, isEmpty);
        expect(screen.iconName, isNull);
        expect(screen.isSystem, isFalse);
        expect(screen.isActive, isTrue);
        expect(screen.sortOrder, 0);
        expect(screen.category, ScreenCategory.workspace);
        expect(screen.triggerConfig, isNull);
      });

      test('creates with sections', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          sections: [
            DataSection(
              config: DataConfig.task(query: TaskQuery.inbox()),
              title: 'Tasks',
            ),
          ],
        );

        expect(screen.sections, hasLength(1));
      });

      test('creates with support blocks', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          supportBlocks: const [
            SupportBlock.problemSummary(),
          ],
        );

        expect(screen.supportBlocks, hasLength(1));
      });
    });

    group('screen types', () {
      test('list type', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'list',
          name: 'List',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.screenType, ScreenType.list);
      });

      test('dashboard type', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'dash',
          name: 'Dashboard',
          screenType: ScreenType.dashboard,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.screenType, ScreenType.dashboard);
      });

      test('focus type', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'focus',
          name: 'Focus',
          screenType: ScreenType.focus,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.screenType, ScreenType.focus);
      });

      test('workflow type', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'workflow',
          name: 'Workflow',
          screenType: ScreenType.workflow,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.screenType, ScreenType.workflow);
      });
    });

    group('screen categories', () {
      test('workspace category', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          category: ScreenCategory.workspace,
        );

        expect(screen.category, ScreenCategory.workspace);
      });

      test('wellbeing category', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'wellbeing',
          name: 'Wellbeing',
          screenType: ScreenType.dashboard,
          createdAt: now,
          updatedAt: now,
          category: ScreenCategory.wellbeing,
        );

        expect(screen.category, ScreenCategory.wellbeing);
      });

      test('settings category', () {
        final screen = ScreenDefinition(
          id: 's-1',
          screenKey: 'settings',
          name: 'Settings',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          category: ScreenCategory.settings,
        );

        expect(screen.category, ScreenCategory.settings);
      });
    });

    group('serialization', () {
      test('round-trips through JSON', () {
        final original = ScreenDefinition(
          id: 'screen-123',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          iconName: 'inbox',
          isSystem: true,
          isActive: true,
          sortOrder: 1,
          category: ScreenCategory.workspace,
        );

        final json = original.toJson();
        final restored = ScreenDefinition.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.screenKey, original.screenKey);
        expect(restored.name, original.name);
        expect(restored.screenType, original.screenType);
        expect(restored.iconName, original.iconName);
        expect(restored.isSystem, original.isSystem);
        expect(restored.isActive, original.isActive);
        expect(restored.sortOrder, original.sortOrder);
        expect(restored.category, original.category);
      });
    });
  });

  group('ScreenType', () {
    test('contains all expected values', () {
      expect(ScreenType.values, contains(ScreenType.list));
      expect(ScreenType.values, contains(ScreenType.dashboard));
      expect(ScreenType.values, contains(ScreenType.focus));
      expect(ScreenType.values, contains(ScreenType.workflow));
    });
  });
}
