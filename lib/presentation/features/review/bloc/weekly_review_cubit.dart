import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

class WeeklyReviewConfig {
  WeeklyReviewConfig({
    required this.valuesSummaryEnabled,
    required this.valuesWindowWeeks,
    required this.valueWinsCount,
    required this.maintenanceEnabled,
    required this.showDeadlineRisk,
    required this.showDueSoonUnderControl,
    required this.showStaleItems,
    required this.taskStaleThresholdDays,
    required this.projectIdleThresholdDays,
    required this.deadlineRiskDueWithinDays,
    required this.deadlineRiskMinUnscheduledCount,
    required this.showMissingNextActions,
    required this.missingNextActionsMinOpenTasks,
    required this.showFrequentSnoozed,
  });

  factory WeeklyReviewConfig.fromSettings(GlobalSettings settings) {
    return WeeklyReviewConfig(
      valuesSummaryEnabled: settings.valuesSummaryEnabled,
      valuesWindowWeeks: settings.valuesSummaryWindowWeeks,
      valueWinsCount: settings.valuesSummaryWinsCount,
      maintenanceEnabled: settings.maintenanceEnabled,
      showDeadlineRisk: settings.maintenanceDeadlineRiskEnabled,
      showDueSoonUnderControl: settings.maintenanceDueSoonEnabled,
      showStaleItems: settings.maintenanceStaleEnabled,
      taskStaleThresholdDays: settings.maintenanceTaskStaleThresholdDays,
      projectIdleThresholdDays: settings.maintenanceProjectIdleThresholdDays,
      deadlineRiskDueWithinDays: settings.maintenanceDeadlineRiskDueWithinDays,
      deadlineRiskMinUnscheduledCount:
          settings.maintenanceDeadlineRiskMinUnscheduledCount,
      showMissingNextActions: settings.maintenanceMissingNextActionsEnabled,
      missingNextActionsMinOpenTasks:
          settings.maintenanceMissingNextActionsMinOpenTasks,
      showFrequentSnoozed: settings.maintenanceFrequentSnoozedEnabled,
    );
  }

  final bool valuesSummaryEnabled;
  final int valuesWindowWeeks;
  final int valueWinsCount;
  final bool maintenanceEnabled;
  final bool showDeadlineRisk;
  final bool showDueSoonUnderControl;
  final bool showStaleItems;
  final int taskStaleThresholdDays;
  final int projectIdleThresholdDays;
  final int deadlineRiskDueWithinDays;
  final int deadlineRiskMinUnscheduledCount;
  final bool showMissingNextActions;
  final int missingNextActionsMinOpenTasks;
  final bool showFrequentSnoozed;
}

enum WeeklyReviewStatus { loading, ready, failure }

class WeeklyReviewValueRing {
  const WeeklyReviewValueRing({
    required this.value,
    required this.percent,
  });

  final Value value;
  final double percent;
}

class WeeklyReviewValuesSummary {
  const WeeklyReviewValuesSummary({
    required this.rings,
    required this.topValueName,
    required this.bottomValueName,
    required this.hasData,
  });

  final List<WeeklyReviewValueRing> rings;
  final String? topValueName;
  final String? bottomValueName;
  final bool hasData;
}

class WeeklyReviewValueWin {
  const WeeklyReviewValueWin({
    required this.valueName,
    required this.completionCount,
  });

  final String valueName;
  final int completionCount;
}

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

class WeeklyReviewMaintenanceItem {
  const WeeklyReviewMaintenanceItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class WeeklyReviewMaintenanceSection {
  const WeeklyReviewMaintenanceSection({
    required this.id,
    required this.title,
    required this.emptyMessage,
    required this.items,
  });

  final String id;
  final String title;
  final String emptyMessage;
  final List<WeeklyReviewMaintenanceItem> items;
}

class WeeklyReviewState {
  const WeeklyReviewState({
    this.status = WeeklyReviewStatus.loading,
    this.ratingsSummary,
    this.valuesSummary,
    this.valueWins = const [],
    this.maintenanceSections = const [],
    this.errorMessage,
  });

