@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/value_ratings_repository.dart';
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
