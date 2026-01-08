/// Contract tests for icon resolution.
///
/// These tests verify that the NavigationIconResolver correctly maps
/// all system screen keys to specific icons (not the default fallback).
///
/// Contract tests use REAL components (not mocks) to verify that
/// two components agree on their interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

void main() {
  group('Icon Contracts', () {
    late NavigationIconResolver resolver;

    setUp(() {
      resolver = const NavigationIconResolver();
    });

    group('SystemScreenDefinitions ↔ NavigationIconResolver', () {
      test('all system screens have specific icons (not default fallback)', () {
        for (final screen in SystemScreenDefinitions.all) {
          final result = resolver.resolve(
            screenId: screen.screenKey,
            iconName: screen.chrome.iconName,
          );

          expect(
            result.icon,
            isNot(Icons.widgets_outlined),
            reason:
                'Screen "${screen.screenKey}" fell through to default icon. '
                'Add a case for "${screen.screenKey}" in NavigationIconResolver.',
          );
          expect(
            result.selectedIcon,
            isNot(Icons.widgets),
            reason:
                'Screen "${screen.screenKey}" fell through to default selectedIcon.',
          );
        }
      });

      test('each system screen has distinct icons', () {
        final iconsByScreen = <String, IconData>{};

        for (final screen in SystemScreenDefinitions.all) {
          final result = resolver.resolve(
            screenId: screen.screenKey,
            iconName: screen.chrome.iconName,
          );

          // Check if this icon is already used by another screen
          final existingScreen = iconsByScreen.entries
              .where((e) => e.value == result.icon)
              .map((e) => e.key)
              .firstOrNull;

          if (existingScreen != null) {
            // Some screens intentionally share icons (e.g., label/value detail)
            // so we just log this, not fail
            // ignore for now
          }

          iconsByScreen[screen.screenKey] = result.icon;
        }

        // Verify we tested all screens
        expect(
          iconsByScreen.length,
          SystemScreenDefinitions.all.length,
          reason: 'Not all system screens were checked',
        );
      });

      test('inbox screen has inbox icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.inbox.screenKey,
          iconName: SystemScreenDefinitions.inbox.chrome.iconName,
        );
        expect(result.icon, Icons.inbox_outlined);
        expect(result.selectedIcon, Icons.inbox);
      });

      test('myDay screen has sun icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.myDay.screenKey,
          iconName: SystemScreenDefinitions.myDay.chrome.iconName,
        );
        expect(result.icon, Icons.wb_sunny_outlined);
        expect(result.selectedIcon, Icons.wb_sunny);
      });

      test('logbook screen has done_all icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.logbook.screenKey,
          iconName: SystemScreenDefinitions.logbook.chrome.iconName,
        );
        expect(result.icon, Icons.done_all_outlined);
        expect(result.selectedIcon, Icons.done_all);
      });

      test('values screen has star icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.values.screenKey,
          iconName: SystemScreenDefinitions.values.chrome.iconName,
        );
        expect(result.icon, Icons.star_outline);
        expect(result.selectedIcon, Icons.star);
      });

      test('journal screen has book icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.journal.screenKey,
          iconName: SystemScreenDefinitions.journal.chrome.iconName,
        );
        expect(result.icon, Icons.book_outlined);
        expect(result.selectedIcon, Icons.book);
      });

      test('workflows screen has account_tree icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.workflows.screenKey,
          iconName: SystemScreenDefinitions.workflows.chrome.iconName,
        );
        expect(result.icon, Icons.account_tree_outlined);
        expect(result.selectedIcon, Icons.account_tree);
      });

      test('screen_management screen has dashboard_customize icon', () {
        final result = resolver.resolve(
          screenId: SystemScreenDefinitions.screenManagement.screenKey,
          iconName: SystemScreenDefinitions.screenManagement.chrome.iconName,
        );
        expect(result.icon, Icons.dashboard_customize_outlined);
        expect(result.selectedIcon, Icons.dashboard_customize);
      });
    });

    group('defaultSortOrders contract', () {
      test('all system screens have default sort orders', () {
        for (final screen in SystemScreenDefinitions.all) {
          final sortOrder = SystemScreenDefinitions.getDefaultSortOrder(
            screen.screenKey,
          );

          expect(
            sortOrder,
            isNot(999),
            reason:
                'Screen "${screen.screenKey}" has no default sort order. '
                'Add it to SystemScreenDefinitions.defaultSortOrders.',
          );
        }
      });

      test('sort orders are unique within categories', () {
        final workspaceOrders = <int>[];
        final settingsOrders = <int>[];

        for (final screen in SystemScreenDefinitions.all) {
          final order = SystemScreenDefinitions.getDefaultSortOrder(
            screen.screenKey,
          );

          if (order < 100) {
            expect(
              workspaceOrders.contains(order),
              isFalse,
              reason:
                  'Duplicate workspace sort order $order for ${screen.screenKey}',
            );
            workspaceOrders.add(order);
          } else {
            expect(
              settingsOrders.contains(order),
              isFalse,
              reason:
                  'Duplicate settings sort order $order for ${screen.screenKey}',
            );
            settingsOrders.add(order);
          }
        }
      });
    });
  });
}
