@Tags(['unit'])
library;

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:powersync/powersync.dart';
import 'package:taskly_data/src/infrastructure/powersync/powersync_status_stream.dart';

import '../../../helpers/test_imports.dart';

class _MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}

void main() {
  testSafe(
    'sharedPowerSyncStatusStream caches per database instance',
    () async {
      final db = _MockPowerSyncDatabase();
      final controller = StreamController<SyncStatus>.broadcast();
      addTearDown(controller.close);

      when(() => db.statusStream).thenAnswer((_) => controller.stream);

      final first = sharedPowerSyncStatusStream(db);
      final second = sharedPowerSyncStatusStream(db);

      expect(identical(first, second), isTrue);
      verify(() => db.statusStream).called(1);
    },
  );
}
