/// Contract tests for repository and BLoC stream interactions.
///
/// These tests verify that repositories emit data in formats
/// that BLoCs can correctly consume and transform into UI states.
///
/// Contract tests use REAL components to catch drift between
/// data layer and presentation layer expectations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/interfaces/screen_catalog_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';
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
          for (final screen in SystemScreenSpecs.all) {
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
        final screen = SystemScreenSpecs.myDay;
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
          for (final screen in SystemScreenSpecs.all) {
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

    // ═══════════════════════════════════════════════════════════════════════
    // Screen Definition Type Contracts
    // ═══════════════════════════════════════════════════════════════════════

    group('ScreenSpec types', () {
      testContract('all system screens have required fields', () {
        for (final screen in SystemScreenSpecs.all) {
          expect(screen.screenKey, isNotEmpty);
          expect(screen.name, isNotEmpty);
        }
      });

      testContract('all system screens expose module slots', () {
        for (final screen in SystemScreenSpecs.all) {
          expect(screen.modules, isNotNull);
        }
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // Sort Order Contracts
    // ═══════════════════════════════════════════════════════════════════════

    group('Sort order contracts', () {
      testContract('default sort order for settings is 100', () {
        expect(SystemScreenSpecs.getDefaultSortOrder('settings'), 100);
      });

      testContract('default sort orders for main screens are < 100', () {
        for (final screen in SystemScreenSpecs.navigationScreens) {
          if (screen.screenKey == 'settings') continue;
          expect(
            SystemScreenSpecs.getDefaultSortOrder(screen.screenKey),
            lessThan(100),
            reason: '${screen.screenKey} should sort before settings',
          );
        }
      });

      testContract('unknown screens sort last (999)', () {
        expect(SystemScreenSpecs.getDefaultSortOrder('unknown'), 999);
      });
    });
  });
}
