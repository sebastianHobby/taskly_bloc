import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_tile_capabilities_resolver.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:rxdart/rxdart.dart';

/// Service for fetching data for screen sections.
///
/// This service handles data fetching for all section types defined in DR-017.
/// It coordinates with existing repositories and the allocation orchestrator
/// to provide section-specific data results.
class SectionDataService {
  SectionDataService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required HomeDayKeyService dayKeyService,
    required AgendaSectionDataService agendaDataService,
    AnalyticsService? analyticsService,
    SettingsRepositoryContract? settingsRepository,
    JournalRepositoryContract? journalRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _journalRepository = journalRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _dayKeyService = dayKeyService,
       _agendaDataService = agendaDataService,
       _analyticsService = analyticsService,
       _settingsRepository = settingsRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final JournalRepositoryContract? _journalRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final HomeDayKeyService _dayKeyService;
  final AgendaSectionDataService _agendaDataService;
  final AnalyticsService? _analyticsService;
  final SettingsRepositoryContract? _settingsRepository;

  DateTime _todayUtcDay() => _dayKeyService.todayDayKeyUtc();

  Future<SectionDataResult> fetchDataListV2(ListSectionParamsV2 params) {
    return _fetchDataSectionV2(params);
  }

  Stream<SectionDataResult> watchDataListV2(ListSectionParamsV2 params) {
    return _watchDataSectionV2(params);
  }

  Future<SectionDataResult> fetchInterleavedListV2(
    InterleavedListSectionParamsV2 params,
  ) {
    return _fetchInterleavedListSectionV2(params);
  }

  Stream<SectionDataResult> watchInterleavedListV2(
    InterleavedListSectionParamsV2 params,
  ) {
    return _watchInterleavedListSectionV2(params);
  }

  Future<SectionDataResult> fetchHierarchyValueProjectTaskV2(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) {
    return _fetchHierarchyValueProjectTaskSectionV2(params);
  }

  Stream<SectionDataResult> watchHierarchyValueProjectTaskV2(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) {
    return _watchHierarchyValueProjectTaskSectionV2(params);
  }

  Future<SectionDataResult> fetchAgendaV2(AgendaSectionParamsV2 params) {
    return _fetchAgendaSectionV2(params);
  }

  Stream<SectionDataResult> watchAgendaV2(AgendaSectionParamsV2 params) {
    return _watchAgendaSectionV2(params);
  }

  // ===========================================================================
  // DATA SECTION
  // ===========================================================================

  static _PrimaryEntityKind _kindFor(DataConfig config) {
    return switch (config) {
      TaskDataConfig() => _PrimaryEntityKind.task,
      ProjectDataConfig() => _PrimaryEntityKind.project,
      ValueDataConfig() => _PrimaryEntityKind.value,
      JournalDataConfig() => _PrimaryEntityKind.journal,
      AllocationSnapshotTasksTodayDataConfig() => _PrimaryEntityKind.task,
    };
  }

  Stream<List<Task>> _watchSnapshotTasksForToday() {
    final dayUtc = _todayUtcDay();
    return _allocationSnapshotRepository
        .watchLatestTaskRefsForUtcDay(dayUtc)
        .switchMap((refs) {
          final ids = refs.map((r) => r.taskId).toList(growable: false);
          return _taskRepository.watchByIds(ids);
        });
  }

  static List<ScreenItem> _toScreenItems(
    _PrimaryEntityKind kind,
    List<Object> entities,
  ) {
    return switch (kind) {
      _PrimaryEntityKind.task =>
        entities
            .cast<Task>()
            .map<ScreenItem>(
              (t) => ScreenItem.task(
                t,
                tileCapabilities: EntityTileCapabilitiesResolver.forTask(t),
              ),
            )
            .toList(),
      _PrimaryEntityKind.project =>
        entities
            .cast<Project>()
            .map<ScreenItem>(
              (p) => ScreenItem.project(
                p,
                tileCapabilities: EntityTileCapabilitiesResolver.forProject(p),
              ),
            )
            .toList(),
      _PrimaryEntityKind.value =>
        entities
            .cast<Value>()
            .map<ScreenItem>(
              (v) => ScreenItem.value(
                v,
                tileCapabilities: EntityTileCapabilitiesResolver.forValue(v),
              ),
            )
            .toList(),
      _PrimaryEntityKind.journal => const <ScreenItem>[],
    };
  }

