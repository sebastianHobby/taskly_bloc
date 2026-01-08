import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/attention/attention_item.dart';
import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_project_history_window.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/domain/models/settings/project_health_review_settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_history_metrics.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_detector.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:uuid/uuid.dart';

/// Evaluates attention rules against current data to produce AttentionItems
///
/// Called by screen section interpreters when evaluating attention-related
/// templates (issuesSummary, allocationAlerts, checkInSummary).
///
/// Uses rule-based evaluation with dismissal tracking via state hashes.
class AttentionEvaluator {
  AttentionEvaluator({
    required AttentionRepositoryContract attentionRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required SettingsRepositoryContract settingsRepository,
  }) : _attentionRepository = attentionRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _settingsRepository = settingsRepository;

  final AttentionRepositoryContract _attentionRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final SettingsRepositoryContract _settingsRepository;
  final _uuid = const Uuid();

  // ==========================================================================
  // Public Evaluation Methods
  // ==========================================================================

  /// Evaluate issues (problems) for given entity types
  ///
  /// Used by IssuesSummaryBlock to get overdue/stale/idle issues
  Future<List<AttentionItem>> evaluateIssues({
    List<AttentionEntityType>? entityTypes,
    AttentionSeverity? minSeverity,
  }) async {
    final rules = await _attentionRepository
        .watchRulesByType(AttentionRuleType.problem)
        .first;

    final activeRules = rules.where((r) => r.active).toList();
    final items = <AttentionItem>[];

    for (final rule in activeRules) {
      // Filter by requested entity types
      final entityType = _parseEntityType(
        rule.entitySelector['entity_type'] as String?,
      );
      if (entityTypes != null && !entityTypes.contains(entityType)) {
        continue;
      }

      // Filter by minimum severity
      if (minSeverity != null &&
          _severityIndex(rule.severity) < _severityIndex(minSeverity)) {
        continue;
      }

      final ruleItems = await _evaluateProblemRule(rule);
      items.addAll(ruleItems);
    }

    return items;
  }

  /// Evaluate allocation warnings
  ///
  /// Used by AllocationAlertsBlock to show snapshot-driven allocation alerts.
  Future<List<AttentionItem>> evaluateAllocationAlerts() async {
    final rules = await _attentionRepository
        .watchRulesByType(AttentionRuleType.allocationWarning)
        .first;

    final activeRules = rules.where((r) => r.active).toList();
    final items = <AttentionItem>[];

    for (final rule in activeRules) {
      final ruleItems = await _evaluateAllocationRule(rule);
      items.addAll(ruleItems);
    }

    return items;
  }

  /// Evaluate due reviews
  ///
  /// Used by CheckInSummaryBlock to show reviews that need attention
  Future<List<AttentionItem>> evaluateReviews() async {
    final rules = await _attentionRepository
        .watchRulesByType(AttentionRuleType.review)
        .first;

    final activeRules = rules.where((r) => r.active).toList();

    final reviewSessionRules = activeRules
        .where((r) {
          final entityType = _parseEntityType(
            r.entitySelector['entity_type'] as String?,
          );
          return entityType == AttentionEntityType.reviewSession;
        })
        .toList(growable: false);

    final projectHealthRules = activeRules
        .where((r) {
          final entityType = _parseEntityType(
            r.entitySelector['entity_type'] as String?,
          );
          return entityType == AttentionEntityType.project;
        })
        .toList(growable: false);

    final items = <AttentionItem>[];

    // Project health reviews: allow multiple coaching prompts.
    if (projectHealthRules.isNotEmpty) {
      items.addAll(await _evaluateProjectHealthReviews(projectHealthRules));
    }

    // Design: only ever show ONE review at a time.
    // If multiple reviews are due, select the most overdue.
    final candidates =
        <({AttentionRule rule, int overdueDays, int freqDays})>[];

    for (final rule in reviewSessionRules) {
      final dueInfo = await _getReviewDueInfo(rule);
      if (dueInfo == null) continue;
      candidates.add((
        rule: rule,
        overdueDays: dueInfo.overdueDays,
        freqDays: dueInfo.frequencyDays,
      ));
    }

    if (candidates.isEmpty) return items;

    candidates.sort((a, b) {
      final score = b.overdueDays.compareTo(a.overdueDays);
      if (score != 0) return score;
      final cadence = a.freqDays.compareTo(b.freqDays);
      if (cadence != 0) return cadence;
      return a.rule.ruleKey.compareTo(b.rule.ruleKey);
    });

    final best = candidates.first;
    items.add(_createReviewItem(best.rule, overdueDays: best.overdueDays));

    items.sort((a, b) {
      final order = a.ruleId.compareTo(b.ruleId);
      if (order != 0) return order;
      return a.title.compareTo(b.title);
    });

    return items;
  }

