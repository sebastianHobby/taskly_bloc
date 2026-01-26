import 'package:taskly_domain/src/allocation/model/allocation_config.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/projects/model/project_anchor_state.dart';
import 'package:taskly_domain/src/projects/model/project_next_action.dart';

/// Interface for allocation strategies
abstract class AllocationStrategy {
  /// Allocates tasks across categories based on weights
  ///
  /// Parameters should include tasks, categories (id -> weight), max tasks, etc.
  AllocationResult allocate(AllocationParameters parameters);

  /// Strategy name for transparency
  String get strategyName;

  /// Description of how this strategy works
  String get description;
}

/// Parameters for allocation
class AllocationParameters {
  const AllocationParameters({
    required this.nowUtc,
    required this.todayDayKeyUtc,
    required this.tasks,
    required this.projects,
    required this.projectNextActions,
    required this.projectAnchorStates,
    required this.categories,
    required this.anchorCount,
    required this.tasksPerAnchorMin,
    required this.tasksPerAnchorMax,
    required this.freeSlots,
    required this.nextActionPolicy,
    required this.rotationPressureDays,
    required this.readinessFilter,
    required this.maxTasks,
    this.taskUrgencyThresholdDays = 3,
    this.keepValuesInBalance = false,
    this.completionsByValue = const {},
    this.routineSelectionsByValue = const {},
  });

  /// Current time (UTC).
  final DateTime nowUtc;

  /// Today's home-day key (UTC midnight).
  ///
  /// This is the canonical anchor for date-only scheduling semantics.
  final DateTime todayDayKeyUtc;

  /// Tasks to allocate
  final List<Task> tasks;

  /// Projects to allocate anchors from.
  final List<Project> projects;

  /// Ranked next actions per project.
  final List<ProjectNextAction> projectNextActions;

  /// Anchor state per project.
  final List<ProjectAnchorState> projectAnchorStates;

  /// Categories (value IDs) with their weights
  final Map<String, double> categories;

  /// Number of anchor projects to select.
  final int anchorCount;

  /// Minimum tasks per anchor.
  final int tasksPerAnchorMin;

  /// Maximum tasks per anchor.
  final int tasksPerAnchorMax;

  /// Extra free slots beyond anchor allocation.
  final int freeSlots;

  /// Next action policy for task selection within anchors.
  final NextActionPolicy nextActionPolicy;

  /// Days since last progress to apply rotation pressure.
  final int rotationPressureDays;

  /// Only anchor projects with actionable tasks.
  final bool readinessFilter;

  /// Maximum tasks to allocate.
  final int maxTasks;

  /// Days threshold for task urgency.
  final int taskUrgencyThresholdDays;

  /// Whether the engine may use completion history to do bounded balancing.
  final bool keepValuesInBalance;

  /// Recent completions by value ID (pre-computed for Reflector mode).
  /// Passed in from orchestrator to avoid async in allocate().
  final Map<String, int> completionsByValue;

  /// Routine selections for today by value ID.
  final Map<String, int> routineSelectionsByValue;
}
