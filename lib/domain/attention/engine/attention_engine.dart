import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as v2;
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule_runtime_state.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/services/allocation/urgency_detector.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:uuid/uuid.dart';

/// Reactive attention evaluation engine.
///
/// Phase 04 note:
/// - This is not wired into sections/UI yet (Phase 05).
/// - It re-evaluates on data changes and on [invalidations] pulses.
class AttentionEngine implements AttentionEngineContract {
  AttentionEngine({
    required v2.AttentionRepositoryContract attentionRepository,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required SettingsRepositoryContract settingsRepository,
    required HomeDayKeyService dayKeyService,
    required Stream<void> invalidations,
  }) : _attentionRepository = attentionRepository,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _settingsRepository = settingsRepository,
       _dayKeyService = dayKeyService,
       _invalidations = invalidations;

  final v2.AttentionRepositoryContract _attentionRepository;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final SettingsRepositoryContract _settingsRepository;
  final HomeDayKeyService _dayKeyService;
  final Stream<void> _invalidations;

  final _uuid = const Uuid();

  @override
  Stream<List<AttentionItem>> watch(AttentionQuery query) {
    final pulse$ = _invalidations
        // Convert to a value stream so it can be composed.
        .map((_) => DateTime.now().microsecondsSinceEpoch)
        .startWith(DateTime.now().microsecondsSinceEpoch);

    final dayUtc$ = pulse$
        .map((_) => _dayKeyService.todayDayKeyUtc())
        .distinct((a, b) => a.isAtSameMomentAs(b));

    final snapshot$ = dayUtc$.switchMap(
      _allocationSnapshotRepository.watchLatestForUtcDay,
    );

    // Ensure pulses also cause re-evaluation even when snapshot/rules/tasks
    // haven't changed.
    final snapshotOrPulse$ =
        Rx.combineLatest2<AllocationSnapshot?, int, AllocationSnapshot?>(
          snapshot$,
          pulse$,
          (snapshot, _) => snapshot,
        );

    final rules$ = _attentionRepository.watchActiveRules().map(
      (rules) => rules.where(query.matchesRule).toList(growable: false),
    );

    return Rx.combineLatest4<
          List<AttentionRule>,
          List<Task>,
          List<Project>,
          AllocationSnapshot?,
          ({
            List<AttentionRule> rules,
            List<Task> tasks,
            List<Project> projects,
            AllocationSnapshot? snapshot,
          })
        >(
          rules$,
          _taskRepository.watchAll(),
          _projectRepository.watchAll(),
          snapshotOrPulse$,
          (rules, tasks, projects, snapshot) => (
            rules: rules,
            tasks: tasks,
            projects: projects,
            snapshot: snapshot,
          ),
        )
        .asyncMap((inputs) => _evaluate(query, inputs));
  }

  Future<List<AttentionItem>> _evaluate(
    AttentionQuery query,
    ({
      List<AttentionRule> rules,
      List<Task> tasks,
      List<Project> projects,
      AllocationSnapshot? snapshot,
    })
    inputs,
  ) async {
    final items = <AttentionItem>[];

    for (final rule in inputs.rules) {
      if (!_matchesQueryEntityTypes(query, rule)) continue;
      if (!_matchesMinSeverity(query, rule)) continue;

      final ruleItems = await _evaluateRule(
        rule,
        tasks: inputs.tasks,
        projects: inputs.projects,
        snapshot: inputs.snapshot,
      );

      if (query.entityTypes == null) {
        items.addAll(ruleItems);
      } else {
        items.addAll(
          ruleItems.where((i) => query.entityTypes!.contains(i.entityType)),
        );
      }
    }

    return items;
  }

  bool _matchesQueryEntityTypes(AttentionQuery query, AttentionRule rule) {
    final filter = query.entityTypes;
    if (filter == null) return true;

    final entityTypeStr = rule.entitySelector['entity_type'] as String?;
    final entityType = _parseEntityType(entityTypeStr);
    if (entityType == null) return false;

    return filter.contains(entityType);
  }

