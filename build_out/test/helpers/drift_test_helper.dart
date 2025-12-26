import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

/// Create a fresh in-memory AppDatabase for tests.
/// Sets Drift runtime option to avoid noisy warnings about multiple databases.
Future<AppDatabase> createTestDatabase() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );

  // Ensure database is initialized
  await db.doWhenOpened((e) {});

  return db;
}

/// Close and dispose of a test database
Future<void> closeTestDatabase(AppDatabase db) => db.close();
