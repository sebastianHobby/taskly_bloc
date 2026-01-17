import 'package:taskly_domain/src/allocation/model/focus_mode.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

/// Weights used for scoring tasks based on focus mode.
class ScoringWeights {
  const ScoringWeights({
    this.importance = 1.0,
    this.urgency = 1.0,
    this.synergy = 0.0,
    this.balance = 0.0,
  });

  /// Weight for value alignment/importance.
  final double importance;

  /// Weight for deadline urgency.
  final double urgency;

  /// Weight for value synergy (tasks touching multiple values).
  final double synergy;

  /// Weight for balance (boosting neglected values).
  final double balance;

  @override
  String toString() =>
      'ScoringWeights(importance: $importance, urgency: $urgency, '
      'synergy: $synergy, balance: $balance)';
}

/// Context needed to calculate task scores.
class ScoringContext {
  const ScoringContext({
    required this.categoryWeights,
    required this.todayDayKeyUtc,
    this.completionsByValue = const {},
    this.totalWeight = 1.0,
    this.neglectLookbackDays = 7,
  });

  /// Map of value ID to its weight/priority.
  final Map<String, double> categoryWeights;

  /// Map of value ID to completion count (for balance calculation).
  final Map<String, int> completionsByValue;

  /// Sum of all category weights.
  final double totalWeight;

  /// Today's home-day key (UTC midnight) used for date-only urgency.
  final DateTime todayDayKeyUtc;

  /// Number of days to look back for neglect calculation.
  final int neglectLookbackDays;
}

/// Result of scoring a task.
class TaskScore {
  const TaskScore({
    required this.task,
    required this.totalScore,
    required this.importanceScore,
    required this.urgencyScore,
    this.synergyScore = 0.0,
    this.balanceScore = 0.0,
    this.categoryId,
  });

  final Task task;
  final double totalScore;
  final double importanceScore;
  final double urgencyScore;
  final double synergyScore;
  final double balanceScore;
  final String? categoryId;

  @override
  String toString() =>
      'TaskScore(task: ${task.name}, total: $totalScore, '
      'importance: $importanceScore, urgency: $urgencyScore, '
      'synergy: $synergyScore, balance: $balanceScore)';
}

/// Unified scoring service for task allocation.
///
/// Provides consistent scoring across all allocation strategies.
/// Scores are calculated using a weighted combination of:
/// - Importance: Value alignment/priority
/// - Urgency: Deadline proximity
/// - Synergy: Tasks touching multiple values
/// - Balance: Boosting neglected values
///
/// Focus mode presets determine the weight distribution.
class TaskScoringService {
  const TaskScoringService();

  /// Calculates a unified score for a task based on focus mode and context.
  TaskScore calculateScore(
    Task task,
    FocusMode mode,
    ScoringContext context, {
    ScoringWeights? customWeights,
  }) {
    final weights = customWeights ?? _getWeights(mode);

    final importanceScore = _calculateImportance(task, context);
    final urgencyScore = _calculateUrgency(task, context);
    final synergyScore = _calculateSynergy(task, context);
    final balanceScore = _calculateBalance(task, context);

    final totalScore =
        (weights.importance * importanceScore) +
        (weights.urgency * urgencyScore) +
        (weights.synergy * synergyScore) +
        (weights.balance * balanceScore);

    // Find the primary category for this task
    final categoryId = _findPrimaryCategory(task, context);

    return TaskScore(
      task: task,
      totalScore: totalScore,
      importanceScore: importanceScore,
      urgencyScore: urgencyScore,
      synergyScore: synergyScore,
      balanceScore: balanceScore,
      categoryId: categoryId,
    );
  }

  /// Returns scoring weights for a given focus mode.
  ScoringWeights _getWeights(FocusMode mode) {
    return switch (mode) {
      FocusMode.intentional => const ScoringWeights(
        importance: 2,
        urgency: 0.5,
        synergy: 1,
        balance: 0.5,
      ),
      FocusMode.sustainable => const ScoringWeights(
        importance: 1,
        urgency: 1,
        synergy: 1.5,
        balance: 1.5,
      ),
      FocusMode.responsive => const ScoringWeights(
        importance: 0.5,
        urgency: 3,
        synergy: 0,
        balance: 0,
      ),
      FocusMode.personalized => const ScoringWeights(
        // Personalized mode uses custom weights provided by caller
        importance: 1,
        urgency: 1,
        synergy: 1,
        balance: 1,
      ),
    };
  }

