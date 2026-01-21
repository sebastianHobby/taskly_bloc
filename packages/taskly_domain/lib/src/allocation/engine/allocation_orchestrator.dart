import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/settings_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/settings/settings.dart';
import 'package:taskly_domain/src/preferences/model/settings_key.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/engine/suggested_picks_engine.dart';
import 'package:taskly_domain/src/allocation/engine/urgency_detector.dart';
import 'package:taskly_domain/src/services/analytics/analytics_service.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

/// Orchestrates task allocation using pinned labels and allocation strategies.
///
/// Now uses settings-based allocation configuration instead of separate
/// database tables. Allocation preferences and value rankings are stored
/// in user profile settings overrides.
class AllocationOrchestrator {
  AllocationOrchestrator({
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required AnalyticsService analyticsService,
    required ProjectRepositoryContract projectRepository,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
  }) : _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository,
       _dayKeyService = dayKeyService,
       _clock = clock;

  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  final ProjectRepositoryContract _projectRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;

  /// Compute a single allocation snapshot (pinned + allocated tasks).
  ///
  /// This intentionally does **not** keep a live stream subscription.
  /// Callers should re-trigger this explicitly (e.g. on ritual open, day
  /// boundary, or app resume).
  Future<AllocationResult> getAllocationSnapshot({
    DateTime? nowUtc,
    int? maxTasksOverride,
  }) async {
    final resolvedNowUtc = nowUtc ?? _clock.nowUtc();
    final todayUtc = _dayKeyService.todayDayKeyUtc(nowUtc: resolvedNowUtc);

    AppLog.routine(
      'domain.allocation',
      'getAllocationSnapshot: nowUtc=${resolvedNowUtc.toIso8601String()} '
          'todayUtc=${todayUtc.toIso8601String()}',
    );

    final results = await Future.wait([
      _taskRepository.getAll(TaskQuery.incomplete()),
      _projectRepository.getAll(),
      _settingsRepository.load(SettingsKey.allocation),
    ]);

    final tasks = results[0] as List<Task>;
    final projects = results[1] as List<Project>;
    final allocationConfig = results[2] as AllocationConfig;

    return _computeAllocation(
      tasks: tasks,
      projects: projects,
      allocationConfig: allocationConfig,
      nowUtc: resolvedNowUtc,
      todayDayKeyUtc: todayUtc,
      maxTasksOverride: maxTasksOverride,
    );
  }

  Future<AllocationResult> _computeAllocation({
    required List<Task> tasks,
    required List<Project> projects,
    required AllocationConfig allocationConfig,
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
    int? maxTasksOverride,
  }) async {
    final maxTasks = maxTasksOverride ?? allocationConfig.suggestionsPerBatch;

    AppLog.routine(
      'domain.allocation',
      'Compute: ${tasks.length} tasks, ${projects.length} projects, '
          'maxTasks=$maxTasks',
    );

    // Ensure values exist (soft-gate).
    final values = await _valueRepository.getAll();
    AppLog.routineThrottled(
      'allocation.values_count',
      const Duration(seconds: 30),
      'domain.allocation',
      'Found ${values.length} values in DB',
    );
    if (values.isEmpty) {
      return AllocationResult(
        allocatedTasks: const [],
        reasoning: const AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'No values defined',
        ),
        excludedTasks: const [],
        requiresValueSetup: true,
      );
    }