  Future<List<AttentionItem>> _evaluateProjectHealthReviews(
    List<AttentionRule> rules,
  ) async {
    final allocationConfig = await _settingsRepository.load(
      SettingsKey.allocation,
    );
    final settings = _resolveProjectHealthSettings(allocationConfig);
    final settingsFingerprint = _projectHealthSettingsFingerprint(
      settings,
      focusMode: allocationConfig.focusMode,
    );

    final todayUtc = DateTime.now().toUtc();
    AllocationProjectHistoryWindow? historyWindow;

    if (rules.any((r) {
      final predicate = r.entitySelector['predicate'] as String?;
      return predicate == 'highValueNeglected' ||
          predicate == 'noAllocatedRecently';
    })) {
      historyWindow = await _allocationSnapshotRepository
          .getProjectHistoryWindow(
            windowEndDayUtc: todayUtc,
            windowDays: settings.historyWindowDays,
          );
    }

    final projects = await _projectRepository.watchAll().first;
    final activeProjects = projects.where((p) => !p.completed).toList();

    final tasks = await _taskRepository.watchAll().first;
    final tasksByProjectId = <String, List<Task>>{};
    for (final task in tasks) {
      final projectId = task.projectId;
      if (projectId == null) continue;
      tasksByProjectId.putIfAbsent(projectId, () => <Task>[]).add(task);
    }

    final items = <AttentionItem>[];

    for (final rule in rules) {
      final predicate = rule.entitySelector['predicate'] as String?;
      if (predicate == null) continue;

      final ruleItems = switch (predicate) {
        'highValueNeglected' => await _evaluateHighValueNeglectedProjects(
          rule: rule,
          projects: activeProjects,
          historyWindow: historyWindow,
          settings: settings,
          settingsFingerprint: settingsFingerprint,
        ),
        'noAllocatedRecently' => await _evaluateNoAllocatedRecentlyProjects(
          rule: rule,
          projects: activeProjects,
          historyWindow: historyWindow,
          settings: settings,
          settingsFingerprint: settingsFingerprint,
        ),
        'noAllocatableTasks' => await _evaluateNoAllocatableTasksProjects(
          rule: rule,
          projects: activeProjects,
          tasksByProjectId: tasksByProjectId,
          allocationConfig: allocationConfig,
          settings: settings,
          settingsFingerprint: settingsFingerprint,
        ),
        _ => const <AttentionItem>[],
      };

      items.addAll(ruleItems);
    }

    return items;
  }

  ProjectHealthReviewSettings _resolveProjectHealthSettings(
    AllocationConfig allocationConfig,
  ) {
    final persisted = allocationConfig.projectHealthReviewSettings;
    if (allocationConfig.focusMode == FocusMode.personalized) {
      return persisted;
    }

    final preset = ProjectHealthReviewSettings.forFocusMode(
      allocationConfig.focusMode,
    );

    // Keep runtime gate state stable even when using presets.
    return preset.copyWith(
      noAllocatableFirstDayUtc: persisted.noAllocatableFirstDayUtc,
    );
  }

  String _projectHealthSettingsFingerprint(
    ProjectHealthReviewSettings settings, {
    required FocusMode focusMode,
  }) {
    return _stableFingerprint([
      'focusMode=${focusMode.name}',
      'enableHighValueNeglected=${settings.enableHighValueNeglected}',
      'enableNoAllocatedRecently=${settings.enableNoAllocatedRecently}',
      'enableNoAllocatableTasksGated=${settings.enableNoAllocatableTasksGated}',
      'historyWindowDays=${settings.historyWindowDays}',
      'minCoverageDays=${settings.minCoverageDays}',
      'primaryValueWeight=${settings.primaryValueWeight}',
      'secondaryValuesWeightFactor=${settings.secondaryValuesWeightFactor}',
      'highValueImportanceThreshold=${settings.highValueImportanceThreshold}',
      'highValueNeglectedDaysThreshold=${settings.highValueNeglectedDaysThreshold}',
      'highValueNeglectedTopK=${settings.highValueNeglectedTopK}',
      'noAllocatedRecentlyDaysThreshold=${settings.noAllocatedRecentlyDaysThreshold}',
      'noAllocatedRecentlyTopK=${settings.noAllocatedRecentlyTopK}',
      'noAllocatableGatingDays=${settings.noAllocatableGatingDays}',
      'noAllocatableTopK=${settings.noAllocatableTopK}',
    ]);
  }

