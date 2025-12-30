import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Interface for allocation strategies
abstract class AllocationStrategy {
  /// Allocates tasks across categories based on priority rankings
  ///
  /// Parameters:
  /// - [tasks]: Available tasks to allocate
  /// - [ranking]: User's priority ranking with weights
  /// - [totalLimit]: Maximum total tasks to allocate
  /// - [parameters]: Strategy-specific parameters
  Future<AllocationResult> allocate({
    required List<Task> tasks,
    required PriorityRanking ranking,
    required int totalLimit,
    Map<String, dynamic>? parameters,
  });

  /// Strategy name for transparency
  String get strategyName;

  /// Description of how this strategy works
  String get description;
}

/// Parameters for allocation
class AllocationParameters {
  const AllocationParameters({
    this.urgencyInfluence = 0.4,
    this.minimumTasksPerCategory = 1,
    this.topNCategories = 3,
    this.allowOverflow = false,
  });

  /// How much urgency affects allocation (0-1, for urgency-weighted strategy)
  final double urgencyInfluence;

  /// Minimum tasks per category (for minimum-viable strategy)
  final int minimumTasksPerCategory;

  /// Number of top categories to focus on (for top-categories strategy)
  final int topNCategories;

  /// Whether to allow exceeding total limit to meet minimums
  final bool allowOverflow;
}
