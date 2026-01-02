import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart'
    as domain;
import 'package:taskly_bloc/domain/interfaces/workflow_sessions_repository_contract.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of [WorkflowSessionsRepositoryContract].
class WorkflowSessionsRepositoryImpl
    implements WorkflowSessionsRepositoryContract {
  WorkflowSessionsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<domain.WorkflowSession?> watchSession(String id) {
    return (_db.select(_db.workflowSessions)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((e) => e == null ? null : _mapEntity(e));
  }

  @override
  Stream<List<domain.WorkflowSession>> watchSessionsForScreen(
    String screenKey,
  ) {
    return (_db.select(_db.workflowSessions)
          ..where((t) => t.screenKey.equals(screenKey))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_mapEntity).toList());
  }

  @override
  Future<String> startSession({
    required String screenKey,
    required int totalItems,
    String? sessionNotes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db
        .into(_db.workflowSessions)
        .insert(
          db.WorkflowSessionsCompanion.insert(
            id: Value(id),
            screenKey: screenKey,
            status: Value(db_screens.WorkflowStatus.inProgress),
            startedAt: Value(now),
            totalItems: Value(totalItems),
            sessionNotes: Value(sessionNotes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  @override
  Future<void> completeSession({
    required String sessionId,
    String? sessionNotes,
  }) async {
    final now = DateTime.now();

    await (_db.update(
      _db.workflowSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      db.WorkflowSessionsCompanion(
        status: Value(db_screens.WorkflowStatus.completed),
        completedAt: Value(now),
        sessionNotes: Value(sessionNotes),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> abandonSession({
    required String sessionId,
    String? sessionNotes,
  }) async {
    final now = DateTime.now();

    await (_db.update(
      _db.workflowSessions,
    )..where((t) => t.id.equals(sessionId))).write(
      db.WorkflowSessionsCompanion(
        status: Value(db_screens.WorkflowStatus.abandoned),
        completedAt: Value(now),
        sessionNotes: Value(sessionNotes),
        updatedAt: Value(now),
      ),
    );
  }

  domain.WorkflowSession _mapEntity(db.WorkflowSessionEntity entity) {
    return domain.WorkflowSession(
      id: entity.id,
      userId: entity.userId ?? '',
      screenKey: entity.screenKey,
      status: _mapStatus(entity.status),
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      totalItems: entity.totalItems,
      itemsReviewed: entity.itemsReviewed,
      itemsSkipped: entity.itemsSkipped,
      sessionNotes: entity.sessionNotes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  domain.WorkflowStatus _mapStatus(db_screens.WorkflowStatus status) {
    return switch (status) {
      db_screens.WorkflowStatus.inProgress => domain.WorkflowStatus.inProgress,
      db_screens.WorkflowStatus.completed => domain.WorkflowStatus.completed,
      db_screens.WorkflowStatus.abandoned => domain.WorkflowStatus.abandoned,
    };
  }
}
