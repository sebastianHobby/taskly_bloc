import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_core/logging.dart';

class WeeklyReviewConfig {
  WeeklyReviewConfig({
    required this.checkInWindowWeeks,
    required this.maintenanceEnabled,
    required this.showDeadlineRisk,
    required this.showStaleItems,
    required this.taskStaleThresholdDays,
    required this.projectIdleThresholdDays,
    required this.deadlineRiskDueWithinDays,
    required this.deadlineRiskMinUnscheduledCount,
    required this.showFrequentSnoozed,
  });

  factory WeeklyReviewConfig.fromSettings(GlobalSettings settings) {
    return WeeklyReviewConfig(
      checkInWindowWeeks: defaultCheckInWindowWeeks,
      maintenanceEnabled: settings.maintenanceEnabled,
      showDeadlineRisk: settings.maintenanceDeadlineRiskEnabled,
      showStaleItems: settings.maintenanceStaleEnabled,
      taskStaleThresholdDays: settings.maintenanceTaskStaleThresholdDays,
      projectIdleThresholdDays: settings.maintenanceProjectIdleThresholdDays,
      deadlineRiskDueWithinDays: settings.maintenanceDeadlineRiskDueWithinDays,
      deadlineRiskMinUnscheduledCount:
          settings.maintenanceDeadlineRiskMinUnscheduledCount,
      showFrequentSnoozed: settings.maintenanceFrequentSnoozedEnabled,
    );
  }

  final int checkInWindowWeeks;
  final bool maintenanceEnabled;
  final bool showDeadlineRisk;
  final bool showStaleItems;
  final int taskStaleThresholdDays;
  final int projectIdleThresholdDays;
  final int deadlineRiskDueWithinDays;
  final int deadlineRiskMinUnscheduledCount;
  final bool showFrequentSnoozed;

  static const int defaultCheckInWindowWeeks = 4;
}

enum WeeklyReviewStatus { loading, ready, failure }

class WeeklyReviewRatingEntry {
  const WeeklyReviewRatingEntry({
    required this.value,
    required this.rating,
    required this.lastRating,
    required this.weeksSinceLastRating,
    required this.history,
    required this.taskCompletions,
    required this.routineCompletions,
    required this.trend,
  });

  final Value value;
  final int rating;
  final int? lastRating;
  final int? weeksSinceLastRating;
  final List<ValueWeeklyRating> history;
  final int taskCompletions;
  final int routineCompletions;
  final List<double> trend;
}

class WeeklyReviewRatingsSummary {
  const WeeklyReviewRatingsSummary({
    required this.weekStartUtc,
    required this.entries,
    required this.maxRating,
    required this.graceWeeks,
    required this.ratingsEnabled,
    required this.ratingsOverdue,
    required this.ratingsInGrace,
    this.selectedValueId,
  });

  final DateTime weekStartUtc;
  final List<WeeklyReviewRatingEntry> entries;
  final int maxRating;
  final int graceWeeks;
  final bool ratingsEnabled;
  final bool ratingsOverdue;
  final bool ratingsInGrace;
  final String? selectedValueId;

  int get ratedCount => entries.where((entry) => entry.rating > 0).length;

  int get totalCount => entries.length;

  bool get isComplete => totalCount == 0 || ratedCount == totalCount;

  WeeklyReviewRatingEntry? get selectedEntry {
    if (entries.isEmpty) return null;
    final selectedId = selectedValueId;
    if (selectedId == null) return entries.first;
    for (final entry in entries) {
      if (entry.value.id == selectedId) return entry;
    }
    return entries.first;
  }
}

enum WeeklyReviewEvidenceStatus { idle, loading, ready, failure }

enum WeeklyReviewEvidenceRange { lastWeek, last30Days, last90Days }

class WeeklyReviewEvidenceItem {
  const WeeklyReviewEvidenceItem({
    required this.id,
    required this.name,
    required this.count,
    this.lastCompletedAtUtc,
  });

  final String id;
  final String name;
  final int count;
  final DateTime? lastCompletedAtUtc;
}

class WeeklyReviewEvidenceState {
  const WeeklyReviewEvidenceState({
    required this.valueId,
    required this.range,
    required this.status,
    required this.taskItems,
    required this.routineItems,
    this.error,
  });