  Future<List<AttentionItem>> _evaluateHighValueNeglectedProjects({
    required AttentionRule rule,
    required List<Project> projects,
    required AllocationProjectHistoryWindow? historyWindow,
    required ProjectHealthReviewSettings settings,
    required String settingsFingerprint,
  }) async {
    if (!settings.enableHighValueNeglected) return const <AttentionItem>[];
    if (historyWindow == null) return const <AttentionItem>[];
    if (historyWindow.snapshotCoverageDays < settings.minCoverageDays) {
      return const <AttentionItem>[];
    }

    final todayDayUtc = _dateOnlyUtc(DateTime.now().toUtc());

    final scored =
        <
          ({Project project, int importance, int daysSince, DateTime? lastDay})
        >[];

    for (final project in projects) {
      final importance = _projectImportanceScore(project, settings);
      if (importance < settings.highValueImportanceThreshold) continue;

      final lastDay = historyWindow.lastAllocatedDayByProjectId[project.id];
      final daysSince = AllocationHistoryMetrics.daysSinceLastAllocated(
        todayUtc: todayDayUtc,
        lastAllocatedDayUtc: lastDay,
        settings: settings,
      );

      if (daysSince < settings.highValueNeglectedDaysThreshold) continue;
      scored.add((
        project: project,
        importance: importance,
        daysSince: daysSince,
        lastDay: lastDay,
      ));
    }

    scored.sort((a, b) {
      final imp = b.importance.compareTo(a.importance);
      if (imp != 0) return imp;
      final days = b.daysSince.compareTo(a.daysSince);
      if (days != 0) return days;
      return a.project.name.compareTo(b.project.name);
    });

    final selected = scored.take(settings.highValueNeglectedTopK);
    final items = <AttentionItem>[];

    for (final entry in selected) {
      final project = entry.project;
      final stateHash = _computeProjectHealthStateHash(
        project,
        rule: rule,
        predicate: 'highValueNeglected',
        settingsFingerprint: settingsFingerprint,
        lastAllocatedDayUtc: entry.lastDay,
        importanceScore: entry.importance,
      );

      final dismissed = await _attentionRepository.wasDismissed(
        rule.id,
        project.id,
        stateHash,
      );
      if (dismissed) continue;

      items.add(
        _createProjectHealthItem(
          rule,
          project,
          metadata: {
            'project_importance_score': entry.importance,
            'days_since_last_allocated': entry.daysSince,
            'last_allocated_day_utc': entry.lastDay?.toIso8601String(),
            'settings_fingerprint': settingsFingerprint,
            'state_hash': stateHash,
          },
        ),
      );
    }

    return items;
  }

  Future<List<AttentionItem>> _evaluateNoAllocatedRecentlyProjects({
    required AttentionRule rule,
    required List<Project> projects,
    required AllocationProjectHistoryWindow? historyWindow,
    required ProjectHealthReviewSettings settings,
    required String settingsFingerprint,
  }) async {
    if (!settings.enableNoAllocatedRecently) return const <AttentionItem>[];
    if (historyWindow == null) return const <AttentionItem>[];
    if (historyWindow.snapshotCoverageDays < settings.minCoverageDays) {
      return const <AttentionItem>[];
    }

    final todayDayUtc = _dateOnlyUtc(DateTime.now().toUtc());

    final scored = <({Project project, int daysSince, DateTime? lastDay})>[];
    for (final project in projects) {
      final lastDay = historyWindow.lastAllocatedDayByProjectId[project.id];
      final daysSince = AllocationHistoryMetrics.daysSinceLastAllocated(
        todayUtc: todayDayUtc,
        lastAllocatedDayUtc: lastDay,
        settings: settings,
      );

      if (daysSince < settings.noAllocatedRecentlyDaysThreshold) continue;
      scored.add((project: project, daysSince: daysSince, lastDay: lastDay));
    }

    scored.sort((a, b) {
      final days = b.daysSince.compareTo(a.daysSince);
      if (days != 0) return days;
      return a.project.name.compareTo(b.project.name);
    });

    final selected = scored.take(settings.noAllocatedRecentlyTopK);
    final items = <AttentionItem>[];

    for (final entry in selected) {
      final project = entry.project;
      final stateHash = _computeProjectHealthStateHash(
        project,
        rule: rule,
        predicate: 'noAllocatedRecently',
        settingsFingerprint: settingsFingerprint,
        lastAllocatedDayUtc: entry.lastDay,
      );

      final dismissed = await _attentionRepository.wasDismissed(
        rule.id,
        project.id,
        stateHash,
      );
      if (dismissed) continue;

      items.add(
        _createProjectHealthItem(
          rule,
          project,
          metadata: {
            'days_since_last_allocated': entry.daysSince,
            'last_allocated_day_utc': entry.lastDay?.toIso8601String(),
            'settings_fingerprint': settingsFingerprint,
            'state_hash': stateHash,
          },
        ),
      );
    }

    return items;
  }

