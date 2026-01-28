import 'dart:async';

import 'package:drift/drift.dart' as drift_pkg;
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/converters/date_only_string_converter.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart'
    as drift;
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart' show Clock, dateOnly, systemClock;

class ValueRatingsRepository implements ValueRatingsRepositoryContract {
  ValueRatingsRepository({
    required this.driftDb,
    required this.idGenerator,
    Clock clock = systemClock,
  }) : _clock = clock;

  final drift.AppDatabase driftDb;
  final IdGenerator idGenerator;
  final Clock _clock;

  @override
  Stream<List<ValueWeeklyRating>> watchAll({int weeks = 4}) {
    final cutoff = _weekStartCutoff(weeks);
    final cutoffSql = dateOnlyStringConverter.toSql(cutoff);
    final query = driftDb.select(driftDb.valueRatingsWeeklyTable)
      ..where((row) => row.weekStart.isBiggerOrEqualValue(cutoffSql))
      ..orderBy([(row) => drift_pkg.OrderingTerm(expression: row.weekStart)]);
    return query.watch().map(_mapRows);
  }

  @override
  Future<List<ValueWeeklyRating>> getAll({int weeks = 4}) async {
    final cutoff = _weekStartCutoff(weeks);
    final cutoffSql = dateOnlyStringConverter.toSql(cutoff);
    final rows =
        await (driftDb.select(driftDb.valueRatingsWeeklyTable)
              ..where((row) => row.weekStart.isBiggerOrEqualValue(cutoffSql))
              ..orderBy([
                (row) => drift_pkg.OrderingTerm(expression: row.weekStart),
              ]))
            .get();
    return _mapRows(rows);
  }

  @override
  Future<List<ValueWeeklyRating>> getForValue(
    String valueId, {
    int weeks = 4,
  }) async {
    final cutoff = _weekStartCutoff(weeks);
    final cutoffSql = dateOnlyStringConverter.toSql(cutoff);
    final rows =
        await (driftDb.select(driftDb.valueRatingsWeeklyTable)
              ..where((row) => row.valueId.equals(valueId))
              ..where((row) => row.weekStart.isBiggerOrEqualValue(cutoffSql))
              ..orderBy([
                (row) => drift_pkg.OrderingTerm(expression: row.weekStart),
              ]))
            .get();
    return _mapRows(rows);
  }

  @override
  Future<void> upsertWeeklyRating({
    required String valueId,
    required DateTime weekStartUtc,
    required int rating,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final weekStart = dateOnly(weekStartUtc);
        final now = _clock.nowUtc();
        final id = idGenerator.valueWeeklyRatingId(
          valueId: valueId,
          weekStartUtc: weekStart,
        );

        final psMetadata = encodeCrudMetadata(context, clock: _clock);
        final companion = drift.ValueRatingsWeeklyTableCompanion(
          id: drift_pkg.Value(id),
          valueId: drift_pkg.Value(valueId),
          weekStart: drift_pkg.Value(weekStart),
          rating: drift_pkg.Value(rating),
          psMetadata: psMetadata == null
              ? const drift_pkg.Value<String?>.absent()
              : drift_pkg.Value(psMetadata),
          updatedAt: drift_pkg.Value(now),
        );

        final updated = await (driftDb.update(
          driftDb.valueRatingsWeeklyTable,
        )..where((row) => row.id.equals(id))).write(companion);

        if (updated == 0) {
          await driftDb
              .into(driftDb.valueRatingsWeeklyTable)
              .insert(
                companion.copyWith(createdAt: drift_pkg.Value(now)),
                mode: drift_pkg.InsertMode.insert,
              );
        }

        AppLog.routineStructured(
          'data.value_ratings',
          'weekly rating upserted',
          fields: <String, Object?>{
            'valueId': valueId,
            'weekStart': weekStart.toIso8601String(),
            'rating': rating,
            'updated': updated > 0,
          },
        );
      },
      area: 'data.value_ratings',
      opName: 'upsert',
      context: context,
    );
  }

  DateTime _weekStartCutoff(int weeks) {
    final safeWeeks = weeks.clamp(1, 52);
    final nowUtc = _clock.nowUtc();
    final today = dateOnly(nowUtc);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return weekStart.subtract(Duration(days: (safeWeeks - 1) * 7));
  }

  List<ValueWeeklyRating> _mapRows(
    List<drift.ValueRatingsWeeklyTableData> rows,
  ) {
    return rows
        .map(
          (row) => ValueWeeklyRating(
            id: row.id,
            valueId: row.valueId,
            weekStartUtc: row.weekStart,
            rating: row.rating,
            createdAtUtc: row.createdAt,
            updatedAtUtc: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }
}
