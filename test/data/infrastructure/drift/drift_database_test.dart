/// Unit tests for AppDatabase wiring (schema + migration overrides).
library;

import 'package:drift/drift.dart' show MigrationStrategy;

import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);

  group('AppDatabase', () {
    testSafe('exposes expected schemaVersion', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      expect(db.schemaVersion, 17);
    });

    testSafe('exposes a migration strategy', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final migration = db.migration;
      expect(migration, isNotNull);

      // Sanity: Ensure the migration strategy is the Drift type.
      expect(migration, isA<MigrationStrategy>());
    });
  });
}
