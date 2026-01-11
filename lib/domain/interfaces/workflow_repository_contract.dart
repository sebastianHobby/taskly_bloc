import 'package:taskly_bloc/domain/workflow/model/workflow.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_definition.dart';

/// Contract for workflow data operations.
abstract class WorkflowRepositoryContract {
  // Workflow Definitions
  Future<WorkflowDefinition> createWorkflowDefinition(
    WorkflowDefinition definition,
  );
  Future<void> updateWorkflowDefinition(WorkflowDefinition definition);
  Future<void> deleteWorkflowDefinition(String id);
  Future<WorkflowDefinition?> getWorkflowDefinition(String id);
  Future<List<WorkflowDefinition>> getAllWorkflowDefinitions();
  Stream<List<WorkflowDefinition>> watchWorkflowDefinitions();

  // Workflow Instances
  Future<Workflow> createWorkflow(Workflow workflow);
  Future<void> updateWorkflow(Workflow workflow);
  Future<void> deleteWorkflow(String id);
  Future<Workflow?> getWorkflow(String id);
  Stream<Workflow> watchWorkflow(String id);
  Stream<List<Workflow>> watchActiveWorkflows();
  Future<List<Workflow>> getWorkflowsByDefinition(String definitionId);
}
