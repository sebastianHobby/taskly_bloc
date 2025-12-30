import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as domain_screens;
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart'
    as domain_workflow;
import 'package:taskly_bloc/domain/repositories/problem_acknowledgments_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of [ProblemAcknowledgmentsRepository].
class ProblemAcknowledgmentsRepositoryImpl
    implements ProblemAcknowledgmentsRepository {
  ProblemAcknowledgmentsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<domain_workflow.ProblemAcknowledgment>>
  watchAcknowledgmentsForEntity({
    required domain_screens.EntityType entityType,
    required String entityId,
  }) {
    return (_db.select(_db.problemAcknowledgments)
          ..where(
            (t) =>
                t.entityId.equals(entityId) &
                t.entityType.equals(_mapEntityTypeToDrift(entityType).name),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.acknowledgedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch()
        .map((rows) => rows.map(_mapEntity).toList());
  }

  @override
  Future<String> acknowledge({
    required domain_workflow.ProblemType problemType,
    required domain_screens.EntityType entityType,
    required String entityId,
    domain_workflow.ResolutionAction? resolutionAction,
    DateTime? snoozeUntil,
    DateTime? acknowledgedAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final effectiveAcknowledgedAt = acknowledgedAt ?? now;

    await _db
        .into(_db.problemAcknowledgments)
        .insert(
          db.ProblemAcknowledgmentsCompanion.insert(
            id: Value(id),
            userId: const Value(''),
            problemType: _problemTypeToDb(problemType),
            entityId: entityId,
            entityType: _mapEntityTypeToDrift(entityType),
            acknowledgedAt: Value(effectiveAcknowledgedAt),
            resolutionAction: Value(
              resolutionAction == null
                  ? null
                  : _resolutionActionToDb(resolutionAction),
            ),
            snoozeUntil: Value(snoozeUntil),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return id;
  }

  domain_workflow.ProblemAcknowledgment _mapEntity(
    db.ProblemAcknowledgmentEntity entity,
  ) {
    return domain_workflow.ProblemAcknowledgment(
      id: entity.id,
      userId: entity.userId ?? '',
      problemType: _problemTypeFromDb(entity.problemType),
      entityId: entity.entityId,
      entityType: _mapEntityTypeFromDrift(entity.entityType),
      acknowledgedAt: entity.acknowledgedAt,
      resolutionAction: entity.resolutionAction == null
          ? null
          : _resolutionActionFromDb(entity.resolutionAction!),
      snoozeUntil: entity.snoozeUntil,
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

  domain_workflow.ProblemType _problemTypeFromDb(String value) {
    return switch (value) {
      'excluded_urgent_task' => domain_workflow.ProblemType.excludedUrgentTask,
      'overdue_high_priority' =>
        domain_workflow.ProblemType.overdueHighPriority,
      'no_next_actions' => domain_workflow.ProblemType.noNextActions,
      'unbalanced_allocation' =>
        domain_workflow.ProblemType.unbalancedAllocation,
      'stale_tasks' => domain_workflow.ProblemType.staleTasks,
      _ => domain_workflow.ProblemType.staleTasks,
    };
  }

  String _problemTypeToDb(domain_workflow.ProblemType type) {
    return switch (type) {
      domain_workflow.ProblemType.excludedUrgentTask => 'excluded_urgent_task',
      domain_workflow.ProblemType.overdueHighPriority =>
        'overdue_high_priority',
      domain_workflow.ProblemType.noNextActions => 'no_next_actions',
      domain_workflow.ProblemType.unbalancedAllocation =>
        'unbalanced_allocation',
      domain_workflow.ProblemType.staleTasks => 'stale_tasks',
    };
  }

  domain_workflow.ResolutionAction _resolutionActionFromDb(String value) {
    return switch (value) {
      'dismissed' => domain_workflow.ResolutionAction.dismissed,
      'fixed' => domain_workflow.ResolutionAction.fixed,
      'snoozed' => domain_workflow.ResolutionAction.snoozed,
      _ => domain_workflow.ResolutionAction.dismissed,
    };
  }

  String _resolutionActionToDb(domain_workflow.ResolutionAction action) {
    return switch (action) {
      domain_workflow.ResolutionAction.dismissed => 'dismissed',
      domain_workflow.ResolutionAction.fixed => 'fixed',
      domain_workflow.ResolutionAction.snoozed => 'snoozed',
    };
  }
}
