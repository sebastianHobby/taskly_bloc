// Copyright 2024 The Taskly Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Central test imports with automatic timeout protection.
///
/// ## Why Use This?
///
/// Flutter's `testWidgets` can hang indefinitely due to:
/// - `pumpAndSettle()` with BLoC streams (10-minute default timeout)
/// - `@Timeout` only triggers on **inactivity**, not total duration
/// - Tests appear "stuck" but are actually pumping frames
///
/// This file provides:
/// - `testWidgetsSafe` - Widget tests with 30s total timeout
/// - `testSafe` - Unit tests with 30s total timeout
/// - `testWidgetsIntegration` - Integration tests with 45s timeout
///
/// ## Usage
///
/// Replace your test imports:
/// ```dart
/// // Before:
/// import 'package:flutter_test/flutter_test.dart';
///
/// // After:
/// import '../helpers/test_imports.dart';
/// ```
///
/// Then use the safe test functions:
/// ```dart
/// testWidgetsSafe('my widget test', (tester) async {
///   // Automatically times out after 30s total duration
/// });
///
/// testSafe('my unit test', () async {
///   // Automatically times out after 30s total duration
/// });
/// ```
library;

// ═══════════════════════════════════════════════════════════════════════════
// Core Test Exports
// ═══════════════════════════════════════════════════════════════════════════

/// Re-export flutter_test for all standard test utilities.
/// We intentionally keep `testWidgets` and `test` available for edge cases
/// where the standard timeout isn't appropriate.
export 'package:flutter_test/flutter_test.dart';

/// Re-export bloc_test for BLoC testing utilities.
export 'package:bloc_test/bloc_test.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Safe Test Functions & Pump Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Export timeout-protected test functions and pump utilities.
export 'test_helpers.dart'
    show
        // Timeout-safe test wrappers
        PumpHelpers,
        kDefaultPumpTimeout,
        kDefaultStreamTimeout,
        kDefaultTestTimeout,
        kGlobalSafetyTimeout,
        // Timeout constant
        testSafe,
        // Pump helpers extension
        testWidgetsSafe;

// ═══════════════════════════════════════════════════════════════════════════
// Common Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Re-export common test utilities.
export 'pump_app.dart';
export 'custom_matchers.dart';
export 'fallback_values.dart';
export 'bloc_test_helpers.dart';
export 'checks.dart';
export 'disposables.dart';
export 'test_clock.dart';
export 'test_environment.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Specialized Test Helpers
// ═══════════════════════════════════════════════════════════════════════════

/// Contract test utilities (verify component agreements).
export 'contract_test_helpers.dart' hide TimeoutException;

/// Integration test utilities (real database, real components).
export 'integration_test_helpers.dart';

/// Widget test utilities (BLoC-aware widget testing).
export 'widget_test_helpers.dart';

/// BLoC test patterns and utilities.
export 'bloc_test_patterns.dart' hide TimeoutException;
