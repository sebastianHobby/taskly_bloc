import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

void main() {
  group('SystemScreenSpecs', () {
    group('myDay', () {
      test('is defined correctly', () {
        final myDay = SystemScreenSpecs.myDay;

        expect(myDay.screenKey, 'my_day');
        expect(myDay.name, 'My Day');
        expect(myDay, isA<ScreenSpec>());

        final module = myDay.modules.primary
            .whereType<ScreenModuleHierarchyValueProjectTaskV2>()
            .single;

        final params = module.params;
        expect(params.sources, hasLength(1));
        expect(
          params.sources.single,
          isA<AllocationSnapshotTasksTodayDataConfig>(),
        );
        expect(
          params.enrichment.items.any(
            (i) => i.maybeWhen(
              allocationMembership: () => true,
              orElse: () => false,
            ),
          ),
          isTrue,
        );
      });
    });

    group('legacy screens removed', () {
      test('today is no longer defined', () {
        expect(SystemScreenSpecs.getByKey('today'), isNull);
      });

      test('next_actions is no longer defined', () {
        expect(SystemScreenSpecs.getByKey('next_actions'), isNull);
      });

      test('workflows is no longer defined', () {
        expect(SystemScreenSpecs.getByKey('workflows'), isNull);
      });
    });

    group('all list', () {
      test('contains myDay', () {
        expect(
          SystemScreenSpecs.all.map((s) => s.screenKey),
          contains('my_day'),
        );
      });

      test('does not contain today or next_actions', () {
        final keys = SystemScreenSpecs.all.map((s) => s.screenKey).toList();
        expect(keys, isNot(contains('today')));
        expect(keys, isNot(contains('next_actions')));
      });

      test('contains expected screens', () {
        final keys = SystemScreenSpecs.all.map((s) => s.screenKey).toList();
        expect(
          keys,
          containsAll([
            'my_day',
            'scheduled',
            'someday',
            'journal',
            'values',
            'projects',
            'statistics',
            'settings',
            'browse',
          ]),
        );

        // Legacy / removed screens are not included.
        expect(keys.contains('workflows'), isFalse);
        expect(keys.contains('screen_management'), isFalse);
      });
    });

    group('getByKey', () {
      test('returns myDay for my_day key', () {
        expect(SystemScreenSpecs.getByKey('my_day'), SystemScreenSpecs.myDay);
      });

      test('returns null for removed screens', () {
        expect(SystemScreenSpecs.getByKey('today'), isNull);
        expect(SystemScreenSpecs.getByKey('next_actions'), isNull);
      });

      test('returns correct screen for existing keys', () {
        expect(
          SystemScreenSpecs.getByKey('scheduled'),
          SystemScreenSpecs.scheduled,
        );
      });

      test('returns settings screens for existing keys', () {
        expect(
          SystemScreenSpecs.getByKey('allocation_settings'),
          SystemScreenSpecs.allocationSettings,
        );
        expect(
          SystemScreenSpecs.getByKey('attention_rules'),
          SystemScreenSpecs.attentionRules,
        );
      });
    });

    group('getDefaultSortOrder', () {
      test('returns correct order for myDay', () {
        expect(SystemScreenSpecs.getDefaultSortOrder('my_day'), 0);
      });

      test('returns 999 for unknown screens', () {
        expect(SystemScreenSpecs.getDefaultSortOrder('today'), 999);
        expect(SystemScreenSpecs.getDefaultSortOrder('next_actions'), 999);
      });
    });

    group('isSystemScreen', () {
      test('returns true for myDay', () {
        expect(SystemScreenSpecs.isSystemScreen('my_day'), isTrue);
      });

      test('returns false for removed screens', () {
        expect(SystemScreenSpecs.isSystemScreen('today'), isFalse);
        expect(SystemScreenSpecs.isSystemScreen('next_actions'), isFalse);
      });
    });
  });
}