  final String valueId;
  final WeeklyReviewEvidenceRange range;
  final WeeklyReviewEvidenceStatus status;
  final List<WeeklyReviewEvidenceItem> taskItems;
  final List<WeeklyReviewEvidenceItem> routineItems;
  final Object? error;
}

enum WeeklyReviewMaintenanceSectionType {
  deadlineRisk,
  staleItems,
  frequentlySnoozed,
}

sealed class WeeklyReviewMaintenanceItem {
  const WeeklyReviewMaintenanceItem({
    required this.name,
    this.entityId,
    this.entityType,
  });

  final String? name;
  final String? entityId;
  final AttentionEntityType? entityType;
}

final class WeeklyReviewDeadlineRiskItem extends WeeklyReviewMaintenanceItem {
  const WeeklyReviewDeadlineRiskItem({
    required super.name,
    required this.dueInDays,
    required this.unscheduledCount,
    super.entityId,
    super.entityType,
  });

  final int? dueInDays;
  final int unscheduledCount;
}

final class WeeklyReviewStaleItem extends WeeklyReviewMaintenanceItem {
  const WeeklyReviewStaleItem({
    required super.name,
    required this.thresholdDays,
    super.entityId,
    super.entityType,
  });

  final int thresholdDays;
}

final class WeeklyReviewFrequentSnoozedItem
    extends WeeklyReviewMaintenanceItem {
  const WeeklyReviewFrequentSnoozedItem({
    required super.name,
    required this.snoozeCount,
    required this.totalSnoozeDays,
    super.entityId,
    super.entityType,
  });

  final int snoozeCount;
  final int totalSnoozeDays;
}

class WeeklyReviewMaintenanceSection {
  const WeeklyReviewMaintenanceSection({
    required this.type,
    required this.items,
  });

  final WeeklyReviewMaintenanceSectionType type;
  final List<WeeklyReviewMaintenanceItem> items;
}

class WeeklyReviewState {
  const WeeklyReviewState({
    this.status = WeeklyReviewStatus.loading,
    this.ratingsSummary,
    this.maintenanceSections = const [],
    this.evidence,
    this.error,
  });

  final WeeklyReviewStatus status;
  final WeeklyReviewRatingsSummary? ratingsSummary;
  final List<WeeklyReviewMaintenanceSection> maintenanceSections;
  final WeeklyReviewEvidenceState? evidence;
  final Object? error;

  WeeklyReviewState copyWith({
    WeeklyReviewStatus? status,
    WeeklyReviewRatingsSummary? ratingsSummary,
    List<WeeklyReviewMaintenanceSection>? maintenanceSections,
    WeeklyReviewEvidenceState? evidence,
    Object? error,
  }) {
    return WeeklyReviewState(
      status: status ?? this.status,
      ratingsSummary: ratingsSummary ?? this.ratingsSummary,
      maintenanceSections: maintenanceSections ?? this.maintenanceSections,
      evidence: evidence ?? this.evidence,
      error: error,
    );
  }
}

sealed class WeeklyReviewEvent {
  const WeeklyReviewEvent();
}

final class WeeklyReviewRequested extends WeeklyReviewEvent {
  const WeeklyReviewRequested(this.config);

  final WeeklyReviewConfig config;
}

final class WeeklyReviewValueSelected extends WeeklyReviewEvent {
  const WeeklyReviewValueSelected(this.valueId);

  final String valueId;
}

final class WeeklyReviewValueRatingChanged extends WeeklyReviewEvent {
  const WeeklyReviewValueRatingChanged({
    required this.valueId,
    required this.rating,
  });

  final String valueId;
  final int rating;
}

final class WeeklyReviewEvidenceRequested extends WeeklyReviewEvent {
  const WeeklyReviewEvidenceRequested({
    required this.valueId,
    required this.range,
  });

  final String valueId;
  final WeeklyReviewEvidenceRange range;
}

