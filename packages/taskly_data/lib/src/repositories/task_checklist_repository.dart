import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/checklists.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart'
    show Clock, dateOnlyOrNull, encodeDateOnly, systemClock;

final class TaskChecklistRepository implements TaskChecklistRepositoryContract {
  TaskChecklistRepository({
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
  Stream<List<ChecklistItem>> watchItems(String taskId) {
    final query = (_db.select(_db.taskChecklistItemsTable)
      ..where((t) => t.taskId.equals(taskId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]));
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ChecklistItem(
              id: row.id,
              parentId: row.taskId,
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
  Future<List<ChecklistItem>> getItems(String taskId) async {
    final rows =
        await (_db.select(_db.taskChecklistItemsTable)
              ..where((t) => t.taskId.equals(taskId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]))
            .get();
    return rows
        .map(
          (row) => ChecklistItem(
            id: row.id,
            parentId: row.taskId,
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
    required String taskId,
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
            _db.taskChecklistItemsTable,
          )..where((t) => t.taskId.equals(taskId))).go();

          for (var i = 0; i < normalized.length; i += 1) {
            await _db
                .into(_db.taskChecklistItemsTable)
                .insert(
                  TaskChecklistItemsTableCompanion.insert(
                    id: _ids.taskChecklistItemId(),
                    taskId: taskId,
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
      area: 'data.task_checklist',
      opName: 'replaceItems',
      context: context,
    );
  }

  @override
  Stream<List<ChecklistItemState>> watchState({
    required String taskId,
    required DateTime? occurrenceDate,
  }) {
    final normalizedDate = dateOnlyOrNull(occurrenceDate);
    final query = _db.select(_db.taskChecklistItemStateTable)
      ..where((t) => t.taskId.equals(taskId));
    if (normalizedDate == null) {
      query.where((t) => t.occurrenceDate.isNull());
    } else {
      query.where(
        (t) => t.occurrenceDate.equals(encodeDateOnly(normalizedDate)),
      );
    }
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
    required String taskId,
    required DateTime? occurrenceDate,
  }) async {
    final normalizedDate = dateOnlyOrNull(occurrenceDate);
    final query = _db.select(_db.taskChecklistItemStateTable)
      ..where((t) => t.taskId.equals(taskId));
    if (normalizedDate == null) {
      query.where((t) => t.occurrenceDate.isNull());
    } else {
      query.where(
        (t) => t.occurrenceDate.equals(encodeDateOnly(normalizedDate)),
      );
    }
    final rows = await query.get();
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
    required String taskId,
    required String itemId,
    required bool isChecked,
    required DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final normalizedDate = dateOnlyOrNull(occurrenceDate);
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        final query = _db.select(_db.taskChecklistItemStateTable)
          ..where((t) => t.taskId.equals(taskId))
          ..where((t) => t.checklistItemId.equals(itemId));
        if (normalizedDate == null) {
          query.where((t) => t.occurrenceDate.isNull());
        } else {
          query.where(
            (t) => t.occurrenceDate.equals(encodeDateOnly(normalizedDate)),
          );
        }
        final existing = await query.getSingleOrNull();

        if (existing == null) {
          await _db
              .into(_db.taskChecklistItemStateTable)
              .insert(
                TaskChecklistItemStateTableCompanion.insert(
                  id: _ids.taskChecklistItemStateId(
                    taskId: taskId,
                    checklistItemId: itemId,
                    occurrenceDate: normalizedDate,
                  ),
                  taskId: taskId,
                  checklistItemId: itemId,
                  occurrenceDate: Value(normalizedDate),
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
          _db.taskChecklistItemStateTable,
        )..where((t) => t.id.equals(existing.id))).write(
          TaskChecklistItemStateTableCompanion(
            isChecked: Value(isChecked),
            checkedAt: Value(isChecked ? now : null),
            updatedAt: Value(now),
            psMetadata: psMetadata == null
                ? const Value.absent()
                : Value(psMetadata),
          ),
        );
      },
      area: 'data.task_checklist',
      opName: 'setChecked',
      context: context,
    );
  }
}
