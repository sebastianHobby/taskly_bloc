import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import 'fallback_values.dart';

/// Standard test environment initialization.
///
/// This centralizes the “ambient” setup we want in most tests:
/// - talker/logging initialization (safe + idempotent)
/// - mocktail fallback registration (safe + idempotent)
///
/// Recommended usage:
///
/// ```dart
/// void main() {
///   setUpAll(setUpAllTestEnvironment);
///   setUp(setUpTestEnvironment);
/// }
/// ```
void setUpAllTestEnvironment() {
  // Some suites never touch widgets, but they may still use MethodChannels.
  // Initializing the binding is safe and avoids surprises.
  TestWidgetsFlutterBinding.ensureInitialized();

  initializeTalkerForTest();
  registerAllFallbackValues();
}

/// Per-test setup hook.
///
/// Keep this small: per-test work should focus on isolation, not heavy global
/// initialization.
void setUpTestEnvironment() {
  initializeTalkerForTest();
}
