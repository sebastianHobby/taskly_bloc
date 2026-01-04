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
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

import '../helpers/contract_test_helpers.dart';

void main() {
  group('Repository ↔ BLoC Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // ScreenWithPreferences Contract
    // ═══════════════════════════════════════════════════════════════════════

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
        final screen = SystemScreenDefinitions.inbox;
        final wrapped = ScreenWithPreferences(
          screen: screen,
          preferences: const ScreenPreferences(isActive: true, sortOrder: 5),
        );

        // Properties that NavigationBloc expects
        expect(wrapped.screen.screenKey, isNotEmpty);
        expect(wrapped.screen.name, isNotEmpty);
        expect(wrapped.screen.category, isNotNull);
        expect(wrapped.preferences.isActive, isNotNull);
        expect(wrapped.preferences.sortOrder, isNotNull);
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // NavigationBloc ↔ NavigationIconResolver Contract
    // ═══════════════════════════════════════════════════════════════════════

    group('NavigationBloc ↔ NavigationIconResolver', () {
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
              iconName: wrapped.screen.iconName,
            );

            // All properties needed for NavigationDestination must be non-null
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

    // ═══════════════════════════════════════════════════════════════════════
    // Screen Definition Type Contracts
    // ═══════════════════════════════════════════════════════════════════════

    group('ScreenDefinition types', () {
      testContract('all system screens are of expected types', () {
        for (final screen in SystemScreenDefinitions.all) {
          // All system screens should be ScreenDefinition subclasses
          expect(screen, isA<ScreenDefinition>());

          // They should have required fields
          expect(screen.screenKey, isNotEmpty);
          expect(screen.name, isNotEmpty);
          // category is available on all ScreenDefinition variants
          expect(screen.category, isNotNull);
        }
      });

      testContract('data-driven screens have sections property', () {
        for (final screen in SystemScreenDefinitions.all) {
          // Only DataDrivenScreenDefinition has sections
          if (screen is DataDrivenScreenDefinition) {
            expect(
              screen.sections,
              isNotNull,
              reason: 'sections should be accessible for ${screen.screenKey}',
            );
            expect(
              screen.screenType,
              isNotNull,
              reason: 'screenType should be set for ${screen.screenKey}',
            );
          }
        }
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // Category Contracts
    // ═══════════════════════════════════════════════════════════════════════

    group('ScreenCategory contracts', () {
      testContract('system screens have consistent category assignments', () {
        // Workspace screens
        expect(
          SystemScreenDefinitions.inbox.category,
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenDefinitions.myDay.category,
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenDefinitions.planned.category,
          ScreenCategory.workspace,
        );
        expect(
          SystemScreenDefinitions.projects.category,
          ScreenCategory.workspace,
        );

        // Settings screens
        expect(
          SystemScreenDefinitions.settings.category,
          ScreenCategory.settings,
        );
        expect(
          SystemScreenDefinitions.screenManagement.category,
          ScreenCategory.settings,
        );
      });

      testContract(
        'all system screens belong to a valid category',
        () {
          for (final screen in SystemScreenDefinitions.all) {
            expect(
              screen.category,
              anyOf(
                ScreenCategory.workspace,
                ScreenCategory.wellbeing,
                ScreenCategory.settings,
              ),
              reason: '${screen.screenKey} has unexpected category',
            );
          }
        },
      );
    });

    // ═══════════════════════════════════════════════════════════════════════
    // Sort Order Contracts
    // ═══════════════════════════════════════════════════════════════════════

    group('Sort order contracts', () {
      testContract('workspace screens have sort orders < 100', () {
        for (final screen in SystemScreenDefinitions.all) {
          if (screen.category == ScreenCategory.workspace) {
            final order = SystemScreenDefinitions.getDefaultSortOrder(
              screen.screenKey,
            );
            expect(
              order,
              lessThan(100),
              reason:
                  '${screen.screenKey} is workspace but has order >= 100: $order',
            );
          }
        }
      });

      testContract('settings screens have sort orders >= 100', () {
        for (final screen in SystemScreenDefinitions.all) {
          if (screen.category == ScreenCategory.settings) {
            final order = SystemScreenDefinitions.getDefaultSortOrder(
              screen.screenKey,
            );
            expect(
              order,
              greaterThanOrEqualTo(100),
              reason:
                  '${screen.screenKey} is settings but has order < 100: $order',
            );
          }
        }
      });
    });
  });
}
