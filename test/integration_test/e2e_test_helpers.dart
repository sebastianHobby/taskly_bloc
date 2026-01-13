/// End-to-end test helpers for Flutter integration tests.
///
/// E2E tests verify complete user journeys through the app.
/// They run on a real device/emulator with a real app instance.
///
/// ## Key Differences from Widget Tests
///
/// - Widget tests run in isolation with mocks
/// - E2E tests run the full app with real services
/// - E2E tests are slower but catch integration issues
///
/// ## Pattern
///
/// ```dart
/// void main() {
///   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
///
///   group('Navigation smoke test', () {
///     testWidgetsE2E('can navigate to all screens', (tester) async {
///       await tester.pumpFullApp();
///       await tester.loginAsTestUser();
///
///       for (final screenKey in ['inbox', 'today', 'projects']) {
///         await tester.navigateToScreen(screenKey);
///         await tester.expectScreenVisible(screenKey);
///       }
///     });
///   });
/// }
/// ```
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

// ═══════════════════════════════════════════════════════════════════════════
// E2E Test Constants
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for E2E tests (2 minutes).
///
/// E2E tests involve real I/O, animations, and network calls.
const Duration kE2ETestTimeout = Duration(minutes: 2);

/// Timeout for waiting for screen transitions.
const Duration kScreenTransitionTimeout = Duration(seconds: 10);

/// Timeout for waiting for data to load.
const Duration kDataLoadTimeout = Duration(seconds: 15);

/// Default pump frame count for E2E tests.
const int kE2EPumpFrames = 20;

// ═══════════════════════════════════════════════════════════════════════════
// E2E Test Wrapper
// ═══════════════════════════════════════════════════════════════════════════

/// E2E test with timeout protection.
///
/// Use for full app integration tests.
///
/// ```dart
/// testWidgetsE2E('user can complete task', (tester) async {
///   await tester.pumpFullApp();
///   // ... test user journey
/// });
/// ```
@isTest
void testWidgetsE2E(
  String description,
  Future<void> Function(WidgetTester) callback, {
  Duration timeout = kE2ETestTimeout,
  bool skip = false,
}) {
  testWidgets(
    description,
    skip: skip,
    (tester) async {
      await callback(tester).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'E2E test "$description" exceeded ${timeout.inSeconds}s. '
            'Check for: missing screen transitions, stuck animations, '
            'network timeouts, or infinite loading states.',
            timeout,
          );
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// E2E Pump Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// E2E-specific pump helpers.
extension E2EPumpHelpers on WidgetTester {
  /// Pumps frames suitable for E2E tests with streams and animations.
  ///
  /// More frames than widget tests because E2E involves more async operations.
  Future<void> pumpE2E([int frameCount = kE2EPumpFrames]) async {
    for (var i = 0; i < frameCount; i++) {
      await pump(const Duration(milliseconds: 50));
    }
  }

  /// Waits for a screen to load and become visible.
  ///
  /// Looks for common indicators:
  /// - Loading indicators disappearing
  /// - Content appearing
  /// - Error states (fails if found)
  Future<void> waitForScreenLoad({
    Duration timeout = kDataLoadTimeout,
    Finder? contentFinder,
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await pump(const Duration(milliseconds: 100));

      // Check for error state
      if (find.textContaining('Error').evaluate().isNotEmpty ||
          find.byIcon(Icons.error).evaluate().isNotEmpty) {
        fail('Screen showed error state during load');
      }

      // Check for loading indicator
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;

      // If specific content finder provided, wait for it
      if (contentFinder != null) {
        if (contentFinder.evaluate().isNotEmpty && !hasLoading) {
          return;
        }
      } else {
        // Otherwise just wait for loading to finish
        if (!hasLoading) {
          // Pump a few more frames to ensure UI is stable
          await pumpE2E(5);
          return;
        }
      }
    }

    fail('Screen did not finish loading within ${timeout.inSeconds}s');
  }

  /// Navigates to a screen by tapping on navigation item.
  ///
  /// Works with NavigationRail, BottomNavigationBar, or Drawer.
  Future<void> tapNavigationItem(String label) async {
    // Try NavigationRail first
    var navItem = find.ancestor(
      of: find.text(label),
      matching: find.byType(NavigationDestination),
    );

    if (navItem.evaluate().isEmpty) {
      // Try as direct text tap
      navItem = find.text(label);
    }

    if (navItem.evaluate().isEmpty) {
      fail('Navigation item "$label" not found');
    }

    await tap(navItem.first);
    await pumpE2E();
  }

  /// Finds and taps a widget, with retry logic.
  ///
  /// Useful for E2E where UI might still be rendering.
  Future<void> tapWithRetry(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    String? errorMessage,
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        await tap(finder.first);
        await pumpE2E();
        return;
      }
    }

    fail(errorMessage ?? 'Widget not found for tap: $finder');
  }

  /// Enters text into a field, with retry logic.
  Future<void> enterTextWithRetry(
    Finder finder,
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      await pump(const Duration(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) {
        await enterText(finder.first, text);
        await pumpE2E();
        return;
      }
    }

    fail('Text field not found: $finder');
  }

  /// Scrolls until a widget is visible.
  Future<void> scrollUntilVisible(
    Finder finder, {
    Finder? scrollable,
    double delta = -200,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    final scrollableFinder = scrollable ?? find.byType(Scrollable).first;

    while (stopwatch.elapsed < timeout) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }

      await drag(scrollableFinder, Offset(0, delta));
      await pumpE2E(3);
    }

    fail('Widget not found after scrolling: $finder');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// E2E Assertions
// ═══════════════════════════════════════════════════════════════════════════

/// Asserts that a screen is currently visible.
///
/// Checks for screen-specific content or title.
void expectScreenVisible(WidgetTester tester, String screenKey) {
  // Look for screen title or key-based identifier
  final hasTitle = find
      .text(_screenKeyToTitle(screenKey))
      .evaluate()
      .isNotEmpty;
  final hasKey = find.byKey(Key('screen_$screenKey')).evaluate().isNotEmpty;

  expect(
    hasTitle || hasKey,
    isTrue,
    reason: 'Expected screen "$screenKey" to be visible',
  );
}

/// Maps screen keys to expected titles.
String _screenKeyToTitle(String screenKey) {
  const titles = {
    'my_day': 'My Day',
    'scheduled': 'Scheduled',
    'someday': 'Someday',
    'today': 'Today',
    'upcoming': 'Upcoming',
    'logbook': 'Logbook',
    'projects': 'Projects',
    'labels': 'Labels',
    'values': 'Values',
    'next_actions': 'Next Actions',
    'settings': 'Settings',
    'workflows': 'Workflows',
    'screen_management': 'Screens',
    'statistics': 'Statistics',
    'journal': 'Journal',
  };
  return titles[screenKey] ?? screenKey;
}

/// Exception for E2E test timeout.
class TimeoutException implements Exception {
  TimeoutException(this.message, this.duration);
  final String message;
  final Duration duration;

  @override
  String toString() => 'TimeoutException: $message';
}