  bool _matchesMinSeverity(AttentionQuery query, AttentionRule rule) {
    final min = query.minSeverity;
    if (min == null) return true;
    return _severityIndex(rule.severity) >= _severityIndex(min);
  }

  Future<List<AttentionItem>> _evaluateRule(
    AttentionRule rule, {
    required List<Task> tasks,
    required List<Project> projects,
    required AllocationSnapshot? snapshot,
  }) async {
    return switch (rule.ruleType) {
      AttentionRuleType.problem => _evaluateProblemRule(
        rule,
        tasks: tasks,
        projects: projects,
      ),
      AttentionRuleType.review => _evaluateReviewRule(rule),
      AttentionRuleType.allocationWarning => _evaluateAllocationRule(
        rule,
        tasks: tasks,
        projects: projects,
        snapshot: snapshot,
      ),
      AttentionRuleType.workflowStep => const <AttentionItem>[],
    };
  }

  Future<List<AttentionItem>> _evaluateProblemRule(
    AttentionRule rule, {
    required List<Task> tasks,
    required List<Project> projects,
  }) async {
    final predicate = rule.entitySelector['predicate'] as String?;
    final entityTypeStr = rule.entitySelector['entity_type'] as String?;

    if (predicate == null || entityTypeStr == null) {
      return const <AttentionItem>[];
    }

    final entityType = _parseEntityType(entityTypeStr);

    return switch (entityType) {
      AttentionEntityType.task => _evaluateTaskPredicate(
        rule,
        tasks,
        predicate,
      ),
      AttentionEntityType.project => _evaluateProjectPredicate(
        rule,
        projects,
        predicate,
      ),
      // Legacy evaluator treated journal as out-of-scope v1.
      AttentionEntityType.journal => const <AttentionItem>[],
      AttentionEntityType.value => const <AttentionItem>[],
      AttentionEntityType.tracker => const <AttentionItem>[],
      AttentionEntityType.reviewSession => const <AttentionItem>[],
      null => const <AttentionItem>[],
    };
  }

  Future<List<AttentionItem>> _evaluateTaskPredicate(
    AttentionRule rule,
    List<Task> tasks,
    String predicate,
  ) async {
    final runtimeStates = await _loadRuntimeStateIndex(rule.id);
    final latestResolutions = await _loadLatestResolutionIndex(rule.id);

    final now = DateTime.now();
    final matching = <Task>[];

    for (final task in tasks) {
      if (task.completed) continue;

      final matches = switch (predicate) {
        'isOverdue' => _isTaskOverdue(task, rule.triggerConfig),
        'isStale' => _isTaskStale(task, rule.triggerConfig),
        _ => false,
      };

      if (!matches) continue;

      final stateHash = _computeTaskStateHash(
        task,
        rule: rule,
        predicate: predicate,
      );

      final key = _runtimeKey(
        entityType: AttentionEntityType.task,
        entityId: task.id,
      );

      if (_isSuppressed(
        now: now,
        stateHash: stateHash,
        runtimeState: runtimeStates[key],
        latestResolution: latestResolutions[task.id],
      )) {
        continue;
      }

      matching.add(task);
    }

    return matching
        .map((t) => _createTaskItem(rule, t))
        .toList(growable: false);
  }

