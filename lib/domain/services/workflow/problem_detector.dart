import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';

/// Computes soft-gate problems for a workflow run.
///
/// This is intentionally pure (no repositories) so it can be unit tested.
class ProblemDetector {
  const ProblemDetector();

  /// Detect problems for the current workflow context.
  ///
  /// - [workflowTasks]: tasks in the current workflow run.
  /// - [urgentTasksAllOpen]: the app's current set of *urgent* open tasks.
  ///   Used to detect urgent tasks that are excluded from the workflow.
  List<DetectedProblem> detectForWorkflowRun({
    required List<Task> workflowTasks,
    required List<Task> urgentTasksAllOpen,
    required SoftGatesSettings settings,
    required DateTime now,
  }) {
    final workflowTaskIds = workflowTasks.map((t) => t.id).toSet();

    final urgentExcluded = urgentTasksAllOpen
        .where((t) => !workflowTaskIds.contains(t.id))
        .toList(growable: false);

    final urgentProblems = urgentExcluded
        .map(
          (task) => DetectedProblem(
            type: ProblemType.excludedUrgentTask,
            entityId: task.id,
            entityType: EntityType.task,
            title: 'Urgent task outside this workflow',
            description:
                '“${task.name}” is due within ${settings.urgentDeadlineWithinDays} '
                'days (or overdue) but is not included in this workflow.',
            suggestedAction:
                "Review it, reschedule it, or adjust this workflow's filters.",
          ),
        )
        .toList(growable: false);

    final staleCutoff = now.subtract(
      Duration(days: settings.staleAfterDaysWithoutUpdates),
    );

    final staleProblems = workflowTasks
        .where((t) => !t.completed)
        .where((t) => t.updatedAt.isBefore(staleCutoff))
        .map(
          (task) => DetectedProblem(
            type: ProblemType.staleTasks,
            entityId: task.id,
            entityType: EntityType.task,
            title: 'Stale task in workflow',
            description:
                '“${task.name}” has not been updated in '
                '${settings.staleAfterDaysWithoutUpdates} days.',
            suggestedAction:
                "Update it, break it down, or remove it if it's no longer relevant.",
          ),
        )
        .toList(growable: false);

    return <DetectedProblem>[...urgentProblems, ...staleProblems];
  }

  /// Returns open tasks considered urgent given [settings].
  ///
  /// Used by the workflow runner to build [urgentTasksAllOpen] efficiently.
  @visibleForTesting
  bool isUrgentOpenTask({
    required Task task,
    required SoftGatesSettings settings,
    required DateTime now,
  }) {
    if (task.completed) return false;
    final deadline = task.deadlineDate;
    if (deadline == null) return false;

    final latestUrgent = now.add(
      Duration(days: settings.urgentDeadlineWithinDays),
    );
    return !deadline.isAfter(latestUrgent);
  }
}
