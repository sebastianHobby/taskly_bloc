/// Contract tests for route generation.
///
/// These tests verify that the Routing utility and GoRouter agree on
/// paths for all system screens.
///
/// Contract tests use REAL components to verify that two components
/// agree on their interface - catching drift between implementations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';

void main() {
  group('Route Contracts', () {
    group('Routing.screenPath ↔ SystemScreenDefinitions', () {
      test('all system screens produce valid paths', () {
        for (final screen in SystemScreenDefinitions.all) {
          final path = Routing.screenPath(screen.screenKey);

          // Path should start with /
          expect(
            path.startsWith('/'),
            isTrue,
            reason: 'Path for "${screen.screenKey}" should start with /',
          );

          // Path should not contain underscores (converted to hyphens)
          expect(
            path.contains('_'),
            isFalse,
            reason:
                'Path for "${screen.screenKey}" contains underscores: $path',
          );

          // Path should not have double slashes
          expect(
            path.contains('//'),
            isFalse,
            reason: 'Path for "${screen.screenKey}" has double slashes: $path',
          );

          // Path should be lowercase
          expect(
            path,
            path.toLowerCase(),
            reason: 'Path for "${screen.screenKey}" is not lowercase: $path',
          );
        }
      });

      test('screenKey round-trips through path conversion', () {
        for (final screen in SystemScreenDefinitions.all) {
          final path = Routing.screenPath(screen.screenKey);
          final segment = path.substring(1); // Remove leading /
          final restored = Routing.parseScreenKey(segment);

          expect(
            restored,
            screen.screenKey,
            reason:
                'Round-trip failed: '
                '"${screen.screenKey}" → "$path" → "$restored"',
          );
        }
      });

      test('my_day screen has /my-day path', () {
        final path = Routing.screenPath(
          SystemScreenDefinitions.myDay.screenKey,
        );
        expect(path, '/my-day');
      });
    });

    group('SystemScreenDefinitions.getById', () {
      test('all system screen keys are recognized by getById', () {
        for (final screen in SystemScreenDefinitions.all) {
          final found = SystemScreenDefinitions.getById(screen.screenKey);

          expect(
            found,
            isNotNull,
            reason:
                'SystemScreenDefinitions.getById("${screen.screenKey}") returned null',
          );
          expect(found!.screenKey, screen.screenKey);
        }
      });

      test('unknown screen keys return null', () {
        final found = SystemScreenDefinitions.getById('unknown_screen_xyz');
        expect(found, isNull);
      });
    });

    group('Router path matching', () {
      // These tests verify the actual route patterns that GoRouter expects
      // correspond to what Routing.screenPath generates

      test('segment pattern matches all system screens', () {
        // The router uses /:segment for the unified screen route
        // This tests that all system screen paths match that pattern

        final segmentPattern = RegExp(r'^/[a-z0-9-]+$');

        for (final screen in SystemScreenDefinitions.all) {
          final path = Routing.screenPath(screen.screenKey);

          expect(
            segmentPattern.hasMatch(path),
            isTrue,
            reason:
                'Path "$path" for "${screen.screenKey}" '
                'does not match /:segment pattern',
          );
        }
      });

      test('no system screen paths conflict with special routes', () {
        // Only entity routes and workflow-run are special (not convention-based)
        // All other routes use the /:segment pattern via Routing.buildScreen()
        const specialRoutes = <String>{
          '/task',
          '/project',
          '/label',
          '/value',
          '/workflow-run',
        };

        for (final screen in SystemScreenDefinitions.all) {
          final path = Routing.screenPath(screen.screenKey);

          // Exact match check
          expect(
            specialRoutes.contains(path),
            isFalse,
            reason:
                'Screen "${screen.screenKey}" path "$path" '
                'conflicts with a special route',
          );

          // Prefix check (e.g., /task/... for task details)
          for (final special in specialRoutes) {
            if (path.startsWith('$special/') || path == special) {
              fail(
                'Screen "${screen.screenKey}" path "$path" '
                'conflicts with special route "$special"',
              );
            }
          }
        }
      });
    });
  });
}
