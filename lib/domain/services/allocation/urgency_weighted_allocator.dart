import 'package:taskly_bloc/domain/extensions/task_value_inheritance.dart';
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
    final warnings = <AllocationWarning>[];
    final categoryWeights = categories;

    // Calculate total weight
    final totalWeight = categories.values.fold<double>(
      0,
      (sum, weight) => sum + weight,
    );

    if (totalWeight == 0) {
      return AllocationResult(
        allocatedTasks: [],
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: const {},
          urgencyInfluence: urgencyInfluence,
          explanation: 'No categories with weights defined',
        ),
        excludedTasks: [],
        warnings: [
          const AllocationWarning(
            type: WarningType.noTasksInCategory,
            message: 'No priority categories defined',
            suggestedAction: 'Create priority rankings for values or projects',
          ),
        ],
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

      // Get category priority score (0-1)
      final effectiveValues = task.getEffectiveValues();
      final categoryIds = effectiveValues.map((v) => v.id).toSet();

      final matchedCategories = categories.keys
          .where(categoryIds.contains)
          .toList();

      if (matchedCategories.isEmpty) {
        excludedTasks.add(
          ExcludedTask(
            task: task,
            reason: 'Task has no matching priority category',
            exclusionType: ExclusionType.noCategory,
            isUrgent: _isUrgent(task),
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
          isUrgent: _isUrgent(scored.task),
        ),
      );
    }

    // Check for urgent excluded tasks
    final urgentExcluded = excludedTasks
        .where((e) => e.isUrgent ?? false)
        .toList();
    if (urgentExcluded.isNotEmpty) {
      warnings.add(
        AllocationWarning(
          type: WarningType.excludedUrgentTask,
          message: '${urgentExcluded.length} urgent task(s) were excluded',
          suggestedAction:
              'Increase urgency influence or review task priorities',
          affectedTaskIds: urgentExcluded.map((e) => e.task.id).toList(),
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
      warnings: warnings,
    );
  }

  /// Calculates urgency score (0-1) based on deadline proximity
  ///
  /// Returns:
  /// - 1.0 for overdue tasks
  /// - 0.9 for tasks due today
  /// - 0.8 for tasks due tomorrow
  /// - Decreasing score for tasks due further out
  /// - 0.0 for tasks with no deadline
  double _calculateUrgencyScore(Task task) {
    if (task.deadlineDate == null) return 0;

    final now = DateTime.now();
    final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;

    if (daysUntilDeadline < 0) return 1; // Overdue
    if (daysUntilDeadline == 0) return 0.9; // Due today
    if (daysUntilDeadline == 1) return 0.8; // Due tomorrow
    if (daysUntilDeadline <= 3) return 0.7; // Due within 3 days
    if (daysUntilDeadline <= 7) return 0.5; // Due within a week
    if (daysUntilDeadline <= 14) return 0.3; // Due within 2 weeks
    if (daysUntilDeadline <= 30) return 0.1; // Due within a month

    return 0.05; // Due far in future
  }

  bool _isUrgent(Task task) {
    if (task.deadlineDate == null) return false;
    final now = DateTime.now();
    final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;
    return daysUntilDeadline <= 1;
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
