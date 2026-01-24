import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_core/logging.dart';

/// Standard test environment initialization for taskly_data.
void setUpAllTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initializeLoggingForTest();
}

/// Per-test setup hook.
void setUpTestEnvironment() {
  initializeLoggingForTest();
}
