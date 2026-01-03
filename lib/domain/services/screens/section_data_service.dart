import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_config.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_result.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart';
import 'package:taskly_bloc/domain/models/settings/value_ranking.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

/// Service for fetching data for screen sections.
///
/// This service handles data fetching for all section types defined in DR-017.
/// It coordinates with existing repositories and the allocation orchestrator
/// to provide section-specific data results.
class SectionDataService {
  SectionDataService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
    required AllocationOrchestrator allocationOrchestrator,
    WellbeingRepositoryContract? wellbeingRepository,
    AnalyticsService? analyticsService,
    SettingsRepositoryContract? settingsRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _labelRepository = labelRepository,
       _wellbeingRepository = wellbeingRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _analyticsService = analyticsService,
       _settingsRepository = settingsRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final LabelRepositoryContract _labelRepository;
  final WellbeingRepositoryContract? _wellbeingRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final AnalyticsService? _analyticsService;
  final SettingsRepositoryContract? _settingsRepository;

  /// Fetch data for a section (one-time)
  Future<SectionDataResult> fetchSectionData(Section section) async {
    talker.serviceLog(
      'SectionDataService',
      'fetchSectionData: ${section.runtimeType}',
    );
    talker.serviceLog('SectionDataService', 'Section details: $section');

    try {
      final result = await switch (section) {
        DataSection(:final config, :final relatedData, :final enrichment) =>
          _fetchDataSection(config, relatedData, enrichment),
        AllocationSection(:final sourceFilter, :final maxTasks) =>
          _fetchAllocationSection(sourceFilter, maxTasks),
        AgendaSection(
          :final dateField,
          :final grouping,
          :final additionalFilter,
        ) =>
          _fetchAgendaSection(dateField, grouping, additionalFilter),
      };

      talker.serviceLog(
        'SectionDataService',
        'Result type: ${result.runtimeType}',
      );
      talker.serviceLog(
        'SectionDataService',
        'Primary entities: ${result.primaryCount} items',
      );
      return result;
    } catch (e, st) {
      talker.handle(e, st, '[SectionDataService] fetchSectionData failed');
      rethrow;
    }
  }

  /// Watch data for a section (returns a stream)
  Stream<SectionDataResult> watchSectionData(Section section) {
    return switch (section) {
      DataSection(:final config, :final relatedData, :final enrichment) =>
        _watchDataSection(config, relatedData, enrichment),
      AllocationSection(:final sourceFilter, :final maxTasks) =>
        _watchAllocationSection(sourceFilter, maxTasks),
      AgendaSection(
        :final dateField,
        :final grouping,
        :final additionalFilter,
      ) =>
        _watchAgendaSection(dateField, grouping, additionalFilter),
    };
  }

  // ===========================================================================
  // DATA SECTION
  // ===========================================================================