class WeeklyReviewBloc extends Bloc<WeeklyReviewEvent, WeeklyReviewState> {
  WeeklyReviewBloc({
    required AnalyticsService analyticsService,
    required AttentionEngineContract attentionEngine,
    required ValueRepositoryContract valueRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required ValueRatingsWriteService valueRatingsWriteService,
    required RoutineRepositoryContract routineRepository,
    required TaskRepositoryContract taskRepository,
    required NowService nowService,
  }) : _analyticsService = analyticsService,
       _attentionEngine = attentionEngine,
       _valueRepository = valueRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _valueRatingsWriteService = valueRatingsWriteService,
       _routineRepository = routineRepository,
       _taskRepository = taskRepository,
       _nowService = nowService,
       super(const WeeklyReviewState()) {
    on<WeeklyReviewRequested>(_onRequested, transformer: restartable());
    on<WeeklyReviewValueSelected>(_onValueSelected);
    on<WeeklyReviewValueRatingChanged>(
      _onValueRatingChanged,
      transformer: sequential(),
    );
    on<WeeklyReviewEvidenceRequested>(
      _onEvidenceRequested,
      transformer: restartable(),
    );
  }

  final AnalyticsService _analyticsService;
  final AttentionEngineContract _attentionEngine;
  final ValueRepositoryContract _valueRepository;
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final ValueRatingsWriteService _valueRatingsWriteService;
  final RoutineRepositoryContract _routineRepository;
  final TaskRepositoryContract _taskRepository;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  static const int _ratingsHistoryWeeks = 8;
  static const int _ratingsGraceWeeks = 2;
  static const int _ratingsMax = 10;

