import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_alert_evaluator.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_strategy.dart';
import 'package:taskly_bloc/domain/services/allocation/neglect_based_allocator.dart';
import 'package:taskly_bloc/domain/services/allocation/proportional_allocator.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_detector.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_weighted_allocator.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:rxdart/rxdart.dart';

/// Orchestrates task allocation using pinned labels and allocation strategies.
///
/// Now uses settings-based allocation configuration instead of separate
/// database tables. Allocation preferences and value rankings are stored
/// in AppSettings.
class AllocationOrchestrator {
  AllocationOrchestrator({
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required AnalyticsService analyticsService,
    required ProjectRepositoryContract projectRepository,
    AllocationAlertEvaluator? alertEvaluator,
  }) : _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository,
       _alertEvaluator = alertEvaluator ?? const AllocationAlertEvaluator();

  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  final ProjectRepositoryContract _projectRepository;
  final AllocationAlertEvaluator _alertEvaluator;

  /// Watch the full allocation result (pinned + allocated tasks)
  Stream<AllocationResult> watchAllocation() async* {
    talker.debug('[AllocationOrchestrator] watchAllocation started');

    await for (final combined in _combineStreams()) {
      final tasks = combined.$1;
      final projects = combined.$2;
      final allocationConfig = combined.$3;
      final alertSettings = combined.$4;

      talker.debug(
        '[AllocationOrchestrator] Stream update: '
        '${tasks.length} tasks, ${projects.length} projects, dailyLimit=${allocationConfig.dailyLimit}',
      );

      // DEBUG: Log each task's values
      for (final task in tasks) {
        final valueInfo = task.values.map((v) => v.name).join(', ');
        talker.debug(
          '[AllocationOrchestrator] Task "${task.name}" (${task.id.substring(0, 8)}): '
          '${task.values.length} values [${valueInfo.isEmpty ? 'none' : valueInfo}]',
        );
      }

      // Check if user has any values defined
      final values = await _valueRepository.getAll();
      talker.debug(
        '[AllocationOrchestrator] Found ${values.length} values in DB: '
        '${values.map((v) => '${v.name}(${v.id.substring(0, 8)})').join(', ')}',
      );
      if (values.isEmpty) {
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

      // Identify pinned projects
      final pinnedProjectIds = projects
          .where((p) => p.isPinned)
          .map((p) => p.id)
          .toSet();

      // Partition tasks into pinned vs regular
      // A task is pinned if it is explicitly pinned OR its project is pinned
      final pinnedTasks = tasks
          .where(
            (t) =>
                t.isPinned ||
                (t.projectId != null && pinnedProjectIds.contains(t.projectId)),
          )
          .toList();

      final regularTasks = tasks
          .where(
            (t) =>
                !t.isPinned &&
                (t.projectId == null ||
                    !pinnedProjectIds.contains(t.projectId)),
          )
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
        final taskValues = entry.value.values;

        return AllocatedTask(
          task: entry.value,
          qualifyingValueId: taskValues.isNotEmpty
              ? taskValues.first.id
              : 'pinned',
          allocationScore: 10, // Max score for pinned
        );
      }).toList();

      // Allocate regular tasks
      final allocatedRegularTasks = await _allocateRegularTasks(
        regularTasks,
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

      // Evaluate alerts on excluded tasks
      final alertResult = _alertEvaluator.evaluate(
        excludedTasks: allocatedRegularTasks.excludedTasks,
        config: alertSettings.config,
      );

      yield AllocationResult(
        allocatedTasks: allAllocatedTasks,
        reasoning: allocatedRegularTasks.reasoning,
        excludedTasks: allocatedRegularTasks.excludedTasks,
        alertResult: alertResult,
        activePersona: allocationConfig.persona,
      );
    }
  }

  /// Allocate regular (non-pinned) tasks using persona-based strategy.
  ///
  /// For Phase 1, this simplifies to proportional allocation.
  /// Future phases will implement persona-specific logic.
  Future<AllocationResult> _allocateRegularTasks(
    List<Task> tasks,
    AllocationConfig config,
  ) async {
    // Get all values first - needed for both ranking check and allocation
    final values = await _valueRepository.getAll();

    talker.debug(
      '[AllocationOrchestrator] _allocateRegularTasks: '
      '${values.length} values',
    );

    // Build category map - use value priority
    final categories = <String, double>{};

    if (values.isNotEmpty) {
      // Use priority from value
      for (final value in values) {
        categories[value.id] = value.priority.weight.toDouble();
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
          explanation: 'No values or rankings configured',
        ),
        excludedTasks: tasks
            .map(
              (t) => ExcludedTask(
                task: t,
                reason: 'No values or rankings configured',
                exclusionType: ExclusionType.noCategory,
              ),
            )
            .toList(),
      );
    }

    // Filter tasks to only those with values
    final tasksWithValues = tasks.where((t) => t.values.isNotEmpty).toList();

    // DEBUG: Log filtering results
    talker.debug(
      '[AllocationOrchestrator] Filtering for values: '
      '${tasksWithValues.length}/${tasks.length} tasks have values',
    );
    for (final task in tasks) {
      final hasValue = task.values.isNotEmpty;
      talker.debug(
        '[AllocationOrchestrator]   - "${task.name}": hasValue=$hasValue, '
        'valueCount=${task.values.length}, '
        'values=${task.values.map((v) => v.name).join(", ")}',
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
  Stream<
    (
      List<Task>,
      List<Project>,
      AllocationConfig,
      AllocationAlertSettings,
    )
  >
  _combineStreams() {
    // Watch incomplete tasks
    final tasksStream = _taskRepository.watchAll(TaskQuery.incomplete());

    // Watch projects (if repository available)
    final projectsStream = _projectRepository.watchAll();

    // Watch settings
    final allocationConfigStream = _settingsRepository.watch(
      SettingsKey.allocation,
    );
    final alertSettingsStream = _settingsRepository.watch(
      SettingsKey.allocationAlerts,
    );

    // Combine all streams
    return Rx.combineLatest4(
      tasksStream,
      projectsStream,
      allocationConfigStream,
      alertSettingsStream,
      (tasks, projects, allocationConfig, alertSettings) {
        talker.debug(
          '[AllocationOrchestrator] _combineStreams loaded:\n'
          '  allocationConfig.dailyLimit=${allocationConfig.dailyLimit}',
        );

        return (
          tasks,
          projects,
          allocationConfig,
          alertSettings,
        );
      },
    );
  }

  /// Pin a task
  Future<void> pinTask(String taskId) async {
    talker.debug('[AllocationOrchestrator] Pinning task: $taskId');
    await _taskRepository.setPinned(id: taskId, isPinned: true);
  }

  /// Unpin a task
  Future<void> unpinTask(String taskId) async {
    talker.debug('[AllocationOrchestrator] Unpinning task: $taskId');
    await _taskRepository.setPinned(id: taskId, isPinned: false);
  }

  /// Pin a project
  Future<void> pinProject(String projectId) async {
    talker.debug('[AllocationOrchestrator] Pinning project: $projectId');
    await _projectRepository.setPinned(id: projectId, isPinned: true);
  }

  /// Unpin a project
  Future<void> unpinProject(String projectId) async {
    talker.debug('[AllocationOrchestrator] Unpinning project: $projectId');
    await _projectRepository.setPinned(id: projectId, isPinned: false);
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
