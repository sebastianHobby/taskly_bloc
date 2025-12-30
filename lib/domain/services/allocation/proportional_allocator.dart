import 'package:taskly_bloc/domain/extensions/task_value_inheritance.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';

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
  Future<AllocationResult> allocate({
    required List<Task> tasks,
    required PriorityRanking ranking,
    required int totalLimit,
    Map<String, dynamic>? parameters,
  }) async {
    final allocatedTasks = <AllocatedTask>[];
    final excludedTasks = <ExcludedTask>[];
    final warnings = <AllocationWarning>[];

    // Calculate total weight
    final totalWeight = ranking.items.fold<int>(
      0,
      (sum, item) => sum + item.weight,
    );

    if (totalWeight == 0) {
      return AllocationResult(
        allocatedTasks: [],
        reasoning: const AllocationReasoning(
          strategyUsed: 'Proportional',
          categoryAllocations: {},
          categoryWeights: {},
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

    // Calculate allocation per category
    final categoryAllocations = <String, int>{};
    final categoryWeights = <String, double>{};
    var remainingSlots = totalLimit;

    // First pass: calculate raw allocations
    final rawAllocations = <String, double>{};
    for (final item in ranking.items) {
      final proportion = item.weight / totalWeight;
      rawAllocations[item.entityId] = totalLimit * proportion;
      categoryWeights[item.entityId] = item.weight.toDouble();
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

      // Use effective values for categorization (includes inherited)
      final effectiveValues = task.getEffectiveValues();
      final categoryIds = effectiveValues.map((v) => v.id).toSet();

      // Check if task matches any ranked category
      final matchedCategories = ranking.items
          .where((item) => categoryIds.contains(item.entityId))
          .toList();

      if (matchedCategories.isEmpty) {
        tasksWithoutCategory.add(task);
      } else {
        // Add to highest-weighted matching category
        matchedCategories.sort((a, b) => b.weight.compareTo(a.weight));
        final categoryId = matchedCategories.first.entityId;
        tasksByCategory.putIfAbsent(categoryId, () => []).add(task);
      }
    }

    // Allocate tasks from each category
    for (final entry in categoryAllocations.entries) {
      final categoryId = entry.key;
      final allocation = entry.value;
      final availableTasks = tasksByCategory[categoryId] ?? [];

      if (availableTasks.isEmpty) {
        warnings.add(
          AllocationWarning(
            type: WarningType.noTasksInCategory,
            message: 'No tasks available for category $categoryId',
            suggestedAction: 'Add tasks with this value or adjust priorities',
          ),
        );
        continue;
      }

      // Take up to allocation limit
      final tasksToAllocate = availableTasks.take(allocation).toList();

      for (var i = 0; i < tasksToAllocate.length; i++) {
        allocatedTasks.add(
          AllocatedTask(
            task: tasksToAllocate[i],
            categoryId: categoryId,
            categoryName: _getCategoryName(ranking, categoryId),
            allocationScore: categoryWeights[categoryId]!,
            position: i,
            allocationReason:
                'Allocated proportionally (weight: ${categoryWeights[categoryId]?.toInt()})',
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
            isUrgent: _isUrgent(availableTasks[i]),
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
          isUrgent: _isUrgent(task),
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
              'Review excluded urgent tasks and consider adjusting priorities',
          affectedTaskIds: urgentExcluded.map((e) => e.task.id).toList(),
        ),
      );
    }

    // Check for unbalanced allocation
    if (categoryAllocations.values.any((count) => count == 0)) {
      warnings.add(
        const AllocationWarning(
          type: WarningType.unbalancedAllocation,
          message: 'Some priority categories received no tasks',
          suggestedAction:
              'Consider adjusting category weights or adding more tasks',
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
      warnings: warnings,
    );
  }

  String _getCategoryName(PriorityRanking ranking, String categoryId) {
    return ranking.items
        .firstWhere((item) => item.entityId == categoryId)
        .entityId; // In real implementation, look up label/project name
  }

  bool _isUrgent(Task task) {
    if (task.deadlineDate == null) return false;
    final now = DateTime.now();
    final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;
    return daysUntilDeadline <= 1; // Due within 1 day
  }
}