  Future<List<AttentionItem>> _evaluateNoAllocatableTasksProjects({
    required AttentionRule rule,
    required List<Project> projects,
    required Map<String, List<Task>> tasksByProjectId,
    required AllocationConfig allocationConfig,
    required ProjectHealthReviewSettings settings,
    required String settingsFingerprint,
  }) async {
    if (!settings.enableNoAllocatableTasksGated) return const [];

    final todayDayUtc = _dateOnlyUtc(DateTime.now().toUtc());
    final todayIso = todayDayUtc.toIso8601String();

    final persisted = allocationConfig.projectHealthReviewSettings;
    final gateMap = Map<String, String>.from(
      persisted.noAllocatableFirstDayUtc,
    );
    var gateMapChanged = false;

    final candidates =
        <({Project project, String firstDayIso, int daysPersisted})>[];

    for (final project in projects) {
      final projectTasks = tasksByProjectId[project.id] ?? const <Task>[];

      final hasAllocatable = projectTasks.any(
        (t) => _isTaskAllocatable(t, todayDayUtc),
      );

      final existingFirstDayIso = gateMap[project.id];

      if (hasAllocatable) {
        if (existingFirstDayIso != null) {
          gateMap.remove(project.id);
          gateMapChanged = true;
        }
        continue;
      }

      // No allocatable tasks.
      final firstDayIso = existingFirstDayIso ?? todayIso;
      if (existingFirstDayIso == null) {
        gateMap[project.id] = todayIso;
        gateMapChanged = true;
        continue; // Start gate; don't surface yet.
      }

      final firstDay = DateTime.tryParse(firstDayIso);
      if (firstDay == null) {
        gateMap[project.id] = todayIso;
        gateMapChanged = true;
        continue;
      }

      final daysPersisted = todayDayUtc
          .difference(_dateOnlyUtc(firstDay.toUtc()))
          .inDays;
      if (daysPersisted >= settings.noAllocatableGatingDays) {
        candidates.add((
          project: project,
          firstDayIso: firstDayIso,
          daysPersisted: daysPersisted,
        ));
      }
    }

    if (gateMapChanged) {
      final updatedConfig = allocationConfig.copyWith(
        projectHealthReviewSettings: persisted.copyWith(
          noAllocatableFirstDayUtc: gateMap,
        ),
      );
      await _settingsRepository.save(SettingsKey.allocation, updatedConfig);
    }

    candidates.sort((a, b) {
      final days = b.daysPersisted.compareTo(a.daysPersisted);
      if (days != 0) return days;
      return a.project.name.compareTo(b.project.name);
    });

    final selected = candidates.take(settings.noAllocatableTopK);
    final items = <AttentionItem>[];

    for (final entry in selected) {
      final project = entry.project;
      final stateHash = _computeProjectHealthStateHash(
        project,
        rule: rule,
        predicate: 'noAllocatableTasks',
        settingsFingerprint: settingsFingerprint,
        gateFirstDetectedDayUtcIso: entry.firstDayIso,
      );

      final dismissed = await _attentionRepository.wasDismissed(
        rule.id,
        project.id,
        stateHash,
      );
      if (dismissed) continue;

      items.add(
        _createProjectHealthItem(
          rule,
          project,
          metadata: {
            'no_allocatable_first_detected_day_utc': entry.firstDayIso,
            'no_allocatable_days_persisted': entry.daysPersisted,
            'settings_fingerprint': settingsFingerprint,
            'state_hash': stateHash,
          },
        ),
      );
    }

    return items;
  }

  bool _isTaskAllocatable(Task task, DateTime todayDayUtc) {
    if (task.completed) return false;
    final start = task.startDate;
    if (start == null) return true;
    final startDay = _dateOnlyUtc(start.toUtc());
    return !startDay.isAfter(todayDayUtc);
  }

