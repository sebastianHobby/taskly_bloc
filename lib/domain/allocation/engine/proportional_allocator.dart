import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_scoring.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_strategy.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';

/// Proportional allocation strategy
///
/// Divides tasks across categories based on their weight ratios.
/// A category with weight 8 gets 2x more tasks than a category with weight 4.
///
/// Algorithm:
/// 1. Calculate total weight across all categories
/// 2. Allocate tasks proportionally: (category_weight / total_weight) * total_limit
/// 3. Round allocations while preserving total
/// 4. Fill each category's allocation from available tasks
class ProportionalAllocator implements AllocationStrategy {
  @override
  String get strategyName => 'Proportional';

  @override
  String get description =>
      'Allocates tasks proportionally based on category weights. '
      'Higher weighted categories receive more tasks.';

  @override
  AllocationResult allocate(AllocationParameters parameters) {
    final tasks = parameters.tasks;
    final categories = parameters.categories;
    final totalLimit = parameters.maxTasks;
    final now = DateTime.now();

    final allocatedTasks = <AllocatedTask>[];
    final excludedTasks = <ExcludedTask>[];

    // Calculate total weight
    final totalWeight = categories.values.fold<double>(
      0,
      (sum, weight) => sum + weight,
    );

    if (totalWeight == 0) {
      return const AllocationResult(
        allocatedTasks: [],
        excludedTasks: [],
        reasoning: AllocationReasoning(
          strategyUsed: 'Proportional',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'No categories with weights defined',
        ),
      );
    }

    // Calculate allocation per category
    final categoryAllocations = <String, int>{};
    final categoryWeights = categories;
    var remainingSlots = totalLimit;

    // First pass: calculate raw allocations
    final rawAllocations = <String, double>{};
    for (final entry in categories.entries) {
      final proportion = entry.value / totalWeight;
      rawAllocations[entry.key] = totalLimit * proportion;
    }

    // Second pass: round down and track remainders
    final remainders = <String, double>{};
    for (final entry in rawAllocations.entries) {
      final allocated = entry.value.floor();
      categoryAllocations[entry.key] = allocated;
      remainingSlots -= allocated;
      remainders[entry.key] = entry.value - allocated;
    }

    // Third pass: distribute remaining slots to categories with largest remainders
    if (remainingSlots > 0) {
      final sortedByRemainder = remainders.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var i = 0; i < remainingSlots && i < sortedByRemainder.length; i++) {
        final categoryId = sortedByRemainder[i].key;
        categoryAllocations[categoryId] = categoryAllocations[categoryId]! + 1;
      }
    }

    // Group tasks by category (using effective values for inheritance)
    final tasksByCategory = <String, List<Task>>{};
    final tasksWithoutCategory = <Task>[];

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

      // Use effective values (task values override project, else inherit).
      final categoryIds = task.effectiveValues.map((v) => v.id).toSet();

      // Check if task matches any category from parameters
      final matchedCategories = categories.keys
          .where(categoryIds.contains)
          .toList();

      if (matchedCategories.isEmpty) {
        tasksWithoutCategory.add(task);
      } else {
        // Add to highest-weighted matching category
        matchedCategories.sort(
          (a, b) => categories[b]!.compareTo(categories[a]!),
        );
        final categoryId = matchedCategories.first;
        tasksByCategory.putIfAbsent(categoryId, () => []).add(task);
      }
    }

    // Allocate tasks from each category
    for (final entry in categoryAllocations.entries) {
      final categoryId = entry.key;
      final allocation = entry.value;
      final availableTasks = tasksByCategory[categoryId] ?? [];

      availableTasks.sort(
        (a, b) =>
            _taskScore(
              task: b,
              now: now,
              categoryWeight: categoryWeights[categoryId] ?? 0.0,
              totalWeight: totalWeight,
              parameters: parameters,
            ).compareTo(
              _taskScore(
                task: a,
                now: now,
                categoryWeight: categoryWeights[categoryId] ?? 0.0,
                totalWeight: totalWeight,
                parameters: parameters,
              ),
            ),
      );

      if (availableTasks.isEmpty) {
        // No tasks for this category - problem detection handles this
        continue;
      }

      // Take up to allocation limit
      final tasksToAllocate = availableTasks.take(allocation).toList();

      for (var i = 0; i < tasksToAllocate.length; i++) {
        allocatedTasks.add(
          AllocatedTask(
            task: tasksToAllocate[i],
            qualifyingValueId: categoryId,
            allocationScore: categoryWeights[categoryId] ?? 0.0,
          ),
        );
      }

      // Exclude tasks beyond allocation
      for (var i = allocation; i < availableTasks.length; i++) {
        excludedTasks.add(
          ExcludedTask(
            task: availableTasks[i],
            reason: 'Category limit reached ($allocation tasks)',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: _isUrgent(
              availableTasks[i],
              parameters.taskUrgencyThresholdDays,
            ),
          ),
        );
      }
    }

    // Handle tasks without category
    for (final task in tasksWithoutCategory) {
      excludedTasks.add(
        ExcludedTask(
          task: task,
          reason: 'Task has no matching priority category',
          exclusionType: ExclusionType.noCategory,
          isUrgent: _isUrgent(task, parameters.taskUrgencyThresholdDays),
        ),
      );
    }

    return AllocationResult(
      allocatedTasks: allocatedTasks,
      reasoning: AllocationReasoning(
        strategyUsed: strategyName,
        categoryAllocations: categoryAllocations,
        categoryWeights: categoryWeights,
        explanation: 'Tasks allocated proportionally based on category weights',
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

  double _taskScore({
    required Task task,
    required DateTime now,
    required double categoryWeight,
    required double totalWeight,
    required AllocationParameters parameters,
  }) {
    var score =
        (categoryWeight / totalWeight).clamp(0.0, 1.0) *
        parameters.valuePriorityWeight;

    final isUrgent = _isUrgent(task, parameters.taskUrgencyThresholdDays);
    if (isUrgent) {
      score *= parameters.urgencyBoostMultiplier;
    }

    final deadline = task.deadlineDate;
    if (deadline != null) {
      final daysUntilDeadline = deadline.difference(now).inDays;
      if (daysUntilDeadline < 0) {
        score *= AllocationScoring.overdueEmergencyFactor(
          daysOverdue: -daysUntilDeadline,
          overdueEmergencyMultiplier: parameters.overdueEmergencyMultiplier,
        );
      }
    }

    score *= AllocationScoring.taskPriorityMultiplier(
      task: task,
      taskPriorityBoost: parameters.taskPriorityBoost,
    );

    score *= AllocationScoring.recencyMultiplier(
      task: task,
      now: now,
      recencyPenalty: parameters.recencyPenalty,
    );

    return score;
  }
}