  final WeeklyReviewStatus status;
  final WeeklyReviewRatingsSummary? ratingsSummary;
  final WeeklyReviewValuesSummary? valuesSummary;
  final List<WeeklyReviewValueWin> valueWins;
  final List<WeeklyReviewMaintenanceSection> maintenanceSections;
  final String? errorMessage;

  WeeklyReviewState copyWith({
    WeeklyReviewStatus? status,
    WeeklyReviewRatingsSummary? ratingsSummary,
    WeeklyReviewValuesSummary? valuesSummary,
    List<WeeklyReviewValueWin>? valueWins,
    List<WeeklyReviewMaintenanceSection>? maintenanceSections,
    String? errorMessage,
  }) {
    return WeeklyReviewState(
      status: status ?? this.status,
      ratingsSummary: ratingsSummary ?? this.ratingsSummary,
      valuesSummary: valuesSummary ?? this.valuesSummary,
      valueWins: valueWins ?? this.valueWins,
      maintenanceSections: maintenanceSections ?? this.maintenanceSections,
      errorMessage: errorMessage,
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

class WeeklyReviewBloc extends Bloc<WeeklyReviewEvent, WeeklyReviewState> {
  WeeklyReviewBloc({
    required AnalyticsService analyticsService,
    required AttentionEngineContract attentionEngine,
    required ValueRepositoryContract valueRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required ValueRatingsWriteService valueRatingsWriteService,
    required RoutineRepositoryContract routineRepository,
    required SettingsRepositoryContract settingsRepository,
    required TaskRepositoryContract taskRepository,
    required NowService nowService,
  }) : _analyticsService = analyticsService,
       _attentionEngine = attentionEngine,
       _valueRepository = valueRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _valueRatingsWriteService = valueRatingsWriteService,
       _routineRepository = routineRepository,
       _settingsRepository = settingsRepository,
       _taskRepository = taskRepository,
       _nowService = nowService,
       super(const WeeklyReviewState()) {
    on<WeeklyReviewRequested>(_onRequested, transformer: restartable());
    on<WeeklyReviewValueSelected>(_onValueSelected);
    on<WeeklyReviewValueRatingChanged>(_onValueRatingChanged);
  }

  final AnalyticsService _analyticsService;
  final AttentionEngineContract _attentionEngine;
  final ValueRepositoryContract _valueRepository;
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final ValueRatingsWriteService _valueRatingsWriteService;
  final RoutineRepositoryContract _routineRepository;
  final SettingsRepositoryContract _settingsRepository;
  final TaskRepositoryContract _taskRepository;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  static const int _ratingsHistoryWeeks = 8;
  static const int _ratingsGraceWeeks = 2;
  static const int _ratingsMax = 8;

  Future<void> _onRequested(
    WeeklyReviewRequested event,
    Emitter<WeeklyReviewState> emit,
  ) async {
    final config = event.config;

    emit(state.copyWith(status: WeeklyReviewStatus.loading));

    try {
      final allocationConfig = await _settingsRepository.load(
        SettingsKey.allocation,
      );
      final ratingsEnabled =
          allocationConfig.suggestionSignal == SuggestionSignal.ratingsBased;

      final ratingsSummary = ratingsEnabled
          ? await _buildRatingsSummary(
              config: config,
            )
          : null;

      final shouldShowValuesSummary =
          config.valuesSummaryEnabled && !ratingsEnabled;
      final summary = shouldShowValuesSummary
          ? await _buildValuesSummary(config)
          : null;
      final wins = shouldShowValuesSummary
          ? await _buildValueWins(config)
          : const <WeeklyReviewValueWin>[];

      if (emit.isDone) return;

      final initialSections = config.maintenanceEnabled
          ? await _buildInitialMaintenanceSections(config)
          : _emptyMaintenanceSections(config);

      emit(
        state.copyWith(
          status: WeeklyReviewStatus.ready,
          ratingsSummary: ratingsSummary,
          valuesSummary: summary,
          valueWins: wins,
          maintenanceSections: initialSections,
          errorMessage: null,
        ),
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
          errorMessage: '$error',
        ),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: WeeklyReviewStatus.failure,
          errorMessage: '$e',
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

  Future<WeeklyReviewRatingsSummary> _buildRatingsSummary({
    required WeeklyReviewConfig config,
  }) async {
    final values = await _valueRepository.getAll();
    final nowUtc = _nowService.nowUtc();
    final weekStartUtc = _weekStartFor(nowUtc);

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
    final historyByValue = <String, List<ValueWeeklyRating>>{};
    for (final rating in history) {
      (historyByValue[rating.valueId] ??= []).add(rating);
    }
    for (final entry in historyByValue.entries) {
      entry.value.sort((a, b) => b.weekStartUtc.compareTo(a.weekStartUtc));
    }

    final windowWeeks = config.valuesWindowWeeks.clamp(1, 12);
    final days = windowWeeks * 7;

    final taskCompletions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );
    final valueTrends = await _analyticsService.getValueWeeklyTrends(
      weeks: windowWeeks,
    );

    final routines = await _routineRepository.getAll(includeInactive: true);
    final routineById = {for (final routine in routines) routine.id: routine};
    final routineCompletions = await _routineRepository.getCompletions();
    final startDay = dateOnly(nowUtc).subtract(Duration(days: days - 1));
    final endDay = dateOnly(nowUtc);

    final routineCounts = <String, int>{};
    for (final completion in routineCompletions) {
      final routine = routineById[completion.routineId];
      if (routine == null) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
      routineCounts[routine.valueId] =
          (routineCounts[routine.valueId] ?? 0) + 1;
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
          trend: valueTrends[value.id] ?? const <double>[],
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

  Future<WeeklyReviewValuesSummary> _buildValuesSummary(
    WeeklyReviewConfig config,
  ) async {
    final values = await _valueRepository.getAll();
    if (values.isEmpty) {
      return const WeeklyReviewValuesSummary(
        rings: [],
        topValueName: null,
        bottomValueName: null,
        hasData: false,
      );
    }

    final weeks = config.valuesWindowWeeks.clamp(1, 12);
    final days = weeks * 7;
    final completions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );

    final total = completions.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const WeeklyReviewValuesSummary(
        rings: [],
        topValueName: null,
        bottomValueName: null,
        hasData: false,
      );
    }

    final entries =
        values
            .map((value) {
              final count = completions[value.id] ?? 0;
              final percent = total == 0 ? 0.0 : count / total * 100;
              return WeeklyReviewValueRing(
                value: value,
                percent: percent,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.percent.compareTo(a.percent));

    final topValue = entries.isEmpty ? null : entries.first.value.name;
    final bottomValue = entries.isEmpty ? null : entries.last.value.name;
    final rings = entries.take(5).toList(growable: false);

    return WeeklyReviewValuesSummary(
      rings: rings,
      topValueName: topValue,
      bottomValueName: bottomValue,
      hasData: true,
    );
  }

  Future<List<WeeklyReviewValueWin>> _buildValueWins(
    WeeklyReviewConfig config,
  ) async {
    final values = await _valueRepository.getAll();
    if (values.isEmpty) return const <WeeklyReviewValueWin>[];

    final weeks = config.valuesWindowWeeks.clamp(1, 12);
    final days = weeks * 7;
    final completions = await _analyticsService.getRecentCompletionsByValue(
      days: days,
    );

    if (completions.isEmpty) return const <WeeklyReviewValueWin>[];

    final valueById = {for (final v in values) v.id: v};

    final ranked = completions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = config.valueWinsCount.clamp(1, 5);

    return ranked
        .where((entry) => entry.value > 0)
        .take(maxCount)
        .map((entry) {
          final valueName = valueById[entry.key]?.name ?? 'Value';
          return WeeklyReviewValueWin(
            valueName: valueName,
            completionCount: entry.value,
          );
        })
        .toList(growable: false);
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
          id: 'deadline-risk',
          title: 'Deadline Risk',
          emptyMessage: 'No deadline risks this week.',
          items: riskItems.map(_mapDeadlineRiskItem).toList(growable: false),
        ),
      );
    }

    if (config.showDueSoonUnderControl) {
      sections.add(
        const WeeklyReviewMaintenanceSection(
          id: 'due-soon-under-control',
          title: 'Due Soon (Under Control)',
          emptyMessage: 'No upcoming projects need a check-in.',
          items: [],
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
          id: 'stale-items',
          title: 'Stale Tasks & Projects',
          emptyMessage: 'No stale items right now.',
          items: staleItems
              .map((item) => _mapStaleItem(item, config))
              .toList(growable: false),
        ),
      );
    }

    if (config.showMissingNextActions) {
      final missingItems = items.where(
        (i) => i.ruleKey == 'problem_project_missing_next_actions',
      );
      sections.add(
        WeeklyReviewMaintenanceSection(
          id: 'missing-next-actions',
          title: 'Missing Next Actions',
          emptyMessage: 'No projects are missing next actions.',
          items: missingItems
              .map(_mapMissingNextActionsItem)
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
          (section) => section.id == 'frequently-snoozed' && snoozed != null
              ? snoozed
              : section,
        )
        .toList(growable: false);
  }

  WeeklyReviewMaintenanceSection _buildFrequentSnoozedSection(
    List<WeeklyReviewMaintenanceSection> currentSections,
  ) {
    final existing = currentSections.firstWhere(
      (section) => section.id == 'frequently-snoozed',
      orElse: () => const WeeklyReviewMaintenanceSection(
        id: 'frequently-snoozed',
        title: 'Frequently Snoozed',
        emptyMessage: 'No items are stuck in a snooze loop.',
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
        id: 'frequently-snoozed',
        title: 'Frequently Snoozed',
        emptyMessage: 'No items are stuck in a snooze loop.',
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
        id: 'frequently-snoozed',
        title: 'Frequently Snoozed',
        emptyMessage: 'No items are stuck in a snooze loop.',
        items: [],
      );
    }

    final tasks = await _taskRepository.getByIds(flaggedIds);
    final items = <WeeklyReviewMaintenanceItem>[];

    for (final task in tasks) {
      if (task.completed) continue;
      final stats = statsByTask[task.id];
      if (stats == null) continue;

      final countLabel = stats.snoozeCount == 1
          ? '1 snooze'
          : '${stats.snoozeCount} snoozes';
      final daysLabel = stats.totalSnoozeDays == 1
          ? '1 day'
          : '${stats.totalSnoozeDays} days';

      items.add(
        WeeklyReviewMaintenanceItem(
          title: task.name,
          description:
              'Snoozed $countLabel in the last 28 days ($daysLabel total).',
        ),
      );
    }

    return WeeklyReviewMaintenanceSection(
      id: 'frequently-snoozed',
      title: 'Frequently Snoozed',
      emptyMessage: 'No items are stuck in a snooze loop.',
      items: items,
    );
  }

  WeeklyReviewMaintenanceItem _mapDeadlineRiskItem(AttentionItem item) {
    final name =
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String? ??
        'Project';
    final dueInDays = item.metadata?['due_in_days'] as int?;
    final unscheduled = item.metadata?['unscheduled_tasks_count'] as int? ?? 0;

    final dueLabel = switch (dueInDays) {
      null => 'due soon',
      0 => 'due today',
      1 => 'due tomorrow',
      < 0 => 'overdue by ${dueInDays.abs()} days',
      _ => 'due in $dueInDays days',
    };

    return WeeklyReviewMaintenanceItem(
      title: name,
      description: 'Project is $dueLabel with $unscheduled unscheduled tasks.',
    );
  }

  WeeklyReviewMaintenanceItem _mapStaleItem(
    AttentionItem item,
    WeeklyReviewConfig config,
  ) {
    final name =
        item.metadata?['task_name'] as String? ??
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String? ??
        'Item';

    final thresholdDays = item.ruleKey == 'problem_task_stale'
        ? config.taskStaleThresholdDays
        : config.projectIdleThresholdDays;

    return WeeklyReviewMaintenanceItem(
      title: name,
      description: 'No activity in $thresholdDays days.',
    );
  }

  WeeklyReviewMaintenanceItem _mapMissingNextActionsItem(AttentionItem item) {
    final name =
        item.metadata?['project_name'] as String? ??
        item.metadata?['entity_display_name'] as String? ??
        'Project';

    return WeeklyReviewMaintenanceItem(
      title: name,
      description: item.description,
    );
  }

  List<WeeklyReviewMaintenanceSection> _emptyMaintenanceSections(
    WeeklyReviewConfig config,
  ) {
    return _buildMaintenanceSections(const [], config);
  }
}
