import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';

import 'package:taskly_bloc/domain/models/task.dart';

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
    required this.tasks,
    required this.categories,
    required this.maxTasks,
    this.urgencyInfluence = 0.4,
    this.urgencyThresholdDays = 3,
    this.minimumTasksPerCategory = 1,
    this.topNCategories = 3,
    this.allowOverflow = false,
  });

  /// Tasks to allocate
  final List<Task> tasks;

  /// Categories (value IDs) with their weights
  final Map<String, double> categories;

  /// Maximum tasks to allocate
  final int maxTasks;

  /// How much urgency affects allocation (0-1, for urgency-weighted strategy)
  final double urgencyInfluence;

  /// Days before deadline = urgent
  final int urgencyThresholdDays;

  /// Minimum tasks per category (for minimum-viable strategy)
  final int minimumTasksPerCategory;

  /// Number of top categories to focus on (for top-categories strategy)
  final int topNCategories;

  /// Whether to allow exceeding total limit to meet minimums
  final bool allowOverflow;
}
