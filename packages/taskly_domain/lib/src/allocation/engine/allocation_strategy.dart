import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/allocation/model/allocation_config.dart';
import 'package:taskly_domain/src/core/model/task.dart';

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
    required this.categories,
    required this.maxTasks,
    this.urgencyInfluence = 0.4,
    this.urgencyThresholdDays = 3,
    this.minimumTasksPerCategory = 1,
    this.topNCategories = 3,
    this.allowOverflow = false,
    this.urgentTaskBehavior = UrgentTaskBehavior.warnOnly,
    this.taskUrgencyThresholdDays = 3,
    this.urgencyBoostMultiplier = 1.0,
    this.neglectLookbackDays = 7,
    this.neglectInfluence = 0.7,
    this.valuePriorityWeight = 1.0,
    this.taskPriorityBoost = 1.0,
    this.overdueEmergencyMultiplier = 1.0,
    this.completionsByValue = const {},
  });

  /// Current time (UTC).
  final DateTime nowUtc;

  /// Today's home-day key (UTC midnight).
  ///
  /// This is the canonical anchor for date-only scheduling semantics.
  final DateTime todayDayKeyUtc;

  /// Tasks to allocate
  final List<Task> tasks;

  /// Categories (value IDs) with their weights
  final Map<String, double> categories;

  /// Maximum tasks to allocate
  final int maxTasks;

  /// How much urgency affects allocation (0-1, for urgency-weighted strategy)
  final double urgencyInfluence;

  /// Days before deadline = urgent (deprecated, use taskUrgencyThresholdDays)
  final int urgencyThresholdDays;

  /// Minimum tasks per category (for minimum-viable strategy)
  final int minimumTasksPerCategory;

  /// Number of top categories to focus on (for top-categories strategy)
  final int topNCategories;

  /// Whether to allow exceeding total limit to meet minimums
  final bool allowOverflow;

  /// How to handle urgent tasks without values.
  final UrgentTaskBehavior urgentTaskBehavior;

  /// Days threshold for task urgency.
  final int taskUrgencyThresholdDays;

  /// Boost multiplier for urgent tasks that have values.
  /// Set to 1.0 to disable urgency boosting.
  final double urgencyBoostMultiplier;

  /// Days to look back for completion history (Reflector mode).
  final int neglectLookbackDays;

  /// Weight of neglect score vs base weight (0-1). (Reflector mode).
  /// 0 = pure base weight, 1 = pure neglect-based.
  final double neglectInfluence;

  /// Weight applied to the base value/category contribution.
  ///
  /// This is used for Fine Tuning in Focus Setup.
  final double valuePriorityWeight;

  /// Boost applied to prioritized tasks.
  final double taskPriorityBoost;

  /// Multiplier controlling how much overdue tasks are boosted.
  final double overdueEmergencyMultiplier;

  /// Recent completions by value ID (pre-computed for Reflector mode).
  /// Passed in from orchestrator to avoid async in allocate().
  final Map<String, int> completionsByValue;
}
