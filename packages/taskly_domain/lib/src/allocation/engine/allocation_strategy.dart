import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
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
    this.taskUrgencyThresholdDays = 3,
    this.keepValuesInBalance = false,
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

  /// Days threshold for task urgency.
  final int taskUrgencyThresholdDays;

  /// Whether the engine may use completion history to do bounded balancing.
  final bool keepValuesInBalance;

  /// Recent completions by value ID (pre-computed for Reflector mode).
  /// Passed in from orchestrator to avoid async in allocate().
  final Map<String, int> completionsByValue;
}
