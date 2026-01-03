import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/features/screens/system_screen_factory.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('SystemScreenFactory', () {
    const userId = 'test-user-123';

    group('constants', () {
      test('all screen keys are defined', () {
        expect(SystemScreenFactory.inbox, 'inbox');
        expect(SystemScreenFactory.today, 'today');
        expect(SystemScreenFactory.upcoming, 'upcoming');
        expect(SystemScreenFactory.nextActions, 'next_actions');
        expect(SystemScreenFactory.projects, 'projects');
        expect(SystemScreenFactory.labels, 'labels');
        expect(SystemScreenFactory.values, 'values');
        expect(SystemScreenFactory.wellbeing, 'wellbeing');
        expect(SystemScreenFactory.journal, 'journal');
        expect(SystemScreenFactory.trackers, 'trackers');
        expect(SystemScreenFactory.allocationSettings, 'allocation_settings');
        expect(SystemScreenFactory.navigationSettings, 'navigation_settings');
        expect(SystemScreenFactory.settings, 'settings');
      });

      test('allSystemScreenKeys contains all screen keys', () {
        expect(SystemScreenFactory.allSystemScreenKeys, hasLength(13));
        expect(
          SystemScreenFactory.allSystemScreenKeys,
          contains(SystemScreenFactory.inbox),
        );
        expect(
          SystemScreenFactory.allSystemScreenKeys,
          contains(SystemScreenFactory.settings),
        );
      });

      test('allKeys is alias for allSystemScreenKeys', () {
        expect(
          SystemScreenFactory.allKeys,
          equals(SystemScreenFactory.allSystemScreenKeys),
        );
      });

      test('defaultSortOrders contains all screen keys', () {
        expect(SystemScreenFactory.defaultSortOrders, hasLength(13));
        expect(
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.inbox],
          0,
        );
        expect(
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.settings],
          12,
        );
      });
    });

    group('isSystemScreen', () {
      test('returns true for inbox', () {
        expect(SystemScreenFactory.isSystemScreen('inbox'), isTrue);
      });

      test('returns true for today', () {
        expect(SystemScreenFactory.isSystemScreen('today'), isTrue);
      });

      test('returns true for upcoming', () {
        expect(SystemScreenFactory.isSystemScreen('upcoming'), isTrue);
      });

      test('returns true for next_actions', () {
        expect(SystemScreenFactory.isSystemScreen('next_actions'), isTrue);
      });

      test('returns true for projects', () {
        expect(SystemScreenFactory.isSystemScreen('projects'), isTrue);
      });

      test('returns true for labels', () {
        expect(SystemScreenFactory.isSystemScreen('labels'), isTrue);
      });

      test('returns true for values', () {
        expect(SystemScreenFactory.isSystemScreen('values'), isTrue);
      });

      test('returns true for wellbeing', () {
        expect(SystemScreenFactory.isSystemScreen('wellbeing'), isTrue);
      });

      test('returns true for journal', () {
        expect(SystemScreenFactory.isSystemScreen('journal'), isTrue);
      });

      test('returns true for trackers', () {
        expect(SystemScreenFactory.isSystemScreen('trackers'), isTrue);
      });

      test('returns true for settings', () {
        expect(SystemScreenFactory.isSystemScreen('settings'), isTrue);
      });

      test('returns false for unknown key', () {
        expect(SystemScreenFactory.isSystemScreen('unknown'), isFalse);
      });

      test('returns false for empty string', () {
        expect(SystemScreenFactory.isSystemScreen(''), isFalse);
      });

      test('returns false for custom screen key', () {
        expect(SystemScreenFactory.isSystemScreen('my_custom_screen'), isFalse);
      });
    });

    group('getCategoryForKey', () {
      test('returns workspace for inbox', () {
        expect(
          SystemScreenFactory.getCategoryForKey('inbox'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for today', () {
        expect(
          SystemScreenFactory.getCategoryForKey('today'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for upcoming', () {
        expect(
          SystemScreenFactory.getCategoryForKey('upcoming'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for next_actions', () {
        expect(
          SystemScreenFactory.getCategoryForKey('next_actions'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for projects', () {
        expect(
          SystemScreenFactory.getCategoryForKey('projects'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for labels', () {
        expect(
          SystemScreenFactory.getCategoryForKey('labels'),
          ScreenCategory.workspace,
        );
      });

      test('returns workspace for values', () {
        expect(
          SystemScreenFactory.getCategoryForKey('values'),
          ScreenCategory.workspace,
        );
      });

      test('returns wellbeing for wellbeing', () {
        expect(
          SystemScreenFactory.getCategoryForKey('wellbeing'),
          ScreenCategory.wellbeing,
        );
      });

      test('returns wellbeing for journal', () {
        expect(
          SystemScreenFactory.getCategoryForKey('journal'),
          ScreenCategory.wellbeing,
        );
      });

      test('returns wellbeing for trackers', () {
        expect(
          SystemScreenFactory.getCategoryForKey('trackers'),
          ScreenCategory.wellbeing,
        );
      });

      test('returns settings for allocation_settings', () {
        expect(
          SystemScreenFactory.getCategoryForKey('allocation_settings'),
          ScreenCategory.settings,
        );
      });

      test('returns settings for navigation_settings', () {
        expect(
          SystemScreenFactory.getCategoryForKey('navigation_settings'),
          ScreenCategory.settings,
        );
      });

      test('returns settings for settings', () {
        expect(
          SystemScreenFactory.getCategoryForKey('settings'),
          ScreenCategory.settings,
        );
      });

      test('returns workspace for unknown key', () {
        expect(
          SystemScreenFactory.getCategoryForKey('unknown_key'),
          ScreenCategory.workspace,
        );
      });
    });

    group('createAll', () {
      test('creates all system screens for user', () {
        final screens = SystemScreenFactory.createAll(userId);

        // 11 screens in createAll (excludes allocationSettings and navigationSettings)
        expect(screens, hasLength(11));
      });

      test('all screens are marked as system', () {
        final screens = SystemScreenFactory.createAll(userId);

        for (final screen in screens) {
          expect(screen.isSystem, isTrue);
        }
      });

      test('screens have empty id (repository generates)', () {
        final screens = SystemScreenFactory.createAll(userId);

        for (final screen in screens) {
          expect(screen.id, isEmpty);
        }
      });

      test('screens have correct screenKey set', () {
        final screens = SystemScreenFactory.createAll(userId);
        final screenKeys = screens.map((s) => s.screenKey).toSet();

        expect(screenKeys, contains('inbox'));
        expect(screenKeys, contains('today'));
        expect(screenKeys, contains('upcoming'));
        expect(screenKeys, contains('projects'));
      });

      test('screens have names set', () {
        final screens = SystemScreenFactory.createAll(userId);

        for (final screen in screens) {
          expect(screen.name, isNotEmpty);
        }
      });
    });

    group('create', () {
      test('creates inbox screen', () {
        final screen = SystemScreenFactory.create(userId, 'inbox');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'inbox');
        expect(screen.name, 'Inbox');
        expect(screen.screenType, ScreenType.list);
        expect(screen.isSystem, isTrue);
      });

      test('creates today screen', () {
        final screen = SystemScreenFactory.create(userId, 'today');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'today');
        expect(screen.name, 'Today');
      });

      test('creates upcoming screen', () {
        final screen = SystemScreenFactory.create(userId, 'upcoming');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'upcoming');
        expect(screen.name, 'Upcoming');
      });

      test('creates next_actions screen', () {
        final screen = SystemScreenFactory.create(userId, 'next_actions');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'next_actions');
        expect(screen.name, 'Next Actions');
        expect(screen.screenType, ScreenType.focus);
      });

      test('creates projects screen', () {
        final screen = SystemScreenFactory.create(userId, 'projects');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'projects');
        expect(screen.name, 'Projects');
      });

      test('creates labels screen', () {
        final screen = SystemScreenFactory.create(userId, 'labels');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'labels');
        expect(screen.name, 'Labels');
      });

      test('creates values screen', () {
        final screen = SystemScreenFactory.create(userId, 'values');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'values');
        expect(screen.name, 'Values');
      });

      test('creates wellbeing screen', () {
        final screen = SystemScreenFactory.create(userId, 'wellbeing');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'wellbeing');
        expect(screen.name, 'Wellbeing');
      });

      test('creates journal screen', () {
        final screen = SystemScreenFactory.create(userId, 'journal');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'journal');
        expect(screen.name, 'Journal');
      });

      test('creates trackers screen', () {
        final screen = SystemScreenFactory.create(userId, 'trackers');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'trackers');
        expect(screen.name, 'Trackers');
      });

      test('creates settings screen', () {
        final screen = SystemScreenFactory.create(userId, 'settings');

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'settings');
        expect(screen.name, 'Settings');
      });

      test('creates allocation_settings screen', () {
        final screen = SystemScreenFactory.create(
          userId,
          'allocation_settings',
        );

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'allocation_settings');
        expect(screen.name, 'Allocation');
      });

      test('creates navigation_settings screen', () {
        final screen = SystemScreenFactory.create(
          userId,
          'navigation_settings',
        );

        expect(screen, isNotNull);
        expect(screen!.screenKey, 'navigation_settings');
        expect(screen.name, 'Navigation');
      });

      test('returns null for unknown key', () {
        final screen = SystemScreenFactory.create(userId, 'unknown_screen');

        expect(screen, isNull);
      });

      test('returns null for empty key', () {
        final screen = SystemScreenFactory.create(userId, '');

        expect(screen, isNull);
      });
    });

    group('screen sections', () {
      test('inbox has data section', () {
        final screen = SystemScreenFactory.create(userId, 'inbox');

        expect(screen!.sections, isNotEmpty);
      });

      test('today has agenda section', () {
        final screen = SystemScreenFactory.create(userId, 'today');

        expect(screen!.sections, isNotEmpty);
      });

      test('next_actions has allocation section', () {
        final screen = SystemScreenFactory.create(userId, 'next_actions');

        expect(screen!.sections, isNotEmpty);
      });
    });
  });
}
