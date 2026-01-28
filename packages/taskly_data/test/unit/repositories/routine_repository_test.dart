@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/routine_repository.dart';
import 'package:taskly_domain/routines.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('RoutineRepository', () {
    testSafe('create inserts routine row', () async {
      final db = createAutoClosingDb();
      await _seedValue(db);

      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Hydrate',
        valueId: 'value-1',
        routineType: RoutineType.weeklyFlexible,
        targetCount: 3,
        scheduleDays: const [1, 3, 5],
      );

      final rows = await db.select(db.routinesTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Hydrate');
    });

    testSafe('recordCompletion and removeLatestCompletionForDay', () async {
      final db = createAutoClosingDb();
      await _seedValue(db);

      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Stretch',
        valueId: 'value-1',
        routineType: RoutineType.weeklyFlexible,
        targetCount: 2,
      );
      final routineId = (await db.select(db.routinesTable).getSingle()).id;

      await repo.recordCompletion(routineId: routineId);
      final removed = await repo.removeLatestCompletionForDay(
        routineId: routineId,
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      );

      expect(removed, isTrue);
      final completions = await repo.getCompletions();
      expect(completions, isEmpty);
    });
  });
}

Future<void> _seedValue(AppDatabase db) async {
  await db
      .into(db.valueTable)
      .insert(
        ValueTableCompanion.insert(
          id: const Value('value-1'),
          name: 'Health',
          color: '#00AA00',
        ),
      );
}
