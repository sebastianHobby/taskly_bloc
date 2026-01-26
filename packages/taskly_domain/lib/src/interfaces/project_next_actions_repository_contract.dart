import 'package:taskly_domain/src/models/models.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class ProjectNextActionsRepositoryContract {
  /// Watch all next actions.
  Stream<List<ProjectNextAction>> watchAll();

  /// Watch next actions for a single project (ordered by rank).
  Stream<List<ProjectNextAction>> watchForProject(String projectId);

  Future<List<ProjectNextAction>> getAll();

  Future<List<ProjectNextAction>> getForProject(String projectId);

  /// Replace next actions for a project (ranks 1..3).
  Future<void> setForProject({
    required String projectId,
    required List<ProjectNextActionDraft> actions,
    required OperationContext context,
  });

  /// Remove any next-action rows for a task and compact remaining ranks.
  Future<void> removeForTask({
    required String taskId,
    OperationContext? context,
  });
}
