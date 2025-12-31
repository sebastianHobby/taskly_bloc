import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_preference.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/priority_rankings_repository_contract.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';
import 'package:taskly_bloc/domain/services/allocation/proportional_allocator.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_weighted_allocator.dart';

/// Orchestrates task allocation using pinned labels and allocation strategies
class AllocationOrchestrator {
  AllocationOrchestrator({
    required TaskRepositoryContract taskRepository,
    required LabelRepositoryContract labelRepository,
    required PriorityRankingsRepositoryContract rankingsRepository,
    required AllocationPreferencesRepositoryContract preferencesRepository,
  }) : _taskRepository = taskRepository,
       _labelRepository = labelRepository,
       _rankingsRepository = rankingsRepository,
       _preferencesRepository = preferencesRepository;

  final TaskRepositoryContract _taskRepository;
  final LabelRepositoryContract _labelRepository;
  final PriorityRankingsRepositoryContract _rankingsRepository;
  final AllocationPreferencesRepositoryContract _preferencesRepository;

  /// Watch the full allocation result (pinned + allocated tasks)
  Stream<AllocationResult> watchAllocation() async* {
    await for (final combined in _combineStreams()) {
      final tasks = combined.$1;
      final pinnedLabel = combined.$2;
      final ranking = combined.$3;
      final preferences = combined.$4;

      if (preferences == null) {
        // No preferences set - return empty result
        yield AllocationResult(
          allocatedTasks: const [],
          reasoning: AllocationReasoning(
            strategyUsed: 'none',
            categoryAllocations: const {},
            categoryWeights: const {},
            explanation: 'No allocation preferences configured',
          ),
          excludedTasks: const [],
        );
        continue;
      }

      // Partition tasks into pinned vs regular
      final pinnedTasks = tasks
          .where((t) => t.labels.any((l) => l.id == pinnedLabel?.id))
          .toList();

      final regularTasks = tasks
          .where((t) => !t.labels.any((l) => l.id == pinnedLabel?.id))
          .toList();

      // Sort pinned tasks by deadline (urgent first)
      pinnedTasks.sort((a, b) {
        if (a.deadlineDate == null && b.deadlineDate == null) return 0;
        if (a.deadlineDate == null) return 1;
        if (b.deadlineDate == null) return -1;
        return a.deadlineDate!.compareTo(b.deadlineDate!);
      });

      // Convert pinned tasks to AllocatedTask format
      final allocatedPinnedTasks = pinnedTasks.asMap().entries.map((entry) {
        final valueLabels = entry.value.labels
            .where((l) => l.type == LabelType.value)
            .toList();

        return AllocatedTask(
          task: entry.value,
          qualifyingValueId: valueLabels.isNotEmpty
              ? valueLabels.first.id
              : 'pinned',
          allocationScore: 10, // Max score for pinned
        );
      }).toList();

      // Allocate regular tasks
      final allocatedRegularTasks = await _allocateRegularTasks(
        regularTasks,
        ranking,
        preferences,
      );

      // Combine results
      final allAllocatedTasks = [
        ...allocatedPinnedTasks,
        ...allocatedRegularTasks.allocatedTasks,
      ];

      // Generate warnings
      final warnings = <AllocationWarning>[];

      // Check for excluded urgent tasks
      final excludedUrgent = allocatedRegularTasks.excludedTasks.where((et) {
        if (et.task.deadlineDate == null) return false;
        final daysUntilDeadline = et.task.deadlineDate!
            .difference(DateTime.now())
            .inDays;
        return daysUntilDeadline <= preferences.urgencyThresholdDays;
      }).toList();

      if (excludedUrgent.isNotEmpty && preferences.showExcludedUrgentWarning) {
        warnings.add(
          AllocationWarning(
            type: WarningType.excludedUrgentTask,
            message:
                '${excludedUrgent.length} urgent task(s) excluded from focus list',
            suggestedAction:
                'Review and consider pinning or adjusting priorities',
            affectedTaskIds: excludedUrgent.map((et) => et.task.id).toList(),
          ),
        );
      }

      yield AllocationResult(
        allocatedTasks: allAllocatedTasks,
        reasoning: allocatedRegularTasks.reasoning,
        excludedTasks: allocatedRegularTasks.excludedTasks,
        warnings: warnings,
      );
    }
  }

