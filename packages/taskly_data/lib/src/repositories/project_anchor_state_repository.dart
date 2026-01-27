import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_domain/core.dart' hide Value;
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

final class ProjectAnchorStateRepository
    implements ProjectAnchorStateRepositoryContract {
  ProjectAnchorStateRepository({
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
  Stream<List<ProjectAnchorState>> watchAll() {
    final query = _db.select(_db.projectAnchorStateTable)
      ..orderBy([(t) => OrderingTerm(expression: t.projectId)]);

    return query.watch().map(
      (rows) => rows.map(projectAnchorStateFromTable).toList(growable: false),
    );
  }

  @override
  Future<List<ProjectAnchorState>> getAll() async {
    final rows = await (_db.select(
      _db.projectAnchorStateTable,
    )..orderBy([(t) => OrderingTerm(expression: t.projectId)])).get();
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
        final now = _clock.nowUtc();
        final idByProjectId = <String, String>{
          for (final projectId in ids)
            projectId: _ids.projectAnchorStateIdForProject(
              projectId: projectId,
            ),
        };
        final psMetadata = encodeCrudMetadata(context);

        await _db.transaction(() async {
          for (final projectId in ids) {
            final anchorId = idByProjectId[projectId]!;

            await _db
                .into(_db.projectAnchorStateTable)
                .insert(
                  ProjectAnchorStateTableCompanion.insert(
                    id: anchorId,
                    projectId: projectId,
                    lastAnchoredAt: anchoredAtUtc,
                    createdAt: Value(now),
                    updatedAt: Value(now),
                    psMetadata: Value(psMetadata),
                  ),
                  mode: InsertMode.insertOrIgnore,
                );

            await (_db.update(
              _db.projectAnchorStateTable,
            )..where((t) => t.id.equals(anchorId))).write(
              ProjectAnchorStateTableCompanion(
                projectId: Value(projectId),
                lastAnchoredAt: Value(anchoredAtUtc),
                updatedAt: Value(now),
                psMetadata: psMetadata == null
                    ? const Value.absent()
                    : Value(psMetadata),
              ),
            );
          }
        });
      },
      area: 'data.project_anchor_state',
      opName: 'recordAnchors',
      context: context,
    );
  }
}