  Future<SectionDataResult> _fetchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
    EnrichmentConfig? enrichmentConfig,
  ) async {
    final (entities, entityType) = await _fetchPrimaryEntities(config);
    final related = await _fetchRelatedData(entities, entityType, relatedData);
    final enrichment = await _computeEnrichment(
      enrichmentConfig,
      entities,
      entityType,
    );

    return SectionDataResult.data(
      primaryEntities: entities,
      primaryEntityType: entityType,
      relatedEntities: related,
      enrichment: enrichment,
    );
  }

  Stream<SectionDataResult> _watchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
    EnrichmentConfig? enrichmentConfig,
  ) async* {
    await for (final entities in _watchPrimaryEntities(config)) {
      final entityType = _getEntityType(config);
      final related = await _fetchRelatedData(
        entities,
        entityType,
        relatedData,
      );
      final enrichment = await _computeEnrichment(
        enrichmentConfig,
        entities,
        entityType,
      );

      yield SectionDataResult.data(
        primaryEntities: entities,
        primaryEntityType: entityType,
        relatedEntities: related,
        enrichment: enrichment,
      );
    }
  }

  String _getEntityType(DataConfig config) {
    return switch (config) {
      TaskDataConfig() => 'task',
      ProjectDataConfig() => 'project',
      LabelDataConfig() => 'label',
      ValueDataConfig() => 'value',
      JournalDataConfig() => 'journal',
    };
  }

  Future<(List<dynamic>, String)> _fetchPrimaryEntities(
    DataConfig config,
  ) async {
    return switch (config) {
      TaskDataConfig(:final query) => (
        await _taskRepository.watchAll(query).first,
        'task',
      ),
      ProjectDataConfig(:final query) => (
        await _projectRepository.watchAllByQuery(query).first,
        'project',
      ),
      LabelDataConfig(:final query) => (
        await _fetchLabels(query, excludeValues: true),
        'label',
      ),
      ValueDataConfig(:final query) => (
        await _fetchLabels(query, valuesOnly: true),
        'value',
      ),
      JournalDataConfig(:final query) => (
        await _fetchJournalEntries(query),
        'journal',
      ),
    };
  }

  Future<List<Label>> _fetchLabels(
    LabelQuery? query, {
    bool excludeValues = false,
    bool valuesOnly = false,
  }) async {
    // If a query is provided, use watchByType since LabelRepository doesn't
    // support arbitrary queries yet
    if (valuesOnly) {
      return _labelRepository.watchByType(LabelType.value).first;
    } else if (excludeValues) {
      return _labelRepository.watchByType(LabelType.label).first;
    } else {
      return _labelRepository.watchAll().first;
    }
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

  Stream<List<dynamic>> _watchPrimaryEntities(DataConfig config) {
    return switch (config) {
      TaskDataConfig(:final query) => _taskRepository.watchAll(query),
      ProjectDataConfig(:final query) => _projectRepository.watchAllByQuery(
        query,
      ),
      LabelDataConfig() => _labelRepository.watchByType(LabelType.label),
      ValueDataConfig() => _labelRepository.watchByType(LabelType.value),
      JournalDataConfig(:final query) => _watchJournalEntries(query),
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

  Future<Map<String, List<dynamic>>> _fetchRelatedData(
    List<dynamic> primaryEntities,
    String entityType,
    List<RelatedDataConfig> relatedData,
  ) async {
    final result = <String, List<dynamic>>{};

    for (final config in relatedData) {
      final key = _getRelatedDataKey(config);
      result[key] = await _fetchRelatedEntities(
        primaryEntities,
        entityType,
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

  Future<List<dynamic>> _fetchRelatedEntities(
    List<dynamic> primaryEntities,
    String entityType,
    RelatedDataConfig config,
  ) async {
    return switch (config) {
      RelatedTasksConfig(:final additionalFilter) => await _fetchRelatedTasks(
        primaryEntities,
        entityType,
        additionalFilter,
      ),
      RelatedProjectsConfig() => await _fetchRelatedProjects(
        primaryEntities,
        entityType,
      ),
      ValueHierarchyConfig() => await _fetchValueHierarchy(primaryEntities),
    };
  }

  Future<List<Task>> _fetchRelatedTasks(
    List<dynamic> entities,
    String entityType,
    TaskQuery? filter,
  ) async {
    final allTasks = <Task>[];

    switch (entityType) {
      case 'project':
        for (final project in entities.cast<Project>()) {
          // Get tasks belonging to this project using TaskQuery
          final projectQuery = TaskQuery.byProject(project.id);
          final tasks = await _taskRepository.watchAll(projectQuery).first;
          allTasks.addAll(tasks);
        }
      case 'label':
      case 'value':
        for (final label in entities.cast<Label>()) {
          // Get tasks with this label using TaskQuery
          final labelQuery = TaskQuery.forLabel(labelId: label.id);
          final tasks = await _taskRepository.watchAll(labelQuery).first;
          allTasks.addAll(tasks);
        }
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
    List<dynamic> entities,
    String entityType,
  ) async {
    final projectIds = <String>{};

    switch (entityType) {
      case 'task':
        for (final task in entities.cast<Task>()) {
          if (task.projectId != null) {
            projectIds.add(task.projectId!);
          }
        }
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
    // Special 3-level hierarchy: Value → Project → Task
    // Returns a flat list but preserves the hierarchical context
    // Implementation can be expanded based on specific needs
    return [];
  }

  // ===========================================================================
  // ALLOCATION SECTION
  // ===========================================================================

  Future<SectionDataResult> _fetchAllocationSection(
    TaskQuery? sourceFilter,
    int? maxTasks,
  ) async {
    // Get current allocation from orchestrator
    final allocation = await _allocationOrchestrator.watchAllocation().first;

    // Check if value setup is required
    if (allocation.requiresValueSetup) {
      return SectionDataResult.allocation(
        allocatedTasks: const [],
        totalAvailable: 0,
        requiresValueSetup: true,
      );
    }

    var tasks = allocation.allocatedTasks.map((at) => at.task).toList();

    // Apply source filter if provided
    if (sourceFilter != null) {
      tasks = _applyTaskFilter(tasks, sourceFilter);
    }

    // Limit if maxTasks specified
    if (maxTasks != null && tasks.length > maxTasks) {
      tasks = tasks.take(maxTasks).toList();
    }

    // Count total available (all non-completed tasks)
    final totalAvailable = await _taskRepository.count(TaskQuery.incomplete());

    // Extract excluded urgent tasks for problem detection
    final excludedUrgentTasks = allocation.excludedTasks
        .where((e) => e.isUrgent ?? false)
        .toList();

    return SectionDataResult.allocation(
      allocatedTasks: tasks,
      totalAvailable: totalAvailable,
      excludedCount: allocation.excludedTasks.length,
      excludedUrgentTasks: excludedUrgentTasks,
    );
  }

  Stream<SectionDataResult> _watchAllocationSection(
    TaskQuery? sourceFilter,
    int? maxTasks,
  ) async* {
    await for (final allocation in _allocationOrchestrator.watchAllocation()) {
      // Check if value setup is required
      if (allocation.requiresValueSetup) {
        yield SectionDataResult.allocation(
          allocatedTasks: const [],
          totalAvailable: 0,
          requiresValueSetup: true,
        );
        continue;
      }

      var tasks = allocation.allocatedTasks.map((at) => at.task).toList();

      // Apply source filter if provided
      if (sourceFilter != null) {
        tasks = _applyTaskFilter(tasks, sourceFilter);
      }

      // Limit if maxTasks specified
      if (maxTasks != null && tasks.length > maxTasks) {
        tasks = tasks.take(maxTasks).toList();
      }

      // Count total available
      final totalAvailable = await _taskRepository.count(
        TaskQuery.incomplete(),
      );

      // Extract excluded urgent tasks for problem detection
      final excludedUrgentTasks = allocation.excludedTasks
          .where((e) => e.isUrgent ?? false)
          .toList();

      yield SectionDataResult.allocation(
        allocatedTasks: tasks,
        totalAvailable: totalAvailable,
        excludedCount: allocation.excludedTasks.length,
        excludedUrgentTasks: excludedUrgentTasks,
      );
    }
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
    AgendaDateField dateField,
    AgendaGrouping grouping,
    TaskQuery? additionalFilter,
  ) async {
    final tasks = await _taskRepository.watchAll(additionalFilter).first;
    final (grouped, order) = _groupTasksByDate(tasks, dateField, grouping);

    return SectionDataResult.agenda(
      groupedTasks: grouped,
      groupOrder: order,
    );
  }

  Stream<SectionDataResult> _watchAgendaSection(
    AgendaDateField dateField,
    AgendaGrouping grouping,
    TaskQuery? additionalFilter,
  ) async* {
    await for (final tasks in _taskRepository.watchAll(additionalFilter)) {
      final (grouped, order) = _groupTasksByDate(tasks, dateField, grouping);

      yield SectionDataResult.agenda(
        groupedTasks: grouped,
        groupOrder: order,
      );
    }
  }

  (Map<String, List<Task>>, List<String>) _groupTasksByDate(
    List<Task> tasks,
    AgendaDateField dateField,
    AgendaGrouping grouping,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final groups = <String, List<Task>>{};
    final order = <String>[];

    DateTime? getDate(Task task) {
      return switch (dateField) {
        AgendaDateField.deadlineDate => task.deadlineDate,
        AgendaDateField.startDate => task.startDate,
        // scheduledFor is not currently on Task - fall back to deadlineDate
        AgendaDateField.scheduledFor => task.deadlineDate,
      };
    }

    for (final task in tasks) {
      final date = getDate(task);
      if (date == null) continue;

      final groupKey = switch (grouping) {
        AgendaGrouping.standard => _getStandardGroupKey(
          date,
          today,
          tomorrow,
          weekEnd,
        ),
        AgendaGrouping.byDate => _formatDate(date),
        AgendaGrouping.overdueFirst => _getOverdueFirstGroupKey(
          date,
          today,
          tomorrow,
          weekEnd,
        ),
      };

      groups.putIfAbsent(groupKey, () => []).add(task);
      if (!order.contains(groupKey)) order.add(groupKey);
    }

    // Sort order based on grouping type
    if (grouping == AgendaGrouping.overdueFirst) {
      order.sort((a, b) => _groupPriority(a).compareTo(_groupPriority(b)));
    }

    return (groups, order);
  }

  String _getStandardGroupKey(
    DateTime date,
    DateTime today,
    DateTime tomorrow,
    DateTime weekEnd,
  ) {
    if (date.isBefore(today)) return 'Overdue';
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    if (date.isBefore(weekEnd)) return 'This Week';
    return 'Later';
  }

  String _getOverdueFirstGroupKey(
    DateTime date,
    DateTime today,
    DateTime tomorrow,
    DateTime weekEnd,
  ) {
    // Same as standard but ordering is handled separately
    return _getStandardGroupKey(date, today, tomorrow, weekEnd);
  }

  int _groupPriority(String groupKey) {
    return switch (groupKey) {
      'Overdue' => 0,
      'Today' => 1,
      'Tomorrow' => 2,
      'This Week' => 3,
      'Later' => 4,
      _ => 5,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    List<dynamic> entities,
    String entityType,
  ) async {
    if (config == null) return null;

    return switch (config) {
      ValueStatsEnrichment(:final sparklineWeeks, :final gapWarningThreshold) =>
        _computeValueStatsEnrichment(
          entities,
          entityType,
          sparklineWeeks,
          gapWarningThreshold,
        ),
    };
  }

  /// Compute value statistics enrichment.
  ///
  /// Requires analytics service and settings repository to be available.
  Future<EnrichmentResult?> _computeValueStatsEnrichment(
    List<dynamic> entities,
    String entityType,
    int sparklineWeeks,
    int gapWarningThreshold,
  ) async {
    // Only compute for value entities
    if (entityType != 'value') {
      talker.warning(
        '[SectionDataService] ValueStats enrichment requested for non-value '
        'entity type: $entityType',
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
        _settingsRepository.load(SettingsKey.valueRanking),
      ]);

      final weeklyTrends = results[0] as Map<String, List<double>>;
      final activityStats = results[1] as Map<String, ValueActivityStats>;
      final recentCompletions = results[2] as Map<String, int>;
      final totalRecentCompletions = results[3] as int;
      final unassignedTaskCount = results[4] as int;
      final valueRanking = results[5] as ValueRanking;

      // Calculate total weight for percentage calculation
      final totalWeight = valueRanking.items.fold<int>(
        0,
        (sum, item) => sum + item.weight,
      );

      // Build stats map for each value
      final statsByValueId = <String, ValueStats>{};
      final values = entities.cast<Label>();

      for (final value in values) {
        // Find ranking item for this value
        final rankItem = valueRanking.items.firstWhere(
          (item) => item.labelId == value.id,
          orElse: () => ValueRankItem(labelId: value.id, weight: 5),
        );

        // Calculate target percent from ranking weight
        final targetPercent = totalWeight > 0
            ? (rankItem.weight / totalWeight) * 100
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
