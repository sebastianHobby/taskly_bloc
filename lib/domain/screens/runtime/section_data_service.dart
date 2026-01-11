import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_result.dart';
import 'package:taskly_bloc/domain/screens/language/models/related_data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
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
    WellbeingRepositoryContract? wellbeingRepository,
    AnalyticsService? analyticsService,
    SettingsRepositoryContract? settingsRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _wellbeingRepository = wellbeingRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _dayKeyService = dayKeyService,
       _agendaDataService = agendaDataService,
       _analyticsService = analyticsService,
       _settingsRepository = settingsRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final WellbeingRepositoryContract? _wellbeingRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final HomeDayKeyService _dayKeyService;
  final AgendaSectionDataService _agendaDataService;
  final AnalyticsService? _analyticsService;
  final SettingsRepositoryContract? _settingsRepository;

  DateTime _todayUtcDay() => _dayKeyService.todayDayKeyUtc();

  Future<SectionDataResult> fetchDataList(DataListSectionParams params) async {
    return _fetchDataSection(
      params.config,
      params.relatedData,
      params.enrichment,
    );
  }

  Stream<SectionDataResult> watchDataList(DataListSectionParams params) {
    return _watchDataSection(
      params.config,
      params.relatedData,
      params.enrichment,
    );
  }

  Future<SectionDataResult> fetchAllocation(AllocationSectionParams params) {
    return _fetchAllocationSection(
      sourceFilter: params.sourceFilter,
      maxTasks: params.maxTasks,
      displayMode: params.displayMode,
      showExcludedSection: params.showExcludedSection,
    );
  }

  Stream<SectionDataResult> watchAllocation(AllocationSectionParams params) {
    return _watchAllocationSection(
      sourceFilter: params.sourceFilter,
      maxTasks: params.maxTasks,
      displayMode: params.displayMode,
      showExcludedSection: params.showExcludedSection,
    );
  }

  Future<SectionDataResult> fetchAgenda(AgendaSectionParams params) {
    return _fetchAgendaSection(params);
  }

  Stream<SectionDataResult> watchAgenda(AgendaSectionParams params) {
    return _watchAgendaSection(params);
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

  Future<SectionDataResult> _fetchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
    EnrichmentConfig? enrichmentConfig,
  ) async {
    final kind = _kindFor(config);
    final entities = await _fetchPrimaryEntities(config);
    final related = await _fetchRelatedData(entities, kind, relatedData);
    final enrichment = await _computeEnrichment(
      enrichmentConfig,
      entities,
      kind,
    );

    return SectionDataResult.data(
      items: _toScreenItems(kind, entities),
      relatedEntities: related,
      enrichment: enrichment,
    );
  }

  Stream<SectionDataResult> _watchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
    EnrichmentConfig? enrichmentConfig,
  ) {
    final kind = _kindFor(config);

    // Latest snapshot wins: if the primary entities stream emits again while
    // related/enrichment computation is still running, cancel the in-flight
    // computation and start a new one for the latest entities.
    return _watchPrimaryEntities(config).switchMap(
      (entities) => Stream.fromFuture(
        _buildDataSectionResult(
          kind: kind,
          entities: entities,
          relatedData: relatedData,
          enrichmentConfig: enrichmentConfig,
        ),
      ),
    );
  }

  Future<SectionDataResult> _buildDataSectionResult({
    required _PrimaryEntityKind kind,
    required List<Object> entities,
    required List<RelatedDataConfig> relatedData,
    required EnrichmentConfig? enrichmentConfig,
  }) async {
    final related = await _fetchRelatedData(entities, kind, relatedData);
    final enrichment = await _computeEnrichment(
      enrichmentConfig,
      entities,
      kind,
    );

    return SectionDataResult.data(
      items: _toScreenItems(kind, entities),
      relatedEntities: related,
      enrichment: enrichment,
    );
  }

  Future<List<Object>> _fetchPrimaryEntities(DataConfig config) async {
    return switch (config) {
      TaskDataConfig(:final query) =>
        (await _taskRepository.watchAll(query).first).cast<Object>(),
      ProjectDataConfig(:final query) =>
        (await _projectRepository.watchAll(query).first).cast<Object>(),
      ValueDataConfig() => (await _valueRepository.getAll()).cast<Object>(),
      JournalDataConfig(:final query) => (await _fetchJournalEntries(
        query,
      )).cast<Object>(),
    };
  }

  Future<List<JournalEntry>> _fetchJournalEntries(JournalQuery? query) async {
    if (_wellbeingRepository == null) {
      talker.warning(
        '[SectionDataService] WellbeingRepository not available for journal query',
      );
      return [];
    }
    // Use the repository's watchByQuery if available, otherwise fall back
    return _wellbeingRepository
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
      ValueDataConfig() => _valueRepository.watchAll().map(
        (i) => i.cast<Object>(),
      ),
      JournalDataConfig(:final query) => _watchJournalEntries(
        query,
      ).map((items) => items.cast<Object>()),
    };
  }

  Stream<List<JournalEntry>> _watchJournalEntries(JournalQuery? query) {
    if (_wellbeingRepository == null) {
      talker.warning(
        '[SectionDataService] WellbeingRepository not available for journal watch',
      );
      return Stream.value([]);
    }
    return _wellbeingRepository.watchJournalEntriesByQuery(
      query ?? JournalQuery.all(),
    );
  }

  Future<Map<String, List<Object>>> _fetchRelatedData(
    List<Object> entities,
    _PrimaryEntityKind entityKind,
    List<RelatedDataConfig> relatedData,
  ) async {
    final result = <String, List<Object>>{};

    for (final config in relatedData) {
      final key = _getRelatedDataKey(config);
      result[key] = await _fetchRelatedEntities(
        entities,
        entityKind,
        config,
      );
    }

    return result;
  }

  String _getRelatedDataKey(RelatedDataConfig config) {
    return switch (config) {
      RelatedTasksConfig() => 'tasks',
      RelatedProjectsConfig() => 'projects',
      ValueHierarchyConfig() => 'valueHierarchy',
    };
  }

  Future<List<Object>> _fetchRelatedEntities(
    List<Object> entities,
    _PrimaryEntityKind entityKind,
    RelatedDataConfig config,
  ) async {
    return switch (config) {
      RelatedTasksConfig(:final additionalFilter) => await _fetchRelatedTasks(
        entities,
        entityKind,
        additionalFilter,
      ),
      RelatedProjectsConfig() => await _fetchRelatedProjects(
        entities,
        entityKind,
      ),
      ValueHierarchyConfig() => (await _fetchValueHierarchy(
        entities,
      )).cast<Object>(),
    };
  }

  Future<List<Task>> _fetchRelatedTasks(
    List<Object> entities,
    _PrimaryEntityKind entityKind,
    TaskQuery? filter,
  ) async {
    final allTasks = <Task>[];

    switch (entityKind) {
      case _PrimaryEntityKind.task:
        break;
      case _PrimaryEntityKind.project:
        for (final project in entities.cast<Project>()) {
          // Get tasks belonging to this project using TaskQuery
          final projectQuery = TaskQuery.byProject(project.id);
          final tasks = await _taskRepository.watchAll(projectQuery).first;
          allTasks.addAll(tasks);
        }
      case _PrimaryEntityKind.value:
        for (final value in entities.cast<Value>()) {
          // Get tasks with this value using TaskQuery
          final valueQuery = TaskQuery.forValue(valueId: value.id);
          final tasks = await _taskRepository.watchAll(valueQuery).first;
          allTasks.addAll(tasks);
        }
      case _PrimaryEntityKind.journal:
        break;
    }

    // Remove duplicates
    final uniqueTasks = <String, Task>{};
    for (final task in allTasks) {
      uniqueTasks[task.id] = task;
    }

    var result = uniqueTasks.values.toList();

    // Apply additional filter if provided
    if (filter != null) {
      result = _applyTaskFilter(result, filter);
    }

    return result;
  }

  Future<List<Project>> _fetchRelatedProjects(
    List<Object> entities,
    _PrimaryEntityKind entityKind,
  ) async {
    final projectIds = <String>{};

    switch (entityKind) {
      case _PrimaryEntityKind.task:
        for (final task in entities.cast<Task>()) {
          if (task.projectId != null) {
            projectIds.add(task.projectId!);
          }
        }
      case _PrimaryEntityKind.project:
      case _PrimaryEntityKind.value:
      case _PrimaryEntityKind.journal:
        break;
    }

    if (projectIds.isEmpty) return [];

    // Fetch projects by IDs
    final projects = <Project>[];
    for (final id in projectIds) {
      final project = await _projectRepository.getById(id);
      if (project != null) {
        projects.add(project);
      }
    }

    return projects;
  }

  Future<List<dynamic>> _fetchValueHierarchy(List<dynamic> values) async {
    // Special 3-level hierarchy: Value â†’ Project â†’ Task
    // Returns a flat list but preserves the hierarchical context
    // Implementation can be expanded based on specific needs
    return [];
  }

  // ===========================================================================
  // ALLOCATION SECTION
  // ===========================================================================

  Future<SectionDataResult> _fetchAllocationSection({
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
    required bool showExcludedSection,
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
        showExcludedSection: showExcludedSection,
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
        showExcludedSection: showExcludedSection,
      );
    }

    // Build pinned tasks and value groups for UI rendering
    final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
      allocation.allocatedTasks,
      sourceFilter,
      maxTasks,
    );

    // Extract just the Task objects for backward compatibility
    final tasks = [
      ...pinnedTasks,
      ...tasksByValue.values.expand((g) => g.tasks),
    ].map((at) => at.task).toList();

    // Count total available (all non-completed tasks)
    final totalAvailable = await _taskRepository
        .watchAllCount(TaskQuery.incomplete())
        .first;

    // Allocation warnings are handled by the attention system.
    // Keep excluded tasks data only for optional â€œoutside focusâ€ rendering.
    final excludedUrgentTasks = allocation.excludedTasks
        .where((e) => e.isUrgent ?? false)
        .toList();

    return SectionDataResult.allocation(
      allocatedTasks: tasks,
      totalAvailable: totalAvailable,
      pinnedTasks: pinnedTasks,
      tasksByValue: tasksByValue,
      excludedCount: allocation.excludedTasks.length,
      excludedUrgentTasks: excludedUrgentTasks,
      excludedTasks: allocation.excludedTasks,
      activeFocusMode: allocation.activeFocusMode,
      displayMode: displayMode,
      showExcludedSection: showExcludedSection,
    );
  }

  Stream<SectionDataResult> _watchAllocationSection({
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
    required bool showExcludedSection,
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
            showExcludedSection: showExcludedSection,
          );
        }

        return _allocationOrchestrator.watchAllocation().switchMap(
          (allocation) => Stream.fromFuture(
            _buildAllocationSectionResult(
              allocation: allocation,
              sourceFilter: sourceFilter,
              maxTasks: maxTasks,
              displayMode: displayMode,
              showExcludedSection: showExcludedSection,
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
    required bool showExcludedSection,
  }) async {
    // Check if value setup is required
    if (allocation.requiresValueSetup) {
      return SectionDataResult.allocation(
        allocatedTasks: const [],
        totalAvailable: 0,
        requiresValueSetup: true,
        displayMode: displayMode,
        showExcludedSection: showExcludedSection,
      );
    }

    // Build pinned tasks and value groups for UI rendering
    final (pinnedTasks, tasksByValue) = await _buildAllocationGroups(
      allocation.allocatedTasks,
      sourceFilter,
      maxTasks,
    );

    // Extract just the Task objects for backward compatibility
    final tasks = [
      ...pinnedTasks,
      ...tasksByValue.values.expand((g) => g.tasks),
    ].map((at) => at.task).toList();

    // Count total available
    final totalAvailable = await _taskRepository
        .watchAllCount(TaskQuery.incomplete())
        .first;

    // Extract excluded urgent tasks for problem detection
    final excludedUrgentTasks = allocation.excludedTasks
        .where((e) => e.isUrgent ?? false)
        .toList();

    // Allocation warnings are handled by the attention system.

    return SectionDataResult.allocation(
      allocatedTasks: tasks,
      totalAvailable: totalAvailable,
      pinnedTasks: pinnedTasks,
      tasksByValue: tasksByValue,
      excludedCount: allocation.excludedTasks.length,
      excludedUrgentTasks: excludedUrgentTasks,
      excludedTasks: allocation.excludedTasks,
      activeFocusMode: allocation.activeFocusMode,
      displayMode: displayMode,
      showExcludedSection: showExcludedSection,
    );
  }

  Future<SectionDataResult> _buildAllocationSectionResultFromSnapshot({
    required AllocationSnapshot snapshot,
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
    required bool showExcludedSection,
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
      excludedCount: 0,
      excludedUrgentTasks: const [],
      excludedTasks: const [],
      activeFocusMode: allocationConfig.focusMode,
      displayMode: displayMode,
      showExcludedSection: showExcludedSection,
    );
  }

  Stream<SectionDataResult> _watchAllocationSectionFromSnapshot({
    required AllocationSnapshot snapshot,
    required TaskQuery? sourceFilter,
    required int? maxTasks,
    required AllocationDisplayMode displayMode,
    required bool showExcludedSection,
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
        excludedCount: 0,
        excludedUrgentTasks: const [],
        excludedTasks: const [],
        activeFocusMode: config.focusMode,
        displayMode: displayMode,
        showExcludedSection: showExcludedSection,
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

  Future<SectionDataResult> _fetchAgendaSection(
    AgendaSectionParams params,
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

    return SectionDataResult.agenda(
      agendaData: agendaData,
    );
  }

  Stream<SectionDataResult> _watchAgendaSection(
    AgendaSectionParams params,
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
  // ENRICHMENT COMPUTATION
  // ===========================================================================

  /// Compute enrichment data based on the requested config.
  ///
  /// Returns null if no enrichment was requested or if the required
  /// services are not available.
  Future<EnrichmentResult?> _computeEnrichment(
    EnrichmentConfig? config,
    List<Object> entities,
    _PrimaryEntityKind entityKind,
  ) async {
    if (config == null) return null;

    return switch (config) {
      ValueStatsEnrichment(:final sparklineWeeks, :final gapWarningThreshold) =>
        _computeValueStatsEnrichment(
          entities,
          entityKind,
          sparklineWeeks,
          gapWarningThreshold,
        ),
    };
  }

  /// Compute value statistics enrichment.
  ///
  /// Requires analytics service and settings repository to be available.
  Future<EnrichmentResult?> _computeValueStatsEnrichment(
    List<Object> entities,
    _PrimaryEntityKind entityKind,
    int sparklineWeeks,
    int gapWarningThreshold,
  ) async {
    // Only compute for value entities
    if (entityKind != _PrimaryEntityKind.value) {
      talker.warning(
        '[SectionDataService] ValueStats enrichment requested for non-value '
        'entity kind: $entityKind',
      );
      return null;
    }

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
        _analyticsService.getOrphanTaskCount(),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final recentCompletions = results[2] as Map<String, int>;
      final totalRecentCompletions = results[3] as int;
      final unassignedTaskCount = results[4] as int;

      final values = entities.cast<Value>();

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
        final weeklyTrend = weeklyTrends[value.id] ?? [];

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

      return EnrichmentResult.valueStats(
        statsByValueId: statsByValueId,
        totalRecentCompletions: totalRecentCompletions,
        unassignedTaskCount: unassignedTaskCount,
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

enum _PrimaryEntityKind {
  task,
  project,
  value,
  journal,
}
