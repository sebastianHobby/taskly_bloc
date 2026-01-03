import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/features/screens/system_screen_factory.dart';
import 'package:taskly_bloc/data/services/system_screen_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

class MockScreenDefinitionsRepositoryContract extends Mock
    implements ScreenDefinitionsRepositoryContract {}

void main() {
  group('SystemScreenSeeder', () {
    late MockScreenDefinitionsRepositoryContract mockRepository;
    late SystemScreenSeeder seeder;

    setUpAll(() {
      initializeTalkerForTest();
      registerFallbackValue(<ScreenDefinition>[]);
    });

    setUp(() {
      mockRepository = MockScreenDefinitionsRepositoryContract();
      seeder = SystemScreenSeeder(mockRepository);
    });

    group('seedAll', () {
      test('calls seedSystemScreens with all system screens', () async {
        when(
          () => mockRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('test-user-123');

        final captured = verify(
          () => mockRepository.seedSystemScreens(captureAny()),
        ).captured;
        expect(captured, hasLength(1));

        final screens = captured.first as List<ScreenDefinition>;
        expect(screens, isNotEmpty);
        // createAll returns 11 screens (excludes allocation_settings and
        // navigation_settings which are accessed via Settings screen)
        expect(screens.length, 11);
      });

      test('creates screens with correct screen keys', () async {
        when(
          () => mockRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('user-456');

        final captured = verify(
          () => mockRepository.seedSystemScreens(captureAny()),
        ).captured;

        final screens = captured.first as List<ScreenDefinition>;
        final screenKeys = screens.map((s) => s.screenKey).toSet();
        // createAll returns 11 screens (excludes allocation_settings and
        // navigation_settings which are accessed via Settings screen)
        expect(screenKeys.length, 11);
      });

      test('creates all expected system screens', () async {
        when(
          () => mockRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('test-user');

        final captured = verify(
          () => mockRepository.seedSystemScreens(captureAny()),
        ).captured;

        final screens = captured.first as List<ScreenDefinition>;
        final screenKeys = screens.map((s) => s.screenKey).toList();

        expect(screenKeys, contains(SystemScreenFactory.inbox));
        expect(screenKeys, contains(SystemScreenFactory.today));
        expect(screenKeys, contains(SystemScreenFactory.upcoming));
        expect(screenKeys, contains(SystemScreenFactory.nextActions));
        expect(screenKeys, contains(SystemScreenFactory.projects));
        expect(screenKeys, contains(SystemScreenFactory.labels));
        expect(screenKeys, contains(SystemScreenFactory.values));
        expect(screenKeys, contains(SystemScreenFactory.wellbeing));
        expect(screenKeys, contains(SystemScreenFactory.journal));
        expect(screenKeys, contains(SystemScreenFactory.trackers));
        expect(screenKeys, contains(SystemScreenFactory.settings));
        // allocation_settings and navigation_settings are accessed via
        // Settings screen and are not seeded as navigation destinations
      });

      test('marks all screens as system screens', () async {
        when(
          () => mockRepository.seedSystemScreens(any()),
        ).thenAnswer((_) async {});

        await seeder.seedAll('test-user');

        final captured = verify(
          () => mockRepository.seedSystemScreens(captureAny()),
        ).captured;

        final screens = captured.first as List<ScreenDefinition>;
        for (final screen in screens) {
          expect(screen.isSystem, isTrue);
        }
      });

      test('propagates repository errors', () async {
        when(
          () => mockRepository.seedSystemScreens(any()),
        ).thenThrow(Exception('Database error'));

        expect(
          () => seeder.seedAll('test-user'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('SystemScreenFactory', () {
    group('isSystemScreen', () {
      test('returns true for all system screen keys', () {
        for (final key in SystemScreenFactory.allKeys) {
          expect(SystemScreenFactory.isSystemScreen(key), isTrue);
        }
      });

      test('returns false for non-system screen keys', () {
        expect(SystemScreenFactory.isSystemScreen('custom_screen'), isFalse);
        expect(SystemScreenFactory.isSystemScreen('random'), isFalse);
        expect(SystemScreenFactory.isSystemScreen(''), isFalse);
      });
    });

    group('getCategoryForKey', () {
      test('returns workspace for workspace screens', () {
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.inbox),
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.today),
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.upcoming),
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.projects),
          ScreenCategory.workspace,
        );
      });

      test('returns wellbeing for wellbeing screens', () {
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.wellbeing),
          ScreenCategory.wellbeing,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.journal),
          ScreenCategory.wellbeing,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.trackers),
          ScreenCategory.wellbeing,
        );
      });

      test('returns settings for settings screens', () {
        // Note: allocation_settings and navigation_settings are still valid
        // screen keys but are not shown in navigation menu
        expect(
          SystemScreenFactory.getCategoryForKey(
            SystemScreenFactory.allocationSettings,
          ),
          ScreenCategory.settings,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(
            SystemScreenFactory.navigationSettings,
          ),
          ScreenCategory.settings,
        );
        expect(
          SystemScreenFactory.getCategoryForKey(SystemScreenFactory.settings),
          ScreenCategory.settings,
        );
      });
    });

    group('allKeys', () {
      test('contains expected number of screens', () {
        // allKeys includes all 13 system screen keys (including
        // allocation_settings and navigation_settings)
        expect(SystemScreenFactory.allKeys.length, 13);
      });

      test('contains no duplicates', () {
        final uniqueKeys = SystemScreenFactory.allKeys.toSet();
        expect(uniqueKeys.length, SystemScreenFactory.allKeys.length);
      });
    });

    group('defaultSortOrders', () {
      test('contains all screen keys', () {
        for (final key in SystemScreenFactory.allKeys) {
          expect(
            SystemScreenFactory.defaultSortOrders.containsKey(key),
            isTrue,
          );
        }
      });

      test('workspace screens have lower sort orders', () {
        final workspaceOrders = [
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.inbox]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.today]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.upcoming]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory
              .nextActions]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.projects]!,
        ];

        for (final order in workspaceOrders) {
          // Workspace screens have sequential orders 0-6
          expect(order, lessThan(10));
        }
      });

      test('wellbeing screens have medium sort orders', () {
        final wellbeingOrders = [
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.wellbeing]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.journal]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.trackers]!,
        ];

        for (final order in wellbeingOrders) {
          // Wellbeing screens are sequential after workspace (7-9)
          expect(order, greaterThanOrEqualTo(7));
          expect(order, lessThan(10));
        }
      });

      test('settings screens have high sort orders', () {
        // Settings-related screens have orders 10-12
        final settingsOrders = [
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory
              .allocationSettings]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory
              .navigationSettings]!,
          SystemScreenFactory.defaultSortOrders[SystemScreenFactory.settings]!,
        ];

        for (final order in settingsOrders) {
          expect(order, greaterThanOrEqualTo(10));
        }
      });
    });

    group('createAll', () {
      test('creates screen definitions for user', () {
        final screens = SystemScreenFactory.createAll('test-user');
        // createAll returns 11 screens (excludes allocation_settings and
        // navigation_settings which are accessed via Settings screen)
        expect(screens.length, 11);
      });

      test('all screens have correct screen keys', () {
        final screens = SystemScreenFactory.createAll('user-123');

        final screenKeys = screens.map((s) => s.screenKey).toSet();
        // createAll returns 11 screens
        expect(screenKeys.length, 11);
      });

      test('all screens are marked as system screens', () {
        final screens = SystemScreenFactory.createAll('test-user');

        for (final screen in screens) {
          expect(screen.isSystem, isTrue);
        }
      });

      test('screens have non-empty names', () {
        final screens = SystemScreenFactory.createAll('test-user');

        for (final screen in screens) {
          expect(screen.name, isNotEmpty);
        }
      });

      test('screens have non-empty icons', () {
        final screens = SystemScreenFactory.createAll('test-user');

        for (final screen in screens) {
          expect(screen.iconName, isNotEmpty);
        }
      });
    });
  });
}
