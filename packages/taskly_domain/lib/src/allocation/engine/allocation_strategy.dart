import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/projects/model/project_anchor_state.dart';

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
    required this.projectAnchorStates,
    required this.categories,
    required this.anchorCount,
    required this.tasksPerAnchorMin,
    required this.tasksPerAnchorMax,
    required this.freeSlots,
    required this.rotationPressureDays,
    required this.readinessFilter,
    required this.maxTasks,
    this.taskUrgencyThresholdDays = 3,
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

  /// Days since last progress to apply rotation pressure.
  final int rotationPressureDays;

  /// Only anchor projects with actionable tasks.
  final bool readinessFilter;

  /// Maximum tasks to allocate.
  final int maxTasks;

  /// Days threshold for task urgency.
  final int taskUrgencyThresholdDays;

  /// Routine selections for today by value ID.
  final Map<String, int> routineSelectionsByValue;
}
