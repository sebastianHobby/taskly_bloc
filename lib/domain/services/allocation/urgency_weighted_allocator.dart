import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';

/// Urgency-weighted allocation strategy
///
/// Blends priority rankings with task urgency (deadline proximity).
/// Ensures urgent tasks aren't excluded due to low category priority.
///
/// Algorithm:
/// 1. Calculate base allocation proportionally (like ProportionalAllocator)
/// 2. Calculate urgency score for each task (0-1, based on days until deadline)
/// 3. Adjust allocation: final_score = (1 - influence) * priority + influence * urgency
/// 4. Sort tasks by adjusted score and allocate top N
class UrgencyWeightedAllocator implements AllocationStrategy {
  @override
  String get strategyName => 'Urgency-Weighted';

  @override
  String get description =>
      'Balances priority rankings with task urgency. '
      'Urgent tasks get boosted even if in lower-priority categories.';

  @override
  AllocationResult allocate(AllocationParameters parameters) {
    final tasks = parameters.tasks;
    final categories = parameters.categories;
    final totalLimit = parameters.maxTasks;
    final urgencyInfluence = parameters.urgencyInfluence;

    final allocatedTasks = <AllocatedTask>[];
    final excludedTasks = <ExcludedTask>[];
    final categoryWeights = categories;

    // Calculate total weight
    final totalWeight = categories.values.fold<double>(
      0,
      (sum, weight) => sum + weight,
    );

    if (totalWeight == 0) {
      return AllocationResult(
        allocatedTasks: const [],
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: const {},
          urgencyInfluence: urgencyInfluence,
          explanation: 'No categories with weights defined',
        ),
        excludedTasks: const [],
      );
    }

    // Score all tasks
    final scoredTasks = <ScoredTask>[];

    for (final task in tasks) {
      if (task.completed) {
        excludedTasks.add(
          ExcludedTask(
            task: task,
            reason: 'Task is completed',
            exclusionType: ExclusionType.completed,
          ),
        );
        continue;
      }

      // Get category priority score (0-1) using task's direct values
      final categoryIds = task.values.map((v) => v.id).toSet();

      final matchedCategories = categories.keys
          .where(categoryIds.contains)
          .toList();

      if (matchedCategories.isEmpty) {
        excludedTasks.add(
          ExcludedTask(
            task: task,
            reason: 'Task has no matching priority category',
            exclusionType: ExclusionType.noCategory,
            isUrgent: _isUrgent(task, parameters.taskUrgencyThresholdDays),
          ),
        );
        continue;
      }

      // Use highest category weight
      matchedCategories.sort(
        (a, b) => categories[b]!.compareTo(categories[a]!),
      );
      final topCategoryId = matchedCategories.first;
      final priorityScore = categoryWeights[topCategoryId]! / totalWeight;

      // Calculate urgency score (0-1, where 1 = most urgent)
      final urgencyScore = _calculateUrgencyScore(task);

      // Blend priority and urgency
      final finalScore =
          (1 - urgencyInfluence) * priorityScore +
          urgencyInfluence * urgencyScore;

      scoredTasks.add(
        ScoredTask(
          task: task,
          categoryId: topCategoryId,
          priorityScore: priorityScore,
          urgencyScore: urgencyScore,
          finalScore: finalScore,
        ),
      );
    }

    // Sort by final score (descending) and take top N
    scoredTasks.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    final tasksToAllocate = scoredTasks.take(totalLimit).toList();
    final tasksToExclude = scoredTasks.skip(totalLimit).toList();

    // Create allocated tasks
    final categoryAllocations = <String, int>{};
    for (var i = 0; i < tasksToAllocate.length; i++) {
      final scored = tasksToAllocate[i];

      categoryAllocations[scored.categoryId] =
          (categoryAllocations[scored.categoryId] ?? 0) + 1;

      allocatedTasks.add(
        AllocatedTask(
          task: scored.task,
          qualifyingValueId: scored.categoryId,
          allocationScore: scored.finalScore,
        ),
      );
    }

    // Handle excluded tasks
    for (final scored in tasksToExclude) {
      excludedTasks.add(
        ExcludedTask(
          task: scored.task,
          reason: 'Lower combined priority/urgency score',
          exclusionType: ExclusionType.lowPriority,
          isUrgent: _isUrgent(scored.task, parameters.taskUrgencyThresholdDays),
        ),
      );
    }

    return AllocationResult(
      allocatedTasks: allocatedTasks,
      reasoning: AllocationReasoning(
        strategyUsed: strategyName,
        categoryAllocations: categoryAllocations,
        categoryWeights: categoryWeights,
        urgencyInfluence: urgencyInfluence,
        explanation:
            'Tasks allocated using blended priority (${((1 - urgencyInfluence) * 100).toInt()}%) '
            'and urgency (${(urgencyInfluence * 100).toInt()}%) scores',
      ),
      excludedTasks: excludedTasks,
    );
  }

  /// Calculates urgency score (0-1) using smooth decay curve.
  ///
  /// Uses formula: 1 / (1 + days/7)
  /// - Day 0 = 1.0
  /// - Day 7 = 0.5
  /// - Day 14 = 0.33
  /// - Day 21 = 0.25
  ///
  /// Returns:
  /// - 1.0 for overdue tasks (clamped)
  /// - Smooth decay for future deadlines
  /// - 0.0 for tasks with no deadline
  double _calculateUrgencyScore(Task task) {
    if (task.deadlineDate == null) return 0;

    final now = DateTime.now();
    final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;

    if (daysUntilDeadline < 0) {
      // Overdue: clamp at 1.0
      return 1;
    }

    // Smooth decay: 1 / (1 + days/7)
    return 1.0 / (1.0 + daysUntilDeadline / 7.0);
  }

  bool _isUrgent(Task task, int thresholdDays) {
    if (task.deadlineDate == null) return false;
    final now = DateTime.now();
    final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;
    return daysUntilDeadline <= thresholdDays;
  }
}

/// Internal class for scored tasks
class ScoredTask {
  const ScoredTask({
    required this.task,
    required this.categoryId,
    required this.priorityScore,
    required this.urgencyScore,
    required this.finalScore,
  });

  final Task task;
  final String categoryId;
  final double priorityScore;
  final double urgencyScore;
  final double finalScore;
}
