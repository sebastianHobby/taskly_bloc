import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

final class ProjectNextActionsRepository
    implements ProjectNextActionsRepositoryContract {
  ProjectNextActionsRepository({
    required AppDatabase driftDb,
    required IdGenerator idGenerator,
  }) : _db = driftDb,
       _ids = idGenerator;

  final AppDatabase _db;
  final IdGenerator _ids;

  @override
  Stream<List<ProjectNextAction>> watchAll() {
    final query = _db.select(_db.projectNextActionsTable)
      ..orderBy([
        (t) => OrderingTerm(expression: t.projectId),
        (t) => OrderingTerm(expression: t.rank),
      ]);

    return query.watch().map(
          (rows) => rows.map(projectNextActionFromTable).toList(growable: false),
        );
  }

  @override
  Stream<List<ProjectNextAction>> watchForProject(String projectId) {
    final query = _db.select(_db.projectNextActionsTable)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([(t) => OrderingTerm(expression: t.rank)]);

    return query.watch().map(
          (rows) => rows.map(projectNextActionFromTable).toList(growable: false),
        );
  }

  @override
  Future<List<ProjectNextAction>> getAll() async {
    final rows = await (_db.select(_db.projectNextActionsTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.projectId),
            (t) => OrderingTerm(expression: t.rank),
          ]))
        .get();
    return rows.map(projectNextActionFromTable).toList(growable: false);
  }

  @override
  Future<List<ProjectNextAction>> getForProject(String projectId) async {
    final rows = await (_db.select(_db.projectNextActionsTable)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.rank)]))
        .get();
    return rows.map(projectNextActionFromTable).toList(growable: false);
  }

  @override
  Future<void> setForProject({
    required String projectId,
    required List<ProjectNextActionDraft> actions,
    required OperationContext context,
  }) async {
    return FailureGuard.run(
      () async {
        final normalized = _normalizeActions(actions);
        final now = DateTime.now();
        final userId = _ids.userId;
        final psMetadata = encodeCrudMetadata(context);

        await _db.transaction(() async {
          await (_db.delete(
            _db.projectNextActionsTable,
          )..where((t) => t.projectId.equals(projectId))).go();

          for (final action in normalized) {
            await _db.into(_db.projectNextActionsTable).insert(
                  ProjectNextActionsTableCompanion.insert(
                    id: _ids.projectNextActionId(),
                    userId: Value(userId),
                    projectId: projectId,
                    taskId: action.taskId,
                    rank: action.rank,
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    psMetadata: Value(psMetadata),
                  ),
                  mode: InsertMode.insert,
                );
          }
        });
      },
      area: 'data.project_next_actions',
      opName: 'setForProject',
      context: context,
    );
  }

  @override
  Future<void> removeForTask({
    required String taskId,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = DateTime.now();
        final psMetadata = encodeCrudMetadata(context);

        await _db.transaction(() async {
          final rows = await (_db.select(
            _db.projectNextActionsTable,
          )..where((t) => t.taskId.equals(taskId))).get();

          if (rows.isEmpty) return;

          final projectIds = rows.map((r) => r.projectId).toSet();

          await (_db.delete(
            _db.projectNextActionsTable,
          )..where((t) => t.taskId.equals(taskId))).go();

          for (final projectId in projectIds) {
            await _compactRanks(
              projectId: projectId,
              now: now,
              psMetadata: psMetadata,
            );
          }
        });
      },
      area: 'data.project_next_actions',
      opName: 'removeForTask',
      context: context,
    );
  }

  List<ProjectNextActionDraft> _normalizeActions(
    List<ProjectNextActionDraft> actions,
  ) {
    if (actions.length > 3) {
      throw RepositoryValidationException('Max 3 next actions per project.');
    }

    final taskIds = <String>{};
    final ranks = <int>{};
    for (final action in actions) {
      if (action.rank < 1 || action.rank > 3) {
        throw RepositoryValidationException('Rank must be 1..3.');
      }
      if (!taskIds.add(action.taskId)) {
        throw RepositoryValidationException('Duplicate task in next actions.');
      }
      if (!ranks.add(action.rank)) {
        throw RepositoryValidationException('Duplicate rank in next actions.');
      }
    }

    final normalized = List<ProjectNextActionDraft>.from(actions)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return normalized;
  }

  Future<void> _compactRanks({
    required String projectId,
    required DateTime now,
    required String? psMetadata,
  }) async {
    final rows = await (_db.select(
      _db.projectNextActionsTable,
    )..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm(expression: t.rank)]))
        .get();

    var nextRank = 1;
    for (final row in rows) {
      if (row.rank == nextRank) {
        nextRank += 1;
        continue;
      }

      await (_db.update(
        _db.projectNextActionsTable,
      )..where((t) => t.id.equals(row.id))).write(
        ProjectNextActionsTableCompanion(
          rank: Value(nextRank),
          updatedAt: Value(now),
          psMetadata: psMetadata == null
              ? const Value.absent()
              : Value(psMetadata),
        ),
      );
      nextRank += 1;
    }
  }
}
