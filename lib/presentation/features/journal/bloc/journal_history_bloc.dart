import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

const Object _unset = Object();

sealed class JournalHistoryEvent {
  const JournalHistoryEvent();
}

final class JournalHistoryStarted extends JournalHistoryEvent {
  const JournalHistoryStarted();
}

final class JournalHistoryFiltersChanged extends JournalHistoryEvent {
  const JournalHistoryFiltersChanged(this.filters);

  final JournalHistoryFilters filters;
}

final class JournalHistoryLoadMoreRequested extends JournalHistoryEvent {
  const JournalHistoryLoadMoreRequested();
}

final class JournalHistoryDensityToggled extends JournalHistoryEvent {
  const JournalHistoryDensityToggled();
}

final class JournalHistoryStarterPackDismissed extends JournalHistoryEvent {
  const JournalHistoryStarterPackDismissed();
}

final class JournalHistoryStarterPackApplied extends JournalHistoryEvent {
  const JournalHistoryStarterPackApplied(this.selectedIds);

  final Set<String> selectedIds;
}

final class JournalHistoryDayTrackersPreferencesChanged
    extends JournalHistoryEvent {
  const JournalHistoryDayTrackersPreferencesChanged({
    required this.orderedTrackerIds,
    required this.hiddenTrackerIds,
  });

  final List<String> orderedTrackerIds;
  final Set<String> hiddenTrackerIds;
}

final class JournalHistorySummaryPreferencesChanged
    extends JournalHistoryEvent {
  const JournalHistorySummaryPreferencesChanged({
    required this.hiddenTrackerIds,
  });

  final Set<String> hiddenTrackerIds;
}

final class JournalHistoryDayTrackerQuickValueSaved
    extends JournalHistoryEvent {
  const JournalHistoryDayTrackerQuickValueSaved({
    required this.day,
    required this.trackerId,
    required this.value,
  });

  final DateTime day;
  final String trackerId;
  final Object? value;
}

final class JournalHistoryDayTrackerQuickDeltaAdded
    extends JournalHistoryEvent {
  const JournalHistoryDayTrackerQuickDeltaAdded({
    required this.day,
    required this.trackerId,
    required this.delta,
  });

  final DateTime day;
  final String trackerId;
  final num delta;
}

final class JournalHistoryDayTrackerGoalChanged extends JournalHistoryEvent {
  const JournalHistoryDayTrackerGoalChanged({
    required this.trackerId,
    required this.target,
    required this.unitKey,
  });

  final String trackerId;
  final num? target;
  final String? unitKey;
}

sealed class JournalHistoryState {
  const JournalHistoryState();
}

final class JournalHistoryLoading extends JournalHistoryState {
  const JournalHistoryLoading(this.filters);

  final JournalHistoryFilters filters;
}

final class JournalHistoryLoaded extends JournalHistoryState {
  const JournalHistoryLoaded({
    required this.days,
    required this.filters,
    required this.showStarterPack,
    required this.starterOptions,
    required this.density,
    required this.factorDefinitions,
    required this.factorGroups,
    required this.topInsight,
    required this.insights,
    required this.showInsightsNudge,
    required this.dayTrackerDefinitions,
    required this.dayTrackerOrderIds,
    required this.hiddenDayTrackerIds,
    required this.coreDayTrackerIds,
    required this.hiddenSummaryTrackerIds,
  });

  final List<JournalHistoryDaySummary> days;
  final JournalHistoryFilters filters;
  final bool showStarterPack;
  final List<JournalStarterOption> starterOptions;
  final DisplayDensity density;
  final List<TrackerDefinition> factorDefinitions;
  final List<TrackerGroup> factorGroups;
  final JournalTopInsight? topInsight;
  final List<JournalTopInsight> insights;
  final bool showInsightsNudge;
  final List<TrackerDefinition> dayTrackerDefinitions;
  final List<String> dayTrackerOrderIds;
  final Set<String> hiddenDayTrackerIds;
  final List<String> coreDayTrackerIds;
  final Set<String> hiddenSummaryTrackerIds;
}

final class JournalHistoryError extends JournalHistoryState {
  const JournalHistoryError(this.message, this.filters);

  final String message;
  final JournalHistoryFilters filters;
}