    if (maxTasks <= 0) {
      return AllocationResult(
        allocatedTasks: const [],
        reasoning: const AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'No allocation preferences configured',
        ),
        excludedTasks: const [],
      );
    }

    // Identify pinned projects.
    final pinnedProjectIds = projects
        .where((p) => p.isPinned)
        .map((p) => p.id)
        .toSet();

    // Partition tasks into pinned vs regular.
    // A task is pinned if it is explicitly pinned OR its project is pinned.
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
              (t.projectId == null || !pinnedProjectIds.contains(t.projectId)),
        )
        .toList();

    final pinnedAllocatedTasks = pinnedTasks
        .map(
          (t) => AllocatedTask(
            task: t,
            qualifyingValueId: 'pinned',
            allocationScore: 0,
          ),
        )
        .toList();

    final allocatedRegularTasks = await allocateRegularTasks(
      regularTasks,
      allocationConfig,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
      maxTasksOverride: maxTasksOverride,
    );

    final allAllocatedTasks = [
      ...pinnedAllocatedTasks,
      ...allocatedRegularTasks.allocatedTasks,
    ];

    // Best-effort logging: urgent valueless tasks are a key signal for UX.
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);
    final urgentValueless = urgencyDetector.findUrgentValuelessTasks(
      regularTasks,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    if (urgentValueless.isNotEmpty) {
      talker.debug(
        '[AllocationOrchestrator] urgent valueless tasks: '
        '${urgentValueless.length}',
      );
    }

    return AllocationResult(
      allocatedTasks: allAllocatedTasks,
      reasoning: allocatedRegularTasks.reasoning,
      excludedTasks: allocatedRegularTasks.excludedTasks,
      activeFocusMode: allocationConfig.focusMode,
    );
  }

  /// Allocate regular (non-pinned) tasks using the configured strategy.
  ///
  /// Regular allocation uses a single engine: [SuggestedPicksEngine].
  Future<AllocationResult> allocateRegularTasks(
    List<Task> tasks,
    AllocationConfig config, {
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
    int? maxTasksOverride,
  }) async {
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

    // DEBUG: Log task/value distribution.
    final tasksWithValuesCount = tasks.where((t) => t.values.isNotEmpty).length;
    talker.debug(
      '[AllocationOrchestrator] Task value distribution: '
      '$tasksWithValuesCount/${tasks.length} tasks have values',
    );

    final engine = SuggestedPicksEngine();

    talker.debug(
      '[AllocationOrchestrator] Using ${engine.strategyName}, '
      '$tasksWithValuesCount/${tasks.length} tasks have values, '
      '${categories.length} categories',
    );

    // Fetch recent completions by value if value balancing is enabled.
    final settings = config.strategySettings;
    Map<String, int> completionsByValue = const {};
    if (settings.enableNeglectWeighting) {
      completionsByValue = await _analyticsService.getRecentCompletionsByValue(
        days: 14,
      );

      final totalCompletions = completionsByValue.values.fold<int>(
        0,
        (sum, v) => sum + v,
      );
      if (totalCompletions <= 0) {
        completionsByValue = const {};
      }
    }

    // Run allocation
    final maxTasks = maxTasksOverride ?? config.suggestionsPerBatch;

    final parameters = AllocationParameters(
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
      tasks: tasks,
      categories: categories,
      maxTasks: maxTasks,
      taskUrgencyThresholdDays: settings.taskUrgencyThresholdDays,
      keepValuesInBalance:
          settings.enableNeglectWeighting && completionsByValue.isNotEmpty,
      completionsByValue: completionsByValue,
    );

    return engine.allocate(parameters);
  }

  /// Pin a task
  Future<void> pinTask(String taskId, {OperationContext? context}) async {
    talker.debug('[AllocationOrchestrator] Pinning task: $taskId');
    await _taskRepository.setPinned(
      id: taskId,
      isPinned: true,
      context: context,
    );
  }

  /// Unpin a task
  Future<void> unpinTask(String taskId, {OperationContext? context}) async {
    talker.debug('[AllocationOrchestrator] Unpinning task: $taskId');
    await _taskRepository.setPinned(
      id: taskId,
      isPinned: false,
      context: context,
    );
  }

  /// Pin a project
  Future<void> pinProject(String projectId, {OperationContext? context}) async {
    talker.debug('[AllocationOrchestrator] Pinning project: $projectId');
    await _projectRepository.setPinned(
      id: projectId,
      isPinned: true,
      context: context,
    );
  }

  /// Unpin a project
  Future<void> unpinProject(
    String projectId, {
    OperationContext? context,
  }) async {
    talker.debug('[AllocationOrchestrator] Unpinning project: $projectId');
    await _projectRepository.setPinned(
      id: projectId,
      isPinned: false,
      context: context,
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
