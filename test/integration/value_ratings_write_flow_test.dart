@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe(
    'value ratings repository upserts weekly ratings and emits streams',
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
      final ratingsRepository = ValueRatingsRepository(
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
        name: 'Focus',
        color: '#3366FF',
        priority: ValuePriority.medium,
        context: valueContext,
      );

      final valueRow = await db.select(db.valueTable).getSingle();

      final ratingContext = contextFactory.create(
        feature: 'values',
        intent: 'test',
        operation: 'values.ratings.upsert',
      );

      final weekStart = DateTime.utc(2025, 1, 13);
      await ratingsRepository.upsertWeeklyRating(
        valueId: valueRow.id,
        weekStartUtc: weekStart,
        rating: 5,
        context: ratingContext,
      );

      final created = await ratingsRepository.watchAll().firstWhere(
        (ratings) => ratings.isNotEmpty,
      );
      expect(created.single.rating, 5);

      await ratingsRepository.upsertWeeklyRating(
        valueId: valueRow.id,
        weekStartUtc: weekStart,
        rating: 7,
        context: ratingContext,
      );

      final updated = await ratingsRepository.watchAll().firstWhere(
        (ratings) => ratings.single.rating == 7,
      );
      expect(updated.single.rating, 7);

      final row = await db.select(db.valueRatingsWeeklyTable).getSingle();
      final metadata =
          jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(metadata['cid'], ratingContext.correlationId);
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