class JournalHistoryBloc
    extends Bloc<JournalHistoryEvent, JournalHistoryState> {
  JournalHistoryBloc({
    required JournalRepositoryContract repository,
    required HomeDayKeyService dayKeyService,
    required SettingsRepositoryContract settingsRepository,
    required DateTime Function() nowUtc,
    JournalHistoryFilters? initialFiltersOverride,
    bool persistFilters = true,
  }) : _repository = repository,
       _dayKeyService = dayKeyService,
       _settingsRepository = settingsRepository,
       _nowUtc = nowUtc,
       _initialFiltersOverride = initialFiltersOverride,
       _persistFilters = persistFilters,
       super(JournalHistoryLoading(JournalHistoryFilters.initial())) {
    on<JournalHistoryStarted>(_onStarted, transformer: restartable());
    on<JournalHistoryFiltersChanged>(
      _onFiltersChanged,
      transformer: restartable(),
    );
    on<JournalHistoryLoadMoreRequested>(
      _onLoadMoreRequested,
      transformer: droppable(),
    );
    on<JournalHistoryDensityToggled>(
      _onDensityToggled,
      transformer: sequential(),
    );
    on<JournalHistoryStarterPackDismissed>(
      _onStarterPackDismissed,
      transformer: sequential(),
    );
    on<JournalHistoryStarterPackApplied>(
      _onStarterPackApplied,
      transformer: sequential(),
    );
    on<JournalHistoryDayTrackersPreferencesChanged>(
      _onDayTrackersPreferencesChanged,
      transformer: sequential(),
    );
    on<JournalHistoryDayTrackerQuickValueSaved>(
      _onDayTrackerQuickValueSaved,
      transformer: sequential(),
    );
    on<JournalHistoryDayTrackerQuickDeltaAdded>(
      _onDayTrackerQuickDeltaAdded,
      transformer: sequential(),
    );
    on<JournalHistoryDayTrackerGoalChanged>(
      _onDayTrackerGoalChanged,
      transformer: sequential(),
    );
    on<JournalHistorySummaryPreferencesChanged>(
      _onSummaryPreferencesChanged,
      transformer: sequential(),
    );
  }

  static const int _windowStepDays = 30;
  static const int _maxLookbackDays = 3650;
  static const String _starterPackSeenKey = 'journal_starter_pack_start_01b';
  static const PageKey _journalPageKey = PageKey.journal;

  final JournalRepositoryContract _repository;
  final HomeDayKeyService _dayKeyService;
  final SettingsRepositoryContract _settingsRepository;
  final DateTime Function() _nowUtc;
  final JournalHistoryFilters? _initialFiltersOverride;
  final bool _persistFilters;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();
  bool _starterPackSeen = false;
  DisplayDensity _density = DisplayDensity.compact;
  JournalHistoryFilterPreferences? _savedFilterPreferences;
  List<String> _dayTrackerOrderIds = <String>[];
  Set<String> _hiddenDayTrackerIds = <String>{};
  Set<String> _hiddenSummaryTrackerIds = <String>{};

  static const List<JournalStarterOption> _starterOptions =
      <JournalStarterOption>[
        JournalStarterOption(
          id: 'stress',
          category: 'Essentials',
          name: 'Stress',
          scope: 'entry',
          valueType: 'rating',
          valueKind: 'rating',
          iconName: 'health',
          defaultSelected: true,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
        ),
        JournalStarterOption(
          id: 'sleep_quality',
          category: 'Essentials',
          name: 'Sleep quality',
          scope: 'entry',
          valueType: 'rating',
          valueKind: 'rating',
          iconName: 'bedtime',
          defaultSelected: true,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
        ),
        JournalStarterOption(
          id: 'sleep_duration',
          category: 'Essentials',
          name: 'Sleep duration',
          scope: 'entry',
          valueType: 'quantity',
          valueKind: 'number',
          iconName: 'bedtime',
          defaultSelected: true,
          minInt: 0,
          maxInt: 24,
          stepInt: 1,
          unitKind: 'hours',
          opKind: 'set',
        ),
        JournalStarterOption(
          id: 'exercise',
          category: 'Essentials',
          name: 'Exercise',
          scope: 'day',
          valueType: 'yes_no',
          valueKind: 'boolean',
          iconName: 'fitness_center',
          defaultSelected: true,
        ),
        JournalStarterOption(
          id: 'water_intake',
          category: 'Essentials',
          name: 'Water intake',
          scope: 'day',
          valueType: 'quantity',
          valueKind: 'number',
          iconName: 'water_drop',
          defaultSelected: true,
          minInt: 0,
          maxInt: 5000,
          stepInt: 250,
          unitKind: 'ml',
          opKind: 'add',
        ),
        JournalStarterOption(
          id: 'social_time',
          category: 'Optional',
          name: 'Social time',
          scope: 'day',
          valueType: 'choice',
          valueKind: 'single_choice',
          iconName: 'group',
          defaultSelected: false,
          choices: <String>['None', 'Low', 'Medium', 'High'],
        ),
        JournalStarterOption(
          id: 'energy',
          category: 'Optional',
          name: 'Energy',
          scope: 'entry',
          valueType: 'rating',
          valueKind: 'rating',
          iconName: 'bolt',
          defaultSelected: true,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
        ),
        JournalStarterOption(
          id: 'running',
          category: 'Hobbies',
          name: 'Running',
          scope: 'day',
          valueType: 'yes_no',
          valueKind: 'boolean',
          iconName: 'directions_run',
          defaultSelected: false,
        ),
        JournalStarterOption(
          id: 'guitar_practice',
          category: 'Hobbies',
          name: 'Guitar practice',
          scope: 'day',
          valueType: 'quantity',
          valueKind: 'number',
          iconName: 'music_note',
          defaultSelected: false,
          minInt: 0,
          maxInt: 180,
          stepInt: 15,
          unitKind: 'minutes',
          opKind: 'add',
        ),
        JournalStarterOption(
          id: 'reading',
          category: 'Hobbies',
          name: 'Reading',
          scope: 'day',
          valueType: 'quantity',
          valueKind: 'number',
          iconName: 'menu_book',
          defaultSelected: false,
          minInt: 0,
          maxInt: 180,
          stepInt: 15,
          unitKind: 'minutes',
          opKind: 'add',
        ),
        JournalStarterOption(
          id: 'cooking',
          category: 'Hobbies',
          name: 'Cooking',
          scope: 'day',
          valueType: 'yes_no',
          valueKind: 'boolean',
          iconName: 'restaurant',
          defaultSelected: false,
        ),
        JournalStarterOption(
          id: 'gaming',
          category: 'Hobbies',
          name: 'Gaming',
          scope: 'day',
          valueType: 'quantity',
          valueKind: 'number',
          iconName: 'sports_esports',
          defaultSelected: false,
          minInt: 0,
          maxInt: 240,
          stepInt: 30,
          unitKind: 'minutes',
          opKind: 'add',
        ),
      ];

  Future<void> _onStarted(
    JournalHistoryStarted event,
    Emitter<JournalHistoryState> emit,
  ) async {
    _starterPackSeen = await _settingsRepository.load(
      SettingsKey.microLearningSeen(_starterPackSeenKey),
    );
    final displayPrefs = await _settingsRepository.load(
      SettingsKey.pageDisplay(_journalPageKey),
    );
    _density = displayPrefs?.density ?? DisplayDensity.compact;
    _savedFilterPreferences = await _settingsRepository.load(
      SettingsKey.pageJournalFilters(_journalPageKey),
    );
    _dayTrackerOrderIds = List<String>.from(
      _savedFilterPreferences?.dayTrackerOrderIds ?? const <String>[],
    );
    _hiddenDayTrackerIds = <String>{
      ...?_savedFilterPreferences?.hiddenDayTrackerIds,
    };
    _hiddenSummaryTrackerIds = <String>{
      ...?_savedFilterPreferences?.hiddenSummaryTrackerIds,
    };
    final preferenceFilters = _filtersFromPreferences(_savedFilterPreferences);
    final initialFilters =
        _initialFiltersOverride ??
        (_persistFilters ? preferenceFilters : JournalHistoryFilters.initial());
    await _onFiltersChanged(
      JournalHistoryFiltersChanged(initialFilters),
      emit,
    );
  }

  Future<void> _onFiltersChanged(
    JournalHistoryFiltersChanged event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final filters = event.filters;
    await _persistFiltersPreferences(filters);
    if (state is! JournalHistoryLoaded) {
      emit(JournalHistoryLoading(filters));
    }

    final todayDayKeyUtc = _dayKeyService.todayDayKeyUtc();
    final range = _buildDateRange(filters, todayDayKeyUtc: todayDayKeyUtc);
    final endInclusive = range.end
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    final defs$ = _repository.watchTrackerDefinitions();
    final groups$ = _repository.watchTrackerGroups();
    final entries$ = _repository.watchJournalEntriesByQuery(
      _buildQuery(filters, todayDayKeyUtc: todayDayKeyUtc),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: range.start, end: endInclusive),
    );

    await emit.onEach<JournalHistoryLoaded>(
      Rx.combineLatest4<
            List<TrackerDefinition>,
            List<TrackerGroup>,
            List<JournalEntry>,
            List<TrackerEvent>,
            ({
              List<TrackerDefinition> defs,
              List<TrackerGroup> groups,
              List<JournalEntry> entries,
              List<TrackerEvent> events,
            })
          >(
            defs$,
            groups$,
            entries$,
            events$,
            (defs, groups, entries, events) => (
              defs: defs,
              groups: groups,
              entries: entries,
              events: events,
            ),
          )
          .asyncMap((payload) async {
            final choiceLabelsByTrackerId = await _buildChoiceLabelsByTrackerId(
              payload.defs,
            );
            var days = _buildDaySummaries(
              defs: payload.defs,
              entries: payload.entries,
              events: payload.events,
              choiceLabelsByTrackerId: choiceLabelsByTrackerId,
            );
            days = _applyFactorFilters(days: days, filters: filters);

            final hasCustomTracker = payload.defs.any(
              (d) => d.isActive && d.deletedAt == null && d.systemKey == null,
            );
            final showStarterPack = !_starterPackSeen && !hasCustomTracker;
            final factorDefinitions =
                payload.defs
                    .where(
                      (d) =>
                          d.isActive && d.deletedAt == null && _isUserFactor(d),
                    )
                    .toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            final factorGroups =
                payload.groups.where((g) => g.isActive).toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            final insights = _buildInsights(days: days);
            final topInsight = insights.isEmpty ? null : insights.first;
            final dayTrackerDefinitions = _buildDayTrackerDefinitions(
              payload.defs,
            );
            final coreDayTrackerIds = _resolveCoreDayTrackerIds(
              dayTrackerDefinitions,
            );
            final normalizedOrderIds = _normalizeDayTrackerOrder(
              definitions: dayTrackerDefinitions,
              preferredOrderIds: _dayTrackerOrderIds,
              coreTrackerIds: coreDayTrackerIds,
            );
            final normalizedHiddenIds = _normalizeHiddenDayTrackerIds(
              hiddenIds: _hiddenDayTrackerIds,
              definitions: dayTrackerDefinitions,
            );
            _dayTrackerOrderIds = normalizedOrderIds;
            _hiddenDayTrackerIds = normalizedHiddenIds;

            return JournalHistoryLoaded(
              days: days,
              filters: filters,
              showStarterPack: showStarterPack,
              starterOptions: _starterOptions,
              density: _density,
              factorDefinitions: factorDefinitions,
              factorGroups: factorGroups,
              topInsight: topInsight,
              insights: insights,
              showInsightsNudge: topInsight == null,
              dayTrackerDefinitions: dayTrackerDefinitions,
              dayTrackerOrderIds: normalizedOrderIds,
              hiddenDayTrackerIds: normalizedHiddenIds,
              coreDayTrackerIds: coreDayTrackerIds,
              hiddenSummaryTrackerIds: _hiddenSummaryTrackerIds,
            );
          }),
      onData: emit.call,
      onError: (e, _) {
        emit(JournalHistoryError('Failed to load history: $e', filters));
      },
    );
  }

  Future<void> _onLoadMoreRequested(
    JournalHistoryLoadMoreRequested event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final currentFilters = switch (state) {
      JournalHistoryLoading(:final filters) => filters,
      JournalHistoryLoaded(:final filters) => filters,
      JournalHistoryError(:final filters) => filters,
    };

    if (currentFilters.rangeStart != null && currentFilters.rangeEnd != null) {
      return;
    }

    final nextLookbackDays = (currentFilters.lookbackDays + _windowStepDays)
        .clamp(_windowStepDays, _maxLookbackDays);
    if (nextLookbackDays == currentFilters.lookbackDays) return;

    add(
      JournalHistoryFiltersChanged(
        currentFilters.copyWith(lookbackDays: nextLookbackDays),
      ),
    );
  }

  Future<void> _onStarterPackDismissed(
    JournalHistoryStarterPackDismissed event,
    Emitter<JournalHistoryState> emit,
  ) async {
    await _markStarterPackSeen();
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    emit(
      JournalHistoryLoaded(
        days: current.days,
        filters: current.filters,
        showStarterPack: false,
        starterOptions: current.starterOptions,
        density: current.density,
        factorDefinitions: current.factorDefinitions,
        factorGroups: current.factorGroups,
        topInsight: current.topInsight,
        insights: current.insights,
        showInsightsNudge: current.showInsightsNudge,
        dayTrackerDefinitions: current.dayTrackerDefinitions,
        dayTrackerOrderIds: current.dayTrackerOrderIds,
        hiddenDayTrackerIds: current.hiddenDayTrackerIds,
        coreDayTrackerIds: current.coreDayTrackerIds,
        hiddenSummaryTrackerIds: current.hiddenSummaryTrackerIds,
      ),
    );
  }

  Future<void> _onDensityToggled(
    JournalHistoryDensityToggled event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    _density = current.density == DisplayDensity.compact
        ? DisplayDensity.standard
        : DisplayDensity.compact;
    await _settingsRepository.save<DisplayPreferences?>(
      SettingsKey.pageDisplay(_journalPageKey),
      DisplayPreferences(density: _density),
    );
    emit(
      JournalHistoryLoaded(
        days: current.days,
        filters: current.filters,
        showStarterPack: current.showStarterPack,
        starterOptions: current.starterOptions,
        density: _density,
        factorDefinitions: current.factorDefinitions,
        factorGroups: current.factorGroups,
        topInsight: current.topInsight,
        insights: current.insights,
        showInsightsNudge: current.showInsightsNudge,
        dayTrackerDefinitions: current.dayTrackerDefinitions,
        dayTrackerOrderIds: current.dayTrackerOrderIds,
        hiddenDayTrackerIds: current.hiddenDayTrackerIds,
        coreDayTrackerIds: current.coreDayTrackerIds,
        hiddenSummaryTrackerIds: current.hiddenSummaryTrackerIds,
      ),
    );
  }

  Future<void> _onDayTrackersPreferencesChanged(
    JournalHistoryDayTrackersPreferencesChanged event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    final normalizedOrderIds = _normalizeDayTrackerOrder(
      definitions: current.dayTrackerDefinitions,
      preferredOrderIds: event.orderedTrackerIds,
      coreTrackerIds: current.coreDayTrackerIds,
    );
    final normalizedHiddenIds = _normalizeHiddenDayTrackerIds(
      hiddenIds: event.hiddenTrackerIds,
      definitions: current.dayTrackerDefinitions,
    );
    _dayTrackerOrderIds = normalizedOrderIds;
    _hiddenDayTrackerIds = normalizedHiddenIds;
    await _persistFiltersPreferences(current.filters);
    emit(
      JournalHistoryLoaded(
        days: current.days,
        filters: current.filters,
        showStarterPack: current.showStarterPack,
        starterOptions: current.starterOptions,
        density: current.density,
        factorDefinitions: current.factorDefinitions,
        factorGroups: current.factorGroups,
        topInsight: current.topInsight,
        insights: current.insights,
        showInsightsNudge: current.showInsightsNudge,
        dayTrackerDefinitions: current.dayTrackerDefinitions,
        dayTrackerOrderIds: normalizedOrderIds,
        hiddenDayTrackerIds: normalizedHiddenIds,
        coreDayTrackerIds: current.coreDayTrackerIds,
        hiddenSummaryTrackerIds: current.hiddenSummaryTrackerIds,
      ),
    );
  }

  Future<void> _onSummaryPreferencesChanged(
    JournalHistorySummaryPreferencesChanged event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    _hiddenSummaryTrackerIds = {...event.hiddenTrackerIds};
    await _persistFiltersPreferences(current.filters);
    emit(
      JournalHistoryLoaded(
        days: current.days,
        filters: current.filters,
        showStarterPack: current.showStarterPack,
        starterOptions: current.starterOptions,
        density: current.density,
        factorDefinitions: current.factorDefinitions,
        factorGroups: current.factorGroups,
        topInsight: current.topInsight,
        insights: current.insights,
        showInsightsNudge: current.showInsightsNudge,
        dayTrackerDefinitions: current.dayTrackerDefinitions,
        dayTrackerOrderIds: current.dayTrackerOrderIds,
        hiddenDayTrackerIds: current.hiddenDayTrackerIds,
        coreDayTrackerIds: current.coreDayTrackerIds,
        hiddenSummaryTrackerIds: _hiddenSummaryTrackerIds,
      ),
    );
  }

  Future<void> _onDayTrackerQuickValueSaved(
    JournalHistoryDayTrackerQuickValueSaved event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    final trackerId = event.trackerId.trim();
    if (trackerId.isEmpty) return;
    TrackerDefinition? definition;
    for (final d in current.dayTrackerDefinitions) {
      if (d.id == trackerId) {
        definition = d;
        break;
      }
    }
    if (definition == null) return;
    final now = _nowUtc();
    final context = _contextFactory.create(
      feature: 'journal',
      screen: 'journal_hub',
      intent: 'quick_edit_day_tracker',
      operation: 'journal.appendTrackerEvent',
      entityType: 'tracker_event',
      entityId: trackerId,
      extraFields: <String, Object?>{
        'scope': definition.scope,
        'valueType': definition.valueType,
      },
    );
    final dayUtc = dateOnly(event.day.toUtc());
    final opKind = definition.opKind.trim();
    await _repository.appendTrackerEvent(
      TrackerEvent(
        id: '',
        trackerId: trackerId,
        anchorType: 'day',
        anchorDate: dayUtc,
        op: opKind.isEmpty ? 'set' : opKind,
        value: event.value,
        occurredAt: now,
        recordedAt: now,
      ),
      context: context,
    );
  }

  Future<void> _onDayTrackerQuickDeltaAdded(
    JournalHistoryDayTrackerQuickDeltaAdded event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    final trackerId = event.trackerId.trim();
    if (trackerId.isEmpty) return;
    TrackerDefinition? definition;
    for (final d in current.dayTrackerDefinitions) {
      if (d.id == trackerId) {
        definition = d;
        break;
      }
    }
    if (definition == null) return;
    final now = _nowUtc();
    final context = _contextFactory.create(
      feature: 'journal',
      screen: 'journal_hub',
      intent: 'quick_edit_day_tracker_delta',
      operation: 'journal.appendTrackerEvent',
      entityType: 'tracker_event',
      entityId: trackerId,
      extraFields: <String, Object?>{
        'scope': definition.scope,
        'valueType': definition.valueType,
        'delta': event.delta,
      },
    );
    final dayUtc = dateOnly(event.day.toUtc());
    await _repository.appendTrackerEvent(
      TrackerEvent(
        id: '',
        trackerId: trackerId,
        anchorType: 'day',
        anchorDate: dayUtc,
        op: 'add',
        value: event.delta,
        occurredAt: now,
        recordedAt: now,
      ),
      context: context,
    );
  }

  Future<void> _onDayTrackerGoalChanged(
    JournalHistoryDayTrackerGoalChanged event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final current = state;
    if (current is! JournalHistoryLoaded) return;
    final trackerId = event.trackerId.trim();
    if (trackerId.isEmpty) return;
    TrackerDefinition? definition;
    for (final d in current.dayTrackerDefinitions) {
      if (d.id == trackerId) {
        definition = d;
        break;
      }
    }
    if (definition == null) return;
    final now = _nowUtc();
    final context = _contextFactory.create(
      feature: 'journal',
      screen: 'journal_hub',
      intent: 'update_day_tracker_goal',
      operation: 'journal.saveTrackerDefinition',
      entityType: 'tracker_definition',
      entityId: trackerId,
    );

    final goal = event.target == null
        ? const <String, dynamic>{}
        : <String, dynamic>{
            'target': event.target,
            if ((event.unitKey ?? '').trim().isNotEmpty)
              'unitKey': event.unitKey!.trim().toLowerCase(),
          };

    await _repository.saveTrackerDefinition(
      definition.copyWith(
        goal: goal,
        updatedAt: now,
      ),
      context: context,
    );
  }

  Future<List<TrackerDefinitionChoice>> getChoices(String trackerId) async {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return const <TrackerDefinitionChoice>[];
    final all = await _repository
        .watchTrackerDefinitionChoices(trackerId: trimmed)
        .first;
    return all.where((choice) => choice.isActive).toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> _onStarterPackApplied(
    JournalHistoryStarterPackApplied event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final selected = _starterOptions
        .where((opt) => event.selectedIds.contains(opt.id))
        .toList(growable: false);
    if (selected.isEmpty) {
      await _onStarterPackDismissed(
        const JournalHistoryStarterPackDismissed(),
        emit,
      );
      return;
    }

    final defs = await _repository.watchTrackerDefinitions().first;
    final existingByName = {
      for (final d in defs)
        if (d.deletedAt == null) d.name.trim().toLowerCase(): d,
    };
    final groups = await _repository.watchTrackerGroups().first;
    final groupByName = {
      for (final g in groups)
        if (g.isActive) g.name.trim().toLowerCase(): g,
    };
    final now = _nowUtc();
    final context = _contextFactory.create(
      feature: 'journal',
      screen: 'journal_hub',
      intent: 'apply_starter_pack',
      operation: 'journal.saveTrackerDefinition',
      entityType: 'tracker_definition',
      extraFields: <String, Object?>{'count': selected.length},
    );

    String? hobbiesGroupId;
    if (selected.any((o) => o.category == 'Hobbies')) {
      final existingHobbies = groupByName['hobbies'];
      if (existingHobbies != null) {
        hobbiesGroupId = existingHobbies.id;
      } else {
        await _repository.saveTrackerGroup(
          TrackerGroup(
            id: '',
            name: 'Hobbies',
            sortOrder: 500,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            userId: null,
          ),
          context: context,
        );
        final refreshedGroups = await _repository.watchTrackerGroups().first;
        for (final g in refreshedGroups) {
          if (g.isActive && g.name.trim().toLowerCase() == 'hobbies') {
            hobbiesGroupId = g.id;
            break;
          }
        }
      }
    }

    for (final option in selected) {
      final existing = existingByName[option.name.trim().toLowerCase()];
      if (existing != null) continue;

      String? groupId;
      if (option.category == 'Hobbies') {
        groupId = hobbiesGroupId;
      }

      final definition = TrackerDefinition(
        id: '',
        name: option.name,
        scope: option.scope,
        valueType: option.valueType,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        sortOrder: 1000 + selected.indexOf(option) * 10,
        groupId: groupId,
        source: 'user',
        opKind:
            option.opKind ?? (option.valueType == 'quantity' ? 'add' : 'set'),
        valueKind: option.valueKind,
        minInt: option.minInt,
        maxInt: option.maxInt,
        stepInt: option.stepInt,
        unitKind: option.unitKind,
        config: <String, dynamic>{'iconName': option.iconName},
      );
      await _repository.saveTrackerDefinition(definition, context: context);
    }

    for (final option in selected.where((opt) => opt.choices.isNotEmpty)) {
      final savedDefs = await _repository.watchTrackerDefinitions().first;
      final def = savedDefs.firstWhere(
        (d) => d.name == option.name && d.deletedAt == null,
        orElse: () =>
            throw StateError('Missing starter tracker ${option.name}'),
      );
      for (var i = 0; i < option.choices.length; i++) {
        final label = option.choices[i];
        await _repository.saveTrackerDefinitionChoice(
          TrackerDefinitionChoice(
            id: '',
            trackerId: def.id,
            choiceKey: label.toLowerCase(),
            label: label,
            sortOrder: i * 10,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            userId: null,
          ),
          context: context,
        );
      }
    }

    await _onStarterPackDismissed(
      const JournalHistoryStarterPackDismissed(),
      emit,
    );
  }

  Future<void> _markStarterPackSeen() async {
    if (_starterPackSeen) return;
    _starterPackSeen = true;
    await _settingsRepository.save(
      SettingsKey.microLearningSeen(_starterPackSeenKey),
      true,
    );
  }

  JournalQuery _buildQuery(
    JournalHistoryFilters filters, {
    required DateTime todayDayKeyUtc,
  }) {
    final predicates = <JournalPredicate>[];

    final search = filters.searchText.trim();
    if (search.isNotEmpty) {
      predicates.add(
        JournalTextPredicate(
          operator: TextOperator.contains,
          value: search,
        ),
      );
    }

    final rangeStart = filters.rangeStart;
    final rangeEnd = filters.rangeEnd;
    if (rangeStart != null && rangeEnd != null) {
      final startUtc = dateOnly(rangeStart);
      final endInclusive = dateOnly(
        rangeEnd,
      ).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      predicates.add(
        JournalDatePredicate(
          operator: DateOperator.between,
          startDate: startUtc,
          endDate: endInclusive,
        ),
      );
    } else {
      predicates.add(
        JournalDatePredicate(
          operator: DateOperator.onOrAfter,
          date: todayDayKeyUtc.subtract(
            Duration(days: filters.lookbackDays - 1),
          ),
        ),
      );
    }

    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(shared: predicates),
    );
  }

  DateRange _buildDateRange(
    JournalHistoryFilters filters, {
    required DateTime todayDayKeyUtc,
  }) {
    final rangeStart = filters.rangeStart;
    final rangeEnd = filters.rangeEnd;
    if (rangeStart == null || rangeEnd == null) {
      final startUtc = todayDayKeyUtc.subtract(
        Duration(days: filters.lookbackDays - 1),
      );
      return DateRange(start: startUtc, end: todayDayKeyUtc);
    }
    return DateRange(
      start: dateOnly(rangeStart),
      end: dateOnly(rangeEnd),
    );
  }

  List<JournalHistoryDaySummary> _buildDaySummaries({
    required List<TrackerDefinition> defs,
    required List<JournalEntry> entries,
    required List<TrackerEvent> events,
    required Map<String, Map<String, String>> choiceLabelsByTrackerId,
  }) {
    final definitionById = {for (final d in defs) d.id: d};
    final moodTrackerId = _findMoodTrackerId(defs);

    final entriesByDay = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = dateOnly(entry.entryDate.toUtc());
      (entriesByDay[day] ??= <JournalEntry>[]).add(entry);
    }
    for (final dayEntries in entriesByDay.values) {
      dayEntries.sort((a, b) => b.entryTime.compareTo(a.entryTime));
    }

    final eventsByEntryId = <String, List<TrackerEvent>>{};
    final latestEventByDayTracker = <DateTime, Map<String, TrackerEvent>>{};
    final moodValuesByDay = <DateTime, List<int>>{};
    final quantityTotalsByDayTracker = <DateTime, Map<String, double>>{};
    final daysWithEvents = <DateTime>{};
    for (final event in events) {
      final entryId = event.entryId;
      if (entryId != null) {
        (eventsByEntryId[entryId] ??= <TrackerEvent>[]).add(event);
      }

      final day = dateOnly(event.occurredAt.toUtc());
      daysWithEvents.add(day);
      final latestByTracker = latestEventByDayTracker[day] ??=
          <String, TrackerEvent>{};
      final previousByTracker = latestByTracker[event.trackerId];
      if (previousByTracker == null ||
          previousByTracker.occurredAt.isBefore(event.occurredAt)) {
        latestByTracker[event.trackerId] = event;
      }
      final def = definitionById[event.trackerId];
      if (def != null && _isQuantityDefinition(def)) {
        final amount = switch (event.value) {
          final int v => v.toDouble(),
          final double v => v,
          _ => null,
        };
        if (amount != null) {
          final totalsByTracker = quantityTotalsByDayTracker[day] ??=
              <String, double>{};
          totalsByTracker[event.trackerId] =
              (totalsByTracker[event.trackerId] ?? 0) + amount;
        }
      }

      if (moodTrackerId == null || event.trackerId != moodTrackerId) continue;
      if (event.value is! int) continue;
      (moodValuesByDay[day] ??= <int>[]).add(event.value! as int);
    }

    final allDays = <DateTime>{
      ...entriesByDay.keys,
      ...daysWithEvents,
    };
    final days = allDays.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final day in days)
        () {
          final dayEntries = entriesByDay[day] ?? const <JournalEntry>[];
          final factorTrackerIds = <String>{};
          final latestByTracker =
              latestEventByDayTracker[day] ?? const <String, TrackerEvent>{};
          for (final trackerId in latestByTracker.keys) {
            if (trackerId == moodTrackerId) continue;
            factorTrackerIds.add(trackerId);
          }
          return JournalHistoryDaySummary(
            day: day,
            entries: dayEntries,
            eventsByEntryId: eventsByEntryId,
            latestEventByTrackerId: latestByTracker,
            definitionById: definitionById,
            moodTrackerId: moodTrackerId,
            moodAverage: _average(moodValuesByDay[day]),
            dayQuantityTotalsByTrackerId:
                quantityTotalsByDayTracker[day] ?? const <String, double>{},
            factorTrackerIds: factorTrackerIds,
            choiceLabelsByTrackerId: choiceLabelsByTrackerId,
          );
        }(),
    ];
  }

  Future<Map<String, Map<String, String>>> _buildChoiceLabelsByTrackerId(
    List<TrackerDefinition> definitions,
  ) async {
    final choiceDefs = definitions
        .where((definition) {
          final type = definition.valueType.trim().toLowerCase();
          return type == 'choice' || type == 'single_choice';
        })
        .toList(growable: false);
    if (choiceDefs.isEmpty) return const <String, Map<String, String>>{};

    final results = await Future.wait(
      choiceDefs.map((definition) => getChoices(definition.id)),
    );

    final map = <String, Map<String, String>>{};
    for (var i = 0; i < choiceDefs.length; i++) {
      final definition = choiceDefs[i];
      final labels = <String, String>{};
      for (final choice in results[i]) {
        labels[choice.choiceKey] = choice.label;
      }
      if (labels.isNotEmpty) map[definition.id] = labels;
    }
    return map;
  }

  List<JournalHistoryDaySummary> _applyFactorFilters({
    required List<JournalHistoryDaySummary> days,
    required JournalHistoryFilters filters,
  }) {
    if (filters.factorTrackerIds.isEmpty && filters.factorGroupId == null) {
      return days;
    }
    return days
        .where((day) {
          var matchesFactors = true;
          if (filters.factorTrackerIds.isNotEmpty) {
            matchesFactors = filters.factorTrackerIds.every(
              day.factorTrackerIds.contains,
            );
          }
          if (!matchesFactors) return false;
          final groupId = filters.factorGroupId;
          if (groupId == null || groupId.trim().isEmpty) return true;
          return day.factorTrackerIds.any((trackerId) {
            final definition = day.definitionById[trackerId];
            return definition?.groupId == groupId;
          });
        })
        .toList(growable: false);
  }

  List<JournalTopInsight> _buildInsights({
    required List<JournalHistoryDaySummary> days,
  }) {
    if (days.length < 20) return const <JournalTopInsight>[];
    final factorStats =
        <
          String,
          ({
            int withFactor,
            int withoutFactor,
            double withSum,
            double withoutSum,
          })
        >{};
    for (final day in days) {
      final mood = day.moodAverage;
      if (mood == null) continue;
      final allFactorIds = day.definitionById.keys.where(
        (id) => id != day.moodTrackerId,
      );
      final present = day.factorTrackerIds;
      for (final factorId in allFactorIds) {
        final stats =
            factorStats[factorId] ??
            (withFactor: 0, withoutFactor: 0, withSum: 0.0, withoutSum: 0.0);
        if (present.contains(factorId)) {
          factorStats[factorId] = (
            withFactor: stats.withFactor + 1,
            withoutFactor: stats.withoutFactor,
            withSum: stats.withSum + mood,
            withoutSum: stats.withoutSum,
          );
        } else {
          factorStats[factorId] = (
            withFactor: stats.withFactor,
            withoutFactor: stats.withoutFactor + 1,
            withSum: stats.withSum,
            withoutSum: stats.withoutSum + mood,
          );
        }
      }
    }

    final insights = <JournalTopInsight>[];
    for (final entry in factorStats.entries) {
      final stats = entry.value;
      if (stats.withFactor < 10 || stats.withoutFactor < 10) continue;
      final withAvg = stats.withSum / stats.withFactor;
      final withoutAvg = stats.withoutSum / stats.withoutFactor;
      final delta = withAvg - withoutAvg;
      if (delta.abs() < 0.5) continue;
      final definition = days.first.definitionById[entry.key];
      if (definition == null) continue;
      final confidence = delta.abs() >= 0.8
          ? JournalInsightConfidence.high
          : JournalInsightConfidence.medium;
      final candidate = JournalTopInsight(
        factorId: entry.key,
        factorName: definition.name,
        deltaMood: delta,
        sampleSize: stats.withFactor,
        confidence: confidence,
        windowDays: 30,
      );
      insights.add(candidate);
    }
    insights.sort((a, b) => b.deltaMood.abs().compareTo(a.deltaMood.abs()));
    return insights;
  }

  String? _findMoodTrackerId(List<TrackerDefinition> defs) {
    for (final d in defs) {
      if (d.systemKey == 'mood') return d.id;
    }
    return null;
  }

  bool _isQuantityDefinition(TrackerDefinition d) {
    final valueType = d.valueType.trim().toLowerCase();
    final valueKind = (d.valueKind ?? '').trim().toLowerCase();
    return valueType == 'quantity' || valueKind == 'number';
  }

  double? _average(List<int>? values) {
    if (values == null || values.isEmpty) return null;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return sum / values.length;
  }

  bool _isUserFactor(TrackerDefinition definition) {
    if (definition.systemKey != null) return false;
    final source = definition.source.trim().toLowerCase();
    if (source == 'system') return false;
    return true;
  }

  List<TrackerDefinition> _buildDayTrackerDefinitions(
    List<TrackerDefinition> defs,
  ) {
    final dayTrackers =
        defs
            .where((d) => d.isActive && d.deletedAt == null)
            .where((d) {
              final scope = d.scope.trim().toLowerCase();
              return scope == 'day' ||
                  scope == 'daily' ||
                  scope == 'sleep_night';
            })
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return dayTrackers;
  }

  List<String> _resolveCoreDayTrackerIds(List<TrackerDefinition> defs) {
    String? findByKeyword(String keyword) {
      for (final d in defs) {
        final normalized = d.name.trim().toLowerCase();
        if (normalized.contains(keyword)) return d.id;
      }
      return null;
    }

    final ids = <String>[];
    final sleepId = findByKeyword('sleep');
    if (sleepId != null) ids.add(sleepId);
    return ids;
  }

  List<String> _normalizeDayTrackerOrder({
    required List<TrackerDefinition> definitions,
    required List<String> preferredOrderIds,
    required List<String> coreTrackerIds,
  }) {
    final availableIds = <String>{for (final d in definitions) d.id};
    final ordered = <String>[];
    for (final id in coreTrackerIds) {
      if (availableIds.contains(id) && !ordered.contains(id)) {
        ordered.add(id);
      }
    }
    for (final id in preferredOrderIds) {
      if (availableIds.contains(id) && !ordered.contains(id)) {
        ordered.add(id);
      }
    }
    for (final d in definitions) {
      if (!ordered.contains(d.id)) ordered.add(d.id);
    }
    return ordered;
  }

  Set<String> _normalizeHiddenDayTrackerIds({
    required Set<String> hiddenIds,
    required List<TrackerDefinition> definitions,
  }) {
    final availableIds = <String>{for (final d in definitions) d.id};
    return hiddenIds.where(availableIds.contains).toSet();
  }

  JournalHistoryFilters _filtersFromPreferences(
    JournalHistoryFilterPreferences? preferences,
  ) {
    if (preferences == null) return JournalHistoryFilters.initial();
    final start = _parseIsoDayUtc(preferences.rangeStartIsoDayUtc);
    final end = _parseIsoDayUtc(preferences.rangeEndIsoDayUtc);
    return JournalHistoryFilters.initial().copyWith(
      rangeStart: start,
      rangeEnd: end,
      factorTrackerIds: preferences.factorTrackerIds.toSet(),
      factorGroupId: preferences.factorGroupId,
      lookbackDays: preferences.lookbackDays,
    );
  }

  DateTime? _parseIsoDayUtc(String? isoDayUtc) {
    if (isoDayUtc == null || isoDayUtc.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(isoDayUtc);
    if (parsed == null) return null;
    return dateOnly(parsed.toUtc());
  }

  String? _toIsoDayUtc(DateTime? value) {
    if (value == null) return null;
    final day = dateOnly(value.toUtc());
    final month = day.month.toString().padLeft(2, '0');
    final dayPart = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayPart';
  }

  JournalHistoryFilterPreferences _toPreferences(
    JournalHistoryFilters filters,
  ) {
    return JournalHistoryFilterPreferences(
      rangeStartIsoDayUtc: _toIsoDayUtc(filters.rangeStart),
      rangeEndIsoDayUtc: _toIsoDayUtc(filters.rangeEnd),
      factorTrackerIds: filters.factorTrackerIds.toList(growable: false)
        ..sort(),
      factorGroupId: filters.factorGroupId,
      lookbackDays: filters.lookbackDays,
      dayTrackerOrderIds: _dayTrackerOrderIds,
      hiddenDayTrackerIds: _hiddenDayTrackerIds.toList(growable: false)..sort(),
      hiddenSummaryTrackerIds: _hiddenSummaryTrackerIds.toList(growable: false)
        ..sort(),
    );
  }

  Future<void> _persistFiltersPreferences(JournalHistoryFilters filters) async {
    if (!_persistFilters) return;
    final next = _toPreferences(filters);
    if (next == _savedFilterPreferences) return;
    await _settingsRepository.save<JournalHistoryFilterPreferences?>(
      SettingsKey.pageJournalFilters(_journalPageKey),
      next,
    );
    _savedFilterPreferences = next;
  }
}