  // ===========================================================================
  // DATA SECTION (V2)
  // ===========================================================================

  Future<SectionDataResult> _fetchDataSectionV2(
    ListSectionParamsV2 params,
  ) async {
    final kind = _kindFor(params.config);
    final entities = await _fetchPrimaryEntities(params.config);
    final items = _toScreenItems(kind, entities);
    final enrichment = await _computeEnrichmentV2(params.enrichment, items);

    return SectionDataResult.dataV2(items: items, enrichment: enrichment);
  }

  Stream<SectionDataResult> _watchDataSectionV2(ListSectionParamsV2 params) {
    final kind = _kindFor(params.config);

    return _watchPrimaryEntities(params.config).switchMap((entities) {
      final items = _toScreenItems(kind, entities);
      final base = SectionDataResult.dataV2(items: items);

      // Emit a fast, non-enriched update immediately so UI reflects changes
      // (e.g. create/update) even if enrichment is slow.
      if (params.enrichment.items.isEmpty) {
        return Stream.value(base);
      }

      return Rx.concat([
        Stream.value(base),
        Stream.fromFuture(_computeEnrichmentV2(params.enrichment, items)).map(
          (enrichment) => SectionDataResult.dataV2(
            items: items,
            enrichment: enrichment,
          ),
        ),
      ]);
    });
  }

  // ===========================================================================
  // INTERLEAVED LIST (V2)
  // ===========================================================================

  Future<SectionDataResult> _fetchInterleavedListSectionV2(
    InterleavedListSectionParamsV2 params,
  ) async {
    if (params.sources.isEmpty) {
      return const SectionDataResult.dataV2(items: <ScreenItem>[]);
    }

    final results = await Future.wait(
      params.sources.map(
        (config) async {
          final kind = _kindFor(config);
          final entities = await _fetchPrimaryEntities(config);
          return _toScreenItems(kind, entities);
        },
      ),
    );

    final items = results.expand((e) => e).toList(growable: false);
    final sorted = _sortInterleavedItemsV2(items);
    final enrichment = await _computeEnrichmentV2(params.enrichment, sorted);
    return SectionDataResult.dataV2(items: sorted, enrichment: enrichment);
  }

  Stream<SectionDataResult> _watchInterleavedListSectionV2(
    InterleavedListSectionParamsV2 params,
  ) {
    if (params.sources.isEmpty) {
      return Stream.value(
        const SectionDataResult.dataV2(items: <ScreenItem>[]),
      );
    }

    final streams = params.sources
        .map(
          (config) => _watchPrimaryEntities(config).map(
            (entities) {
              final kind = _kindFor(config);
              return _toScreenItems(kind, entities);
            },
          ),
        )
        .toList(growable: false);

    return Rx.combineLatestList<List<ScreenItem>>(streams).switchMap(
      (lists) {
        final items = lists.expand((e) => e).toList(growable: false);
        final sorted = _sortInterleavedItemsV2(items);
        return Stream.fromFuture(
          _buildInterleavedResultV2(sorted, params.enrichment),
        );
      },
    );
  }

  // ===========================================================================
  // HIERARCHY VALUE -> PROJECT -> TASK (V2)
  // ===========================================================================

  Future<SectionDataResult> _fetchHierarchyValueProjectTaskSectionV2(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) async {
    if (params.sources.isEmpty) {
      return const SectionDataResult.hierarchyValueProjectTaskV2(
        items: <ScreenItem>[],
      );
    }

    final results = await Future.wait(
      params.sources.map(
        (config) async {
          final kind = _kindFor(config);
          final entities = await _fetchPrimaryEntities(config);
          return _toScreenItems(kind, entities);
        },
      ),
    );

    final items = results.expand((e) => e).toList(growable: false);
    final sorted = _sortInterleavedItemsV2(items);
    final enrichment = await _computeEnrichmentV2(params.enrichment, sorted);

    return SectionDataResult.hierarchyValueProjectTaskV2(
      items: sorted,
      enrichment: enrichment,
    );
  }

