import 'package:drift/drift.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_bloc/data/infrastructure/drift/features/workflow_tables.drift.dart'
    as db_workflow;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';

/// Drift implementation of [WorkflowRepositoryContract].
class WorkflowRepositoryImpl implements WorkflowRepositoryContract {
  WorkflowRepositoryImpl(this._db, this._idGenerator);

  final db.AppDatabase _db;
  final IdGenerator _idGenerator;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Workflow Definitions
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Future<WorkflowDefinition> createWorkflowDefinition(
    WorkflowDefinition definition,
  ) async {
    final now = DateTime.now();
    // Use v5 deterministic ID for workflow definitions (userId + name)
    final id = definition.id.isEmpty
        ? _idGenerator.workflowDefinitionId(name: definition.name)
        : definition.id;

    await _db
        .into(_db.workflowDefinitions)
        .insert(
          db.WorkflowDefinitionsCompanion.insert(
            id: id,
            // userId is set by Supabase trigger/RLS, we don't set it locally
            workflowKey: _generateWorkflowKey(definition.name),
            name: definition.name,
            description: Value(definition.description),
            iconName: Value(definition.iconName),
            isSystem: Value(definition.isSystem),
            isActive: Value(definition.isActive),
            sortOrder: const Value(0),
            steps: definition.steps,
            triggerConfig: Value(definition.triggerConfig),
            lastCompletedAt: Value(definition.lastCompletedAt),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    talker.repositoryLog(
      'Workflow',
      'Created workflow definition: $id (${definition.name})',
    );

    return definition.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  @override
  Future<void> updateWorkflowDefinition(WorkflowDefinition definition) async {
    final now = DateTime.now();

    await (_db.update(
      _db.workflowDefinitions,
    )..where((t) => t.id.equals(definition.id))).write(
      db.WorkflowDefinitionsCompanion(
        name: Value(definition.name),
        description: Value(definition.description),
        iconName: Value(definition.iconName),
        isSystem: Value(definition.isSystem),
        isActive: Value(definition.isActive),
        steps: Value(definition.steps),
        triggerConfig: Value(definition.triggerConfig),
        lastCompletedAt: Value(definition.lastCompletedAt),
        updatedAt: Value(now),
      ),
    );

    talker.repositoryLog(
      'Workflow',
      'Updated workflow definition: ${definition.id}',
    );
  }

  @override
  Future<void> deleteWorkflowDefinition(String id) async {
    await (_db.delete(
      _db.workflowDefinitions,
    )..where((t) => t.id.equals(id))).go();

    talker.repositoryLog('Workflow', 'Deleted workflow definition: $id');
  }

  @override
  Future<WorkflowDefinition?> getWorkflowDefinition(String id) async {
    final entity = await (_db.select(
      _db.workflowDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return entity == null ? null : _mapDefinitionEntity(entity);
  }

  @override
  Future<List<WorkflowDefinition>> getAllWorkflowDefinitions() async {
    final entities =
        await (_db.select(_db.workflowDefinitions)
              ..where((t) => t.isActive.equals(true))
              ..orderBy([
                (t) => OrderingTerm(expression: t.sortOrder),
                (t) => OrderingTerm(expression: t.createdAt),
              ]))
            .get();

    return entities.map(_mapDefinitionEntity).toList();
  }

  @override
  Stream<List<WorkflowDefinition>> watchWorkflowDefinitions() {
    return (_db.select(_db.workflowDefinitions)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map((entities) => entities.map(_mapDefinitionEntity).toList());
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Workflow Instances
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Future<Workflow> createWorkflow(Workflow workflow) async {
    final now = DateTime.now();
    // Use v4 random ID for workflow instances (each run is unique)
    final id = workflow.id.isEmpty ? _idGenerator.workflowRunId() : workflow.id;

    await _db
        .into(_db.workflows)
        .insert(
          db.WorkflowsCompanion.insert(
            id: Value(id),
            // userId is set by Supabase trigger/RLS, we don't set it locally
            workflowDefinitionId: workflow.workflowDefinitionId,
            status: Value(_toDbStatus(workflow.status)),
            startedAt: Value(workflow.createdAt),
            completedAt: Value(workflow.completedAt),
            currentStepIndex: Value(workflow.currentStepIndex),
            stepStates: workflow.stepStates,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    talker.repositoryLog(
      'Workflow',
      'Created workflow: $id (definition: ${workflow.workflowDefinitionId})',
    );

    return workflow.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  @override
  Future<void> updateWorkflow(Workflow workflow) async {
    final now = DateTime.now();

    await (_db.update(
      _db.workflows,
    )..where((t) => t.id.equals(workflow.id))).write(
      db.WorkflowsCompanion(
        status: Value(_toDbStatus(workflow.status)),
        completedAt: Value(workflow.completedAt),
        currentStepIndex: Value(workflow.currentStepIndex),
        stepStates: Value(workflow.stepStates),
        updatedAt: Value(now),
      ),
    );

    talker.repositoryLog('Workflow', 'Updated workflow: ${workflow.id}');
  }

  @override
  Future<void> deleteWorkflow(String id) async {
    await (_db.delete(_db.workflows)..where((t) => t.id.equals(id))).go();
    talker.repositoryLog('Workflow', 'Deleted workflow: $id');
  }

  @override
  Future<Workflow?> getWorkflow(String id) async {
    final entity = await (_db.select(
      _db.workflows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return entity == null ? null : _mapWorkflowEntity(entity);
  }

  @override
  Stream<Workflow> watchWorkflow(String id) {
    return (_db.select(
      _db.workflows,
    )..where((t) => t.id.equals(id))).watchSingle().map(_mapWorkflowEntity);
  }

  @override
  Stream<List<Workflow>> watchActiveWorkflows() {
    return (_db.select(_db.workflows)
          ..where(
            (t) => t.status.equals(
              db_workflow.WorkflowInstanceStatus.inProgress.name,
            ),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch()
        .map((entities) => entities.map(_mapWorkflowEntity).toList());
  }

  @override
  Future<List<Workflow>> getWorkflowsByDefinition(String definitionId) async {
    final entities =
        await (_db.select(_db.workflows)
              ..where((t) => t.workflowDefinitionId.equals(definitionId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    return entities.map(_mapWorkflowEntity).toList();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Private mapping helpers
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  WorkflowDefinition _mapDefinitionEntity(db.WorkflowDefinitionEntity e) {
    return WorkflowDefinition(
      id: e.id,
      name: e.name,
      description: e.description,
      iconName: e.iconName,
      isSystem: e.isSystem,
      isActive: e.isActive,
      steps: e.steps,
      triggerConfig: e.triggerConfig,
      lastCompletedAt: e.lastCompletedAt,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  Workflow _mapWorkflowEntity(db.WorkflowEntity e) {
    return Workflow(
      id: e.id,
      workflowDefinitionId: e.workflowDefinitionId,
      status: _fromDbStatus(e.status),
      stepStates: e.stepStates,
      currentStepIndex: e.currentStepIndex,
      completedAt: e.completedAt,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  db_workflow.WorkflowInstanceStatus _toDbStatus(WorkflowStatus status) {
    return switch (status) {
      WorkflowStatus.inProgress =>
        db_workflow.WorkflowInstanceStatus.inProgress,
      WorkflowStatus.completed => db_workflow.WorkflowInstanceStatus.completed,
      WorkflowStatus.abandoned => db_workflow.WorkflowInstanceStatus.abandoned,
    };
  }

  WorkflowStatus _fromDbStatus(db_workflow.WorkflowInstanceStatus status) {
    return switch (status) {
      db_workflow.WorkflowInstanceStatus.inProgress =>
        WorkflowStatus.inProgress,
      db_workflow.WorkflowInstanceStatus.completed => WorkflowStatus.completed,
      db_workflow.WorkflowInstanceStatus.abandoned => WorkflowStatus.abandoned,
    };
  }

  String _generateWorkflowKey(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
