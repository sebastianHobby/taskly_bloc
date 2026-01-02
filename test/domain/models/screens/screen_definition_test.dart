import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  final now = DateTime(2025, 1, 15, 12);

  ViewDefinition createTestView() {
    return ViewDefinition.collection(
      selector: EntitySelector(entityType: EntityType.task),
      display: DisplayConfig(),
    );
  }

  group('ScreenDefinition', () {
    group('construction', () {
      test('creates with required fields', () {
        final view = createTestView();
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.id, 'screen-1');
        expect(screen.screenKey, 'inbox');
        expect(screen.name, 'Inbox');
        expect(screen.view, view);
        expect(screen.createdAt, now);
        expect(screen.updatedAt, now);
      });

      test('iconName defaults to null', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.iconName, isNull);
      });

      test('isSystem defaults to false', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.isSystem, false);
      });

      test('isActive defaults to true', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.isActive, true);
      });

      test('sortOrder defaults to 0', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.sortOrder, 0);
      });

      test('category defaults to workspace', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );

        expect(screen.category, ScreenCategory.workspace);
      });

      test('creates with all optional fields', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'today',
          name: 'Today',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
          iconName: 'today',
          isSystem: true,
          isActive: false,
          sortOrder: 5,
          category: ScreenCategory.wellbeing,
        );

        expect(screen.iconName, 'today');
        expect(screen.isSystem, true);
        expect(screen.isActive, false);
        expect(screen.sortOrder, 5);
        expect(screen.category, ScreenCategory.wellbeing);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final view = createTestView();
        final screen1 = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );
        final screen2 = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen1, equals(screen2));
        expect(screen1.hashCode, equals(screen2.hashCode));
      });

      test('not equal when id differs', () {
        final view = createTestView();
        final screen1 = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );
        final screen2 = ScreenDefinition(
          id: 'screen-2',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen1, isNot(equals(screen2)));
      });

      test('not equal when screenKey differs', () {
        final view = createTestView();
        final screen1 = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );
        final screen2 = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'today',
          name: 'Inbox',
          view: view,
          createdAt: now,
          updatedAt: now,
        );

        expect(screen1, isNot(equals(screen2)));
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );
        final copied = screen.copyWith(name: 'My Inbox');

        expect(copied.name, 'My Inbox');
        expect(copied.id, 'screen-1');
        expect(copied.screenKey, 'inbox');
      });

      test('copies with new sortOrder', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );
        final copied = screen.copyWith(sortOrder: 10);

        expect(copied.sortOrder, 10);
      });

      test('copies with new isActive', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
        );
        final copied = screen.copyWith(isActive: false);

        expect(copied.isActive, false);
      });

      test('copies with new view', () {
        final oldView = createTestView();
        final newView = ViewDefinition.detail(
          parentType: DetailParentType.project,
        );
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'inbox',
          name: 'Inbox',
          view: oldView,
          createdAt: now,
          updatedAt: now,
        );
        final copied = screen.copyWith(view: newView);

        expect(copied.view, newView);
        expect(copied.view, isNot(equals(oldView)));
      });

      test('preserves unchanged fields', () {
        final screen = ScreenDefinition(
          id: 'screen-1',
          screenKey: 'today',
          name: 'Today',
          view: createTestView(),
          createdAt: now,
          updatedAt: now,
          iconName: 'star',
          isSystem: true,
          sortOrder: 5,
        );
        final copied = screen.copyWith(name: 'My Today');

        expect(copied.iconName, 'star');
        expect(copied.isSystem, true);
        expect(copied.sortOrder, 5);
      });
    });
  });
}
