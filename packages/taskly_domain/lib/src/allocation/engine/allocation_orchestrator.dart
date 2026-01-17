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
import 'package:taskly_domain/src/allocation/engine/neglect_based_allocator.dart';
import 'package:taskly_domain/src/allocation/engine/proportional_allocator.dart';
import 'package:taskly_domain/src/allocation/engine/urgency_detector.dart';
import 'package:taskly_domain/src/allocation/engine/urgency_weighted_allocator.dart';
import 'package:taskly_domain/src/services/analytics/analytics_service.dart';
import 'package:taskly_domain/src/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_domain/src/allocation/model/allocation_snapshot.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

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
    AllocationSnapshotRepositoryContract? allocationSnapshotRepository,
  }) : _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository,
       _dayKeyService = dayKeyService,
       _clock = clock,
       _allocationSnapshotRepository = allocationSnapshotRepository;

  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  final ProjectRepositoryContract _projectRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;
  final AllocationSnapshotRepositoryContract? _allocationSnapshotRepository;

  /// Watch the full allocation result (pinned + allocated tasks)
  Stream<AllocationResult> watchAllocation() {
    AppLog.routine('domain.allocation', 'watchAllocation started');

    // Latest snapshot wins: cancel in-flight computations when inputs change.
    return combineStreams()
        .switchMap(
          (combined) => Stream.fromFuture(_computeAllocation(combined)),
        )
        .asyncMap((computed) async {
          // Persist a stable daily snapshot of allocation membership.
          // IMPORTANT: App code does not filter on `user_id`; RLS + PowerSync buckets
          // handle scoping.
          final repo = _allocationSnapshotRepository;
          if (repo != null && !computed.result.requiresValueSetup) {
            final allocated = computed.result.allocatedTasks
                .map(
                  (a) => AllocationSnapshotEntryInput(
                    entity: AllocationEntityRef(
                      type: AllocationSnapshotEntityType.task,
                      id: a.task.id,
                    ),
                    projectId: a.task.projectId,
                    qualifyingValueId: a.qualifyingValueId,
                    effectivePrimaryValueId: a.task.effectivePrimaryValueId,
                    allocationScore: a.allocationScore,
                  ),
                )
                .toList();

            await repo.persistAllocatedForUtcDay(
              dayUtc: computed.dayUtc,
              capAtGeneration: computed.capAtGeneration,
              candidatePoolCountAtGeneration:
                  computed.candidatePoolCountAtGeneration,
              allocated: allocated,
            );
          }

          return computed.result;
        });
  }

  Future<
    ({
      AllocationResult result,
      DateTime dayUtc,
      int capAtGeneration,
      int candidatePoolCountAtGeneration,
    })
  >
  _computeAllocation(
    (List<Task>, List<Project>, AllocationConfig) combined,
  ) async {
    final tasks = combined.$1;
    final projects = combined.$2;
    final allocationConfig = combined.$3;

    final nowUtc = _clock.nowUtc();
    final todayUtc = _dayKeyService.todayDayKeyUtc(nowUtc: nowUtc);

    AppLog.routineThrottled(
      'allocation.stream_update',
      const Duration(seconds: 10),
      'domain.allocation',
      'Stream update: ${tasks.length} tasks, ${projects.length} projects, '
          'dailyLimit=${allocationConfig.dailyLimit}',
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
      return (
        result: AllocationResult(
          allocatedTasks: const [],
          reasoning: const AllocationReasoning(
            strategyUsed: 'none',
            categoryAllocations: {},
            categoryWeights: {},
            explanation: 'No values defined',
          ),
          excludedTasks: const [],
          requiresValueSetup: true,
        ),
        dayUtc: todayUtc,
        capAtGeneration: allocationConfig.dailyLimit,
        candidatePoolCountAtGeneration: 0,
      );
    }

    if (allocationConfig.dailyLimit == 0) {
      return (
        result: AllocationResult(
          allocatedTasks: const [],
          reasoning: const AllocationReasoning(
            strategyUsed: 'none',
            categoryAllocations: {},
            categoryWeights: {},
            explanation: 'No allocation preferences configured',
          ),
          excludedTasks: const [],
        ),
        dayUtc: todayUtc,
        capAtGeneration: allocationConfig.dailyLimit,
        candidatePoolCountAtGeneration: 0,
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
      todayDayKeyUtc: todayUtc,
    );

    final candidatePoolCountNow =
        allocatedRegularTasks.allocatedTasks.length +
        allocatedRegularTasks.excludedTasks.length;

    final snapshotRepo = _allocationSnapshotRepository;
    final latestSnapshot = snapshotRepo == null
        ? null
        : await snapshotRepo.getLatestForUtcDay(todayUtc);

    // Once a day has been generated, keep cap/pool stable across versions so the
    // 'top-up allowed' decision never flips due to mid-day completions.
    final capAtGeneration =
        latestSnapshot?.capAtGeneration ?? allocationConfig.dailyLimit;
    final candidatePoolCountAtGeneration =
        latestSnapshot?.candidatePoolCountAtGeneration ?? candidatePoolCountNow;

    final stabilizedRegular = _stabilizeRegularAllocation(
      todayUtc: todayUtc,
      capAtGeneration: capAtGeneration,
      candidatePoolCountAtGeneration: candidatePoolCountAtGeneration,
      latestSnapshot: latestSnapshot,
      regularTasks: regularTasks,
      allocatedRegularTasks: allocatedRegularTasks.allocatedTasks,
    );

    final allAllocatedTasks = [...pinnedAllocatedTasks, ...stabilizedRegular];

    // Best-effort logging: urgent valueless tasks are a key signal for UX.
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);
    final urgentValueless = urgencyDetector.findUrgentValuelessTasks(
      regularTasks,
      todayDayKeyUtc: todayUtc,
    );
    if (urgentValueless.isNotEmpty) {
      talker.debug(
        '[AllocationOrchestrator] urgent valueless tasks: '
        '${urgentValueless.length}',
      );
    }

    return (
      result: AllocationResult(
        allocatedTasks: allAllocatedTasks,
        reasoning: allocatedRegularTasks.reasoning,
        excludedTasks: allocatedRegularTasks.excludedTasks,
        activeFocusMode: allocationConfig.focusMode,
      ),
      dayUtc: todayUtc,
      capAtGeneration: capAtGeneration,
      candidatePoolCountAtGeneration: candidatePoolCountAtGeneration,
    );
  }

  List<AllocatedTask> _stabilizeRegularAllocation({
    required DateTime todayUtc,
    required int capAtGeneration,
    required int candidatePoolCountAtGeneration,
    required AllocationSnapshot? latestSnapshot,
    required List<Task> regularTasks,
    required List<AllocatedTask> allocatedRegularTasks,
  }) {
    // No snapshot: use computed allocation as-is.
    if (latestSnapshot == null) return allocatedRegularTasks;

    // Only allow top-up when the day was initially generated with a shortage.
    final topUpAllowed = candidatePoolCountAtGeneration < capAtGeneration;

    final regularTaskById = <String, Task>{
      for (final t in regularTasks) t.id: t,
    };

    final suggestedById = <String, AllocatedTask>{
      for (final a in allocatedRegularTasks) a.task.id: a,
    };

    final prevEntries = latestSnapshot.allocated
        .where(
          (e) =>
              e.entity.type == AllocationSnapshotEntityType.task &&
              e.qualifyingValueId != 'pinned',
        )
        .toList();

    final lockedPrev = <AllocatedTask>[];
    final lockedIds = <String>{};

    for (final e in prevEntries) {
      final task = regularTaskById[e.entity.id];
      if (task == null) continue; // Completed/removed/ineligible.

      final fromSuggested = suggestedById[e.entity.id];
      if (fromSuggested != null) {
        lockedPrev.add(fromSuggested);
      } else {
        lockedPrev.add(
          AllocatedTask(
            task: task,
            qualifyingValueId: e.qualifyingValueId ?? 'snapshot',
            allocationScore: e.allocationScore ?? 0,
          ),
        );
      }

      lockedIds.add(e.entity.id);
    }

    if (!topUpAllowed) {
      // Freeze membership (allow shrink, no refill).
      return lockedPrev.length <= capAtGeneration
          ? lockedPrev
          : lockedPrev.take(capAtGeneration).toList();
    }

    final remainingSlots = capAtGeneration - lockedPrev.length;
    if (remainingSlots <= 0) {
      return lockedPrev.take(capAtGeneration).toList();
    }

    final topUps = <AllocatedTask>[];
    for (final a in allocatedRegularTasks) {
      if (lockedIds.contains(a.task.id)) continue;
      topUps.add(a);
      if (topUps.length >= remainingSlots) break;
    }

    return [...lockedPrev, ...topUps];
  }

  /// Allocate regular (non-pinned) tasks using the configured strategy.
  ///
  /// For Phase 1, this simplifies to proportional allocation.
  /// Future phases may implement focus-mode-specific logic.
  Future<AllocationResult> allocateRegularTasks(
    List<Task> tasks,
    AllocationConfig config,
    {
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
  }
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

    // DEBUG: Log task/value distribution.
    final tasksWithValuesCount = tasks.where((t) => t.values.isNotEmpty).length;
    talker.debug(
      '[AllocationOrchestrator] Task value distribution: '
      '$tasksWithValuesCount/${tasks.length} tasks have values',
    );

    // Create allocation strategy based on configuration.
    final strategy = createStrategyForConfig(config);

    talker.debug(
      '[AllocationOrchestrator] Using ${strategy.strategyName} strategy, '
      '$tasksWithValuesCount/${tasks.length} tasks have values, '
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
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
      tasks: tasks,
      categories: categories,
      maxTasks: config.dailyLimit,
      urgencyInfluence: settings.urgencyBoostMultiplier - 1.0,
      urgentTaskBehavior: settings.urgentTaskBehavior,
      taskUrgencyThresholdDays: settings.taskUrgencyThresholdDays,
      urgencyBoostMultiplier: settings.urgencyBoostMultiplier,
      neglectLookbackDays: settings.neglectLookbackDays,
      neglectInfluence: settings.neglectInfluence,
      valuePriorityWeight: settings.valuePriorityWeight,
      taskPriorityBoost: settings.taskPriorityBoost,
      recencyPenalty: settings.recencyPenalty,
      overdueEmergencyMultiplier: settings.overdueEmergencyMultiplier,
      completionsByValue: completionsByValue,
    );

    return strategy.allocate(parameters);
  }

  /// Create allocation strategy based on allocation configuration.
  ///
  /// Selects appropriate allocator based on enabled features:
  /// - NeglectBasedAllocator when enableNeglectWeighting is true
  /// - UrgencyWeightedAllocator when urgency boost > 1.0
  /// - ProportionalAllocator as default
  AllocationStrategy createStrategyForConfig(AllocationConfig config) {
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
    )
  >
  combineStreams() {
    // Watch incomplete tasks
    final tasksStream = _taskRepository.watchAll(TaskQuery.incomplete());

    // Watch projects (if repository available)
    final projectsStream = _projectRepository.watchAll();

    // Watch settings
    final allocationConfigStream = _settingsRepository.watch(
      SettingsKey.allocation,
    );

    // Combine all streams
    return Rx.combineLatest3(
      tasksStream,
      projectsStream,
      allocationConfigStream,
      (tasks, projects, allocationConfig) {
        talker.debug(
          '[AllocationOrchestrator] _combineStreams loaded:\n'
          '  allocationConfig.dailyLimit=${allocationConfig.dailyLimit}',
        );

        return (
          tasks,
          projects,
          allocationConfig,
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
