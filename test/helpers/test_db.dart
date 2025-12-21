import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

/// Create a fresh in-memory AppDatabase for tests.
/// Sets Drift runtime option to avoid noisy warnings about multiple databases.
AppDatabase createTestDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

Future<void> closeTestDb(AppDatabase db) => db.close();
