import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';
import 'package:taskly_bloc/domain/services/allocation/neglect_based_allocator.dart';
import 'package:taskly_bloc/domain/services/allocation/proportional_allocator.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_detector.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_weighted_allocator.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';

/// Orchestrates task allocation using pinned labels and allocation strategies.
///
/// Now uses settings-based allocation configuration instead of separate
/// database tables. Allocation preferences and value rankings are stored
/// in AppSettings.
class AllocationOrchestrator {
  AllocationOrchestrator({
    required TaskRepositoryContract taskRepository,
    required LabelRepositoryContract labelRepository,
    required SettingsRepositoryContract settingsRepository,
    required AnalyticsService analyticsService,
    ProjectRepositoryContract? projectRepository, // Reserved for future use
  }) : _taskRepository = taskRepository,
       _labelRepository = labelRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final LabelRepositoryContract _labelRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  // ignore: unused_field
  final ProjectRepositoryContract? _projectRepository;

  /// Watch the full allocation result (pinned + allocated tasks)
  Stream<AllocationResult> watchAllocation() async* {
    talker.debug('[AllocationOrchestrator] watchAllocation started');

    await for (final combined in _combineStreams()) {
      final tasks = combined.$1;
      final pinnedLabel = combined.$2;
      final allocationConfig = combined.$3;
      final valueRanking = combined.$4;

      talker.debug(
        '[AllocationOrchestrator] Stream update: '
        '${tasks.length} tasks, dailyLimit=${allocationConfig.dailyLimit}',
      );

      // DEBUG: Log each task's labels
      for (final task in tasks) {
        final labelInfo = task.labels
            .map((l) => '${l.name}(${l.type.name})')
            .join(', ');
        talker.debug(
          '[AllocationOrchestrator] Task "${task.name}" (${task.id.substring(0, 8)}): '
          '${task.labels.length} labels [${labelInfo.isEmpty ? 'none' : labelInfo}]',
        );
      }

      // Check if user has any values defined
      final valueLabels = await _labelRepository.getAllByType(LabelType.value);
      talker.debug(
        '[AllocationOrchestrator] Found ${valueLabels.length} value labels in DB: '
        '${valueLabels.map((l) => '${l.name}(${l.id.substring(0, 8)})').join(', ')}',
      );
      if (valueLabels.isEmpty) {
        talker.debug(
          '[AllocationOrchestrator] No values defined - setup required',
        );
        // No values defined - require setup
        yield AllocationResult(
          allocatedTasks: const [],
          reasoning: AllocationReasoning(
            strategyUsed: 'none',
            categoryAllocations: const {},
            categoryWeights: const {},
            explanation: 'No values defined',
          ),
          excludedTasks: const [],
          requiresValueSetup: true,
        );
        continue;
      }

      if (allocationConfig.dailyLimit == 0) {
        talker.debug(
          '[AllocationOrchestrator] Daily limit is 0 - no allocation',
        );
        // No allocation configured - return empty result
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

      talker.debug(
        '[AllocationOrchestrator] Partitioned: '
        '${pinnedTasks.length} pinned, ${regularTasks.length} regular',
      );

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
        valueRanking,
        allocationConfig,
      );

      // Combine results
      final allAllocatedTasks = [
        ...allocatedPinnedTasks,
        ...allocatedRegularTasks.allocatedTasks,
      ];

      // Create urgency detector from config
      final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);
      final urgentBehavior =
          allocationConfig.strategySettings.urgentTaskBehavior;

      // Find urgent value-less tasks from regular tasks (not pinned)
      final urgentValuelessTasks = urgencyDetector.findUrgentValuelessTasks(
        regularTasks,
      );

      // Handle urgent value-less tasks based on behavior
      switch (urgentBehavior) {
        case UrgentTaskBehavior.ignore:
        case UrgentTaskBehavior.warnOnly:
          // Do nothing - urgent tasks without values are excluded
          // Problem detection is handled by ProblemDetectorService
          if (urgentValuelessTasks.isNotEmpty) {
            talker.debug(
              '[AllocationOrchestrator] ${urgentValuelessTasks.length} urgent '
              'value-less tasks (behavior: $urgentBehavior)',
            );
          }
        case UrgentTaskBehavior.includeAll:
          // Add urgent value-less tasks to allocated list with override flag
          for (final task in urgentValuelessTasks) {
            // Don't add if already allocated (shouldn't happen, but safety)
            if (allAllocatedTasks.any((at) => at.task.id == task.id)) continue;

            allAllocatedTasks.add(
              AllocatedTask(
                task: task,
                qualifyingValueId: 'urgent-override',
                allocationScore: 10, // High score for urgent override
                isUrgentOverride: true,
              ),
            );
          }
          if (urgentValuelessTasks.isNotEmpty) {
            talker.debug(
              '[AllocationOrchestrator] Added ${urgentValuelessTasks.length} '
              'urgent value-less tasks via override',
            );
          }
      }

      talker.debug(
        '[AllocationOrchestrator] Final result: '
        '${allAllocatedTasks.length} allocated, '
        '${allocatedRegularTasks.excludedTasks.length} excluded',
      );

      yield AllocationResult(
        allocatedTasks: allAllocatedTasks,
        reasoning: allocatedRegularTasks.reasoning,
        excludedTasks: allocatedRegularTasks.excludedTasks,
      );
    }
  }

  /// Allocate regular (non-pinned) tasks using persona-based strategy.
  ///
  /// For Phase 1, this simplifies to proportional allocation.
  /// Future phases will implement persona-specific logic.
  Future<AllocationResult> _allocateRegularTasks(
    List<Task> tasks,
    ValueRanking valueRanking,
    AllocationConfig config,
  ) async {
    // Get all value labels first - needed for both ranking check and allocation
    final valueLabels = await _labelRepository.getAllByType(LabelType.value);
    final valueLabelMap = {for (final l in valueLabels) l.id: l};

    talker.debug(
      '[AllocationOrchestrator] _allocateRegularTasks: '
      '${valueRanking.items.length} ranking items, '
      '${valueLabels.length} value labels',
    );

    // Build category map - use ranking if available, otherwise use all values
    // with equal weight
    final categories = <String, double>{};

    if (valueRanking.items.isNotEmpty) {
      // Use explicit ranking
      for (final item in valueRanking.items) {
        if (valueLabelMap.containsKey(item.labelId)) {
          categories[item.labelId] = item.weight.toDouble();
        }
      }
    } else if (valueLabels.isNotEmpty) {
      // No ranking configured - use all values with equal weight (default: 5)
      talker.debug(
        '[AllocationOrchestrator] No ranking configured, using all '
        '${valueLabels.length} values with equal weight',
      );
      for (final label in valueLabels) {
        categories[label.id] = 5.0; // Default weight
      }
    }

    // If still no categories, exclude all tasks
    if (categories.isEmpty) {
      talker.debug('[AllocationOrchestrator] No categories available');
      return AllocationResult(
        allocatedTasks: const [],
        reasoning: AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: const {},
          categoryWeights: const {},
          explanation: 'No value labels or rankings configured',
        ),
        excludedTasks: tasks
            .map(
              (t) => ExcludedTask(
                task: t,
                reason: 'No value labels or rankings configured',
                exclusionType: ExclusionType.noCategory,
              ),
            )
            .toList(),
      );
    }

    // Filter tasks to only those with values
    final tasksWithValues = tasks
        .where((t) => t.labels.any((l) => l.type == LabelType.value))
        .toList();

    // DEBUG: Log filtering results
    talker.debug(
      '[AllocationOrchestrator] Filtering for value labels: '
      '${tasksWithValues.length}/${tasks.length} tasks have value labels',
    );
    for (final task in tasks) {
      final hasValue = task.labels.any((l) => l.type == LabelType.value);
      final valueLabelsOnTask = task.labels
          .where((l) => l.type == LabelType.value)
          .toList();
      talker.debug(
        '[AllocationOrchestrator]   - "${task.name}": hasValue=$hasValue, '
        'labelCount=${task.labels.length}, '
        'valueLabels=${valueLabelsOnTask.map((l) => l.name).join(", ")}',
      );
    }

    // Create allocation strategy based on persona
    final strategy = _createStrategyForPersona(config);

    talker.debug(
      '[AllocationOrchestrator] Using ${strategy.strategyName} strategy, '
      '${tasksWithValues.length}/${tasks.length} tasks have values, '
      '${categories.length} categories',
    );

    // Fetch recent completions by value if neglect weighting is enabled
    final settings = config.strategySettings;
    Map<String, int> completionsByValue = const {};
    if (settings.enableNeglectWeighting) {
      completionsByValue = await _analyticsService.getRecentCompletionsByValue(
        days: settings.neglectLookbackDays,
      );
    }

    // Run allocation
    final parameters = AllocationParameters(
      tasks: tasksWithValues,
      categories: categories,
      maxTasks: config.dailyLimit,
      urgencyInfluence: settings.urgencyBoostMultiplier - 1.0,
      urgentTaskBehavior: settings.urgentTaskBehavior,
      taskUrgencyThresholdDays: settings.taskUrgencyThresholdDays,
      urgencyBoostMultiplier: settings.urgencyBoostMultiplier,
      neglectLookbackDays: settings.neglectLookbackDays,
      neglectInfluence: settings.neglectInfluence,
      completionsByValue: completionsByValue,
    );

    return strategy.allocate(parameters);
  }

  /// Create allocation strategy based on persona configuration.
  ///
  /// Selects appropriate allocator based on enabled features:
  /// - NeglectBasedAllocator when enableNeglectWeighting is true (Reflector)
  /// - UrgencyWeightedAllocator when urgency boost > 1.0 (Firefighter/Realist)
  /// - ProportionalAllocator as default (Idealist)
  AllocationStrategy _createStrategyForPersona(AllocationConfig config) {
    final settings = config.strategySettings;

    // Check for neglect weighting first (enables combo mode in Custom)
    if (settings.enableNeglectWeighting) {
      return NeglectBasedAllocator();
    }

    // If urgency boost > 1.0, use urgency-weighted allocator
    if (settings.urgencyBoostMultiplier > 1.0) {
      return UrgencyWeightedAllocator();
    }

    // Default to proportional allocation
    return ProportionalAllocator();
  }

  /// Combine all necessary streams
  Stream<(List<Task>, Label?, AllocationConfig, ValueRanking)>
  _combineStreams() async* {
    // Watch incomplete tasks
    final tasksStream = _taskRepository.watchAll(TaskQuery.incomplete());

    // Combine all streams
    await for (final tasks in tasksStream) {
      final pinnedLabel = await _labelRepository.getSystemLabel(
        SystemLabelType.pinned,
      );
      final allocationConfig = await _settingsRepository.load(
        SettingsKey.allocation,
      );
      final valueRanking = await _settingsRepository.load(
        SettingsKey.valueRanking,
      );

      final rankingStr = valueRanking.items
          .map((i) => '${i.labelId.substring(0, 8)}:w${i.weight}')
          .join(', ');
      talker.debug(
        '[AllocationOrchestrator] _combineStreams loaded:\n'
        '  allocationConfig.dailyLimit=${allocationConfig.dailyLimit}\n'
        '  valueRanking.items.length=${valueRanking.items.length}\n'
        '  valueRanking.items=[$rankingStr]',
      );

      yield (tasks, pinnedLabel, allocationConfig, valueRanking);
    }
  }

  /// Pin a task
  Future<void> pinTask(String taskId) async {
    talker.debug('[AllocationOrchestrator] Pinning task: $taskId');
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
    talker.debug('[AllocationOrchestrator] Unpinning task: $taskId');
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
    talker.debug('[AllocationOrchestrator] Toggling completion: $taskId');
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