  int _projectImportanceScore(
    Project project,
    ProjectHealthReviewSettings settings,
  ) {
    final primary = project.primaryValue;
    final primaryScore = primary == null
        ? 0.0
        : primary.priority.weight * settings.primaryValueWeight;
    final secondarySum = project.secondaryValues
        .map((v) => v.priority.weight)
        .fold<int>(0, (a, b) => a + b);
    final secondaryScore = secondarySum * settings.secondaryValuesWeightFactor;
    return (primaryScore + secondaryScore).round();
  }

  String _computeProjectHealthStateHash(
    Project project, {
    required AttentionRule rule,
    required String predicate,
    required String settingsFingerprint,
    DateTime? lastAllocatedDayUtc,
    int? importanceScore,
    String? gateFirstDetectedDayUtcIso,
  }) {
    final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);
    return _stableFingerprint([
      'entity=project',
      'projectId=${project.id}',
      'predicate=$predicate',
      'rule=$ruleFingerprint',
      'settings=$settingsFingerprint',
      'updatedAt=${project.updatedAt.toIso8601String()}',
      'completed=${project.completed}',
      'lastAllocatedDayUtc=${lastAllocatedDayUtc?.toIso8601String() ?? 'none'}',
      if (importanceScore != null) 'importance=$importanceScore',
      if (gateFirstDetectedDayUtcIso != null)
        'gateFirstDayUtc=$gateFirstDetectedDayUtcIso',
    ]);
  }

  AttentionItem _createProjectHealthItem(
    AttentionRule rule,
    Project project, {
    required Map<String, Object?> metadata,
  }) {
    final base = _createProjectItem(rule, project);
    return base.copyWith(
      metadata: {
        ...?base.metadata,
        ...metadata,
      },
    );
  }

  /// Check if any reviews are due (for launch mode decision)
  ///
  /// If true, ScreenDataInterpreter should navigate to /check-in workflow
  Future<bool> hasAnyReviewDue() async {
    final reviews = await evaluateReviews();
    return reviews.isNotEmpty;
  }

  /// Get total attention item count (for launch mode decision)
  ///
  /// If count > threshold, ScreenDataInterpreter should use workflow mode
  Future<int> getTotalAttentionCount({
    List<AttentionEntityType>? entityTypes,
  }) async {
    final issues = await evaluateIssues(entityTypes: entityTypes);
    final allocations = await evaluateAllocationAlerts();
    final reviews = await evaluateReviews();
    return issues.length + allocations.length + reviews.length;
  }

  // ==========================================================================
  // Private Problem Evaluation
  // ==========================================================================

  Future<List<AttentionItem>> _evaluateProblemRule(AttentionRule rule) async {
    final predicate = rule.entitySelector['predicate'] as String?;
    final entityTypeStr = rule.entitySelector['entity_type'] as String?;

    if (predicate == null || entityTypeStr == null) return [];

    final entityType = _parseEntityType(entityTypeStr);

    switch (entityType) {
      case AttentionEntityType.task:
        return _evaluateTaskPredicate(rule, predicate);
      case AttentionEntityType.project:
        return _evaluateProjectPredicate(rule, predicate);
      case AttentionEntityType.journal:
        return _evaluateJournalPredicate(rule, predicate);
      case AttentionEntityType.value:
      case AttentionEntityType.tracker:
      case AttentionEntityType.reviewSession:
        // Not yet implemented
        return [];
    }
  }

  Future<List<AttentionItem>> _evaluateTaskPredicate(
    AttentionRule rule,
    String predicate,
  ) async {
    final tasks = await _taskRepository.watchAll().first;
    final matching = <Task>[];

    for (final task in tasks) {
      if (task.completed) continue; // Skip completed tasks

      final matches = switch (predicate) {
        'isOverdue' => _isTaskOverdue(task, rule.triggerConfig),
        'isStale' => _isTaskStale(task, rule.triggerConfig),
        _ => false,
      };

      if (matches) {
        // Check if dismissed (with state hash)
        final stateHash = _computeTaskStateHash(
          task,
          rule: rule,
          predicate: predicate,
        );
        final dismissed = await _attentionRepository.wasDismissed(
          rule.id,
          task.id,
          stateHash,
        );
        if (!dismissed) {
          matching.add(task);
        }
      }
    }

    return matching.map((task) => _createTaskItem(rule, task)).toList();
  }

  Future<List<AttentionItem>> _evaluateProjectPredicate(
    AttentionRule rule,
    String predicate,
  ) async {
    final projects = await _projectRepository.watchAll().first;
    final matching = <Project>[];

    for (final project in projects) {
      if (project.completed) continue; // Skip completed projects

      final matches = switch (predicate) {
        'isIdle' => _isProjectIdle(project, rule.triggerConfig),
        'isStale' => _isProjectStale(project, rule.triggerConfig),
        _ => false,
      };

      if (matches) {
        // Check if dismissed (with state hash)
        final stateHash = _computeProjectStateHash(
          project,
          rule: rule,
          predicate: predicate,
        );
        final dismissed = await _attentionRepository.wasDismissed(
          rule.id,
          project.id,
          stateHash,
        );
        if (!dismissed) {
          matching.add(project);
        }
      }
    }

    return matching
        .map((project) => _createProjectItem(rule, project))
        .toList();
  }

  Future<List<AttentionItem>> _evaluateJournalPredicate(
    AttentionRule rule,
    String predicate,
  ) async {
    // Journal evaluation requires journal repository dependency.
    // Out of scope for v1 - journal rules will be implemented when
    // journal system is fully integrated with attention system.
    // See PHASE_4_PRESENTATION.md for planned implementation.
    return [];
  }

  // ==========================================================================
  // Private Allocation Evaluation
  // ==========================================================================

  Future<List<AttentionItem>> _evaluateAllocationRule(
    AttentionRule rule,
  ) async {
    final predicate = rule.entitySelector['predicate'] as String?;
    final entityTypeStr = rule.entitySelector['entity_type'] as String?;
    if (predicate == null || entityTypeStr == null) return [];

    final entityType = _parseEntityType(entityTypeStr);
    if (entityType != AttentionEntityType.task) return [];

    final dayUtc = _dateOnlyUtc(DateTime.now().toUtc());
    final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
      dayUtc,
    );

    if (snapshot == null) return [];

    final allocatedTaskIds = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .map((e) => e.entity.id)
        .toSet();

    final tasks = await _taskRepository.watchAll().first;
    final candidates = await _selectAllocationTaskCandidates(
      tasks,
      predicate: predicate,
    );

    final notAllocated = candidates
        .where((t) {
          if (t.completed) return false;
          return !allocatedTaskIds.contains(t.id);
        })
        .toList(growable: false);

    final items = <AttentionItem>[];
    final allocationVersion = snapshot.version;

    for (final task in notAllocated) {
      final stateHash = _computeAllocationTaskStateHash(
        task,
        rule: rule,
        predicate: predicate,
        dayUtc: dayUtc,
        allocationVersion: allocationVersion,
      );

      final dismissed = await _attentionRepository.wasDismissed(
        rule.id,
        task.id,
        stateHash,
      );

      if (!dismissed) {
        items.add(
          _createAllocationTaskItem(
            rule,
            task,
            dayUtc: dayUtc,
            allocationVersion: allocationVersion,
          ),
        );
      }
    }

    return items;
  }

  Future<List<Task>> _selectAllocationTaskCandidates(
    List<Task> tasks, {
    required String predicate,
  }) async {
    final allocationConfig = await _settingsRepository.load(
      SettingsKey.allocation,
    );
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);

    final projects = await _projectRepository.watchAll().first;
    final projectById = {for (final p in projects) p.id: p};

    // Back-compat: old predicate name before snapshot-based alerts.
    final normalizedPredicate = predicate == 'excludedFromAllocation'
        ? 'urgentValueless'
        : predicate;

    return switch (normalizedPredicate) {
      'urgentValueless' =>
        urgencyDetector
            .findUrgentValuelessTasks(tasks)
            .where((t) => !t.completed)
            .toList(growable: false),
      'urgentValueAligned' =>
        tasks
            .where(
              (t) =>
                  !t.completed &&
                  urgencyDetector.isTaskUrgent(t) &&
                  !t.isEffectivelyValueless,
            )
            .toList(growable: false),
      'projectUrgentValueless' =>
        tasks
            .where((t) {
              if (t.completed) return false;
              if (!t.isEffectivelyValueless) return false;

              final project =
                  t.project ??
                  (t.projectId == null ? null : projectById[t.projectId]);
              if (project == null) return false;
              return urgencyDetector.isProjectUrgent(project);
            })
            .toList(growable: false),
      _ => const <Task>[],
    };
  }

  AttentionItem _createAllocationTaskItem(
    AttentionRule rule,
    Task task, {
    required DateTime dayUtc,
    required int allocationVersion,
  }) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      ruleType: rule.ruleType,
      entityId: task.id,
      entityType: AttentionEntityType.task,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Allocation Alert',
      description: _formatTaskDescription(
        displayConfig['description'] as String? ?? 'Task needs allocation',
        task,
      ),
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: DateTime.now(),
      metadata: {
        'task_name': task.name,
        'deadline_date': task.deadlineDate?.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
        'allocation_day_utc': dayUtc.toIso8601String(),
        'allocation_version': allocationVersion,
      },
    );
  }

  String _computeAllocationTaskStateHash(
    Task task, {
    required AttentionRule rule,
    required String predicate,
    required DateTime dayUtc,
    required int allocationVersion,
  }) {
    final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);
    final day = _dateOnlyUtc(dayUtc).toIso8601String();

    return _stableFingerprint([
      'entity=task',
      'taskId=${task.id}',
      'predicate=$predicate',
      'rule=$ruleFingerprint',
      'allocationDayUtc=$day',
      'allocationVersion=$allocationVersion',
    ]);
  }

  DateTime _dateOnlyUtc(DateTime utc) {
    final asUtc = utc.toUtc();
    return DateTime.utc(asUtc.year, asUtc.month, asUtc.day);
  }

  // ==========================================================================
  // Private Review Evaluation
  // ==========================================================================

  Future<({int overdueDays, int frequencyDays})?> _getReviewDueInfo(
    AttentionRule rule,
  ) async {
    final frequencyDays = rule.triggerConfig['frequency_days'] as int? ?? 7;

    // Reviews use rule key as the entity ID.
    final lastResolution = await _attentionRepository.getLatestResolution(
      rule.id,
      rule.ruleKey,
    );

    if (lastResolution == null) {
      // Never completed = due. Treat as highly overdue so it wins.
      return (overdueDays: 1000000, frequencyDays: frequencyDays);
    }

    // Only count as complete if actually reviewed (not skipped/snoozed).
    if (lastResolution.resolutionAction != AttentionResolutionAction.reviewed) {
      return (overdueDays: 1000000, frequencyDays: frequencyDays);
    }

    final daysSinceCompletion = DateTime.now()
        .difference(lastResolution.resolvedAt)
        .inDays;
    final overdueDays = daysSinceCompletion - frequencyDays;

    if (overdueDays < 0) return null;
    return (overdueDays: overdueDays, frequencyDays: frequencyDays);
  }

  // ==========================================================================
  // Private Predicate Helpers
  // ==========================================================================

  bool _isTaskOverdue(Task task, Map<String, dynamic> config) {
    if (task.deadlineDate == null) return false;
    final thresholdHours = config['threshold_hours'] as int? ?? 0;
    final threshold = DateTime.now().subtract(Duration(hours: thresholdHours));
    return task.deadlineDate!.isBefore(threshold);
  }

  bool _isTaskStale(Task task, Map<String, dynamic> config) {
    final thresholdDays = config['threshold_days'] as int? ?? 30;
    final threshold = DateTime.now().subtract(Duration(days: thresholdDays));
    return task.updatedAt.isBefore(threshold);
  }

  bool _isProjectIdle(Project project, Map<String, dynamic> config) {
    final thresholdDays = config['threshold_days'] as int? ?? 30;
    final threshold = DateTime.now().subtract(Duration(days: thresholdDays));
    return project.updatedAt.isBefore(threshold);
  }

  bool _isProjectStale(Project project, Map<String, dynamic> config) {
    return _isProjectIdle(project, config); // Same logic for now
  }

  // ==========================================================================
  // Private Item Creators
  // ==========================================================================

  AttentionItem _createTaskItem(AttentionRule rule, Task task) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      ruleType: rule.ruleType,
      entityId: task.id,
      entityType: AttentionEntityType.task,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Task Issue',
      description: _formatTaskDescription(
        displayConfig['description'] as String? ?? 'Task needs attention',
        task,
      ),
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: DateTime.now(),
      metadata: {
        'task_name': task.name,
        'deadline_date': task.deadlineDate?.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
      },
    );
  }

  AttentionItem _createProjectItem(AttentionRule rule, Project project) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      ruleType: rule.ruleType,
      entityId: project.id,
      entityType: AttentionEntityType.project,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Project Issue',
      description: _formatProjectDescription(
        displayConfig['description'] as String? ?? 'Project needs attention',
        project,
      ),
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: DateTime.now(),
      metadata: {
        'project_name': project.name,
        'updated_at': project.updatedAt.toIso8601String(),
      },
    );
  }

  AttentionItem _createReviewItem(
    AttentionRule rule, {
    required int overdueDays,
  }) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      ruleType: rule.ruleType,
      entityId: rule.ruleKey, // Reviews use rule key as entity ID
      entityType: AttentionEntityType.reviewSession,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Review Due',
      description: displayConfig['description'] as String? ?? 'Time for review',
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: DateTime.now(),
      metadata: {
        'frequency_days': rule.triggerConfig['frequency_days'],
        'overdue_days': overdueDays,
        'review_type': rule.entitySelector['review_type'],
      },
    );
  }

  // ==========================================================================
  // Private Helpers
  // ==========================================================================

  AttentionEntityType _parseEntityType(String? value) {
    return AttentionEntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttentionEntityType.task,
    );
  }

  int _severityIndex(AttentionSeverity severity) {
    return switch (severity) {
      AttentionSeverity.info => 0,
      AttentionSeverity.warning => 1,
      AttentionSeverity.critical => 2,
    };
  }

  List<AttentionResolutionAction> _parseResolutionActions(
    List<String> actions,
  ) {
    return actions
        .map(
          (a) => AttentionResolutionAction.values.firstWhere(
            (e) => e.name == a,
            orElse: () => AttentionResolutionAction.reviewed,
          ),
        )
        .toList();
  }

  String _formatTaskDescription(String template, Task task) {
    return template
        .replaceAll('{name}', task.name)
        .replaceAll('{task_name}', task.name);
  }

  String _formatProjectDescription(String template, Project project) {
    return template
        .replaceAll('{name}', project.name)
        .replaceAll('{project_name}', project.name);
  }

  /// Compute state hash for dismissal tracking
  ///
  /// When a task is dismissed, we store this hash.
  /// If the hash changes (task was modified), the dismissal is invalidated.
  ///
  /// IMPORTANT: This value is persisted. It must be stable across app restarts.
  /// Do not use Dart's `hashCode` here.
  String _computeTaskStateHash(
    Task task, {
    required AttentionRule rule,
    required String predicate,
  }) {
    final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);

    // Variant A: only resurface when the user changes something relevant.
    final relevantParts = switch (predicate) {
      // Overdue should only resurface if deadline/completion changes.
      'isOverdue' => <String?>[
        task.deadlineDate?.toIso8601String(),
        task.completed.toString(),
      ],
      // Stale should resurface if task is updated (updatedAt changes).
      'isStale' => <String?>[
        task.updatedAt.toIso8601String(),
        task.completed.toString(),
      ],
      _ => <String?>[
        task.updatedAt.toIso8601String(),
        task.completed.toString(),
      ],
    };

    return _stableFingerprint([
      'entity=task',
      'taskId=${task.id}',
      'predicate=$predicate',
      'rule=$ruleFingerprint',
      ...relevantParts.whereType<String>().map((p) => 'v=$p'),
    ]);
  }

  String _computeProjectStateHash(
    Project project, {
    required AttentionRule rule,
    required String predicate,
  }) {
    final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);

    // Variant A: resurface when project is updated/completed state changes.
    return _stableFingerprint([
      'entity=project',
      'projectId=${project.id}',
      'predicate=$predicate',
      'rule=$ruleFingerprint',
      'updatedAt=${project.updatedAt.toIso8601String()}',
      'completed=${project.completed}',
    ]);
  }

  String _ruleFingerprint(AttentionRule rule, {required String predicate}) {
    // Include only the rule semantics that should invalidate a dismissal.
    // This ensures that changing thresholds/selector re-surfaces items.
    final selector = _stableMapFingerprint(rule.entitySelector);
    final trigger = _stableMapFingerprint(rule.triggerConfig);
    return _stableFingerprint([
      'ruleKey=${rule.ruleKey}',
      'ruleType=${rule.ruleType.name}',
      'predicate=$predicate',
      'selector=$selector',
      'trigger=$trigger',
    ]);
  }

  String _stableMapFingerprint(Map<String, dynamic> map) {
    final keys = map.keys.toList()..sort();
    return keys.map((k) => '$k=${map[k]}').join('&');
  }

  String _stableFingerprint(List<String> parts) {
    // A deterministic, stable "hash" string.
    // Stored verbatim and compared for equality.
    return parts.join('|');
  }
}
