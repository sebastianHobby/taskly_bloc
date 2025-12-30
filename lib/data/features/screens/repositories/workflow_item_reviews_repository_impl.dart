import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as domain_screens;
import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart'
    as domain_workflow;
import 'package:taskly_bloc/domain/repositories/workflow_item_reviews_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of [WorkflowItemReviewsRepository].
class WorkflowItemReviewsRepositoryImpl
    implements WorkflowItemReviewsRepository {
  WorkflowItemReviewsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<domain_workflow.WorkflowItemReview>> watchSessionItemReviews(
    String sessionId,
  ) {
    return (_db.select(_db.workflowItemReviews)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.reviewedAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_mapEntity).toList());
  }

  @override
  Future<String> addItemReview({
    required String sessionId,
    required domain_screens.EntityType entityType,
    required String entityId,
    required domain_workflow.WorkflowAction action,
    String? reviewNotes,
    DateTime? reviewedAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final effectiveReviewedAt = reviewedAt ?? now;

    await _db.transaction(() async {
      // Insert the action.
      await _db
          .into(_db.workflowItemReviews)
          .insert(
            db.WorkflowItemReviewsCompanion.insert(
              id: Value(id),
              sessionId: sessionId,
              entityId: entityId,
              entityType: _mapEntityTypeToDrift(entityType),
              action: _mapActionToDrift(action),
              reviewNotes: Value(reviewNotes),
              reviewedAt: Value(effectiveReviewedAt),
              userId: const Value(''),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // Update session counters.
      final session = await (_db.select(
        _db.workflowSessions,
      )..where((t) => t.id.equals(sessionId))).getSingle();

      final updatedReviewed =
          session.itemsReviewed +
          (action == domain_workflow.WorkflowAction.reviewed ? 1 : 0);
      final updatedSkipped =
          session.itemsSkipped +
          (action == domain_workflow.WorkflowAction.skipped ? 1 : 0);

      await (_db.update(
        _db.workflowSessions,
      )..where((t) => t.id.equals(sessionId))).write(
        db.WorkflowSessionsCompanion(
          itemsReviewed: Value(updatedReviewed),
          itemsSkipped: Value(updatedSkipped),
          updatedAt: Value(now),
        ),
      );

      // Update the underlying entity review fields.
      await _updateEntityReviewFields(
        entityType: entityType,
        entityId: entityId,
        reviewedAt: effectiveReviewedAt,
        reviewNotes: reviewNotes,
      );
    });

    return id;
  }

  Future<void> _updateEntityReviewFields({
    required domain_screens.EntityType entityType,
    required String entityId,
    required DateTime reviewedAt,
    required String? reviewNotes,
  }) async {
    switch (entityType) {
      case domain_screens.EntityType.task:
        await (_db.update(
          _db.taskTable,
        )..where((t) => t.id.equals(entityId))).write(
          db.TaskTableCompanion(
            lastReviewedAt: Value(reviewedAt),
            reviewNotes: Value(reviewNotes),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      case domain_screens.EntityType.project:
        await (_db.update(
          _db.projectTable,
        )..where((t) => t.id.equals(entityId))).write(
          db.ProjectTableCompanion(
            lastReviewedAt: Value(reviewedAt),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      case domain_screens.EntityType.label:
      case domain_screens.EntityType.goal:
        return;
    }
  }

  domain_workflow.WorkflowItemReview _mapEntity(
    db.WorkflowItemReviewEntity entity,
  ) {
    return domain_workflow.WorkflowItemReview(
      id: entity.id,
      sessionId: entity.sessionId,
      userId: entity.userId ?? '',
      entityId: entity.entityId,
      entityType: _mapEntityTypeFromDrift(entity.entityType),
      action: _mapActionFromDrift(entity.action),
      reviewNotes: entity.reviewNotes,
      reviewedAt: entity.reviewedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  domain_screens.EntityType _mapEntityTypeFromDrift(
    db_screens.EntityType type,
  ) {
    return switch (type) {
      db_screens.EntityType.task => domain_screens.EntityType.task,
      db_screens.EntityType.project => domain_screens.EntityType.project,
      db_screens.EntityType.label => domain_screens.EntityType.label,
      db_screens.EntityType.goal => domain_screens.EntityType.goal,
    };
  }

  db_screens.EntityType _mapEntityTypeToDrift(domain_screens.EntityType type) {
    return switch (type) {
      domain_screens.EntityType.task => db_screens.EntityType.task,
      domain_screens.EntityType.project => db_screens.EntityType.project,
      domain_screens.EntityType.label => db_screens.EntityType.label,
      domain_screens.EntityType.goal => db_screens.EntityType.goal,
    };
  }

  domain_workflow.WorkflowAction _mapActionFromDrift(
    db_screens.WorkflowAction action,
  ) {
    return switch (action) {
      db_screens.WorkflowAction.reviewed =>
        domain_workflow.WorkflowAction.reviewed,
      db_screens.WorkflowAction.skipped =>
        domain_workflow.WorkflowAction.skipped,
    };
  }

  db_screens.WorkflowAction _mapActionToDrift(
    domain_workflow.WorkflowAction action,
  ) {
    return switch (action) {
      domain_workflow.WorkflowAction.reviewed =>
        db_screens.WorkflowAction.reviewed,
      domain_workflow.WorkflowAction.skipped =>
        db_screens.WorkflowAction.skipped,
    };
  }
}