  Stream<SectionDataResult> _watchHierarchyValueProjectTaskSectionV2(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) {
    if (params.sources.isEmpty) {
      return Stream.value(
        const SectionDataResult.hierarchyValueProjectTaskV2(
          items: <ScreenItem>[],
        ),
      );
    }

    final streams = params.sources
        .map(
          (config) => _watchPrimaryEntities(config).map(
            (entities) {
              final kind = _kindFor(config);
              return _toScreenItems(kind, entities);
            },
          ),
        )
        .toList(growable: false);

    return Rx.combineLatestList(streams).switchMap((results) async* {
      final items = results.expand((e) => e).toList(growable: false);
      final sorted = _sortInterleavedItemsV2(items);
      final enrichment = await _computeEnrichmentV2(params.enrichment, sorted);
      yield SectionDataResult.hierarchyValueProjectTaskV2(
        items: sorted,
        enrichment: enrichment,
      );
    });
  }

  Future<SectionDataResult> _buildInterleavedResultV2(
    List<ScreenItem> items,
    EnrichmentPlanV2 enrichmentPlan,
  ) async {
    final enrichment = await _computeEnrichmentV2(enrichmentPlan, items);
    return SectionDataResult.dataV2(items: items, enrichment: enrichment);
  }

  List<ScreenItem> _sortInterleavedItemsV2(List<ScreenItem> items) {
    final entityItems = <ScreenItem>[];
    final structuralItems = <ScreenItem>[];

    for (final item in items) {
      switch (item) {
        case ScreenItemTask() || ScreenItemProject() || ScreenItemValue():
          entityItems.add(item);
        default:
          structuralItems.add(item);
      }
    }

    entityItems.sort((a, b) {
      final aKey = _updatedAtKeyFor(a);
      final bKey = _updatedAtKeyFor(b);
      final byKey = -aKey.compareTo(bKey);
      if (byKey != 0) return byKey;
      return _stableIdFor(a).compareTo(_stableIdFor(b));
    });

    return <ScreenItem>[...entityItems, ...structuralItems];
  }

  DateTime _updatedAtKeyFor(ScreenItem item) {
    return switch (item) {
      ScreenItemTask(:final task) => task.updatedAt,
      ScreenItemProject(:final project) => project.updatedAt,
      ScreenItemValue(:final value) => value.updatedAt,
      _ => DateTime.utc(0),
    };
  }

  String _stableIdFor(ScreenItem item) {
    return switch (item) {
      ScreenItemTask(:final task) => 't:${task.id}',
      ScreenItemProject(:final project) => 'p:${project.id}',
      ScreenItemValue(:final value) => 'v:${value.id}',
      ScreenItemHeader(:final title) => 'h:$title',
      ScreenItemDivider() => 'd',
    };
  }

  Future<List<Object>> _fetchPrimaryEntities(DataConfig config) async {
    return switch (config) {
      TaskDataConfig(:final query) =>
        (await _taskRepository.watchAll(query).first).cast<Object>(),
      ProjectDataConfig(:final query) =>
        (await _projectRepository.watchAll(query).first).cast<Object>(),
      ValueDataConfig(:final query) => (await _valueRepository.getAll(
        query,
      )).cast<Object>(),
      JournalDataConfig(:final query) => (await _fetchJournalEntries(
        query,
      )).cast<Object>(),
      AllocationSnapshotTasksTodayDataConfig() =>
        (await _fetchSnapshotTasksForToday()).cast<Object>(),
    };
  }

  Future<List<Task>> _fetchSnapshotTasksForToday() async {
    final dayUtc = _todayUtcDay();
    final refs = await _allocationSnapshotRepository.getLatestTaskRefsForUtcDay(
      dayUtc,
    );
    final ids = refs.map((r) => r.taskId).toList(growable: false);
    return _taskRepository.getByIds(ids);
  }