final class JournalHistoryDaySummary {
  const JournalHistoryDaySummary({
    required this.day,
    required this.entries,
    required this.eventsByEntryId,
    required this.latestEventByTrackerId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.moodAverage,
    required this.dayQuantityTotalsByTrackerId,
    required this.factorTrackerIds,
    required this.choiceLabelsByTrackerId,
  });

  final DateTime day;
  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerEvent> latestEventByTrackerId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final double? moodAverage;
  final Map<String, double> dayQuantityTotalsByTrackerId;
  final Set<String> factorTrackerIds;
  final Map<String, Map<String, String>> choiceLabelsByTrackerId;
}

enum JournalInsightConfidence { medium, high }

final class JournalTopInsight {
  const JournalTopInsight({
    required this.factorId,
    required this.factorName,
    required this.deltaMood,
    required this.sampleSize,
    required this.confidence,
    required this.windowDays,
  });

  final String factorId;
  final String factorName;
  final double deltaMood;
  final int sampleSize;
  final JournalInsightConfidence confidence;
  final int windowDays;
}

final class JournalStarterOption {
  const JournalStarterOption({
    required this.id,
    required this.category,
    required this.name,
    required this.scope,
    required this.valueType,
    required this.valueKind,
    required this.iconName,
    required this.defaultSelected,
    this.opKind,
    this.minInt,
    this.maxInt,
    this.stepInt,
    this.unitKind,
    this.choices = const <String>[],
  });

