@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe(
    'routine repository create/update and completion/skip emit streams',
    () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final idGenerator = FakeIdGenerator('user-1');
      final contextFactory = TestOperationContextFactory();

      final valueRepository = ValueRepository(
        driftDb: db,
        idGenerator: idGenerator,
        clock: clock,
      );
      final routineRepository = RoutineRepository(
        driftDb: db,
        idGenerator: idGenerator,
        clock: clock,
      );

      final valueContext = contextFactory.create(
        feature: 'values',
        intent: 'test',
        operation: 'values.create',
      );
      await valueRepository.create(
        name: 'Health',
        color: '#00CC66',
        priority: ValuePriority.high,
        context: valueContext,
      );

      final valueRow = await db.select(db.valueTable).getSingle();

      final routineContext = contextFactory.create(
        feature: 'routines',
        intent: 'test',
        operation: 'routines.create',
      );

      await routineRepository.create(
        name: 'Morning walk',
        valueId: valueRow.id,
        routineType: RoutineType.weeklyFixed,
        targetCount: 3,
        scheduleDays: const [1, 3, 5],
        context: routineContext,
      );

      final created = await routineRepository.watchAll().firstWhere(
        (routines) => routines.isNotEmpty,
      );
      expect(created, hasLength(1));

      final routineId = created.single.id;
      await routineRepository.update(
        id: routineId,
        name: 'Morning walk updated',
        valueId: valueRow.id,
        routineType: RoutineType.weeklyFixed,
        targetCount: 4,
        scheduleDays: const [2, 4],
        context: routineContext,
      );

      final updated = await routineRepository
          .watchById(routineId)
          .firstWhere((routine) => routine?.name == 'Morning walk updated');
      expect(updated?.targetCount, 4);

      final routineRow = await db.select(db.routinesTable).getSingle();
      final routineMeta =
          jsonDecode(routineRow.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(routineMeta['cid'], routineContext.correlationId);

      await routineRepository.recordCompletion(
        routineId: routineId,
        completedAtUtc: DateTime.utc(2025, 1, 16),
        context: routineContext,
      );

      final completions = await routineRepository.watchCompletions().firstWhere(
        (items) => items.isNotEmpty,
      );
      expect(completions.single.routineId, routineId);

      final completionRow = await db
          .select(db.routineCompletionsTable)
          .getSingle();
      final completionMeta =
          jsonDecode(completionRow.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(completionMeta['cid'], routineContext.correlationId);

      await routineRepository.recordSkip(
        routineId: routineId,
        periodType: RoutineSkipPeriodType.week,
        periodKeyUtc: DateTime.utc(2025, 1, 13),
        context: routineContext,
      );

      final skips = await routineRepository.watchSkips().firstWhere(
        (items) => items.isNotEmpty,
      );
      expect(skips.single.routineId, routineId);

      final skipRow = await db.select(db.routineSkipsTable).getSingle();
      final skipMeta =
          jsonDecode(skipRow.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(skipMeta['cid'], routineContext.correlationId);
    },
  );
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