  Future<List<JournalEntry>> _fetchJournalEntries(JournalQuery? query) async {
    if (_journalRepository == null) {
      talker.warning(
        '[SectionDataService] JournalRepository not available for journal query',
      );
      return [];
    }
    // Use the repository's watchByQuery if available, otherwise fall back
    return _journalRepository
        .watchJournalEntriesByQuery(
          query ?? JournalQuery.all(),
        )
        .first;
  }

  Stream<List<Object>> _watchPrimaryEntities(DataConfig config) {
    return switch (config) {
      TaskDataConfig(:final query) =>
        _taskRepository.watchAll(query).map((items) => items.cast<Object>()),
      ProjectDataConfig(:final query) =>
        _projectRepository.watchAll(query).map((items) => items.cast<Object>()),
      ValueDataConfig(:final query) =>
        _valueRepository.watchAll(query).map((items) => items.cast<Object>()),
      JournalDataConfig(:final query) => _watchJournalEntries(
        query,
      ).map((items) => items.cast<Object>()),
      AllocationSnapshotTasksTodayDataConfig() =>
        _watchSnapshotTasksForToday().map((items) => items.cast<Object>()),
    };
  }

  Stream<List<JournalEntry>> _watchJournalEntries(JournalQuery? query) {
    if (_journalRepository == null) {
      talker.warning(
        '[SectionDataService] JournalRepository not available for journal watch',
      );
      return Stream.value([]);
    }
    return _journalRepository.watchJournalEntriesByQuery(
      query ?? JournalQuery.all(),
    );
  }

  // ===========================================================================
  // AGENDA SECTION
  // ===========================================================================

  Future<SectionDataResult> _fetchAgendaSectionV2(
    AgendaSectionParamsV2 params,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeEnd = DateTime(today.year, today.month + 2, 0);
    final agendaData = await _agendaDataService.getAgendaData(
      referenceDate: now,
      focusDate: now,
      rangeStart: today,
      rangeEnd: rangeEnd,
    );

    final enrichment = await _computeAgendaEnrichmentV2(
      params.enrichment,
      agendaData,
    );

    return SectionDataResult.agenda(
      agendaData: agendaData,
      enrichment: enrichment,
    );
  }

  Stream<SectionDataResult> _watchAgendaSectionV2(
    AgendaSectionParamsV2 params,
  ) async* {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeEnd = DateTime(today.year, today.month + 2, 0);

    yield* _agendaDataService
        .watchAgendaData(
          referenceDate: now,
          focusDate: now,
          rangeStart: today,
          rangeEnd: rangeEnd,
        )
        .asyncMap((agendaData) async {
          final enrichment = await _computeAgendaEnrichmentV2(
            params.enrichment,
            agendaData,
          );
          return SectionDataResult.agenda(
            agendaData: agendaData,
            enrichment: enrichment,
          );
        });
  }

  Future<EnrichmentResultV2?> _computeAgendaEnrichmentV2(
    EnrichmentPlanV2 plan,
    AgendaData agendaData,
  ) async {
    if (plan.items.isEmpty) return null;

    final tasksById = <String, Task>{};
    final projectsById = <String, Project>{};

    void addAgendaItem(AgendaItem item) {
      final task = item.task;
      if (task != null) {
        tasksById[task.id] = task;
      }

      final project = item.project;
      if (project != null) {
        projectsById[project.id] = project;
      }
    }

    for (final group in agendaData.groups) {
      group.items.forEach(addAgendaItem);
    }
    agendaData.overdueItems.forEach(addAgendaItem);

    final items = <ScreenItem>[
      ...tasksById.values.map(ScreenItem.task),
      ...projectsById.values.map(ScreenItem.project),
    ];

    return _computeEnrichmentV2(plan, items);
  }

  // ===========================================================================
  // ENRICHMENT COMPUTATION (V2)
  // ===========================================================================

