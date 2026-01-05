import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';

/// Service for detecting problems in tasks and projects.
///
/// Uses opt-in problem detection based on DisplayConfig.problemsToDetect
/// combined with global threshold settings from SoftGatesSettings.
///
/// This replaces the old acknowledgment-based system with a lightweight
/// detection system that shows problems inline without requiring persistence.
class ProblemDetectorService {
  ProblemDetectorService({
    required SettingsRepositoryContract settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final SettingsRepositoryContract _settingsRepository;

  /// Detect problems for a list of tasks based on opt-in configuration
  Future<List<DetectedProblem>> detectTaskProblems({
    required List<Task> tasks,
    required DisplayConfig displayConfig,
  }) async {
    if (displayConfig.problemsToDetect.isEmpty) {
      return []; // No opt-in detection configured
    }

    final settings = await _settingsRepository.load(SettingsKey.softGates);
    final problems = <DetectedProblem>[];

    for (final task in tasks) {
      for (final problemType in displayConfig.problemsToDetect) {
        final problem = _detectTaskProblem(
          task: task,
          problemType: problemType,
          settings: settings,
        );
        if (problem != null) {
          problems.add(problem);
        }
      }
    }

    return problems;
  }

  /// Detect problems for a list of projects based on opt-in configuration
  Future<List<DetectedProblem>> detectProjectProblems({
    required List<Project> projects,
    required DisplayConfig displayConfig,
  }) async {
    if (displayConfig.problemsToDetect.isEmpty) {
      return []; // No opt-in detection configured
    }

    final settings = await _settingsRepository.load(SettingsKey.softGates);
    final problems = <DetectedProblem>[];

    for (final project in projects) {
      for (final problemType in displayConfig.problemsToDetect) {
        final problem = _detectProjectProblem(
          project: project,
          problemType: problemType,
          settings: settings,
        );
        if (problem != null) {
          problems.add(problem);
        }
      }
    }

    return problems;
  }

  DetectedProblem? _detectTaskProblem({
    required Task task,
    required ProblemType problemType,
    required SoftGatesSettings settings,
  }) {
    switch (problemType) {
      case ProblemType.taskOverdue:
        // Check if task is overdue
        if (task.deadlineDate != null &&
            task.deadlineDate!.isBefore(DateTime.now()) &&
            !task.completed) {
          return DetectedProblem(
            type: ProblemType.taskOverdue,
            entityId: task.id,
            entityType: EntityType.task,
            title: 'Overdue task',
            description: '"${task.name}" is past its deadline',
            suggestedAction:
                'Complete, reschedule, or break into smaller tasks',
          );
        }

      case ProblemType.taskStale:
        // Check if task hasn't been updated recently
        final daysSinceUpdate = DateTime.now()
            .difference(task.updatedAt)
            .inDays;
        if (daysSinceUpdate > settings.staleAfterDaysWithoutUpdates &&
            !task.completed) {
          return DetectedProblem(
            type: ProblemType.taskStale,
            entityId: task.id,
            entityType: EntityType.task,
            title: 'Stale task',
            description:
                '"${task.name}" hasn\'t been updated in $daysSinceUpdate days',
            suggestedAction: 'Review and update or complete this task',
          );
        }

      case ProblemType.projectIdle:
      case ProblemType.allocationUnbalanced:
      case ProblemType.journalOverdue:
      case ProblemType.trackerMissing:
        // These are allocation-level or wellbeing problems, not task-level
        break;

      case ProblemType.taskOrphan:
        // Check if task has no value assigned (direct or inherited via project)
        if (!task.completed) {
          final hasDirectValue = task.values.isNotEmpty;
          final hasInheritedValue = task.project?.values.isNotEmpty ?? false;
          if (!hasDirectValue && !hasInheritedValue) {
            return DetectedProblem(
              type: ProblemType.taskOrphan,
              entityId: task.id,
              entityType: EntityType.task,
              title: 'Orphan task',
              description: '"${task.name}" has no value assigned',
              suggestedAction: 'Assign a value to include in allocation',
            );
          }
        }
    }

    return null;
  }

  DetectedProblem? _detectProjectProblem({
    required Project project,
    required ProblemType problemType,
    required SoftGatesSettings settings,
  }) {
    switch (problemType) {
      case ProblemType.taskStale:
        // Check if project hasn't been updated recently
        final daysSinceUpdate = DateTime.now()
            .difference(project.updatedAt)
            .inDays;
        if (daysSinceUpdate > settings.staleAfterDaysWithoutUpdates &&
            !project.completed) {
          return DetectedProblem(
            type: ProblemType.taskStale,
            entityId: project.id,
            entityType: EntityType.project,
            title: 'Stale project',
            description:
                '"${project.name}" hasn\'t been updated in $daysSinceUpdate days',
            suggestedAction: 'Review project status and update or archive',
          );
        }

      case ProblemType.taskOverdue:
      case ProblemType.projectIdle:
      case ProblemType.allocationUnbalanced:
      case ProblemType.taskOrphan:
      case ProblemType.journalOverdue:
      case ProblemType.trackerMissing:
        // These are task/allocation-level/wellbeing problems
        break;
    }

    return null;
  }
}
