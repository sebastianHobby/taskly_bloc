import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

final class ProjectAnchorStateRepository
    implements ProjectAnchorStateRepositoryContract {
  ProjectAnchorStateRepository({
    required AppDatabase driftDb,
    required IdGenerator idGenerator,
  }) : _db = driftDb,
       _ids = idGenerator;

  final AppDatabase _db;
  final IdGenerator _ids;

  @override
  Stream<List<ProjectAnchorState>> watchAll() {
    final query = _db.select(_db.projectAnchorStateTable)
      ..orderBy([(t) => OrderingTerm(expression: t.projectId)]);

    return query.watch().map(
          (rows) => rows.map(projectAnchorStateFromTable).toList(growable: false),
        );
  }

  @override
  Future<List<ProjectAnchorState>> getAll() async {
    final rows = await (_db.select(_db.projectAnchorStateTable)
          ..orderBy([(t) => OrderingTerm(expression: t.projectId)]))
        .get();
    return rows.map(projectAnchorStateFromTable).toList(growable: false);
  }

  @override
  Future<void> recordAnchors({
    required Iterable<String> projectIds,
    required DateTime anchoredAtUtc,
    OperationContext? context,
  }) async {
    final ids = projectIds.toSet();
    if (ids.isEmpty) return;

    return FailureGuard.run(
      () async {
        final now = DateTime.now();
        final userId = _ids.userId;
        final psMetadata = encodeCrudMetadata(context);

        await _db.transaction(() async {
          for (final projectId in ids) {
            final updated = await (_db.update(
              _db.projectAnchorStateTable,
            )..where((t) => t.projectId.equals(projectId))).write(
              ProjectAnchorStateTableCompanion(
                lastAnchoredAt: Value(anchoredAtUtc),
                updatedAt: Value(now),
                psMetadata: psMetadata == null
                    ? const Value.absent()
                    : Value(psMetadata),
              ),
            );

            if (updated == 0) {
              await _db.into(_db.projectAnchorStateTable).insert(
                    ProjectAnchorStateTableCompanion.insert(
                      id: _ids.projectAnchorStateId(),
                      userId: Value(userId),
                      projectId: projectId,
                      lastAnchoredAt: anchoredAtUtc,
                      createdAt: Value(now),
                      updatedAt: Value(now),
                      psMetadata: Value(psMetadata),
                    ),
                    mode: InsertMode.insert,
                  );
            }
          }
        });
      },
      area: 'data.project_anchor_state',
      opName: 'recordAnchors',
      context: context,
    );
  }
}
