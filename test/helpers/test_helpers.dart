import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for total test duration (30 seconds).
///
/// Flutter's `@Timeout` only triggers on **inactivity**. Our wrapper
/// enforces this as a **hard limit** regardless of test activity.
const Duration kDefaultTestTimeout = Duration(seconds: 30);

/// Default timeout for stream operations (5 seconds).
/// Used by waitForStreamEmissions, expectStreamEmits, etc.
const Duration kDefaultStreamTimeout = Duration(seconds: 5);

/// Default timeout for pumpUntilFound operations (2 seconds).
const Duration kDefaultPumpTimeout = Duration(seconds: 2);

/// Global safety net timeout (60 seconds).
/// Reference value for dart_test.yaml - tests should never reach this.
const Duration kGlobalSafetyTimeout = Duration(seconds: 60);

// ═══════════════════════════════════════════════════════════════════════════
// Safe Test Wrappers
// ═══════════════════════════════════════════════════════════════════════════

/// Widget test with **hard timeout** on total duration.
///
/// Use instead of `testWidgets` to prevent infinite hangs.
///
/// ## Why this exists
///
/// `testWidgets` + `pumpAndSettle()` can hang indefinitely because:
/// - BLoC streams continuously schedule frames
/// - `@Timeout` only triggers on inactivity (not active pumping)
/// - Default `pumpAndSettle` timeout is **10 minutes**
///
/// ## Usage
///
/// ```dart
/// testWidgetsSafe('shows user name', (tester) async {
///   await tester.pumpWidget(MyApp());
///   await tester.pumpForStream(); // NOT pumpAndSettle()
///   expect(find.text('John'), findsOneWidget);
/// });
///
/// // Custom timeout for slow tests:
/// testWidgetsSafe('integration flow', timeout: Duration(seconds: 60), (tester) async {
///   // ...
/// });
/// ```
@isTest
void testWidgetsSafe(
  String description,
  Future<void> Function(WidgetTester) callback, {
  Duration timeout = kDefaultTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  testWidgets(
    description,
    skip: skip,
    tags: tags,
    (tester) async {
      try {
        await callback(tester).timeout(
          timeout,
          onTimeout: () {
            _dumpWidgetTestDiagnostics(description);
            throw TimeoutException(
              'Test "$description" exceeded ${timeout.inSeconds}s total duration. '
              'Check for: pumpAndSettle() with streams, unclosed subscriptions, '
              'or infinite animations. Use pumpForStream() instead.',
              timeout,
            );
          },
        );
      } finally {
        // Flush short-lived timers, then dispose widgets before tearDown.
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 200));
      }
    },
  );
}

/// Unit test with **hard timeout** on total duration.
///
/// Use instead of `test` for async tests to prevent infinite hangs.
///
/// ## Usage
///
/// ```dart
/// testSafe('processes stream', () async {
///   final results = await myStream.take(5).toList();
///   expect(results, hasLength(5));
/// });
/// ```
@isTest
void testSafe(
  String description,
  Future<void> Function() callback, {
  Duration timeout = kDefaultTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  test(
    description,
    skip: skip,
    tags: tags,
    () async {
      await callback().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Test "$description" exceeded ${timeout.inSeconds}s total duration. '
            'Check for unresolved futures or infinite streams.',
            timeout,
          );
        },
      );
    },
  );
}

void _dumpWidgetTestDiagnostics(String description) {
  try {
    debugPrint('--- Widget test timeout diagnostics: "$description" ---');
    debugPrint('Dumping widget tree...');
    debugDumpApp();
    debugPrint('Dumping render tree...');
    debugDumpRenderTree();
    debugPrint('Dumping focus tree...');
    debugDumpFocusTree();
    debugPrint('Dumping semantics tree...');
    debugDumpSemanticsTree();

    final scheduler = SchedulerBinding.instance;
    debugPrint(
      'Scheduler: phase=${scheduler.schedulerPhase} '
      'hasScheduledFrame=${scheduler.hasScheduledFrame} '
      'transientCallbacks=${scheduler.transientCallbackCount}',
    );
    debugPrint('--- End widget test timeout diagnostics ---');
  } catch (error, stackTrace) {
    debugPrint(
      'Widget test timeout diagnostics failed: $error\n$stackTrace',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pump Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Essential pump helpers for stream-based widgets.
///
/// ## Quick Reference
///
/// | Scenario | Method |
/// |----------|--------|
/// | BLoC/stream widgets | `pumpForStream()` |
/// | Known animation | `pump(Duration(...))` |
/// | Wait for async widget | `pumpUntilFound(finder)` |
/// | Pure widgets, no streams | `pumpAndSettle()` ← only safe without streams |
extension PumpHelpers on WidgetTester {
  /// Pumps multiple frames for BLoC/stream-based widgets.
  ///
  /// **Use this instead of `pumpAndSettle()`** when your widget has:
  /// - BLoC with `watchAll()`, `watchAuthState()`, etc.
  /// - Any stream subscription
  /// - Continuous state updates
  ///
  /// ## Why pumpAndSettle() hangs
  ///
  /// `pumpAndSettle()` loops until no frames are scheduled.
  /// Streams continuously schedule frames → infinite loop → 10 min timeout.
  ///
  /// ## Why this works
  ///
  /// `pump()` without duration processes ONE frame without waiting.
  /// We pump enough frames for the UI to stabilize.
  ///
  /// ```dart
  /// await tester.pumpWidget(MyBlocWidget());
  /// await tester.pumpForStream(); // ✅ Safe
  /// // await tester.pumpAndSettle(); // ❌ Will hang
  /// ```
  Future<void> pumpForStream([int frameCount = 10]) async {
    for (var i = 0; i < frameCount; i++) {
      await pump();
    }
  }

  /// Pumps until a widget appears or timeout is reached.
  ///
  /// Returns `true` if found, `false` if timeout reached.
  ///
  /// ```dart
  /// await tester.pumpWidget(MyAsyncWidget());
  /// final found = await tester.pumpUntilFound(find.text('Loaded'));
  /// expect(found, isTrue);
  /// ```
  Future<bool> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 2),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      await pump(interval);
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