  Future<List<AttentionItem>> _evaluateProjectPredicate(
    AttentionRule rule,
    List<Project> projects,
    String predicate,
  ) async {
    final runtimeStates = await _loadRuntimeStateIndex(rule.id);
    final latestResolutions = await _loadLatestResolutionIndex(rule.id);

    final now = DateTime.now();
    final matching = <Project>[];

    for (final project in projects) {
      if (project.completed) continue;

      final matches = switch (predicate) {
        'isIdle' => _isProjectIdle(project, rule.triggerConfig),
        'isStale' => _isProjectStale(project, rule.triggerConfig),
        _ => false,
      };

      if (!matches) continue;

      final stateHash = _computeProjectStateHash(
        project,
        rule: rule,
        predicate: predicate,
      );

      final key = _runtimeKey(
        entityType: AttentionEntityType.project,
        entityId: project.id,
      );

      if (_isSuppressed(
        now: now,
        stateHash: stateHash,
        runtimeState: runtimeStates[key],
        latestResolution: latestResolutions[project.id],
      )) {
        continue;
      }

      matching.add(project);
    }

    return matching
        .map((p) => _createProjectItem(rule, p))
        .toList(growable: false);
  }

  Future<List<AttentionItem>> _evaluateAllocationRule(
    AttentionRule rule, {
    required List<Task> tasks,
    required List<Project> projects,
    required AllocationSnapshot? snapshot,
  }) async {
    if (snapshot == null) return const <AttentionItem>[];

    final predicate = rule.entitySelector['predicate'] as String?;
    final entityTypeStr = rule.entitySelector['entity_type'] as String?;
    if (predicate == null || entityTypeStr == null) {
      return const <AttentionItem>[];
    }

    final entityType = _parseEntityType(entityTypeStr);
    if (entityType != AttentionEntityType.task) return const <AttentionItem>[];

    final runtimeStates = await _loadRuntimeStateIndex(rule.id);
    final latestResolutions = await _loadLatestResolutionIndex(rule.id);

    final allocatedTaskIds = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .map((e) => e.entity.id)
        .toSet();

    final candidates = await _selectAllocationTaskCandidates(
      tasks,
      projects: projects,
      predicate: predicate,
    );

    final allocationVersion = snapshot.version;
    final dayUtc = snapshot.dayUtc;

    final now = DateTime.now();
    final items = <AttentionItem>[];

    for (final task in candidates) {
      if (task.completed) continue;
      if (allocatedTaskIds.contains(task.id)) continue;

      final stateHash = _computeAllocationTaskStateHash(
        task,
        rule: rule,
        predicate: predicate,
        dayUtc: dayUtc,
        allocationVersion: allocationVersion,
      );

      final key = _runtimeKey(
        entityType: AttentionEntityType.task,
        entityId: task.id,
      );

      if (_isSuppressed(
        now: now,
        stateHash: stateHash,
        runtimeState: runtimeStates[key],
        latestResolution: latestResolutions[task.id],
      )) {
        continue;
      }

      items.add(
        _createAllocationTaskItem(
          rule,
          task,
          dayUtc: dayUtc,
          allocationVersion: allocationVersion,
        ),
      );
    }

    return items;
  }

  Future<List<AttentionItem>> _evaluateReviewRule(AttentionRule rule) async {
    final entityTypeStr = rule.entitySelector['entity_type'] as String?;
    final entityType = _parseEntityType(entityTypeStr);

    // Only scheduled review sessions are supported here.
    if (entityType != AttentionEntityType.reviewSession) {
      return const <AttentionItem>[];
    }

    final dueInfo = await _getReviewDueInfo(rule);
    if (dueInfo == null) return const <AttentionItem>[];

    return <AttentionItem>[
      _createReviewItem(rule, overdueDays: dueInfo.overdueDays),
    ];
  }

