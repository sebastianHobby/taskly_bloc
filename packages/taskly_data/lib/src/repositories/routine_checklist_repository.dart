import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/checklists.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart'
    show Clock, dateOnly, dateOnlyOrNull, encodeDateOnly, systemClock;

final class RoutineChecklistRepository
    implements RoutineChecklistRepositoryContract {
  RoutineChecklistRepository({
    required AppDatabase driftDb,
    required IdGenerator idGenerator,
    Clock clock = systemClock,
  }) : _db = driftDb,
       _ids = idGenerator,
       _clock = clock;

  final AppDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Stream<List<ChecklistItem>> watchItems(String routineId) {
    final query = (_db.select(_db.routineChecklistItemsTable)
      ..where((t) => t.routineId.equals(routineId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]));
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ChecklistItem(
              id: row.id,
              parentId: row.routineId,
              title: row.title,
              sortIndex: row.sortIndex,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<ChecklistItem>> getItems(String routineId) async {
    final rows =
        await (_db.select(_db.routineChecklistItemsTable)
              ..where((t) => t.routineId.equals(routineId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]))
            .get();
    return rows
        .map(
          (row) => ChecklistItem(
            id: row.id,
            parentId: row.routineId,
            title: row.title,
            sortIndex: row.sortIndex,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> replaceItems({
    required String routineId,
    required List<String> titlesInOrder,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final normalized = titlesInOrder
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .take(20)
            .toList(growable: false);
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await _db.transaction(() async {
          await (_db.delete(
            _db.routineChecklistItemsTable,
          )..where((t) => t.routineId.equals(routineId))).go();

          for (var i = 0; i < normalized.length; i += 1) {
            await _db
                .into(_db.routineChecklistItemsTable)
                .insert(
                  RoutineChecklistItemsTableCompanion.insert(
                    id: _ids.routineChecklistItemId(),
                    routineId: routineId,
                    title: normalized[i],
                    sortIndex: i,
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    psMetadata: Value(psMetadata),
                  ),
                  mode: InsertMode.insert,
                );
          }
        });
      },
      area: 'data.routine_checklist',
      opName: 'replaceItems',
      context: context,
    );
  }

  @override
  Stream<List<ChecklistItemState>> watchState({
    required String routineId,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
  }) {
    final normalizedKey = dateOnlyOrNull(windowKey) ?? dateOnly(windowKey);
    final key = encodeDateOnly(normalizedKey);
    final query = (_db.select(_db.routineChecklistItemStateTable)
      ..where((t) => t.routineId.equals(routineId))
      ..where((t) => t.periodType.equals(periodType.name))
      ..where((t) => t.windowKey.equals(key)));
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ChecklistItemState(
              itemId: row.checklistItemId,
              isChecked: row.isChecked,
              checkedAt: row.checkedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<ChecklistItemState>> getState({
    required String routineId,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
  }) async {
    final normalizedKey = dateOnlyOrNull(windowKey) ?? dateOnly(windowKey);
    final key = encodeDateOnly(normalizedKey);
    final rows =
        await (_db.select(_db.routineChecklistItemStateTable)
              ..where((t) => t.routineId.equals(routineId))
              ..where((t) => t.periodType.equals(periodType.name))
              ..where((t) => t.windowKey.equals(key)))
            .get();
    return rows
        .map(
          (row) => ChecklistItemState(
            itemId: row.checklistItemId,
            isChecked: row.isChecked,
            checkedAt: row.checkedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> setChecked({
    required String routineId,
    required String itemId,
    required bool isChecked,
    required RoutinePeriodType periodType,
    required DateTime windowKey,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final normalizedKey = dateOnlyOrNull(windowKey) ?? dateOnly(windowKey);
        final key = encodeDateOnly(normalizedKey);
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        final existing =
            await (_db.select(_db.routineChecklistItemStateTable)
                  ..where((t) => t.routineId.equals(routineId))
                  ..where((t) => t.checklistItemId.equals(itemId))
                  ..where((t) => t.periodType.equals(periodType.name))
                  ..where((t) => t.windowKey.equals(key)))
                .getSingleOrNull();

        if (existing == null) {
          await _db
              .into(_db.routineChecklistItemStateTable)
              .insert(
                RoutineChecklistItemStateTableCompanion.insert(
                  id: _ids.routineChecklistItemStateId(
                    routineId: routineId,
                    checklistItemId: itemId,
                    periodType: periodType.name,
                    windowKey: normalizedKey,
                  ),
                  routineId: routineId,
                  checklistItemId: itemId,
                  periodType: periodType.name,
                  windowKey: normalizedKey,
                  isChecked: Value(isChecked),
                  checkedAt: Value(isChecked ? now : null),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  psMetadata: Value(psMetadata),
                ),
                mode: InsertMode.insert,
              );
          return;
        }

        await (_db.update(
          _db.routineChecklistItemStateTable,
        )..where((t) => t.id.equals(existing.id))).write(
          RoutineChecklistItemStateTableCompanion(
            isChecked: Value(isChecked),
            checkedAt: Value(isChecked ? now : null),
            updatedAt: Value(now),
            psMetadata: psMetadata == null
                ? const Value.absent()
                : Value(psMetadata),
          ),
        );
      },
      area: 'data.routine_checklist',
      opName: 'setChecked',
      context: context,
    );
  }
}
