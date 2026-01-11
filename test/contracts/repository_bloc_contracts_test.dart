/// Contract tests for repository and BLoC stream interactions.
///
/// These tests verify that repositories emit data in formats
/// that BLoCs can correctly consume and transform into UI states.
///
/// Contract tests use REAL components to catch drift between
/// data layer and presentation layer expectations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

import '../helpers/contract_test_helpers.dart';

void main() {
  group('Repository â†” BLoC Contracts', () {
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // ScreenWithPreferences Contract
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    group('ScreenWithPreferences', () {
      testContract(
        'all system screens can be wrapped in ScreenWithPreferences',
        () {
          for (final screen in SystemScreenDefinitions.all) {
            final wrapped = ScreenWithPreferences(
              screen: screen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            );

            expect(wrapped.screen, isNotNull);
            expect(wrapped.screen.screenKey, screen.screenKey);
            expect(wrapped.preferences, isNotNull);
          }
        },
      );

      testContract('ScreenWithPreferences exposes all required properties', () {
        final screen = SystemScreenDefinitions.myDay;
        final wrapped = ScreenWithPreferences(
          screen: screen,
          preferences: const ScreenPreferences(isActive: true, sortOrder: 5),
        );

        // Properties that NavigationBloc expects
        expect(wrapped.screen.screenKey, isNotEmpty);
        expect(wrapped.screen.name, isNotEmpty);
        expect(wrapped.preferences.isActive, isNotNull);
        expect(wrapped.preferences.sortOrder, isNotNull);
      });
    });

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // NavigationBloc â†” NavigationIconResolver Contract
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    group('NavigationBloc â†” NavigationIconResolver', () {
      late NavigationIconResolver resolver;

      setUp(() {
        resolver = const NavigationIconResolver();
      });

      testContract(
        'NavigationDestination can be built from any system screen',
        () {
          for (final screen in SystemScreenDefinitions.all) {
            // Simulate what NavigationBloc does when building destinations
            final wrapped = ScreenWithPreferences(
              screen: screen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            );

            final icons = resolver.resolve(
              screenId: wrapped.screen.screenKey,
              iconName: wrapped.screen.chrome.iconName,
            );

            // All properties needed for NavigationDestination must be noncumen-null
            expect(wrapped.screen.name, isNotEmpty, reason: 'name required');
            expect(icons.icon, isNotNull, reason: 'icon required');
            expect(
              icons.selectedIcon,
              isNotNull,
              reason: 'selectedIcon required',
            );
          }
        },
      );
    });

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // Screen Definition Type Contracts
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    group('ScreenDefinition types', () {
      testContract('all system screens are of expected types', () {
        for (final screen in SystemScreenDefinitions.all) {
          // All system screens should be ScreenDefinition subclasses
          expect(screen, isA<ScreenDefinition>());

          // They should have required fields
          expect(screen.screenKey, isNotEmpty);
          expect(screen.name, isNotEmpty);
        }
      });

      testContract('data-driven screens have sections property', () {
        for (final screen in SystemScreenDefinitions.all) {
          // Unified model: all ScreenDefinitions have sections.
          expect(
            screen.sections,
            isNotNull,
            reason: 'sections should be accessible for ${screen.screenKey}',
          );
        }
      });
    });

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    // Sort Order Contracts
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    group('Sort order contracts', () {
      testContract('default sort order for settings is 100', () {
        expect(SystemScreenDefinitions.getDefaultSortOrder('settings'), 100);
      });

      testContract('default sort orders for main screens are < 100', () {
        for (final entry in SystemScreenDefinitions.defaultSortOrders.entries) {
          if (entry.key == 'settings') continue;
          expect(
            entry.value,
            lessThan(100),
            reason: '${entry.key} should sort before settings',
          );
        }
      });

      testContract('unknown screens sort last (999)', () {
        expect(SystemScreenDefinitions.getDefaultSortOrder('unknown_key'), 999);
      });
    });
  });
}