  Future<({int overdueDays, int frequencyDays})?> _getReviewDueInfo(
    AttentionRule rule,
  ) async {
    final frequencyDays = rule.triggerConfig['frequency_days'] as int? ?? 7;

    // Reviews use rule key as entity id.
    final lastResolution = await _attentionRepository.getLatestResolution(
      rule.id,
      rule.ruleKey,
    );

    if (lastResolution == null) {
      return (overdueDays: 1000000, frequencyDays: frequencyDays);
    }

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
  // Suppression semantics (dismiss/snooze)
  // ==========================================================================

  bool _isSuppressed({
    required DateTime now,
    required String? stateHash,
    required AttentionRuleRuntimeState? runtimeState,
    required AttentionResolution? latestResolution,
  }) {
    // Runtime state is the preferred mechanism.
    if (runtimeState != null) {
      final next = runtimeState.nextEvaluateAfter;
      if (next != null && now.isBefore(next)) return true;

      final dismissedHash = runtimeState.dismissedStateHash;
      if (dismissedHash != null && dismissedHash == stateHash) return true;
    }

    // Back-compat: use the audit trail resolution records.
    if (latestResolution == null) return false;

    switch (latestResolution.resolutionAction) {
      case AttentionResolutionAction.dismissed:
        final storedHash =
            latestResolution.actionDetails?['state_hash'] as String?;
        return storedHash != null && storedHash == stateHash;
      case AttentionResolutionAction.snoozed:
        final untilRaw = latestResolution.actionDetails?['snooze_until'];
        final until = untilRaw is String ? DateTime.tryParse(untilRaw) : null;
        return until != null && now.isBefore(until);
      case AttentionResolutionAction.reviewed:
      case AttentionResolutionAction.skipped:
        return false;
    }
  }

  Future<Map<String, AttentionRuleRuntimeState>> _loadRuntimeStateIndex(
    String ruleId,
  ) async {
    final rows = await _attentionRepository
        .watchRuntimeStateForRule(ruleId)
        .first;

    return {
      for (final row in rows)
        _runtimeKey(entityType: row.entityType, entityId: row.entityId): row,
    };
  }

  Future<Map<String, AttentionResolution>> _loadLatestResolutionIndex(
    String ruleId,
  ) async {
    final rows = await _attentionRepository
        .watchResolutionsForRule(ruleId)
        .first;

    final latest = <String, AttentionResolution>{};
    for (final row in rows) {
      latest.putIfAbsent(row.entityId, () => row);
    }

    return latest;
  }

  String _runtimeKey({
    required AttentionEntityType? entityType,
    required String? entityId,
  }) {
    // Null scope means rule-wide state.
    return '${entityType?.name ?? ''}|${entityId ?? ''}';
  }

  // ==========================================================================
  // Predicate helpers
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
    return _isProjectIdle(project, config);
  }

  // ==========================================================================
  // Allocation candidate selection
  // ==========================================================================

  Future<List<Task>> _selectAllocationTaskCandidates(
    List<Task> tasks, {
    required List<Project> projects,
    required String predicate,
  }) async {
    final allocationConfig = await _settingsRepository.load(
      SettingsKey.allocation,
    );
    final urgencyDetector = UrgencyDetector.fromConfig(allocationConfig);

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

  // ==========================================================================
  // Item creators
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
      entityId: rule.ruleKey,
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

  // ==========================================================================
  // State hashing
  // ==========================================================================

  String _computeTaskStateHash(
    Task task, {
    required AttentionRule rule,
    required String predicate,
  }) {
    final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);

    final relevantParts = switch (predicate) {
      'isOverdue' => <String?>[
        task.deadlineDate?.toIso8601String(),
        task.completed.toString(),
      ],
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

    return _stableFingerprint([
      'entity=project',
      'projectId=${project.id}',
      'predicate=$predicate',
      'rule=$ruleFingerprint',
      'updatedAt=${project.updatedAt.toIso8601String()}',
      'completed=${project.completed}',
    ]);
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

  String _ruleFingerprint(AttentionRule rule, {required String predicate}) {
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
    return parts.join('|');
  }

  // ==========================================================================
  // Misc helpers
  // ==========================================================================

  AttentionEntityType? _parseEntityType(String? value) {
    return switch (value) {
      'task' => AttentionEntityType.task,
      'project' => AttentionEntityType.project,
      'journal' => AttentionEntityType.journal,
      'value' => AttentionEntityType.value,
      'tracker' => AttentionEntityType.tracker,
      'review_session' || 'reviewSession' => AttentionEntityType.reviewSession,
      _ => null,
    };
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
        .toList(growable: false);
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
}
