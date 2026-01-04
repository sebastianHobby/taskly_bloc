/// Helpers for contract tests.
///
/// Contract tests verify that two components agree on their interface.
/// Unlike unit tests that use mocks, contract tests use REAL components
/// to catch drift between implementations.
///
/// ## When to use contract tests
///
/// - Component A generates data that Component B consumes
/// - A change in A could silently break B without failing unit tests
/// - Examples: SystemScreenDefinitions ↔ NavigationIconResolver
///
/// ## Pattern
///
/// ```dart
/// group('ComponentA ↔ ComponentB', () {
///   test('all A items are handled by B', () {
///     for (final item in ComponentA.all) {
///       final result = componentB.process(item);
///       expect(result, isNot(defaultFallback));
///     }
///   });
/// });
/// ```
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'test_helpers.dart' show kDefaultTestTimeout;

// ═══════════════════════════════════════════════════════════════════════════
// Contract Test Wrapper
// ═══════════════════════════════════════════════════════════════════════════

/// Default timeout for contract tests (10 seconds).
///
/// Contract tests should be fast - they verify interface agreement,
/// not complex behavior.
const Duration kContractTestTimeout = Duration(seconds: 10);

/// Contract test with timeout protection.
///
/// Use for tests that verify two components agree on their interface.
/// These tests use REAL components, not mocks.
///
/// ```dart
/// testContract('all system screens have icons', () {
///   for (final screen in SystemScreenDefinitions.all) {
///     final icon = resolver.resolve(screenId: screen.screenKey);
///     expect(icon, isNot(defaultIcon));
///   }
/// });
/// ```
@isTest
void testContract(
  String description,
  dynamic Function() callback, {
  Duration timeout = kContractTestTimeout,
  bool skip = false,
}) {
  test(
    description,
    skip: skip,
    () async {
      final result = callback();
      if (result is Future) {
        await result.timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException(
              'Contract test "$description" exceeded ${timeout.inSeconds}s. '
              'Contract tests should be fast - check for blocking operations.',
              timeout,
            );
          },
        );
      }
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Contract Verification Utilities
// ═══════════════════════════════════════════════════════════════════════════

/// Verifies that all items in [source] produce non-default results via [transform].
///
/// Useful for verifying exhaustive handling (e.g., all screens have icons).
///
/// ```dart
/// verifyExhaustiveMapping(
///   source: SystemScreenDefinitions.all,
///   transform: (screen) => resolver.resolve(screenId: screen.screenKey),
///   isDefault: (result) => result.icon == Icons.widgets_outlined,
///   itemLabel: (screen) => screen.screenKey,
///   errorHint: 'Add a case in NavigationIconResolver',
/// );
/// ```
void verifyExhaustiveMapping<TSource, TResult>({
  required Iterable<TSource> source,
  required TResult Function(TSource) transform,
  required bool Function(TResult) isDefault,
  required String Function(TSource) itemLabel,
  String? errorHint,
}) {
  final failures = <String>[];

  for (final item in source) {
    final result = transform(item);
    if (isDefault(result)) {
      final hint = errorHint != null ? ' $errorHint.' : '';
      failures.add('"${itemLabel(item)}" fell through to default.$hint');
    }
  }

  if (failures.isNotEmpty) {
    fail('Contract violations:\n${failures.map((f) => '  • $f').join('\n')}');
  }
}

/// Verifies that all items in [source] produce unique results via [transform].
///
/// Useful for verifying no collisions (e.g., unique icons per screen).
///
/// ```dart
/// verifyUniqueMapping(
///   source: SystemScreenDefinitions.all,
///   transform: (screen) => resolver.resolve(screenId: screen.screenKey).icon,
///   itemLabel: (screen) => screen.screenKey,
///   allowDuplicates: {'settings', 'screen_management'}, // intentionally same
/// );
/// ```
void verifyUniqueMapping<TSource, TResult>({
  required Iterable<TSource> source,
  required TResult Function(TSource) transform,
  required String Function(TSource) itemLabel,
  Set<String>? allowDuplicates,
}) {
  final seen = <TResult, String>{};
  final duplicates = <String>[];
  final allowed = allowDuplicates ?? {};

  for (final item in source) {
    final result = transform(item);
    final label = itemLabel(item);

    if (allowed.contains(label)) continue;

    final existing = seen[result];
    if (existing != null) {
      duplicates.add('"$label" has same value as "$existing"');
    } else {
      seen[result] = label;
    }
  }

  if (duplicates.isNotEmpty) {
    fail('Duplicate mappings:\n${duplicates.map((d) => '  • $d').join('\n')}');
  }
}

/// Verifies a round-trip transformation preserves the original value.
///
/// Useful for encoder/decoder pairs (e.g., screenKey ↔ URL path).
///
/// ```dart
/// verifyRoundTrip(
///   source: SystemScreenDefinitions.all.map((s) => s.screenKey),
///   encode: Routing.screenPath,
///   decode: (path) => Routing.parseScreenKey(path.substring(1)),
///   itemLabel: (key) => key,
/// );
/// ```
void verifyRoundTrip<T>({
  required Iterable<T> source,
  required String Function(T) encode,
  required T Function(String) decode,
  required String Function(T) itemLabel,
}) {
  final failures = <String>[];

  for (final original in source) {
    final encoded = encode(original);
    final decoded = decode(encoded);

    if (decoded != original) {
      failures.add(
        '"${itemLabel(original)}" → "$encoded" → "$decoded" (expected "${itemLabel(original)}")',
      );
    }
  }

  if (failures.isNotEmpty) {
    fail('Round-trip failures:\n${failures.map((f) => '  • $f').join('\n')}');
  }
}

/// Exception for contract test timeout.
class TimeoutException implements Exception {
  TimeoutException(this.message, this.duration);
  final String message;
  final Duration duration;

  @override
  String toString() => 'TimeoutException: $message';
}
