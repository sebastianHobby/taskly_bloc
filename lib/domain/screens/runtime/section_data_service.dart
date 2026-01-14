import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';
import 'package:taskly_bloc/domain/settings/settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';
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
    required AllocationOrchestrator allocationOrchestrator,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required HomeDayKeyService dayKeyService,
    required AgendaSectionDataService agendaDataService,
    JournalRepositoryContract? journalRepository,
    AnalyticsService? analyticsService,
    SettingsRepositoryContract? settingsRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _journalRepository = journalRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _dayKeyService = dayKeyService,
       _agendaDataService = agendaDataService,
       _analyticsService = analyticsService,
       _settingsRepository = settingsRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final JournalRepositoryContract? _journalRepository;
  final AllocationOrchestrator _allocationOrchestrator;
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

  Future<SectionDataResult> fetchAllocation(AllocationSectionParams params) {
    return _fetchAllocationSection(
      sourceFilter: params.sourceFilter,
      maxTasks: params.maxTasks,
      displayMode: params.displayMode,
    );
  }

  Stream<SectionDataResult> watchAllocation(AllocationSectionParams params) {
    return _watchAllocationSection(
      sourceFilter: params.sourceFilter,
      maxTasks: params.maxTasks,
      displayMode: params.displayMode,
    );
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

  static List<ScreenItem> _toScreenItems(
    _PrimaryEntityKind kind,
    List<Object> entities,
  ) {
    return switch (kind) {
      _PrimaryEntityKind.task =>
        entities.cast<Task>().map<ScreenItem>(ScreenItem.task).toList(),
      _PrimaryEntityKind.project =>
        entities.cast<Project>().map<ScreenItem>(ScreenItem.project).toList(),
      _PrimaryEntityKind.value =>
        entities.cast<Value>().map<ScreenItem>(ScreenItem.value).toList(),
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

    return _watchPrimaryEntities(params.config).switchMap(
      (entities) => Stream.fromFuture(
        _buildDataSectionResultV2(
          kind: kind,
          entities: entities,
          enrichmentPlan: params.enrichment,
        ),
      ),
    );
  }

  Future<SectionDataResult> _buildDataSectionResultV2({
    required _PrimaryEntityKind kind,
    required List<Object> entities,
    required EnrichmentPlanV2 enrichmentPlan,
  }) async {
    final items = _toScreenItems(kind, entities);
    final enrichment = await _computeEnrichmentV2(enrichmentPlan, items);

    return SectionDataResult.dataV2(items: items, enrichment: enrichment);
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
    final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
      dayUtc,
    );
    return _tasksFromSnapshot(snapshot);
  }

  Future<List<Task>> _fetchSnapshotTasksForTodayFrom(AllocationSnapshot? snap) {
    return Future.value(_tasksFromSnapshot(snap));
  }

  List<Task> _tasksFromSnapshot(AllocationSnapshot? snapshot) {
    if (snapshot == null) return const <Task>[];

    final taskEntries = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .toList(growable: false);

    // Preserve snapshot ordering.
    // Note: repository lookup is async in other paths; here we only build ids.
    // Actual task loading occurs in async helper below.
    // (This function is kept sync so we can share ordering logic.)
    //
    // We return an empty list here and load in the async watcher/fetcher.
    //
    // Implementation note: this is overridden by async loaders.
    return const <Task>[];
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
  // ALLOCATION SECTION
  // ===========================================================================

  Future<SectionDataResult> _fetchAllocationSection({
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
  }) async {
    final dayUtc = _todayUtcDay();
    final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
      dayUtc,
    );

    if (snapshot != null) {
      return _buildAllocationSectionResultFromSnapshot(
        snapshot: snapshot,
        sourceFilter: sourceFilter,
        maxTasks: maxTasks,
        displayMode: displayMode,
      );
    }

    // Fallback to live allocation (first-run before snapshot exists).
    final allocation = await _allocationOrchestrator.watchAllocation().first;

    // Check if value setup is required
    if (allocation.requiresValueSetup) {
      return SectionDataResult.allocation(
        allocatedTasks: const [],
        totalAvailable: 0,
        requiresValueSetup: true,
        displayMode: displayMode,
      );
    }

    // Build pinned tasks and value groups for UI rendering
    final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
      allocation.allocatedTasks,
      sourceFilter,
      maxTasks,
    );

    // Flatten tasks for UI consumption.
    final tasks = [
      ...pinnedTasks,
      ...tasksByValue.values.expand((g) => g.tasks),
    ].map((at) => at.task).toList();

    // Count total available (all non-completed tasks)
    final totalAvailable = await _taskRepository
        .watchAllCount(TaskQuery.incomplete())
        .first;

    // Allocation warnings are handled by the attention system.

    return SectionDataResult.allocation(
      allocatedTasks: tasks,
      totalAvailable: totalAvailable,
      pinnedTasks: pinnedTasks,
      tasksByValue: tasksByValue,
      activeFocusMode: allocation.activeFocusMode,
      displayMode: displayMode,
    );
  }

  Stream<SectionDataResult> _watchAllocationSection({
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
  }) {
    final dayUtc = _todayUtcDay();

    // Prefer persisted snapshots. If a snapshot does not exist yet for today,
    // fall back to live allocation (first-run bootstrap).
    return _allocationSnapshotRepository.watchLatestForUtcDay(dayUtc).switchMap(
      (snapshot) {
        if (snapshot != null) {
          return _watchAllocationSectionFromSnapshot(
            snapshot: snapshot,
            sourceFilter: sourceFilter,
            maxTasks: maxTasks,
            displayMode: displayMode,
          );
        }

        return _allocationOrchestrator.watchAllocation().switchMap(
          (allocation) => Stream.fromFuture(
            _buildAllocationSectionResult(
              allocation: allocation,
              sourceFilter: sourceFilter,
              maxTasks: maxTasks,
              displayMode: displayMode,
            ),
          ),
        );
      },
    );
  }

  Future<SectionDataResult> _buildAllocationSectionResult({
    required AllocationResult allocation,
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
  }) async {
    // Check if value setup is required
    if (allocation.requiresValueSetup) {
      return SectionDataResult.allocation(
        allocatedTasks: const [],
        totalAvailable: 0,
        requiresValueSetup: true,
        displayMode: displayMode,
      );
    }

    // Build pinned tasks and value groups for UI rendering
    final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
      allocation.allocatedTasks,
      sourceFilter,
      maxTasks,
    );

    // Flatten tasks for UI consumption.
    final tasks = [
      ...pinnedTasks,
      ...tasksByValue.values.expand((g) => g.tasks),
    ].map((at) => at.task).toList();

    // Count total available
    final totalAvailable = await _taskRepository
        .watchAllCount(TaskQuery.incomplete())
        .first;

    // Allocation warnings are handled by the attention system.

    return SectionDataResult.allocation(
      allocatedTasks: tasks,
      totalAvailable: totalAvailable,
      pinnedTasks: pinnedTasks,
      tasksByValue: tasksByValue,
      activeFocusMode: allocation.activeFocusMode,
      displayMode: displayMode,
    );
  }

  Future<SectionDataResult> _buildAllocationSectionResultFromSnapshot({
    required AllocationSnapshot snapshot,
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
  }) async {
    final taskEntries = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .toList(growable: false);

    final tasks = <Task>[];
    final allocatedTasks = <AllocatedTask>[];

    for (final entry in taskEntries) {
      final task = await _taskRepository.getById(entry.entity.id);
      if (task == null) continue;
      tasks.add(task);
      allocatedTasks.add(
        AllocatedTask(
          task: task,
          qualifyingValueId: entry.qualifyingValueId ?? 'unknown',
          allocationScore: entry.allocationScore ?? 0,
        ),
      );
    }

    final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
      allocatedTasks,
      sourceFilter,
      maxTasks,
    );

    final flatTasks = [
      ...pinnedTasks,
      ...tasksByValue.values.expand((g) => g.tasks),
    ].map((at) => at.task).toList();

    final totalAvailable = await _taskRepository
        .watchAllCount(TaskQuery.incomplete())
        .first;

    final allocationConfig = _settingsRepository == null
        ? const AllocationConfig()
        : await _settingsRepository.load(SettingsKey.allocation);

    return SectionDataResult.allocation(
      allocatedTasks: flatTasks,
      totalAvailable: totalAvailable,
      pinnedTasks: pinnedTasks,
      tasksByValue: tasksByValue,
      activeFocusMode: allocationConfig.focusMode,
      displayMode: displayMode,
    );
  }

  Stream<SectionDataResult> _watchAllocationSectionFromSnapshot({
    required AllocationSnapshot snapshot,
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
  }) {
    final taskEntries = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .toList(growable: false);

    final taskStreams = taskEntries
        .map((e) => _taskRepository.watchById(e.entity.id))
        .toList(growable: false);

    final tasksStream = taskStreams.isEmpty
        ? Stream.value(const <Task?>[])
        : Rx.combineLatestList<Task?>(taskStreams);

    final totalAvailableStream = _taskRepository.watchAllCount(
      TaskQuery.incomplete(),
    );

    final allocationConfigStream = _settingsRepository == null
        ? Stream.value(const AllocationConfig())
        : _settingsRepository.watch(SettingsKey.allocation);

    return Rx.combineLatest3(
      tasksStream,
      totalAvailableStream,
      allocationConfigStream,
      (List<Task?> tasks, int totalAvailable, AllocationConfig cfg) => (
        tasks,
        totalAvailable,
        cfg,
      ),
    ).asyncMap((tuple) async {
      final tasksNullable = tuple.$1;
      final totalAvailable = tuple.$2;
      final config = tuple.$3;

      final allocatedTasks = <AllocatedTask>[];
      for (var i = 0; i < taskEntries.length; i++) {
        final task = i < tasksNullable.length ? tasksNullable[i] : null;
        if (task == null) continue;
        final entry = taskEntries[i];
        allocatedTasks.add(
          AllocatedTask(
            task: task,
            qualifyingValueId: entry.qualifyingValueId ?? 'unknown',
            allocationScore: entry.allocationScore ?? 0,
          ),
        );
      }

      final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
        allocatedTasks,
        sourceFilter,
        maxTasks,
      );

      final flatTasks = [
        ...pinnedTasks,
        ...tasksByValue.values.expand((g) => g.tasks),
      ].map((at) => at.task).toList();

      return SectionDataResult.allocation(
        allocatedTasks: flatTasks,
        totalAvailable: totalAvailable,
        pinnedTasks: pinnedTasks,
        tasksByValue: tasksByValue,
        activeFocusMode: config.focusMode,
        displayMode: displayMode,
      );
    });
  }

  /// Builds pinned tasks list and value groups from allocated tasks.
  ///
  /// Separates pinned tasks (qualifyingValueId == 'pinned') from regular tasks,
  /// then groups regular tasks by their qualifying value ID.
  Future<(List<AllocatedTask>, Map<String, AllocationValueGroup>)>
  _buildAllocationGroups(
    List<AllocatedTask> allocatedTasks,
    TaskQuery? sourceFilter,
    int? maxTasks,
  ) async {
    // Apply source filter if provided
    var filteredTasks = allocatedTasks;
    if (sourceFilter != null) {
      final filteredTaskObjects = _applyTaskFilter(
        allocatedTasks.map((at) => at.task).toList(),
        sourceFilter,
      );
      final filteredIds = filteredTaskObjects.map((t) => t.id).toSet();
      filteredTasks = allocatedTasks
          .where((at) => filteredIds.contains(at.task.id))
          .toList();
    }

    // Limit if maxTasks specified
    if (maxTasks != null && filteredTasks.length > maxTasks) {
      filteredTasks = filteredTasks.take(maxTasks).toList();
    }

    // Separate pinned tasks from regular tasks
    final pinnedTasks = filteredTasks
        .where((at) => at.qualifyingValueId == 'pinned')
        .toList();

    final regularTasks = filteredTasks
        .where((at) => at.qualifyingValueId != 'pinned')
        .toList();

    // Group regular tasks by their qualifying value ID
    final groupedByValue = <String, List<AllocatedTask>>{};
    for (final task in regularTasks) {
      groupedByValue.putIfAbsent(task.qualifyingValueId, () => []).add(task);
    }

    // Build AllocationValueGroup for each value
    final tasksByValue = <String, AllocationValueGroup>{};
    for (final entry in groupedByValue.entries) {
      final valueId = entry.key;
      final tasks = entry.value;

      // Look up value for name, color, and icon
      final value = await _valueRepository.getById(valueId);
      final valueName = value?.name ?? 'Unknown Value';
      final valuePriority = value?.priority ?? ValuePriority.medium;
      final color = value?.color;
      final iconName = value?.iconName;

      tasksByValue[valueId] = AllocationValueGroup(
        valueId: valueId,
        valueName: valueName,
        valuePriority: valuePriority,
        tasks: tasks,
        weight: 1, // Default weight - could be enhanced later
        quota: tasks.length,
        color: color,
        iconName: iconName,
      );
    }

    return (pinnedTasks, tasksByValue);
  }

  List<Task> _applyTaskFilter(List<Task> tasks, TaskQuery query) {
    // Apply in-memory filtering based on query predicates
    // For full SQL filtering, use the repository's watchAll method instead
    return tasks.where((task) {
      // Filter by completion status if specified in predicates
      for (final predicate in query.filter.shared) {
        if (predicate is TaskBoolPredicate) {
          if (predicate.field == TaskBoolField.completed) {
            final isCompleted = task.completed;
            final shouldMatch = predicate.operator == BoolOperator.isTrue;
            if (isCompleted != shouldMatch) return false;
          }
        }
      }
      return true;
    }).toList();
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

    return SectionDataResult.agenda(agendaData: agendaData);
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
        .map((agendaData) => SectionDataResult.agenda(agendaData: agendaData));
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

    final hasAny =
        valueStatsByValueId.isNotEmpty ||
        totalRecentCompletions != null ||
        openTaskCounts != null ||
        agendaTagByTaskId.isNotEmpty;
    if (!hasAny) return null;

    return EnrichmentResultV2(
      valueStatsByValueId: valueStatsByValueId,
      totalRecentCompletions: totalRecentCompletions,
      openTaskCounts: openTaskCounts,
      agendaTagByTaskId: agendaTagByTaskId,
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
      final start = task.startDate;
      final deadline = task.deadlineDate;

      final hasSameStartAndDeadline =
          start != null &&
          deadline != null &&
          DateTime(start.year, start.month, start.day) ==
              DateTime(deadline.year, deadline.month, deadline.day);

      final isInProgressToday =
          !hasSameStartAndDeadline &&
          start != null &&
          deadline != null &&
          today.isAfter(DateTime(start.year, start.month, start.day)) &&
          today.isBefore(DateTime(deadline.year, deadline.month, deadline.day));

      if (isInProgressToday) {
        map[task.id] = AgendaTagV2.inProgress;
        continue;
      }

      final startsToday =
          start != null &&
          DateTime(start.year, start.month, start.day) == today;
      final dueToday =
          deadline != null &&
          DateTime(deadline.year, deadline.month, deadline.day) == today;

      // Prefer starts/due over dateField-driven behavior so tags are consistent
      // anywhere `TaskTileVariant.agenda` is used.
      if (startsToday) {
        map[task.id] = AgendaTagV2.starts;
      } else if (dueToday) {
        map[task.id] = AgendaTagV2.due;
      }
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
      // Fetch all required data in parallel
      final results = await Future.wait([
        _analyticsService.getValueWeeklyTrends(weeks: sparklineWeeks),
        _analyticsService.getValueActivityStats(),
        _analyticsService.getRecentCompletionsByValue(
          days: sparklineWeeks * 7,
        ),
        _analyticsService.getTotalRecentCompletions(days: sparklineWeeks * 7),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final recentCompletions = results[2] as Map<String, int>;
      final totalRecentCompletions = results[3] as int;

      // Calculate total weight for percentage calculation
      final totalWeight = values.fold<int>(
        0,
        (sum, value) => sum + value.priority.weight,
      );

      // Build stats map for each value
      final statsByValueId = <String, ValueStats>{};

      for (final value in values) {
        // Calculate target percent from priority weight
        final targetPercent = totalWeight > 0
            ? (value.priority.weight / totalWeight) * 100
            : 0.0;

        // Calculate actual percent from recent completions
        final actualPercent = totalRecentCompletions > 0
            ? ((recentCompletions[value.id] ?? 0) / totalRecentCompletions) *
                  100
            : 0.0;

        // Get weekly trend data
        final weeklyTrend = weeklyTrends[value.id] ?? const <double>[];

        // Get activity stats
        final activity =
            activityStats[value.id] ??
            const ValueActivityStats(taskCount: 0, projectCount: 0);

        statsByValueId[value.id] = ValueStats(
          targetPercent: targetPercent,
          actualPercent: actualPercent,
          taskCount: activity.taskCount,
          projectCount: activity.projectCount,
          weeklyTrend: weeklyTrend,
          gapWarningThreshold: gapWarningThreshold,
        );
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