  /// Allocate regular (non-pinned) tasks using the selected strategy
  Future<AllocationResult> _allocateRegularTasks(
    List<Task> tasks,
    PriorityRanking? ranking,
    AllocationPreference preferences,
  ) async {
    if (ranking == null || ranking.items.isEmpty) {
      // No ranking - all tasks excluded
      return AllocationResult(
        allocatedTasks: const [],
        reasoning: AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: const {},
          categoryWeights: const {},
          explanation: 'No value rankings configured',
        ),
        excludedTasks: tasks
            .map(
              (t) => ExcludedTask(
                task: t,
                reason: 'No value rankings configured',
                exclusionType: ExclusionType.noCategory,
              ),
            )
            .toList(),
      );
    }

    // Get all value labels
    final valueLabels = await _labelRepository.getAllByType(LabelType.value);
    final valueLabelMap = {for (final l in valueLabels) l.id: l};

    // Filter tasks to only those with values
    final tasksWithValues = tasks
        .where((t) => t.labels.any((l) => l.type == LabelType.value))
        .toList();

    // Create allocation strategy
    final strategy = _createStrategy(preferences.strategyType);

    // Build category map from ranking
    final categories = <String, double>{};
    for (final item in ranking.items) {
      if (valueLabelMap.containsKey(item.entityId)) {
        categories[item.entityId] = item.weight.toDouble();
      }
    }

    // Run allocation
    final parameters = AllocationParameters(
      tasks: tasksWithValues,
      categories: categories,
      maxTasks: preferences.dailyTaskLimit,
      urgencyInfluence: preferences.urgencyInfluence,
      urgencyThresholdDays: preferences.urgencyThresholdDays,
    );

    return strategy.allocate(parameters);
  }

  /// Create allocation strategy based on type
  AllocationStrategy _createStrategy(AllocationStrategyType type) {
    return switch (type) {
      AllocationStrategyType.proportional => ProportionalAllocator(),
      AllocationStrategyType.urgencyWeighted => UrgencyWeightedAllocator(),
      // Future strategies - currently defaulting to proportional in UI
      AllocationStrategyType.roundRobin ||
      AllocationStrategyType.minimumViable ||
      AllocationStrategyType.dynamic ||
      AllocationStrategyType.topCategories => throw UnimplementedError(
        'Strategy $type not yet implemented',
      ),
    };
  }

  /// Combine all necessary streams
  Stream<(List<Task>, Label?, PriorityRanking?, AllocationPreference?)>
  _combineStreams() async* {
    // Watch incomplete tasks
    final tasksStream = _taskRepository.watchAll();

    // Combine all streams
    await for (final tasks in tasksStream) {
      final pinnedLabel = await _labelRepository.getSystemLabel(
        SystemLabelType.pinned,
      );
      // Get latest ranking value from stream
      final ranking = await _rankingsRepository
          .watchRankingByType(RankingType.value)
          .first;
      final preferences = await _preferencesRepository.getPreferences();

      yield (tasks, pinnedLabel, ranking, preferences);
    }
  }

  /// Pin a task
  Future<void> pinTask(String taskId) async {
    final pinnedLabel = await _labelRepository.getOrCreateSystemLabel(
      SystemLabelType.pinned,
    );
    await _labelRepository.addLabelToTask(
      taskId: taskId,
      labelId: pinnedLabel.id,
    );
  }

  /// Unpin a task
  Future<void> unpinTask(String taskId) async {
    final pinnedLabel = await _labelRepository.getSystemLabel(
      SystemLabelType.pinned,
    );
    if (pinnedLabel == null) return;

    await _labelRepository.removeLabelFromTask(
      taskId: taskId,
      labelId: pinnedLabel.id,
    );
  }

  /// Toggle task completion state
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = await _taskRepository.getById(taskId);
    if (task == null) return;

    await _taskRepository.update(
      id: task.id,
      name: task.name,
      description: task.description,
      completed: !task.completed,
      startDate: task.startDate,
      deadlineDate: task.deadlineDate,
      projectId: task.projectId,
      repeatIcalRrule: task.repeatIcalRrule,
    );
  }
}
