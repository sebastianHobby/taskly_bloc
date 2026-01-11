import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';

/// Creates a fresh in-memory AppDatabase for tests.
///
/// This database:
/// - Lives entirely in memory (no disk I/O)
/// - Has foreign keys enabled
/// - Is fully initialized and ready to use
/// - Automatically initializes the talker logging service
/// - Should be closed after tests using [closeTestDb]
///
/// Sets [driftRuntimeOptions.dontWarnAboutMultipleDatabases] to avoid
/// warnings when running many tests in parallel.
///
/// Usage:
/// ```dart
/// void main() {
///   late AppDatabase db;
///
///   setUp(() {
///     db = createTestDb();
///   });
///
///   tearDown(() async {
///     await closeTestDb(db);
///   });
///
///   test('example', () async {
///     // Use db for testing...
///   });
/// }
/// ```
AppDatabase createTestDb() {
  // Initialize talker for tests - required by repositories that use logging
  initializeTalkerForTest();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

/// Close and dispose of a test database.
///
/// Always call this in tearDown to properly clean up resources.
Future<void> closeTestDb(AppDatabase db) => db.close();

// Legacy aliases for backward compatibility with drift_test_helper.dart
// These can be removed once all tests are migrated to use the primary names.

/// @Deprecated('Use createTestDb instead')
@Deprecated('Use createTestDb instead')
Future<AppDatabase> createTestDatabase() async => createTestDb();

/// @Deprecated('Use closeTestDb instead')
@Deprecated('Use closeTestDb instead')
Future<void> closeTestDatabase(AppDatabase db) => closeTestDb(db);
