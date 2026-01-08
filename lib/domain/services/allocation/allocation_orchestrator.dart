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
import 'package:taskly_bloc/domain/interfaces/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_snapshot.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';

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
    AllocationSnapshotRepositoryContract? allocationSnapshotRepository,
    AllocationAlertEvaluator? alertEvaluator,
  }) : _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _alertEvaluator = alertEvaluator ?? const AllocationAlertEvaluator();

  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  final ProjectRepositoryContract _projectRepository;
  final AllocationAlertEvaluator _alertEvaluator;
  final AllocationSnapshotRepositoryContract? _allocationSnapshotRepository;

  /// Watch the full allocation result (pinned + allocated tasks)
  Stream<AllocationResult> watchAllocation() {
    talker.debug('[AllocationOrchestrator] watchAllocation started');

    // Latest snapshot wins: cancel in-flight computations when inputs change.
    return combineStreams()
        .switchMap(
          (combined) => Stream.fromFuture(_computeAllocation(combined)),
        )
        .asyncMap((result) async {
          // Persist a stable daily snapshot of allocation membership.
          // IMPORTANT: App code does not filter on `user_id`; RLS + PowerSync buckets
          // handle scoping.
          final repo = _allocationSnapshotRepository;
          if (repo != null) {
            final todayUtc = dateOnly(DateTime.now().toUtc());
            final allocated = result.allocatedTasks
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
              dayUtc: todayUtc,
              allocated: allocated,
            );
          }

          return result;
        });
  }

  Future<AllocationResult> _computeAllocation(
    (List<Task>, List<Project>, AllocationConfig) combined,
  ) async {
    final tasks = combined.$1;
    final projects = combined.$2;
    final allocationConfig = combined.$3;

    talker.debug(
      '[AllocationOrchestrator] Stream update: '
      '${tasks.length} tasks, ${projects.length} projects, '
      'dailyLimit=${allocationConfig.dailyLimit}',
    );

    // Ensure values exist (soft-gate).
    final values = await _valueRepository.getAll();
    talker.debug(
      '[AllocationOrchestrator] Found ${values.length} values in DB: '
      '${values.map((v) => '${v.name}(${v.id.substring(0, 8)})').join(', ')}',
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

    if (allocationConfig.dailyLimit == 0) {
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
    );

    final allAllocatedTasks = [
      ...pinnedAllocatedTasks,
      ...allocatedRegularTasks.allocatedTasks,
    ];

    // Evaluate alerts on excluded tasks.
    // Note: alert settings have migrated to the attention system.
    final alertResult = _alertEvaluator.evaluate(
      excludedTasks: allocatedRegularTasks.excludedTasks,
      config: const AllocationAlertConfig(),
    );

    // Best-effort logging: urgent valueless tasks are a key signal for UX.
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);
    final urgentValueless = urgencyDetector.findUrgentValuelessTasks(
      regularTasks,
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
      alertResult: alertResult,
      activeFocusMode: allocationConfig.focusMode,
    );
  }

  /// Allocate regular (non-pinned) tasks using persona-based strategy.
  ///
  /// For Phase 1, this simplifies to proportional allocation.
  /// Future phases will implement persona-specific logic.
  Future<AllocationResult> allocateRegularTasks(
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

    // DEBUG: Log task/value distribution.
    final tasksWithValuesCount = tasks.where((t) => t.values.isNotEmpty).length;
    talker.debug(
      '[AllocationOrchestrator] Task value distribution: '
      '$tasksWithValuesCount/${tasks.length} tasks have values',
    );

    // Create allocation strategy based on persona
    final strategy = createStrategyForPersona(config);

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
      tasks: tasks,
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
  AllocationStrategy createStrategyForPersona(AllocationConfig config) {
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