  final String id;
  final String category;
  final String name;
  final String scope;
  final String valueType;
  final String valueKind;
  final String iconName;
  final bool defaultSelected;
  final String? opKind;
  final int? minInt;
  final int? maxInt;
  final int? stepInt;
  final String? unitKind;
  final List<String> choices;
}

final class JournalHistoryFilters {
  const JournalHistoryFilters({
    required this.searchText,
    required this.rangeStart,
    required this.rangeEnd,
    required this.factorTrackerIds,
    required this.factorGroupId,
    required this.lookbackDays,
  });

  factory JournalHistoryFilters.initial() => const JournalHistoryFilters(
    searchText: '',
    rangeStart: null,
    rangeEnd: null,
    factorTrackerIds: <String>{},
    factorGroupId: null,
    lookbackDays: 30,
  );

  final String searchText;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Set<String> factorTrackerIds;
  final String? factorGroupId;
  final int lookbackDays;

  JournalHistoryFilters copyWith({
    String? searchText,
    Object? rangeStart = _unset,
    Object? rangeEnd = _unset,
    Set<String>? factorTrackerIds,
    Object? factorGroupId = _unset,
    int? lookbackDays,
  }) {
    return JournalHistoryFilters(
      searchText: searchText ?? this.searchText,
      rangeStart: identical(rangeStart, _unset)
          ? this.rangeStart
          : rangeStart as DateTime?,
      rangeEnd: identical(rangeEnd, _unset)
          ? this.rangeEnd
          : rangeEnd as DateTime?,
      factorTrackerIds: factorTrackerIds ?? this.factorTrackerIds,
      factorGroupId: identical(factorGroupId, _unset)
          ? this.factorGroupId
          : factorGroupId as String?,
      lookbackDays: lookbackDays ?? this.lookbackDays,
    );
  }
}
