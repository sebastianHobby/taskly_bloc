import 'package:taskly_bloc/domain/extensions/task_value_inheritance.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_detector.dart';

/// Allocator that prioritizes values the user has been neglecting.
///
/// Used by the Reflector persona to maintain balance across values.
/// Calculates neglect scores based on recent completion history.
///
/// **Combined Scoring**: All factors (value weight, neglect, urgency) are
/// combined into a single score per task. No sequential application.
/// This enables Custom mode combinations like "neglect + urgency".
class NeglectBasedAllocator implements AllocationStrategy {
  @override
  String get strategyName => 'Neglect-Based';

  @override
  String get description =>
      "Prioritizes values you've been neglecting recently. "
      'Helps maintain balance across all your values.';

  @override
  AllocationResult allocate(AllocationParameters parameters) {
    final tasks = parameters.tasks;
    final categories = parameters.categories;
    final totalLimit = parameters.maxTasks;
    final completionsByValue = parameters.completionsByValue;

    final allocatedTasks = <AllocatedTask>[];
    final excludedTasks = <ExcludedTask>[];

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
          explanation: 'No categories with weights defined',
        ),
        excludedTasks: const [],
      );
    }

    // Calculate neglect scores per value (lookup table)
    final neglectScores = _calculateNeglectScores(
      categories: categories,
      completionsByValue: completionsByValue,
      totalWeight: totalWeight,
    );

    // Normalize neglect scores to multiplier range
    final neglectMultipliers = _normalizeNeglectScores(
      neglectScores: neglectScores,
      neglectInfluence: parameters.neglectInfluence,
    );

    // Create urgency detector for task urgency
    final detector = UrgencyDetector(
      taskThresholdDays: parameters.taskUrgencyThresholdDays,
      projectThresholdDays: parameters.taskUrgencyThresholdDays,
    );

    // SINGLE-PASS: Calculate combined score for EACH task
    final scoredTasks = <_ScoredTask>[];

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

      // Get task's value(s)
      final effectiveValues = task.getEffectiveValues();
      final categoryIds = effectiveValues.map((v) => v.id).toSet();

      final matchedCategories = categories.keys
          .where(categoryIds.contains)
          .toList();

      if (matchedCategories.isEmpty) {
        excludedTasks.add(
          ExcludedTask(
            task: task,
            reason: 'Task has no matching value category',
            exclusionType: ExclusionType.noCategory,
          ),
        );
        continue;
      }

      // Use first matched category for scoring
      final categoryId = matchedCategories.first;
      final categoryWeight = categories[categoryId] ?? 0;

      // Base score from value weight (normalized)
      final baseScore = categoryWeight / totalWeight;

      // Neglect factor (from task's value)
      final neglectFactor = neglectMultipliers[categoryId] ?? 1.0;

      // Urgency factor (from task's deadline)
      final isUrgent = detector.isTaskUrgent(task);
      final urgencyFactor = isUrgent ? parameters.urgencyBoostMultiplier : 1.0;

      // COMBINED SCORE: all factors multiplied together
      final combinedScore = baseScore * neglectFactor * urgencyFactor;

      // Check if value is neglected (positive neglect score)
      final isNeglectedValue = (neglectScores[categoryId] ?? 0) > 0;

      scoredTasks.add(
        _ScoredTask(
          task: task,
          categoryId: categoryId,
          score: combinedScore,
          isUrgent: isUrgent,
          isNeglectedValue: isNeglectedValue,
        ),
      );
    }

    // Sort by combined score (highest first) and take top N
    scoredTasks.sort((a, b) => b.score.compareTo(a.score));

    // Allocate top tasks
    final categoryAllocations = <String, int>{};
    for (final scored in scoredTasks.take(totalLimit)) {
      categoryAllocations[scored.categoryId] =
          (categoryAllocations[scored.categoryId] ?? 0) + 1;

      allocatedTasks.add(
        AllocatedTask(
          task: scored.task,
          qualifyingValueId: scored.categoryId,
          allocationScore: scored.score,
        ),
      );
    }

    // Remaining tasks are excluded
    for (final scored in scoredTasks.skip(totalLimit)) {
      excludedTasks.add(
        ExcludedTask(
          task: scored.task,
          reason: _buildExclusionReason(scored),
          exclusionType: ExclusionType.lowPriority,
        ),
      );
    }

    return AllocationResult(
      allocatedTasks: allocatedTasks,
      reasoning: AllocationReasoning(
        strategyUsed: strategyName,
        categoryAllocations: categoryAllocations,
        categoryWeights: categories,
        explanation:
            'Tasks allocated based on neglect balancing '
            '(lookback: ${parameters.neglectLookbackDays} days, '
            'influence: ${(parameters.neglectInfluence * 100).toInt()}%)',
      ),
      excludedTasks: excludedTasks,
    );
  }

  /// Calculate neglect score for each value.
  /// Positive = neglected, Negative = over-represented.
  Map<String, double> _calculateNeglectScores({
    required Map<String, double> categories,
    required Map<String, int> completionsByValue,
    required double totalWeight,
  }) {
    final scores = <String, double>{};

    // Total completions across all values
    final totalCompletions = completionsByValue.values.fold(0, (a, b) => a + b);

    if (totalCompletions == 0) {
      // No history, all scores are 0
      for (final categoryId in categories.keys) {
        scores[categoryId] = 0;
      }
      return scores;
    }

    for (final entry in categories.entries) {
      final categoryId = entry.key;
      final weight = entry.value;

      final actual = completionsByValue[categoryId] ?? 0;
      final expectedShare = weight / totalWeight;
      final expected = totalCompletions * expectedShare;

      // Positive means neglected (expected more than actual)
      scores[categoryId] = expected - actual;
    }

    return scores;
  }

  /// Blend base weights with neglect scores.
  /// Returns multiplier values (centered around 1.0) for each value.
  Map<String, double> _normalizeNeglectScores({
    required Map<String, double> neglectScores,
    required double neglectInfluence,
  }) {
    final multipliers = <String, double>{};

    // Find max absolute neglect score for normalization
    final maxNeglect = neglectScores.values
        .map((s) => s.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);

    if (maxNeglect == 0) {
      // No neglect data, all multipliers = 1.0 (no effect)
      for (final entry in neglectScores.entries) {
        multipliers[entry.key] = 1.0;
      }
      return multipliers;
    }

    for (final entry in neglectScores.entries) {
      // Scale neglect score to -1..+1 range
      final normalizedScore = entry.value / maxNeglect;

      // Convert to multiplier: 1.0 + (score * influence)
      // Neglected (positive score) → multiplier > 1.0
      // Over-represented (negative score) → multiplier < 1.0
      multipliers[entry.key] = 1.0 + (normalizedScore * neglectInfluence);
    }

    return multipliers;
  }

  String _buildExclusionReason(_ScoredTask scored) {
    if (scored.isNeglectedValue) {
      return 'Lower priority despite neglected value';
    }
    return 'Lower priority in balanced allocation';
  }
}

/// Internal helper class for scoring tasks.
class _ScoredTask {
  const _ScoredTask({
    required this.task,
    required this.categoryId,
    required this.score,
    required this.isUrgent,
    required this.isNeglectedValue,
  });

  final Task task;
  final String categoryId;
  final double score;
  final bool isUrgent;
  final bool isNeglectedValue;
}
