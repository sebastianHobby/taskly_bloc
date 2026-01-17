import '../model/allocation_result.dart';
import '../../core/model/task.dart';
import 'allocation_scoring.dart';
import 'allocation_strategy.dart';
import '../../services/values/effective_values.dart';

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
    final now = DateTime.now();

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

      // Get category priority score (0-1) using effective values.
      final categoryIds = task.effectiveValues.map((v) => v.id).toSet();

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
      final priorityScore =
          (categoryWeights[topCategoryId]! / totalWeight) *
          parameters.valuePriorityWeight;

      // Calculate urgency score (0-1, where 1 = most urgent)
      final urgencyScore = AllocationScoring.deadlineUrgencyScore(
        task: task,
        now: now,
        overdueEmergencyMultiplier: parameters.overdueEmergencyMultiplier,
      );

      // Blend priority and urgency
      var finalScore =
          (1 - urgencyInfluence) * priorityScore +
          urgencyInfluence * urgencyScore;

      finalScore *= AllocationScoring.taskPriorityMultiplier(
        task: task,
        taskPriorityBoost: parameters.taskPriorityBoost,
      );

      finalScore *= AllocationScoring.recencyMultiplier(
        task: task,
        now: now,
        recencyPenalty: parameters.recencyPenalty,
      );

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
