import 'dart:math' as math;

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/project_anchor_state_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/settings_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/value_ratings_repository_contract.dart';
import 'package:taskly_domain/src/settings/settings.dart';
import 'package:taskly_domain/src/preferences/model/settings_key.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/src/projects/model/project_anchor_state.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/engine/suggested_picks_engine.dart';
import 'package:taskly_domain/src/allocation/engine/urgency_detector.dart';
import 'package:taskly_domain/src/services/analytics/analytics_service.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/time.dart' show dateOnly;

/// Orchestrates task allocation using allocation strategies.
///
/// Now uses settings-based allocation configuration instead of separate
/// database tables. Allocation preferences and value rankings are stored
/// in user profile settings overrides.
class AllocationOrchestrator {
  AllocationOrchestrator({
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required SettingsRepositoryContract settingsRepository,
    required AnalyticsService analyticsService,
    required ProjectRepositoryContract projectRepository,
    required ProjectAnchorStateRepositoryContract projectAnchorStateRepository,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
  }) : _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _settingsRepository = settingsRepository,
       _analyticsService = analyticsService,
       _projectRepository = projectRepository,
       _projectAnchorStateRepository = projectAnchorStateRepository,
       _dayKeyService = dayKeyService,
       _clock = clock;

  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final SettingsRepositoryContract _settingsRepository;
  final AnalyticsService _analyticsService;
  final ProjectRepositoryContract _projectRepository;
  final ProjectAnchorStateRepositoryContract _projectAnchorStateRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;

  static const int _neglectLookbackDays = 14;
  static const double _neglectSmoothingAlpha = 0.20;
  static const int _ratingsLookbackWeeks = 4;
  static const int _ratingsGraceWeeks = 2;
  static const double _ratingsSmoothingAlpha = 0.40;
  static const int _ratingsMax = 8;

  /// Compute a single allocation snapshot.
  ///
  /// This intentionally does **not** keep a live stream subscription.
  /// Callers should re-trigger this explicitly (e.g. on ritual open, day
  /// boundary, or app resume).
  Future<AllocationResult> getAllocationSnapshot({
    DateTime? nowUtc,
    int? maxTasksOverride,
    int? anchorCountOverride,
    Map<String, int> routineSelectionsByValue = const {},
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
      _projectAnchorStateRepository.getAll(),
      _settingsRepository.load(SettingsKey.allocation),
    ]);

    final tasks = results[0] as List<Task>;
    final projects = results[1] as List<Project>;
    final projectAnchorStates = results[2] as List<ProjectAnchorState>;
    final allocationConfig = results[3] as AllocationConfig;

