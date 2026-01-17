import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_data/db.dart';

import 'test_db.dart';

/// Base mixin for repository tests that need database access.
///
/// Provides standard setup/teardown for database-backed tests, ensuring
/// consistent initialization and cleanup across all repository tests.
///
/// Usage:
/// ```dart
/// void main() {
///   late AppDatabase db;
///   late TaskRepository repo;
///
///   setUpAll(baseRepositorySetUpAll);
///
///   setUp(() {
///     db = createTestDb();
///     repo = TaskRepository(driftDb: db, ...);
///   });
///
///   tearDown(() => closeTestDb(db));
///
///   // Your tests here
/// }
/// ```
///
/// Or use the helper functions directly:
/// ```dart
/// void main() {
///   late RepositoryTestContext ctx;
///
///   setUp(() {
///     ctx = RepositoryTestContext();
///   });
///
///   tearDown(() => ctx.dispose());
///
///   test('example', () {
///     final repo = TaskRepository(driftDb: ctx.db, ...);
///     // test logic
///   });
/// }
/// ```

/// Standard setUpAll for repository tests.
///
/// Call this in setUpAll to ensure talker is initialized.
/// Note: createTestDb() now handles this automatically, but this
/// provides an explicit hook if needed.
void baseRepositorySetUpAll() {
  // Talker initialization is now handled by createTestDb()
  // This function exists for explicit documentation and future hooks
}

/// Context object for repository tests.
///
/// Provides a convenient way to manage database lifecycle in tests.
/// Automatically creates an in-memory database with talker initialized.
class RepositoryTestContext {
  /// Creates a new test context with a fresh in-memory database.
  RepositoryTestContext() : db = createTestDb();

  /// The in-memory database for this test context.
  final AppDatabase db;

  /// Disposes of the test context, closing the database.
  Future<void> dispose() => closeTestDb(db);
}

/// Extension methods for common repository test patterns.
extension RepositoryTestExtensions on AppDatabase {
  /// Convenience method to close the database in tearDown.
  Future<void> closeForTest() => close();
}