  Future<void> _onRequested(
    WeeklyReviewRequested event,
    Emitter<WeeklyReviewState> emit,
  ) async {
    final config = event.config;

    AppLog.warnStructured(
      'weekly_review',
      'requested',
      fields: <String, Object?>{
        'maintenanceEnabled': config.maintenanceEnabled,
        'checkInWindowWeeks': config.checkInWindowWeeks,
      },
    );

    emit(state.copyWith(status: WeeklyReviewStatus.loading));

    try {
      final ratingsSummary = await _buildRatingsSummary(
        config: config,
      );

      if (emit.isDone) return;

      final initialSections = config.maintenanceEnabled
          ? await _buildInitialMaintenanceSections(config)
          : _emptyMaintenanceSections(config);

      emit(
        state.copyWith(
          status: WeeklyReviewStatus.ready,
          ratingsSummary: ratingsSummary,
          maintenanceSections: initialSections,
          error: null,
        ),
      );

      AppLog.warnStructured(
        'weekly_review',
        'ready',
        fields: <String, Object?>{
          'ratingsEnabled': ratingsSummary.ratingsEnabled,
          'ratingsEntries': ratingsSummary.entries.length,
          'ratingsComplete': ratingsSummary.isComplete,
        },
      );

      if (!config.maintenanceEnabled) return;

      final maintenance$ = _attentionEngine
          .watch(const AttentionQuery(buckets: {AttentionBucket.action}))
          .map((items) {
            final sections = _buildMaintenanceSections(items, config);
            return state.copyWith(maintenanceSections: sections);
          });

      await emit.forEach<WeeklyReviewState>(
        maintenance$,
        onData: (next) => next,
        onError: (error, stackTrace) => state.copyWith(
          status: WeeklyReviewStatus.failure,
          error: error,
        ),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: WeeklyReviewStatus.failure,
          error: e,
        ),
      );
    }
  }

  void _onValueSelected(
    WeeklyReviewValueSelected event,
    Emitter<WeeklyReviewState> emit,
  ) {
    final current = state.ratingsSummary;
    if (current == null) return;
    if (!current.ratingsEnabled) return;

    emit(
      state.copyWith(
        ratingsSummary: WeeklyReviewRatingsSummary(
          weekStartUtc: current.weekStartUtc,
          entries: current.entries,
          maxRating: current.maxRating,
          graceWeeks: current.graceWeeks,
          ratingsEnabled: current.ratingsEnabled,
          ratingsOverdue: current.ratingsOverdue,
          ratingsInGrace: current.ratingsInGrace,
          selectedValueId: event.valueId,
        ),
      ),
    );
  }

  Future<void> _onValueRatingChanged(
    WeeklyReviewValueRatingChanged event,
    Emitter<WeeklyReviewState> emit,
  ) async {
    final current = state.ratingsSummary;
    if (current == null || !current.ratingsEnabled) return;

    final clamped = event.rating.clamp(1, current.maxRating);
    final updated = _applyRatingChange(
      current,
      valueId: event.valueId,
      rating: clamped,
    );

    emit(state.copyWith(ratingsSummary: updated));

    final context = _contextFactory.create(
      feature: 'weekly_review',
      screen: 'weekly_review',
      intent: 'rate_value',
      operation: 'value.rating.upsert',
      entityType: 'value',
      entityId: event.valueId,
      extraFields: <String, Object?>{
        'weekStartUtc': updated.weekStartUtc.toIso8601String(),
        'rating': clamped,
      },
    );

    await _valueRatingsWriteService.recordWeeklyRatings(
      weekStartUtc: updated.weekStartUtc,
      ratingsByValueId: {event.valueId: clamped},
      context: context,
    );
  }

  Future<void> _onEvidenceRequested(
    WeeklyReviewEvidenceRequested event,
    Emitter<WeeklyReviewState> emit,
  ) async {
    emit(
      state.copyWith(
        evidence: WeeklyReviewEvidenceState(
          valueId: event.valueId,
          range: event.range,
          status: WeeklyReviewEvidenceStatus.loading,
          taskItems: const [],
          routineItems: const [],
        ),
      ),
    );

    try {
      final (tasks, routines) = await _buildEvidenceItems(
        valueId: event.valueId,
        range: event.range,
      );

      if (emit.isDone) return;

      emit(
        state.copyWith(
          evidence: WeeklyReviewEvidenceState(
            valueId: event.valueId,
            range: event.range,
            status: WeeklyReviewEvidenceStatus.ready,
            taskItems: tasks,
            routineItems: routines,
          ),
        ),
      );
    } catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          evidence: WeeklyReviewEvidenceState(
            valueId: event.valueId,
            range: event.range,
            status: WeeklyReviewEvidenceStatus.failure,
            taskItems: const [],
            routineItems: const [],
            error: error,
          ),
        ),
      );
    }
  }

  Future<WeeklyReviewRatingsSummary> _buildRatingsSummary({
    required WeeklyReviewConfig config,
  }) async {
    final values = await _valueRepository.getAll();
    final nowUtc = _nowService.nowUtc();
    final weekStartUtc = _weekStartFor(nowUtc);

    AppLog.warnStructured(
      'weekly_review',
      'build_ratings_summary',
      fields: <String, Object?>{
        'values': values.length,
        'weekStartUtc': weekStartUtc.toIso8601String(),
      },
    );

    if (values.isEmpty) {
      return WeeklyReviewRatingsSummary(
        weekStartUtc: weekStartUtc,
        entries: const [],
        maxRating: _ratingsMax,
        graceWeeks: _ratingsGraceWeeks,
        ratingsEnabled: true,
        ratingsOverdue: false,
        ratingsInGrace: false,
      );
    }

    final history = await _valueRatingsRepository.getAll(
      weeks: _ratingsHistoryWeeks,
    );
    AppLog.warnStructured(
      'weekly_review',
      'ratings_history',
      fields: <String, Object?>{
        'count': history.length,
        'weeks': _ratingsHistoryWeeks,
      },
    );
    final historyByValue = <String, List<ValueWeeklyRating>>{};
    for (final rating in history) {
      (historyByValue[rating.valueId] ??= []).add(rating);
    }
    for (final entry in historyByValue.entries) {
      entry.value.sort((a, b) => b.weekStartUtc.compareTo(a.weekStartUtc));
    }

    final windowWeeks = config.checkInWindowWeeks.clamp(1, 12);
    final days = windowWeeks * 7;

    final taskCompletions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );
    final routines = await _routineRepository.getAll(includeInactive: true);
    final routineById = {for (final routine in routines) routine.id: routine};
    final routineCompletions = await _routineRepository.getCompletions();
    final completionTrends = await _buildCompletionTrends(
      values: values,
      weeks: windowWeeks,
      routineById: routineById,
      routineCompletions: routineCompletions,
    );
    final startDay = dateOnly(nowUtc).subtract(Duration(days: days - 1));
    final endDay = dateOnly(nowUtc);

    final routineCounts = <String, int>{};
    for (final completion in routineCompletions) {
      final routine = routineById[completion.routineId];
      if (routine == null) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      final valueId = routine.value?.id;
      if (valueId == null || valueId.isEmpty) continue;
      routineCounts[valueId] = (routineCounts[valueId] ?? 0) + 1;
    }

    final entries = <WeeklyReviewRatingEntry>[];
    for (final value in values) {
      final valueHistory = historyByValue[value.id] ?? const [];
      ValueWeeklyRating? currentWeek;
      for (final rating in valueHistory) {
        if (dateOnly(rating.weekStartUtc).isAtSameMomentAs(weekStartUtc)) {
          currentWeek = rating;
          break;
        }
      }

      final currentRating = currentWeek?.rating ?? 0;
      final hasCurrentWeek = currentRating > 0;
      final latest = valueHistory.isEmpty ? null : valueHistory.first;
      final weeksSinceLast = latest == null
          ? null
          : weekStartUtc.difference(dateOnly(latest.weekStartUtc)).inDays ~/ 7;

      entries.add(
        WeeklyReviewRatingEntry(
          value: value,
          rating: hasCurrentWeek ? currentRating : 0,
          lastRating: latest?.rating,
          weeksSinceLastRating: weeksSinceLast,
          history: valueHistory.take(4).toList(growable: false),
          taskCompletions: taskCompletions[value.id] ?? 0,
          routineCompletions: routineCounts[value.id] ?? 0,
          trend: completionTrends[value.id] ?? const <double>[],
        ),
      );
    }

    final flags = _ratingsFlags(entries);

    return WeeklyReviewRatingsSummary(
      weekStartUtc: weekStartUtc,
      entries: entries,
      maxRating: _ratingsMax,
      graceWeeks: _ratingsGraceWeeks,
      ratingsEnabled: true,
      ratingsOverdue: flags.overdue,
      ratingsInGrace: flags.inGrace,
      selectedValueId: entries.isEmpty ? null : entries.first.value.id,
    );
  }

  WeeklyReviewRatingsSummary _applyRatingChange(
    WeeklyReviewRatingsSummary summary, {
    required String valueId,
    required int rating,
  }) {
    final nowUtc = _nowService.nowUtc();
    final weekStart = summary.weekStartUtc;

    final updatedEntries = summary.entries
        .map((entry) {
          if (entry.value.id != valueId) return entry;

          final updatedHistory = [...entry.history];
          final index = updatedHistory.indexWhere(
            (item) => dateOnly(item.weekStartUtc).isAtSameMomentAs(weekStart),
          );

          final updatedItem = ValueWeeklyRating(
            id: index >= 0 ? updatedHistory[index].id : 'local-$valueId',
            valueId: valueId,
            weekStartUtc: weekStart,
            rating: rating,
            createdAtUtc: index >= 0
                ? updatedHistory[index].createdAtUtc
                : nowUtc,
            updatedAtUtc: nowUtc,
          );

          if (index >= 0) {
            updatedHistory[index] = updatedItem;
          } else {
            updatedHistory.insert(0, updatedItem);
          }

          return WeeklyReviewRatingEntry(
            value: entry.value,
            rating: rating,
            lastRating: rating,
            weeksSinceLastRating: 0,
            history: updatedHistory.take(4).toList(growable: false),
            taskCompletions: entry.taskCompletions,
            routineCompletions: entry.routineCompletions,
            trend: entry.trend,
          );
        })
        .toList(growable: false);

    final flags = _ratingsFlags(updatedEntries);

    return WeeklyReviewRatingsSummary(
      weekStartUtc: summary.weekStartUtc,
      entries: updatedEntries,
      maxRating: summary.maxRating,
      graceWeeks: summary.graceWeeks,
      ratingsEnabled: summary.ratingsEnabled,
      ratingsOverdue: flags.overdue,
      ratingsInGrace: flags.inGrace,
      selectedValueId: valueId,
    );
  }

  ({bool overdue, bool inGrace}) _ratingsFlags(
    List<WeeklyReviewRatingEntry> entries,
  ) {
    var overdue = false;
    var inGrace = false;

    for (final entry in entries) {
      final weeksSince = entry.weeksSinceLastRating;
      if (weeksSince == null) {
        overdue = true;
        continue;
      }
      if (weeksSince > _ratingsGraceWeeks) {
        overdue = true;
      } else if (weeksSince >= 1) {
        inGrace = true;
      }
    }

    return (overdue: overdue, inGrace: inGrace);
  }

  DateTime _weekStartFor(DateTime nowUtc) {
    final today = dateOnly(nowUtc);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  Future<(List<WeeklyReviewEvidenceItem>, List<WeeklyReviewEvidenceItem>)>
  _buildEvidenceItems({
    required String valueId,
    required WeeklyReviewEvidenceRange range,
  }) async {
    final nowUtc = _nowService.nowUtc();
    final days = _evidenceRangeDays(range);
    final startDay = dateOnly(nowUtc).subtract(Duration(days: days - 1));
    final endDay = dateOnly(nowUtc);

    final completions = await _taskRepository.watchCompletionHistory().first;
    final taskCounts = <String, int>{};
    final taskLatestCompletion = <String, DateTime>{};

    for (final completion in completions) {
      final day = dateOnly(completion.completedAt);
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      final current = taskCounts[completion.entityId] ?? 0;
      taskCounts[completion.entityId] = current + 1;
      final latest = taskLatestCompletion[completion.entityId];
      if (latest == null || completion.completedAt.isAfter(latest)) {
        taskLatestCompletion[completion.entityId] = completion.completedAt;
      }
    }

    final tasks = taskCounts.isEmpty
        ? const <Task>[]
        : await _taskRepository.getByIds(taskCounts.keys);

    final taskItems =
        tasks
            .where((task) => _taskMatchesValue(task, valueId))
            .map(
              (task) => WeeklyReviewEvidenceItem(
                id: task.id,
                name: task.name,
                count: taskCounts[task.id] ?? 0,
                lastCompletedAtUtc: taskLatestCompletion[task.id],
              ),
            )
            .where((item) => item.count > 0)
            .toList(growable: false)
          ..sort(_compareEvidenceItems);

    final routines = await _routineRepository.getAll(includeInactive: true);
    final routineById = {for (final routine in routines) routine.id: routine};
    final routineCompletions = await _routineRepository.getCompletions();
    final routineCounts = <String, int>{};
    final routineLatestCompletion = <String, DateTime>{};

    for (final completion in routineCompletions) {
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      final routine = routineById[completion.routineId];
      if (routine == null) continue;
      if (routine.value?.id != valueId) continue;
      final current = routineCounts[completion.routineId] ?? 0;
      routineCounts[completion.routineId] = current + 1;
      final latest = routineLatestCompletion[completion.routineId];
      if (latest == null || completion.completedAtUtc.isAfter(latest)) {
        routineLatestCompletion[completion.routineId] =
            completion.completedAtUtc;
      }
    }

    final routineItems =
        routineCounts.entries
            .map((entry) {
              final routine = routineById[entry.key];
              if (routine == null) return null;
              return WeeklyReviewEvidenceItem(
                id: routine.id,
                name: routine.name,
                count: entry.value,
                lastCompletedAtUtc: routineLatestCompletion[entry.key],
              );
            })
            .whereType<WeeklyReviewEvidenceItem>()
            .toList(growable: false)
          ..sort(_compareEvidenceItems);

    return (taskItems, routineItems);
  }

  int _evidenceRangeDays(WeeklyReviewEvidenceRange range) {
    return switch (range) {
      WeeklyReviewEvidenceRange.lastWeek => 7,
      WeeklyReviewEvidenceRange.last30Days => 30,
      WeeklyReviewEvidenceRange.last90Days => 90,
    };
  }

  bool _taskMatchesValue(Task task, String valueId) {
    final taskValueIds = <String>{
      for (final value in task.values) value.id,
      for (final value in task.project?.values ?? const <Value>[]) value.id,
    };
    return taskValueIds.contains(valueId);
  }

  int _compareEvidenceItems(
    WeeklyReviewEvidenceItem a,
    WeeklyReviewEvidenceItem b,
  ) {
    final aDate = a.lastCompletedAtUtc;
    final bDate = b.lastCompletedAtUtc;
    if (aDate != null && bDate != null) {
      final dateCompare = bDate.compareTo(aDate);
      if (dateCompare != 0) return dateCompare;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }
    return a.name.compareTo(b.name);
  }

  Future<Map<String, List<double>>> _buildCompletionTrends({
    required List<Value> values,
    required int weeks,
    required Map<String, Routine> routineById,
    required List<RoutineCompletion> routineCompletions,
  }) async {
    final safeWeeks = weeks.clamp(1, 12);
    final trends = <String, List<double>>{
      for (final value in values) value.id: List.filled(safeWeeks, 0),
    };
    if (values.isEmpty) return trends;

    final nowLocal = _nowService.nowLocal();
    final endDay = dateOnly(nowLocal);
    final startDay = endDay.subtract(Duration(days: safeWeeks * 7 - 1));

    final taskCompletions = await _taskRepository
        .watchCompletionHistory()
        .first;
    final taskIds = taskCompletions
        .where((completion) {
          final day = dateOnly(completion.completedAt.toLocal());
          return !(day.isBefore(startDay) || day.isAfter(endDay));
        })
        .map((completion) => completion.entityId)
        .toSet();

    final tasks = taskIds.isEmpty
        ? const <Task>[]
        : await _taskRepository.getByIds(taskIds);
    final taskById = {for (final task in tasks) task.id: task};

    for (final completion in taskCompletions) {
      final day = dateOnly(completion.completedAt.toLocal());
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      final index = day.difference(startDay).inDays ~/ 7;
      if (index < 0 || index >= safeWeeks) continue;
      final task = taskById[completion.entityId];
      if (task == null) continue;
      final valueIds = _effectiveValueIdsForTask(task);
      if (valueIds.isEmpty) continue;
      for (final valueId in valueIds) {
        final series = trends[valueId];
        if (series == null) continue;
        series[index] = series[index] + 1;
      }
    }

    for (final completion in routineCompletions) {
      final day = dateOnly(completion.completedAtUtc.toLocal());
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      final index = day.difference(startDay).inDays ~/ 7;
      if (index < 0 || index >= safeWeeks) continue;
      final routine = routineById[completion.routineId];
      if (routine == null) continue;
      final series = trends[routine.value?.id];
      if (series == null) continue;
      series[index] = series[index] + 1;
    }

    return trends;
  }

  Set<String> _effectiveValueIdsForTask(Task task) {
    return <String>{
      for (final value in task.values) value.id,
      for (final value in task.project?.values ?? const <Value>[]) value.id,
    };
  }

  List<WeeklyReviewMaintenanceSection> _buildMaintenanceSections(
    List<AttentionItem> items,
    WeeklyReviewConfig config,
  ) {
    final sections = <WeeklyReviewMaintenanceSection>[];

    if (config.showDeadlineRisk) {
      final riskItems = items.where(
        (i) => i.ruleKey == 'problem_project_deadline_risk',
      );
      sections.add(
        WeeklyReviewMaintenanceSection(
          type: WeeklyReviewMaintenanceSectionType.deadlineRisk,
          items: riskItems.map(_mapDeadlineRiskItem).toList(growable: false),
        ),
      );
    }

    if (config.showStaleItems) {
      final staleItems = [
        ...items.where((i) => i.ruleKey == 'problem_task_stale'),
        ...items.where((i) => i.ruleKey == 'problem_project_idle'),
      ];
      sections.add(
        WeeklyReviewMaintenanceSection(
          type: WeeklyReviewMaintenanceSectionType.staleItems,
          items: staleItems
              .map((item) => _mapStaleItem(item, config))
              .toList(growable: false),
        ),
      );
    }

    if (config.showFrequentSnoozed) {
      sections.add(_buildFrequentSnoozedSection(state.maintenanceSections));
    }

    return sections;
  }

  Future<List<WeeklyReviewMaintenanceSection>> _buildInitialMaintenanceSections(
    WeeklyReviewConfig config,
  ) async {
    if (!config.maintenanceEnabled) {
      return _emptyMaintenanceSections(config);
    }

    final base = _buildMaintenanceSections(const [], config);
    final snoozed = config.showFrequentSnoozed
        ? await _buildFrequentSnoozedSectionAsync()
        : null;

    return base
        .map(
          (section) =>
              section.type ==
                      WeeklyReviewMaintenanceSectionType.frequentlySnoozed &&
                  snoozed != null
              ? snoozed
              : section,
        )
        .toList(growable: false);
  }

  WeeklyReviewMaintenanceSection _buildFrequentSnoozedSection(
    List<WeeklyReviewMaintenanceSection> currentSections,
  ) {
    final existing = currentSections.firstWhere(
      (section) =>
          section.type == WeeklyReviewMaintenanceSectionType.frequentlySnoozed,
      orElse: () => const WeeklyReviewMaintenanceSection(
        type: WeeklyReviewMaintenanceSectionType.frequentlySnoozed,
        items: [],
      ),
    );

    return existing;
  }

  Future<WeeklyReviewMaintenanceSection>
  _buildFrequentSnoozedSectionAsync() async {
    final nowUtc = _nowService.nowUtc();
    final sinceUtc = nowUtc.subtract(const Duration(days: 28));

    final statsByTask = await _taskRepository.getSnoozeStats(
      sinceUtc: sinceUtc,
      untilUtc: nowUtc,
    );

    if (statsByTask.isEmpty) {
      return const WeeklyReviewMaintenanceSection(
        type: WeeklyReviewMaintenanceSectionType.frequentlySnoozed,
        items: [],
      );
    }

    final flaggedIds = statsByTask.entries
        .where((entry) {
          final stats = entry.value;
          return stats.snoozeCount >= 3 ||
              (stats.snoozeCount >= 2 && stats.totalSnoozeDays >= 28);
        })
        .map((entry) => entry.key)
        .toList(growable: false);

    if (flaggedIds.isEmpty) {
      return const WeeklyReviewMaintenanceSection(
        type: WeeklyReviewMaintenanceSectionType.frequentlySnoozed,
        items: [],
      );
    }

    final tasks = await _taskRepository.getByIds(flaggedIds);
    final items = <WeeklyReviewMaintenanceItem>[];

    for (final task in tasks) {
      if (task.completed) continue;
      final stats = statsByTask[task.id];
      if (stats == null) continue;

      items.add(
        WeeklyReviewFrequentSnoozedItem(
          name: task.name,
          entityId: task.id,
          entityType: AttentionEntityType.task,
          snoozeCount: stats.snoozeCount,
          totalSnoozeDays: stats.totalSnoozeDays,
        ),
      );
    }

    return WeeklyReviewMaintenanceSection(
      type: WeeklyReviewMaintenanceSectionType.frequentlySnoozed,
      items: items,
    );
  }

  WeeklyReviewDeadlineRiskItem _mapDeadlineRiskItem(AttentionItem item) {
    final name =
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String?;
    final dueInDays = item.metadata?['due_in_days'] as int?;
    final unscheduled = item.metadata?['unscheduled_tasks_count'] as int? ?? 0;

    return WeeklyReviewDeadlineRiskItem(
      name: name,
      entityId: item.entityId,
      entityType: item.entityType,
      dueInDays: dueInDays,
      unscheduledCount: unscheduled,
    );
  }

  WeeklyReviewStaleItem _mapStaleItem(
    AttentionItem item,
    WeeklyReviewConfig config,
  ) {
    final name =
        item.metadata?['task_name'] as String? ??
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String?;

    final thresholdDays = item.ruleKey == 'problem_task_stale'
        ? config.taskStaleThresholdDays
        : config.projectIdleThresholdDays;

    return WeeklyReviewStaleItem(
      name: name,
      entityId: item.entityId,
      entityType: item.entityType,
      thresholdDays: thresholdDays,
    );
  }

  List<WeeklyReviewMaintenanceSection> _emptyMaintenanceSections(
    WeeklyReviewConfig config,
  ) {
    return _buildMaintenanceSections(const [], config);
  }
}
