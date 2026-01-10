import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_section_params.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

void main() {
  group('SystemScreenDefinitions', () {
    group('myDay', () {
      test('is defined correctly', () {
        final myDay = SystemScreenDefinitions.myDay;

        expect(myDay.screenKey, 'my_day');
        expect(myDay.name, 'My Day');
        expect(myDay, isA<ScreenDefinition>());

        final allocationRef = myDay.sections.firstWhere(
          (s) => s.templateId == SectionTemplateId.allocation,
        );
        final params = AllocationSectionParams.fromJson(allocationRef.params);
        expect(params.showExcludedSection, isTrue);
        expect(params.showExcludedWarnings, isTrue);
        expect(params.displayMode, AllocationDisplayMode.groupedByProject);
      });
    });

    group('legacy screens removed', () {
      test('today is no longer defined', () {
        expect(SystemScreenDefinitions.getByKey('today'), isNull);
      });

      test('next_actions is no longer defined', () {
        expect(SystemScreenDefinitions.getByKey('next_actions'), isNull);
      });
    });

    group('all list', () {
      test('contains myDay', () {
        expect(
          SystemScreenDefinitions.all.map((s) => s.screenKey),
          contains('my_day'),
        );
      });

      test('does not contain today or next_actions', () {
        final keys = SystemScreenDefinitions.all
            .map((s) => s.screenKey)
            .toList();
        expect(keys, isNot(contains('today')));
        expect(keys, isNot(contains('next_actions')));
      });

      test('contains expected screens', () {
        final keys = SystemScreenDefinitions.all
            .map((s) => s.screenKey)
            .toList();
        expect(
          keys,
          containsAll([
            'my_day',
            'scheduled',
            'projects',
            'values',
            'settings',
            'journal',
          ]),
        );
        // Hidden/sub-screens are included in all
        expect(keys.contains('workflows'), isTrue);
        expect(keys.contains('screen_management'), isTrue);
      });
    });

    group('getByKey', () {
      test('returns myDay for my_day key', () {
        expect(
          SystemScreenDefinitions.getByKey('my_day'),
          SystemScreenDefinitions.myDay,
        );
      });

      test('returns null for removed screens', () {
        expect(SystemScreenDefinitions.getByKey('today'), isNull);
        expect(SystemScreenDefinitions.getByKey('next_actions'), isNull);
      });

      test('returns correct screen for existing keys', () {
        expect(
          SystemScreenDefinitions.getByKey('scheduled'),
          SystemScreenDefinitions.scheduled,
        );
      });

      test('returns null for legacy aliases (no longer supported)', () {
        // Legacy aliases have been removed - unknown keys return null
        expect(SystemScreenDefinitions.getByKey('upcoming'), isNull);
        expect(SystemScreenDefinitions.getByKey('wellbeing'), isNull);
      });
    });

    group('defaultSortOrders', () {
      test('has myDay at position 0', () {
        expect(SystemScreenDefinitions.defaultSortOrders['my_day'], 0);
      });

      test('does not have today or next_actions', () {
        expect(
          SystemScreenDefinitions.defaultSortOrders.containsKey('today'),
          isFalse,
        );
        expect(
          SystemScreenDefinitions.defaultSortOrders.containsKey('next_actions'),
          isFalse,
        );
      });

      test('has correct order for remaining screens', () {
        expect(SystemScreenDefinitions.defaultSortOrders['my_day'], 0);
        expect(SystemScreenDefinitions.defaultSortOrders['scheduled'], 1);
        expect(SystemScreenDefinitions.defaultSortOrders['someday'], 2);
        expect(SystemScreenDefinitions.defaultSortOrders['journal'], 3);
        expect(SystemScreenDefinitions.defaultSortOrders['values'], 4);
        expect(SystemScreenDefinitions.defaultSortOrders['projects'], 5);
        expect(SystemScreenDefinitions.defaultSortOrders['statistics'], 6);
        expect(SystemScreenDefinitions.defaultSortOrders['orphan_tasks'], 7);
        expect(SystemScreenDefinitions.defaultSortOrders['workflows'], 8);
        expect(
          SystemScreenDefinitions.defaultSortOrders['screen_management'],
          9,
        );
        expect(SystemScreenDefinitions.defaultSortOrders['settings'], 100);

        // Sub-screens that exist but don't appear in navigation ordering.
        expect(SystemScreenDefinitions.defaultSortOrders['logbook'], isNull);
      });

      test('does not have legacy aliases', () {
        // Legacy aliases have been removed
        expect(
          SystemScreenDefinitions.defaultSortOrders.containsKey('upcoming'),
          isFalse,
        );
        expect(
          SystemScreenDefinitions.defaultSortOrders.containsKey('wellbeing'),
          isFalse,
        );
      });
    });

    group('getDefaultSortOrder', () {
      test('returns correct order for myDay', () {
        expect(SystemScreenDefinitions.getDefaultSortOrder('my_day'), 0);
      });

      test('returns 999 for removed screens', () {
        expect(SystemScreenDefinitions.getDefaultSortOrder('today'), 999);
        expect(
          SystemScreenDefinitions.getDefaultSortOrder('next_actions'),
          999,
        );
      });
    });

    group('isSystemScreen', () {
      test('returns true for myDay', () {
        expect(SystemScreenDefinitions.isSystemScreen('my_day'), isTrue);
      });

      test('returns false for removed screens', () {
        expect(SystemScreenDefinitions.isSystemScreen('today'), isFalse);
        expect(SystemScreenDefinitions.isSystemScreen('next_actions'), isFalse);
      });
    });

    group('allKeys', () {
      test('contains my_day', () {
        expect(SystemScreenDefinitions.allKeys, contains('my_day'));
      });

      test('does not contain removed screens', () {
        expect(SystemScreenDefinitions.allKeys, isNot(contains('today')));
        expect(
          SystemScreenDefinitions.allKeys,
          isNot(contains('next_actions')),
        );
      });
    });
  });
}