    return _computeAllocation(
      tasks: tasks,
      projects: projects,
      projectAnchorStates: projectAnchorStates,
      allocationConfig: allocationConfig,
      nowUtc: resolvedNowUtc,
      todayDayKeyUtc: todayUtc,
      maxTasksOverride: maxTasksOverride,
      anchorCountOverride: anchorCountOverride,
      routineSelectionsByValue: routineSelectionsByValue,
    );
  }

  /// Compute an allocation snapshot sized for the My Day "Suggested" ritual.
  ///
  /// Callers specify how many *batches* they want (1, 2, 3, ...).
  /// The per-batch limit remains fully owned by allocation settings.
  Future<AllocationResult> getSuggestedSnapshot({
    required int batchCount,
    DateTime? nowUtc,
    Map<String, int> routineSelectionsByValue = const {},
  }) async {
    final resolvedNowUtc = nowUtc ?? _clock.nowUtc();
    final todayUtc = _dayKeyService.todayDayKeyUtc(nowUtc: resolvedNowUtc);

    AppLog.routine(
      'domain.allocation',
      'getSuggestedSnapshot: nowUtc=${resolvedNowUtc.toIso8601String()} '
          'todayUtc=${todayUtc.toIso8601String()} '
          'batchCount=$batchCount',
    );

    final results = await Future.wait([
      _taskRepository.getAll(TaskQuery.incomplete()),
      _projectRepository.getAll(),
      _projectAnchorStateRepository.getAll(),
      _settingsRepository.load(SettingsKey.allocation),
    ]);

    final tasks = results[0] as List<Task>;
    final projects = results[1] as List<Project>;
    final projectAnchorStates = results[2] as List<ProjectAnchorState>;
    final allocationConfig = results[3] as AllocationConfig;

    final safeBatchCount = batchCount.clamp(1, 50);
    final safeAnchorCount = allocationConfig.strategySettings.anchorCount.clamp(
      1,
      50,
    );
    final anchorCountOverride = safeAnchorCount * safeBatchCount;

    return _computeAllocation(
      tasks: tasks,
      projects: projects,
      projectAnchorStates: projectAnchorStates,
      allocationConfig: allocationConfig,
      nowUtc: resolvedNowUtc,
      todayDayKeyUtc: todayUtc,
      anchorCountOverride: anchorCountOverride,
      routineSelectionsByValue: routineSelectionsByValue,
    );
  }

  /// Compute an allocation snapshot sized to a suggested task target.
  ///
  /// This is used when callers want a predictable pool size without relying on
  /// batch multiplication.
  Future<AllocationResult> getSuggestedSnapshotForTargetCount({
    required int suggestedTaskTarget,
    DateTime? nowUtc,
    Map<String, int> routineSelectionsByValue = const {},
  }) async {
    final resolvedNowUtc = nowUtc ?? _clock.nowUtc();
    final todayUtc = _dayKeyService.todayDayKeyUtc(nowUtc: resolvedNowUtc);

    AppLog.routine(
      'domain.allocation',
      'getSuggestedSnapshotForTargetCount: '
          'nowUtc=${resolvedNowUtc.toIso8601String()} '
          'todayUtc=${todayUtc.toIso8601String()} '
          'target=$suggestedTaskTarget',
    );

    final results = await Future.wait([
      _taskRepository.getAll(TaskQuery.incomplete()),
      _projectRepository.getAll(),
      _projectAnchorStateRepository.getAll(),
      _settingsRepository.load(SettingsKey.allocation),
    ]);

    final tasks = results[0] as List<Task>;
    final projects = results[1] as List<Project>;
    final projectAnchorStates = results[2] as List<ProjectAnchorState>;
    final allocationConfig = results[3] as AllocationConfig;

    final strategy = allocationConfig.strategySettings;
    final tasksPerAnchorMax = strategy.tasksPerAnchorMax.clamp(1, 50);
    final freeSlots = strategy.freeSlots.clamp(0, 10);
    final target = suggestedTaskTarget.clamp(0, 500);

    final anchorCountOverride = target <= 0
        ? 0
        : math.max(
            1,
            ((target - freeSlots).clamp(0, target) / tasksPerAnchorMax).ceil(),
          );

    return _computeAllocation(
      tasks: tasks,
      projects: projects,
      projectAnchorStates: projectAnchorStates,
      allocationConfig: allocationConfig,
      nowUtc: resolvedNowUtc,
      todayDayKeyUtc: todayUtc,
      maxTasksOverride: target,
      anchorCountOverride: anchorCountOverride,
      routineSelectionsByValue: routineSelectionsByValue,
    );
  }

  Future<AllocationResult> _computeAllocation({
    required List<Task> tasks,
    required List<Project> projects,
    required List<ProjectAnchorState> projectAnchorStates,
    required AllocationConfig allocationConfig,
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
    int? maxTasksOverride,
    int? anchorCountOverride,
    Map<String, int> routineSelectionsByValue = const {},
  }) async {
    final strategy = allocationConfig.strategySettings;
    final routineSelections = routineSelectionsByValue;
    final anchorCount = (anchorCountOverride ?? strategy.anchorCount).clamp(
      0,
      100,
    );
    final freeSlots = strategy.freeSlots.clamp(0, 10);
    final baseMaxTasks = math.max(
      0,
      (anchorCount * strategy.tasksPerAnchorMax) + freeSlots,
    );
    final maxTasks = math.max(
      0,
      maxTasksOverride == null
          ? baseMaxTasks
          : math.min(baseMaxTasks, maxTasksOverride),
    );

    AppLog.routine(
      'domain.allocation',
      'Compute: ${tasks.length} tasks, ${projects.length} projects, '
          'anchors=$anchorCount maxTasks=$maxTasks',
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

    final allocatedRegularTasks = await allocateRegularTasks(
      tasks,
      projects: projects,
      projectAnchorStates: projectAnchorStates,
      allocationConfig: allocationConfig,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
      maxTasksOverride: maxTasks,
      anchorCountOverride: anchorCount,
      routineSelectionsByValue: routineSelections,
    );

    // Best-effort logging: urgent valueless tasks are a key signal for UX.
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);
    final urgentValueless = urgencyDetector.findUrgentValuelessTasks(
      tasks,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    if (urgentValueless.isNotEmpty) {
      talker.debug(
        '[AllocationOrchestrator] urgent valueless tasks: '
        '${urgentValueless.length}',
      );
    }

    final result = AllocationResult(
      allocatedTasks: allocatedRegularTasks.allocatedTasks,
      reasoning: allocatedRegularTasks.reasoning,
      excludedTasks: allocatedRegularTasks.excludedTasks,
      activeFocusMode: allocationConfig.focusMode,
      anchorProjectIds: allocatedRegularTasks.anchorProjectIds,
      requiresValueSetup: allocatedRegularTasks.requiresValueSetup,
    );

    if (result.anchorProjectIds.isNotEmpty) {
      await _projectAnchorStateRepository.recordAnchors(
        projectIds: result.anchorProjectIds,
        anchoredAtUtc: nowUtc,
      );
    }

    return result;
  }

  /// Allocate tasks using the configured strategy.
  ///
  /// Allocation uses a single engine: [SuggestedPicksEngine].
  Future<AllocationResult> allocateRegularTasks(
    List<Task> tasks, {
    required List<Project> projects,
    required List<ProjectAnchorState> projectAnchorStates,
    required AllocationConfig allocationConfig,
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
    required int maxTasksOverride,
    required int anchorCountOverride,
    Map<String, int> routineSelectionsByValue = const {},
  }) async {
    // Get all values first - needed for both ranking check and allocation
    final values = await _valueRepository.getAll();

    talker.debug(
      '[AllocationOrchestrator] _allocateRegularTasks: '
      '${values.length} values',
    );

    final useRatingsSignal =
        allocationConfig.suggestionSignal == SuggestionSignal.ratingsBased;

    // Build category map - use value priority (behavior mode) or ratings
    final categories = <String, double>{};

    if (values.isNotEmpty) {
      if (useRatingsSignal) {
        final ratingSignal = await _buildRatingsSignal(
          values: values,
          todayDayKeyUtc: todayDayKeyUtc,
        );
        if (ratingSignal.isStale) {
          return AllocationResult(
            allocatedTasks: const [],
            reasoning: AllocationReasoning(
              strategyUsed: 'ratings',
              categoryAllocations: const {},
              categoryWeights: const {},
              explanation: ratingSignal.explanation,
            ),
            excludedTasks: const [],
            requiresRatings: true,
          );
        }
        categories.addAll(ratingSignal.weights);
      } else {
        // Use priority from value
        for (final value in values) {
          categories[value.id] = value.priority.weight.toDouble();
        }
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
    final settings = allocationConfig.strategySettings;
    Map<String, double> completionsByValue = const {};
    if (!useRatingsSignal && settings.enableNeglectWeighting) {
      final dailyCompletions = await _analyticsService
          .getDailyCompletionsByValue(days: _neglectLookbackDays);
      final smoothedCompletions = _smoothCompletionsByValue(
        dailyCompletions: dailyCompletions,
        valueIds: categories.keys,
        days: _neglectLookbackDays,
      );

      final totalCompletions = smoothedCompletions.values.fold<double>(
        0,
        (sum, v) => sum + v,
      );
      if (totalCompletions > 0) {
        completionsByValue = smoothedCompletions;
      }
    }

    // Run allocation
    final maxTasks = maxTasksOverride;

    final parameters = AllocationParameters(
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
      tasks: tasks,
      projects: projects,
      projectAnchorStates: projectAnchorStates,
      categories: categories,
      maxTasks: maxTasks,
      anchorCount: anchorCountOverride,
      tasksPerAnchorMin: settings.tasksPerAnchorMin,
      tasksPerAnchorMax: settings.tasksPerAnchorMax,
      freeSlots: settings.freeSlots,
      rotationPressureDays: settings.rotationPressureDays,
      readinessFilter: settings.readinessFilter,
      taskUrgencyThresholdDays: settings.taskUrgencyThresholdDays,
      keepValuesInBalance:
          !useRatingsSignal &&
          settings.enableNeglectWeighting &&
          completionsByValue.isNotEmpty,
      completionsByValue: completionsByValue,
      routineSelectionsByValue: routineSelectionsByValue,
    );

    return engine.allocate(parameters);
  }

  Future<_RatingsSignal> _buildRatingsSignal({
    required List<Value> values,
    required DateTime todayDayKeyUtc,
  }) async {
    final ratings = await _valueRatingsRepository.getAll(
      weeks: _ratingsLookbackWeeks,
    );
    final ratingsByValue = <String, Map<DateTime, int>>{};
    final latestByValue = <String, DateTime>{};

    for (final rating in ratings) {
      final weekStart = dateOnly(rating.weekStartUtc);
      (ratingsByValue[rating.valueId] ??= {})[weekStart] = rating.rating;
      final latest = latestByValue[rating.valueId];
      if (latest == null || weekStart.isAfter(latest)) {
        latestByValue[rating.valueId] = weekStart;
      }
    }

    final nowWeekStart = _weekStartFor(todayDayKeyUtc);
    final graceCutoff = nowWeekStart.subtract(
      Duration(days: _ratingsGraceWeeks * 7),
    );

    for (final value in values) {
      final latest = latestByValue[value.id];
      if (latest == null || latest.isBefore(graceCutoff)) {
        return const _RatingsSignal(
          isStale: true,
          weights: {},
          explanation: 'Ratings are overdue',
        );
      }
    }

    final window = <DateTime>[
      for (var i = _ratingsLookbackWeeks - 1; i >= 0; i--)
        nowWeekStart.subtract(Duration(days: i * 7)),
    ];

    final weights = <String, double>{};
    for (final value in values) {
      final perWeek = ratingsByValue[value.id] ?? const {};
      int? lastKnown;
      double? ema;
      for (final week in window) {
        final raw = perWeek[week];
        if (raw != null) {
          lastKnown = raw;
        }
        final rating = lastKnown;
        if (rating == null) continue;
        final clamped = rating.clamp(1, _ratingsMax).toDouble();
        ema = ema == null
            ? clamped
            : (_ratingsSmoothingAlpha * clamped) +
                  ((1 - _ratingsSmoothingAlpha) * ema);
      }
      if (ema != null) {
        weights[value.id] = ema;
      }
    }

    if (weights.isEmpty) {
      return const _RatingsSignal(
        isStale: true,
        weights: {},
        explanation: 'Ratings are missing',
      );
    }

    return _RatingsSignal(
      isStale: false,
      weights: weights,
      explanation: 'Ratings signal',
    );
  }

  DateTime _weekStartFor(DateTime dayKeyUtc) {
    final today = dateOnly(dayKeyUtc);
    return today.subtract(Duration(days: today.weekday - 1));
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

  Map<String, double> _smoothCompletionsByValue({
    required Map<String, List<int>> dailyCompletions,
    required Iterable<String> valueIds,
    required int days,
  }) {
    final smoothed = <String, double>{};

    for (final valueId in valueIds) {
      final raw = dailyCompletions[valueId] ?? const <int>[];
      final normalized = raw.length >= days
          ? raw.sublist(raw.length - days)
          : [
              ...List.filled(days - raw.length, 0),
              ...raw,
            ];

      double? ema;
      for (final count in normalized) {
        final current = count.toDouble();
        ema = ema == null
            ? current
            : (_neglectSmoothingAlpha * current) +
                  ((1 - _neglectSmoothingAlpha) * ema);
      }
      smoothed[valueId] = ema ?? 0.0;
    }

    return smoothed;
  }
}

final class _RatingsSignal {
  const _RatingsSignal({
    required this.isStale,
    required this.weights,
    required this.explanation,
  });

  final bool isStale;
  final Map<String, double> weights;
  final String? explanation;
}