  /// Calculates importance score based on value alignment.
  ///
  /// Returns a score from 0-1 based on the task's primary value weight
  /// relative to total weights.
  double _calculateImportance(Task task, ScoringContext context) {
    if (context.totalWeight == 0) return 0;

    // Use primary value if set, otherwise highest weighted value
    final valueIds = task.effectiveValues.map((v) => v.id).toSet();
    if (valueIds.isEmpty) return 0;

    // Find best matching category weight
    double maxWeight = 0;
    for (final valueId in valueIds) {
      final weight = context.categoryWeights[valueId] ?? 0;
      if (weight > maxWeight) {
        maxWeight = weight;
      }
    }

    return maxWeight / context.totalWeight;
  }

  /// Calculates urgency score using smooth decay curve.
  ///
  /// Formula: 1 / (1 + days/7)
  /// - Day 0 = 1.0
  /// - Day 7 = 0.5
  /// - Day 14 = 0.33
  /// - Day 21 = 0.25
  ///
  /// Returns 1.0 for overdue tasks, 0.0 for tasks with no deadline.
  double _calculateUrgency(Task task, ScoringContext context) {
    if (task.deadlineDate == null) return 0;

    final daysUntilDeadline = task.deadlineDate!
        .difference(context.todayDayKeyUtc)
        .inDays;

    if (daysUntilDeadline < 0) {
      // Overdue: clamp at 1.0
      return 1;
    }

    // Smooth decay: 1 / (1 + days/7)
    return 1.0 / (1.0 + daysUntilDeadline / 7.0);
  }

  /// Calculates synergy score based on value overlap.
  ///
  /// Tasks with more values score higher (cross-cutting impact).
  double _calculateSynergy(Task task, ScoringContext context) {
    final valueCount = task.effectiveValues.length;
    if (valueCount <= 1) return 0;

    // Normalize: 2 effective values = 0.5, 3 effective values = 0.67, 4 effective values = 0.75, etc.
    return 1 - (1 / valueCount);
  }

  /// Calculates balance score based on value neglect.
  ///
  /// Tasks in neglected value categories score higher.
  double _calculateBalance(Task task, ScoringContext context) {
    if (context.completionsByValue.isEmpty) return 0;

    final valueIds = task.effectiveValues.map((v) => v.id).toSet();
    if (valueIds.isEmpty) return 0;

    // Calculate total completions
    final totalCompletions = context.completionsByValue.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (totalCompletions == 0) return 0.5; // No completions = moderate boost

    // Find average neglect for task's values
    double totalNeglect = 0;
    int matchedValues = 0;

    for (final valueId in valueIds) {
      final completions = context.completionsByValue[valueId] ?? 0;
      final expectedShare =
          (context.categoryWeights[valueId] ?? 0) /
          (context.totalWeight > 0 ? context.totalWeight : 1);
      final actualShare = completions / totalCompletions;

      // Neglect = expected - actual (positive = neglected)
      final neglect = (expectedShare - actualShare).clamp(0.0, 1.0);
      totalNeglect += neglect;
      matchedValues++;
    }

    if (matchedValues == 0) return 0;
    return totalNeglect / matchedValues;
  }

  /// Finds the primary category (value) for the task.
  String? _findPrimaryCategory(Task task, ScoringContext context) {
    // Use effective primary (override wins; else project primary)
    final effectivePrimaryId = task.effectivePrimaryValueId;
    if (effectivePrimaryId != null) return effectivePrimaryId;

    // Otherwise find highest weighted matching value
    final valueIds = task.effectiveValues.map((v) => v.id).toSet();
    String? bestCategory;
    double bestWeight = -1;

    for (final valueId in valueIds) {
      final weight = context.categoryWeights[valueId] ?? 0;
      if (weight > bestWeight) {
        bestWeight = weight;
        bestCategory = valueId;
      }
    }

    return bestCategory;
  }

  /// Scores multiple tasks and returns them sorted by score (descending).
  List<TaskScore> scoreAndRank(
    List<Task> tasks,
    FocusMode mode,
    ScoringContext context, {
    ScoringWeights? customWeights,
  }) {
    final scores = tasks
        .map(
          (task) =>
              calculateScore(task, mode, context, customWeights: customWeights),
        )
        .toList();

    scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scores;
  }
}
