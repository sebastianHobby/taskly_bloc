@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/value_ratings_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueRatingsRepository', () {
    testSafe('upsertWeeklyRating inserts then updates', () async {
      final db = createAutoClosingDb();
      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final repo = ValueRatingsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: clock,
      );

      final weekStart = DateTime.utc(2025, 1, 13);

      await repo.upsertWeeklyRating(
        valueId: 'value-1',
        weekStartUtc: weekStart,
        rating: 3,
      );

      await repo.upsertWeeklyRating(
        valueId: 'value-1',
        weekStartUtc: weekStart,
        rating: 4,
      );

      final rows = await repo.getForValue('value-1', weeks: 8);
      expect(rows, hasLength(1));
      expect(rows.single.rating, 4);
      expect(rows.single.weekStartUtc, DateTime.utc(2025, 1, 13));
    });

    testSafe('watchAll/getAll apply week cutoff and ordering', () async {
      final db = createAutoClosingDb();
      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final repo = ValueRatingsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: clock,
      );

      await repo.upsertWeeklyRating(
        valueId: 'value-a',
        weekStartUtc: DateTime.utc(2025, 1, 13),
        rating: 4,
      );
      await repo.upsertWeeklyRating(
        valueId: 'value-b',
        weekStartUtc: DateTime.utc(2025, 1, 6),
        rating: 3,
      );
      await repo.upsertWeeklyRating(
        valueId: 'value-c',
        weekStartUtc: DateTime.utc(2024, 12, 23),
        rating: 2,
      );

      final watched = await repo.watchAll(weeks: 2).first;
      final loaded = await repo.getAll(weeks: 2);

      expect(watched.map((r) => r.valueId).toList(), ['value-b', 'value-a']);
      expect(loaded.map((r) => r.valueId).toList(), ['value-b', 'value-a']);
    });

    testSafe('getForValue respects clamped week range', () async {
      final db = createAutoClosingDb();
      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final repo = ValueRatingsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: clock,
      );

      await repo.upsertWeeklyRating(
        valueId: 'value-1',
        weekStartUtc: DateTime.utc(2024, 2, 5),
        rating: 1,
      );
      await repo.upsertWeeklyRating(
        valueId: 'value-1',
        weekStartUtc: DateTime.utc(2025, 1, 13),
        rating: 5,
      );

      final onlyRecent = await repo.getForValue('value-1', weeks: 0);
      expect(onlyRecent, hasLength(1));
      expect(onlyRecent.single.rating, 5);

      final allClamped = await repo.getForValue('value-1', weeks: 100);
      expect(allClamped, hasLength(2));
    });

    testSafe('upsert writes ps metadata when context is provided', () async {
      final db = createAutoClosingDb();
      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final repo = ValueRatingsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: clock,
      );
      final context = systemOperationContext(
        feature: 'test',
        intent: 'unit',
        operation: 'value_rating_upsert',
      );

      await repo.upsertWeeklyRating(
        valueId: 'value-1',
        weekStartUtc: DateTime.utc(2025, 1, 13),
        rating: 4,
        context: context,
      );

      final row = await db.select(db.valueRatingsWeeklyTable).getSingle();
      expect(row.psMetadata, isNotNull);
    });
  });
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