  Future<EnrichmentResultV2?> _computeEnrichmentV2(
    EnrichmentPlanV2 plan,
    List<ScreenItem> items,
  ) async {
    if (plan.items.isEmpty) return null;

    final wantsValueStats = plan.items.any(
      (i) => i.maybeWhen(valueStats: () => true, orElse: () => false),
    );
    final wantsOpenTaskCounts = plan.items.any(
      (i) => i.maybeWhen(openTaskCounts: () => true, orElse: () => false),
    );

    final wantsAllocationMembership = plan.items.any(
      (i) => i.maybeWhen(allocationMembership: () => true, orElse: () => false),
    );

    final agendaDateFields = plan.items
        .map(
          (i) => i.maybeWhen(
            agendaTags: (dateField) => dateField,
            orElse: () => null,
          ),
        )
        .whereType<AgendaDateFieldV2>()
        .toList(growable: false);
    final AgendaDateFieldV2? agendaDateField = agendaDateFields.isEmpty
        ? null
        : agendaDateFields.first;

    final values = items
        .whereType<ScreenItemValue>()
        .map((i) => i.value)
        .toList();
    final projects = items
        .whereType<ScreenItemProject>()
        .map((i) => i.project)
        .toList();
    final tasks = items.whereType<ScreenItemTask>().map((i) => i.task).toList();

    Map<String, ValueStats> valueStatsByValueId = const {};
    int? totalRecentCompletions;
    OpenTaskCountsV2? openTaskCounts;
    Map<String, AgendaTagV2> agendaTagByTaskId = const {};
    Map<String, bool> isAllocatedByTaskId = const {};
    Map<String, int> allocationRankByTaskId = const {};
    Map<String, String> qualifyingValueIdByTaskId = const {};

    if (wantsValueStats && values.isNotEmpty) {
      const sparklineWeeks = 4;
      const gapWarningThreshold = 15;

      final result = await _computeValueStatsEnrichmentV2(
        values,
        sparklineWeeks: sparklineWeeks,
        gapWarningThreshold: gapWarningThreshold,
      );

      if (result != null) {
        valueStatsByValueId = result.statsByValueId;
        totalRecentCompletions = result.totalRecentCompletions;
      }
    }

    if (wantsOpenTaskCounts && (projects.isNotEmpty || values.isNotEmpty)) {
      openTaskCounts = await _computeOpenTaskCountsV2(projects, values);
    }

    if (agendaDateField != null && tasks.isNotEmpty) {
      agendaTagByTaskId = _computeAgendaTagsV2(tasks, agendaDateField);
    }

    if (wantsAllocationMembership && tasks.isNotEmpty) {
      final dayUtc = _todayUtcDay();
      final refs = await _allocationSnapshotRepository
          .getLatestTaskRefsForUtcDay(
            dayUtc,
          );

      final refByTaskId = <String, AllocationSnapshotTaskRef>{
        for (final r in refs) r.taskId: r,
      };

      isAllocatedByTaskId = <String, bool>{
        for (final t in tasks) t.id: refByTaskId.containsKey(t.id),
      };

      allocationRankByTaskId = <String, int>{
        for (final t in tasks)
          if (refByTaskId[t.id] != null)
            t.id: refByTaskId[t.id]!.allocationRank,
      };

      qualifyingValueIdByTaskId = <String, String>{
        for (final t in tasks)
          if (refByTaskId[t.id]?.qualifyingValueId != null)
            t.id: refByTaskId[t.id]!.qualifyingValueId!,
      };
    }

    final hasAny =
        valueStatsByValueId.isNotEmpty ||
        totalRecentCompletions != null ||
        openTaskCounts != null ||
        agendaTagByTaskId.isNotEmpty ||
        isAllocatedByTaskId.isNotEmpty ||
        allocationRankByTaskId.isNotEmpty ||
        qualifyingValueIdByTaskId.isNotEmpty;
    if (!hasAny) return null;

    return EnrichmentResultV2(
      valueStatsByValueId: valueStatsByValueId,
      totalRecentCompletions: totalRecentCompletions,
      openTaskCounts: openTaskCounts,
      agendaTagByTaskId: agendaTagByTaskId,
      isAllocatedByTaskId: isAllocatedByTaskId,
      allocationRankByTaskId: allocationRankByTaskId,
      qualifyingValueIdByTaskId: qualifyingValueIdByTaskId,
    );
  }

