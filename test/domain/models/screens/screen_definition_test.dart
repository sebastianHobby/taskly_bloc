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

    group('DataDrivenScreenDefinition', () {
      test('creates with required fields', () {
        final screen = DataDrivenScreenDefinition(
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
        final screen = DataDrivenScreenDefinition(
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
        expect(screen.category, ScreenCategory.workspace);
        expect(screen.triggerConfig, isNull);
      });

      test('creates with sections', () {
        final screen = DataDrivenScreenDefinition(
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
        final screen = DataDrivenScreenDefinition(
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

    group('NavigationOnlyScreenDefinition', () {
      test('creates with required fields', () {
        final screen = NavigationOnlyScreenDefinition(
          id: 'nav-1',
          screenKey: 'settings',
          name: 'Settings',
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.id, 'nav-1');
        expect(screen.screenKey, 'settings');
        expect(screen.name, 'Settings');
      });

      test('uses default values for optional fields', () {
        final screen = NavigationOnlyScreenDefinition(
          id: 'nav-1',
          screenKey: 'settings',
          name: 'Settings',
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.iconName, isNull);
        expect(screen.isSystem, isFalse);
        expect(screen.category, ScreenCategory.workspace);
      });
    });

    group('screen types', () {
      test('list type', () {
        final screen = DataDrivenScreenDefinition(
          id: 's-1',
          screenKey: 'list',
          name: 'List',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.screenType, ScreenType.list);
      });

      test('focus type', () {
        final screen = DataDrivenScreenDefinition(
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
        final screen = DataDrivenScreenDefinition(
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
        final screen = DataDrivenScreenDefinition(
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
        final screen = NavigationOnlyScreenDefinition(
          id: 's-1',
          screenKey: 'wellbeing',
          name: 'Wellbeing',
          createdAt: now,
          updatedAt: now,
          category: ScreenCategory.wellbeing,
        );

        expect(screen.category, ScreenCategory.wellbeing);
      });

      test('settings category', () {
        final screen = NavigationOnlyScreenDefinition(
          id: 's-1',
          screenKey: 'settings',
          name: 'Settings',
          createdAt: now,
          updatedAt: now,
          category: ScreenCategory.settings,
        );

        expect(screen.category, ScreenCategory.settings);
      });
    });

    group('serialization', () {
      test('DataDrivenScreenDefinition round-trips through JSON', () {
        final original = DataDrivenScreenDefinition(
          id: 'screen-123',
          screenKey: 'inbox',
          name: 'Inbox',
          screenType: ScreenType.list,
          createdAt: now,
          updatedAt: now,
          iconName: 'inbox',
          isSystem: true,
          category: ScreenCategory.workspace,
        );

        final json = original.toJson();
        final restored = ScreenDefinition.fromJson(json);

        expect(restored, isA<DataDrivenScreenDefinition>());
        expect(restored.id, original.id);
        expect(restored.screenKey, original.screenKey);
        expect(restored.name, original.name);
        expect(restored.iconName, original.iconName);
        expect(restored.isSystem, original.isSystem);
        expect(restored.category, original.category);
        expect(
          (restored as DataDrivenScreenDefinition).screenType,
          original.screenType,
        );
      });

      test('NavigationOnlyScreenDefinition round-trips through JSON', () {
        final original = NavigationOnlyScreenDefinition(
          id: 'nav-123',
          screenKey: 'settings',
          name: 'Settings',
          createdAt: now,
          updatedAt: now,
          iconName: 'settings',
          isSystem: true,
          category: ScreenCategory.settings,
        );

        final json = original.toJson();
        final restored = ScreenDefinition.fromJson(json);

        expect(restored, isA<NavigationOnlyScreenDefinition>());
        expect(restored.id, original.id);
        expect(restored.screenKey, original.screenKey);
        expect(restored.name, original.name);
        expect(restored.iconName, original.iconName);
        expect(restored.isSystem, original.isSystem);
        expect(restored.category, original.category);
      });

      test('fromJson with sections creates DataDrivenScreenDefinition', () {
        final json = {
          'id': 'screen-1',
          'screenKey': 'inbox',
          'name': 'Inbox',
          'screenType': 'list',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'sections': [
            {
              'runtimeType': 'DataSection',
              'config': {
                'runtimeType': 'task',
                'query': {
                  'runtimeType': 'default',
                },
              },
              'title': 'Tasks',
            },
          ],
        };

        final screen = ScreenDefinition.fromJson(json);

        expect(screen, isA<DataDrivenScreenDefinition>());
        expect((screen as DataDrivenScreenDefinition).sections, hasLength(1));
      });

      test('fromJson with empty sections creates NavigationOnly', () {
        final json = {
          'id': 'nav-1',
          'screenKey': 'settings',
          'name': 'Settings',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'sections': <dynamic>[],
        };

        final screen = ScreenDefinition.fromJson(json);

        expect(screen, isA<NavigationOnlyScreenDefinition>());
      });

      test('fromJson without sections creates NavigationOnly', () {
        final json = {
          'id': 'nav-1',
          'screenKey': 'settings',
          'name': 'Settings',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        final screen = ScreenDefinition.fromJson(json);

        expect(screen, isA<NavigationOnlyScreenDefinition>());
      });
    });
  });

  group('ScreenType', () {
    test('contains all expected values', () {
      expect(ScreenType.values, contains(ScreenType.list));
      expect(ScreenType.values, contains(ScreenType.focus));
      expect(ScreenType.values, contains(ScreenType.workflow));
    });

    test('does not contain dashboard (removed)', () {
      final names = ScreenType.values.map((e) => e.name).toList();
      expect(names, isNot(contains('dashboard')));
    });
  });
}
