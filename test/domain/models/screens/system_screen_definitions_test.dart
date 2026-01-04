import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

void main() {
  group('SystemScreenDefinitions', () {
    group('myDay', () {
      test('is defined correctly', () {
        final myDay = SystemScreenDefinitions.myDay;

        expect(myDay.screenKey, 'my_day');
        expect(myDay.name, 'My Day');
        expect(myDay, isA<DataDrivenScreenDefinition>());

        final dataDriven = myDay as DataDrivenScreenDefinition;
        expect(dataDriven.screenType, ScreenType.focus);
        expect(dataDriven.sections.length, 1);
        expect(dataDriven.sections.first, isA<AllocationSection>());

        final section = dataDriven.sections.first as AllocationSection;
        expect(section.showExcludedSection, isTrue);
        expect(section.showExcludedWarnings, isTrue);
        expect(section.displayMode, AllocationDisplayMode.pinnedFirst);
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
            'inbox',
            'my_day',
            'upcoming',
            'logbook',
            'projects',
            'labels',
            'values',
            'settings',
            'wellbeing',
            'workflows',
            'screen_management',
          ]),
        );
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
          SystemScreenDefinitions.getByKey('inbox'),
          SystemScreenDefinitions.inbox,
        );
        expect(
          SystemScreenDefinitions.getByKey('upcoming'),
          SystemScreenDefinitions.upcoming,
        );
      });
    });

    group('defaultSortOrders', () {
      test('has myDay at position 1', () {
        expect(SystemScreenDefinitions.defaultSortOrders['my_day'], 1);
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
        expect(SystemScreenDefinitions.defaultSortOrders['inbox'], 0);
        expect(SystemScreenDefinitions.defaultSortOrders['my_day'], 1);
        expect(SystemScreenDefinitions.defaultSortOrders['upcoming'], 2);
        expect(SystemScreenDefinitions.defaultSortOrders['logbook'], 3);
        expect(SystemScreenDefinitions.defaultSortOrders['projects'], 4);
        expect(SystemScreenDefinitions.defaultSortOrders['labels'], 5);
        expect(SystemScreenDefinitions.defaultSortOrders['values'], 6);
        expect(SystemScreenDefinitions.defaultSortOrders['orphan_tasks'], 7);
      });
    });

    group('getDefaultSortOrder', () {
      test('returns correct order for myDay', () {
        expect(SystemScreenDefinitions.getDefaultSortOrder('my_day'), 1);
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