  Future<OpenTaskCountsV2> _computeOpenTaskCountsV2(
    List<Project> projects,
    List<Value> values,
  ) async {
    final projectCounts = await Future.wait(
      projects.map((p) async {
        final query = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskProjectPredicate(
                operator: ProjectOperator.matches,
                projectId: p.id,
              ),
              const TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );
        final tasks = await _taskRepository.watchAll(query).first;
        return MapEntry(p.id, tasks.length);
      }),
    );

    final valueCounts = await Future.wait(
      values.map((v) async {
        final query = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskValuePredicate(
                operator: ValueOperator.hasAll,
                valueIds: [v.id],
                includeInherited: true,
              ),
              const TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );
        final tasks = await _taskRepository.watchAll(query).first;
        return MapEntry(v.id, tasks.length);
      }),
    );

    return OpenTaskCountsV2(
      byProjectId: Map<String, int>.fromEntries(projectCounts),
      byValueId: Map<String, int>.fromEntries(valueCounts),
    );
  }

  Map<String, AgendaTagV2> _computeAgendaTagsV2(
    List<Task> tasks,
    AgendaDateFieldV2 dateField,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final map = <String, AgendaTagV2>{};
    for (final task in tasks) {
      final start = task.occurrence?.date ?? task.startDate;
      final deadline = task.occurrence?.deadline ?? task.deadlineDate;

      final startDay = start == null
          ? null
          : DateTime(start.year, start.month, start.day);
      final deadlineDay = deadline == null
          ? null
          : DateTime(deadline.year, deadline.month, deadline.day);

      final hasSameStartAndDeadline =
          startDay != null && deadlineDay != null && startDay == deadlineDay;

      final isInProgressToday =
          !hasSameStartAndDeadline &&
          startDay != null &&
          deadlineDay != null &&
          today.isAfter(startDay) &&
          today.isBefore(deadlineDay);

      if (isInProgressToday) {
        map[task.id] = AgendaTagV2.inProgress;
        continue;
      }

      final startsToday = startDay != null && startDay == today;
      final dueToday = deadlineDay != null && deadlineDay == today;

      // Prefer starts/due over dateField-driven behavior so tags are consistent
      // anywhere `TaskTileVariant.agenda` is used.
      if (startsToday) {
        map[task.id] = AgendaTagV2.starts;
        continue;
      }
      if (dueToday) {
        map[task.id] = AgendaTagV2.due;
        continue;
      }

      final derivedDate = switch (dateField) {
        AgendaDateFieldV2.deadlineDate => deadline,
        AgendaDateFieldV2.startDate => start,
        AgendaDateFieldV2.scheduledFor => task.occurrence?.date ?? start,
      };
      if (derivedDate == null) continue;

      final derivedDay = DateTime(
        derivedDate.year,
        derivedDate.month,
        derivedDate.day,
      );
      if (derivedDay != today) continue;

      map[task.id] = switch (dateField) {
        AgendaDateFieldV2.deadlineDate => AgendaTagV2.due,
        AgendaDateFieldV2.startDate => AgendaTagV2.starts,
        AgendaDateFieldV2.scheduledFor => AgendaTagV2.starts,
      };
    }

    return map;
  }

  Future<_ValueStatsEnrichmentV2Result?> _computeValueStatsEnrichmentV2(
    List<Value> values, {
    required int sparklineWeeks,
    required int gapWarningThreshold,
  }) async {
    // Check required services are available
    if (_analyticsService == null || _settingsRepository == null) {
      talker.warning(
        '[SectionDataService] Cannot compute ValueStats enrichment: '
        'analyticsService=${_analyticsService != null}, '
        'settingsRepository=${_settingsRepository != null}',
      );
      return null;
    }

    try {
      final lookbackDays = sparklineWeeks * 7;
      const minAbsoluteShortfallToBadge = 2.0;
      const minExpectedCompletionsToConsider = 2.0;

      // Fetch all required data in parallel
      final results = await Future.wait([
        _analyticsService.getValueWeeklyTrends(weeks: sparklineWeeks),
        _analyticsService.getValueActivityStats(),
        _analyticsService.getValuePrimarySecondaryStats(),
        _analyticsService.getRecentCompletionsByValue(
          days: lookbackDays,
        ),
        _analyticsService.getTotalRecentCompletions(days: lookbackDays),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final primarySecondaryStats =
          results[2] as Map<String, ValuePrimarySecondaryStats>;
      final recentCompletions = results[3] as Map<String, int>;
      final totalRecentCompletions = results[4] as int;

      // Calculate total weight for percentage calculation
      final totalWeight = values.fold<int>(
        0,
        (sum, value) => sum + value.priority.weight,
      );

      // Build stats map for each value
      final statsByValueId = <String, ValueStats>{};

      String? mostNeglectedValueId;
      double bestShortfall = 0;
      int bestPriorityWeight = -1;

      for (final value in values) {
        // Calculate target percent from priority weight
        final targetPercent = totalWeight > 0
            ? (value.priority.weight / totalWeight) * 100
            : 0.0;

        final recentCount = recentCompletions[value.id] ?? 0;
        final expectedCount = totalRecentCompletions > 0
            ? (totalRecentCompletions * (targetPercent / 100))
            : 0.0;

        final shortfall = expectedCount - recentCount;
        final positiveShortfall = shortfall <= 0 ? 0.0 : shortfall;
        final priorityWeight = value.priority.weight;

        final isBestSoFar = positiveShortfall > bestShortfall;
        final isTieBreakWinner =
            positiveShortfall == bestShortfall &&
            priorityWeight > bestPriorityWeight;

        if (expectedCount >= minExpectedCompletionsToConsider &&
            (isBestSoFar || isTieBreakWinner)) {
          mostNeglectedValueId = value.id;
          bestShortfall = positiveShortfall;
          bestPriorityWeight = priorityWeight;
        }

        // Calculate actual percent from recent completions
        final actualPercent = totalRecentCompletions > 0
            ? (recentCount / totalRecentCompletions) * 100
            : 0.0;

        // Get weekly trend data
        final weeklyTrend = weeklyTrends[value.id] ?? const <double>[];

        // Get activity stats
        final activity =
            activityStats[value.id] ??
            const ValueActivityStats(taskCount: 0, projectCount: 0);

        final primarySecondary = primarySecondaryStats[value.id];

        statsByValueId[value.id] = ValueStats(
          targetPercent: targetPercent,
          actualPercent: actualPercent,
          taskCount: activity.taskCount,
          projectCount: activity.projectCount,
          primaryTaskCount: primarySecondary?.primaryTaskCount ?? 0,
          secondaryTaskCount: primarySecondary?.secondaryTaskCount ?? 0,
          primaryProjectCount: primarySecondary?.primaryProjectCount ?? 0,
          secondaryProjectCount: primarySecondary?.secondaryProjectCount ?? 0,
          weeklyTrend: weeklyTrend,
          lookbackDays: lookbackDays,
          recentCompletionCount: recentCount,
          expectedRecentCompletionCount: expectedCount,
          gapWarningThreshold: gapWarningThreshold,
        );
      }

      if (mostNeglectedValueId != null &&
          bestShortfall >= minAbsoluteShortfallToBadge) {
        final existing = statsByValueId[mostNeglectedValueId];
        if (existing != null) {
          statsByValueId[mostNeglectedValueId] = existing.copyWith(
            needsAttention: true,
          );
        }
      }

      return _ValueStatsEnrichmentV2Result(
        statsByValueId: statsByValueId,
        totalRecentCompletions: totalRecentCompletions,
      );
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[SectionDataService] Failed to compute value stats enrichment',
      );
      return null;
    }
  }
}

final class _ValueStatsEnrichmentV2Result {
  const _ValueStatsEnrichmentV2Result({
    required this.statsByValueId,
    required this.totalRecentCompletions,
  });

  final Map<String, ValueStats> statsByValueId;
  final int totalRecentCompletions;
}

enum _PrimaryEntityKind {
  task,
  project,
  value,
  journal,
}
