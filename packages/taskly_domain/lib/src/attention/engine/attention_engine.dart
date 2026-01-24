import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/src/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_domain/src/attention/contracts/attention_repository_contract.dart'
    as v2;
import 'package:taskly_domain/src/attention/model/attention_item.dart';
import 'package:taskly_domain/src/attention/model/attention_resolution.dart';
import 'package:taskly_domain/src/attention/model/attention_rule.dart';
import 'package:taskly_domain/src/attention/model/attention_rule_runtime_state.dart';
import 'package:taskly_domain/src/attention/query/attention_query.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/time/clock.dart';
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
    required Stream<void> invalidations,
    Clock clock = systemClock,
  }) : _attentionRepository = attentionRepository,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _clock = clock,
       _invalidations = invalidations;

  final v2.AttentionRepositoryContract _attentionRepository;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final Clock _clock;
  final Stream<void> _invalidations;

  final _uuid = const Uuid();

  late final Map<String, _EvaluatorSpec> _evaluatorRegistry = {
    'task_predicate_v1': _EvaluatorSpec(
      entityTypes: {AttentionEntityType.task},
      evaluate: _evaluateTaskPredicateV1,
    ),
    'project_predicate_v1': _EvaluatorSpec(
      entityTypes: {AttentionEntityType.project},
      evaluate: _evaluateProjectPredicateV1,
    ),
  };

  @override
  Stream<List<AttentionItem>> watch(AttentionQuery query) {
    final pulse$ = _invalidations
        // Convert to a value stream so it can be composed.
        .map((_) => _clock.nowUtc().microsecondsSinceEpoch)
        .startWith(_clock.nowUtc().microsecondsSinceEpoch);

    final rules$ = _attentionRepository.watchActiveRules().map(
      (rules) => rules.where(query.matchesRule).toList(growable: false),
    );

    return Rx.combineLatest4<
          List<AttentionRule>,
          List<Task>,
          List<Project>,
          int,
          ({
            List<AttentionRule> rules,
            List<Task> tasks,
            List<Project> projects,
          })
        >(
          rules$,
          _taskRepository.watchAll(),
          _projectRepository.watchAll(),
          pulse$,
          (rules, tasks, projects, _) => (
            rules: rules,
            tasks: tasks,
            projects: projects,
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
    })
    inputs,
  ) async {
    final now = _clock.nowUtc();
    final items = <AttentionItem>[];

    for (final rule in inputs.rules) {
      if (!_matchesMinSeverity(query, rule)) continue;

      final evaluatorSpec = _evaluatorRegistry[rule.evaluator];
      if (evaluatorSpec == null) continue;

      final entityTypeFilter = query.entityTypes;
      if (entityTypeFilter != null &&
          evaluatorSpec.entityTypes.intersection(entityTypeFilter).isEmpty) {
        continue;
      }

      final runtimeStates = await _loadRuntimeStateIndex(rule.id);
      final latestResolutions = await _loadLatestResolutionIndex(rule.id);

      final evaluated = await evaluatorSpec.evaluate(
        rule,
        (
          tasks: inputs.tasks,
          projects: inputs.projects,
          now: now,
        ),
      );

      for (final e in evaluated) {
        if (entityTypeFilter != null &&
            !entityTypeFilter.contains(e.item.entityType)) {
          continue;
        }

        final key = _runtimeKey(
          entityType: e.item.entityType,
          entityId: e.item.entityId,
        );

        if (_isSuppressed(
          now: now,
          stateHash: e.stateHash,
          runtimeState: runtimeStates[key],
          latestResolution: latestResolutions[e.item.entityId],
        )) {
          continue;
        }

        final mergedMetadata = <String, dynamic>{...?e.item.metadata};
        if (e.stateHash != null) {
          mergedMetadata['state_hash'] = e.stateHash;
        }

        items.add(e.item.copyWith(metadata: mergedMetadata));
      }
    }

    items.sort((a, b) => (a.sortKey ?? '').compareTo(b.sortKey ?? ''));
    return items;
  }

  bool _matchesMinSeverity(AttentionQuery query, AttentionRule rule) {
    final min = query.minSeverity;
    if (min == null) return true;
    return _severityIndex(rule.severity) >= _severityIndex(min);
  }

  // ========================================================================
  // Evaluators
  // ========================================================================

  Future<List<_EvaluatedItem>> _evaluateTaskPredicateV1(
    AttentionRule rule,
    _EvalInputs inputs,
  ) async {
    final predicate = rule.evaluatorParams['predicate'] as String?;
    if (predicate == null) return const <_EvaluatedItem>[];

    final thresholdDays =
        _readInt(rule.evaluatorParams, 'thresholdDays') ??
        _readInt(rule.evaluatorParams, 'threshold_days') ??
        30;

    final now = inputs.now;
    final matching = <_EvaluatedItem>[];

    for (final task in inputs.tasks) {
      if (task.completed) continue;

      final matches = switch (predicate) {
        'isStale' => _isTaskStale(task, thresholdDays: thresholdDays),
        _ => false,
      };

      if (!matches) continue;

      final stateHash = _computeTaskStateHash(
        task,
        rule: rule,
        predicate: predicate,
      );

      matching.add(
        _EvaluatedItem(
          item: _createTaskItem(rule, task, detectedAt: now),
          stateHash: stateHash,
        ),
      );
    }

    return matching;
  }

  Future<List<_EvaluatedItem>> _evaluateProjectPredicateV1(
    AttentionRule rule,
    _EvalInputs inputs,
  ) async {
    final predicate = rule.evaluatorParams['predicate'] as String?;
    if (predicate == null) return const <_EvaluatedItem>[];

    final dueWithinDays =
        _readInt(rule.evaluatorParams, 'dueWithinDays') ??
        _readInt(rule.evaluatorParams, 'due_within_days');
    final minUnscheduledCount =
        _readInt(rule.evaluatorParams, 'minUnscheduledCount') ??
        _readInt(rule.evaluatorParams, 'min_unscheduled_count');

    final now = inputs.now;
    final items = <_EvaluatedItem>[];

    for (final project in inputs.projects) {
      if (project.completed) continue;

      if (predicate == 'dueSoonManyUnscheduledTasks') {
        final dueWithin = dueWithinDays ?? 14;
        final minUnscheduled = minUnscheduledCount ?? 5;

        final details = _computeProjectDueSoonManyUnscheduledDetails(
          project,
          inputs.tasks,
          now: now,
          dueWithinDays: dueWithin,
        );
        if (details == null) continue;
        if (details.unscheduledTasks.length < minUnscheduled) continue;

        final stateHash = _computeProjectDueSoonManyUnscheduledStateHash(
          project,
          rule: rule,
          dueWithinDays: dueWithin,
          minUnscheduledCount: minUnscheduled,
          unscheduledTasks: details.unscheduledTasks,
        );

        final sortKeyOverride = _computeSortKey(
          rule: rule,
          entityType: AttentionEntityType.project,
          // Sort by due-ness first, then by stable entity id.
          entityId: '${details.sortExtra}|${project.id}',
        );

        final item = _createProjectItem(
          rule,
          project,
          detectedAt: now,
          sortKeyOverride: sortKeyOverride,
          additionalMetadata: {
            'deadline_date': details.deadline.toIso8601String(),
            'due_in_days': details.dueInDays,
            'unscheduled_tasks_count': details.unscheduledTasks.length,
            'due_within_days': dueWithin,
            'min_unscheduled_count': minUnscheduled,
            'detail_lines': details.detailLines,
          },
        );

        items.add(_EvaluatedItem(item: item, stateHash: stateHash));
        continue;
      }

      final matches = switch (predicate) {
        'isIdle' => _isProjectIdle(
          project,
          thresholdDays: _readInt(rule.evaluatorParams, 'thresholdDays') ?? 30,
        ),
        _ => false,
      };

      if (!matches) continue;

      final stateHash = _computeProjectStateHash(
        project,
        rule: rule,
        predicate: predicate,
      );

      items.add(
        _EvaluatedItem(
          item: _createProjectItem(rule, project, detectedAt: now),
          stateHash: stateHash,
        ),
      );
    }

    return items;
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

  // ==========================================================================
  // Item creators
  // ==========================================================================

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

  String _computeProjectDueSoonManyUnscheduledStateHash(
    Project project, {
    required AttentionRule rule,
    required int dueWithinDays,
    required int minUnscheduledCount,
    required List<Task> unscheduledTasks,
  }) {
    final ruleFingerprint = _ruleFingerprint(
      rule,
      predicate: 'dueSoonManyUnscheduledTasks',
    );

    final unscheduledFingerprints =
        unscheduledTasks
            .map(
              (t) => [
                t.id,
                t.startDate?.toIso8601String() ?? '',
                t.deadlineDate?.toIso8601String() ?? '',
                t.completed.toString(),
              ].join(':'),
            )
            .toList()
          ..sort();

    return _stableFingerprint([
      'entity=project',
      'projectId=${project.id}',
      'predicate=dueSoonManyUnscheduledTasks',
      'rule=$ruleFingerprint',
      'projectDeadline=${project.deadlineDate?.toIso8601String() ?? ''}',
      'dueWithinDays=$dueWithinDays',
      'minUnscheduledCount=$minUnscheduledCount',
      ...unscheduledFingerprints.map((p) => 't=$p'),
    ]);
  }

  String _ruleFingerprint(AttentionRule rule, {required String predicate}) {
    final evaluatorParams = _stableMapFingerprint(rule.evaluatorParams);
    return _stableFingerprint([
      'ruleKey=${rule.ruleKey}',
      'bucket=${rule.bucket.name}',
      'evaluator=${rule.evaluator}',
      'predicate=$predicate',
      'params=$evaluatorParams',
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

  bool _isTaskStale(Task task, {required int thresholdDays}) {
    final threshold = _clock.nowUtc().subtract(Duration(days: thresholdDays));
    return task.updatedAt.isBefore(threshold);
  }

  bool _isProjectIdle(Project project, {required int thresholdDays}) {
    final threshold = _clock.nowUtc().subtract(Duration(days: thresholdDays));
    return project.updatedAt.isBefore(threshold);
  }

  ({
    DateTime deadline,
    int dueInDays,
    String sortExtra,
    List<Task> unscheduledTasks,
    List<String> detailLines,
  })?
  _computeProjectDueSoonManyUnscheduledDetails(
    Project project,
    List<Task> tasks, {
    required DateTime now,
    required int dueWithinDays,
  }) {
    final deadline = project.deadlineDate;
    if (deadline == null) return null;

    // Trigger when the deadline is within the configured horizon.
    final dueThreshold = now.add(Duration(days: dueWithinDays));
    if (deadline.isAfter(dueThreshold)) return null;

    final activeProjectTasks = tasks
        .where((t) => !t.completed && t.projectId == project.id)
        .toList(growable: false);

    final unscheduledTasks = activeProjectTasks
        .where((t) => _isUnscheduledForDeadlineRiskRule(t, now: now))
        .toList(growable: false);

    final dueInDays = deadline.difference(now).inDays;
    final dueSort = (dueInDays < 0 ? 0 : dueInDays).toString().padLeft(8, '0');

    final dueLabel = switch (dueInDays) {
      0 => 'Due today',
      1 => 'Due tomorrow',
      < 0 => 'Overdue by ${dueInDays.abs()} day(s)',
      _ => 'Due in $dueInDays day(s)',
    };

    return (
      deadline: deadline,
      dueInDays: dueInDays,
      sortExtra: dueSort,
      unscheduledTasks: unscheduledTasks,
      detailLines: <String>[
        dueLabel,
        'Unscheduled tasks: ${unscheduledTasks.length}',
      ],
    );
  }

  bool _isUnscheduledForDeadlineRiskRule(Task task, {required DateTime now}) {
    final start = task.startDate;
    final deadline = task.deadlineDate;

    // Unscheduled definition (per request):
    // - missing both start + deadline
    // - OR start date is past AND no deadline is set
    if (start == null && deadline == null) return true;
    if (deadline == null && start != null && start.isBefore(now)) return true;
    return false;
  }

  int? _readInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    return switch (v) {
      int() => v,
      double() => v.toInt(),
      String() => int.tryParse(v),
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

  String _computeSortKey({
    required AttentionRule rule,
    required AttentionEntityType entityType,
    required String entityId,
    String? extra,
  }) {
    final bucketOrder = switch (rule.bucket) {
      AttentionBucket.action => '0',
      AttentionBucket.review => '1',
    };
    final severityOrder = switch (rule.severity) {
      AttentionSeverity.critical => '0',
      AttentionSeverity.warning => '1',
      AttentionSeverity.info => '2',
    };

    return [
      bucketOrder,
      severityOrder,
      rule.ruleKey,
      entityType.name,
      entityId,
      ?extra,
    ].join('|');
  }

  AttentionItem _createTaskItem(
    AttentionRule rule,
    Task task, {
    required DateTime detectedAt,
  }) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      bucket: rule.bucket,
      entityId: task.id,
      entityType: AttentionEntityType.task,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Task Issue',
      description: _formatTaskDescription(
        displayConfig['description'] as String? ?? 'Task needs attention',
        task,
      ),
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: detectedAt,
      sortKey: _computeSortKey(
        rule: rule,
        entityType: AttentionEntityType.task,
        entityId: task.id,
      ),
      metadata: {
        'entity_display_name': task.name,
        'task_name': task.name,
        'deadline_date': task.deadlineDate?.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
      },
    );
  }

  AttentionItem _createProjectItem(
    AttentionRule rule,
    Project project, {
    required DateTime detectedAt,
    String? sortKeyOverride,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final displayConfig = rule.displayConfig;
    return AttentionItem(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleKey: rule.ruleKey,
      bucket: rule.bucket,
      entityId: project.id,
      entityType: AttentionEntityType.project,
      severity: rule.severity,
      title: displayConfig['title'] as String? ?? 'Project Issue',
      description: _formatProjectDescription(
        displayConfig['description'] as String? ?? 'Project needs attention',
        project,
      ),
      availableActions: _parseResolutionActions(rule.resolutionActions),
      detectedAt: detectedAt,
      sortKey:
          sortKeyOverride ??
          _computeSortKey(
            rule: rule,
            entityType: AttentionEntityType.project,
            entityId: project.id,
          ),
      metadata: {
        'entity_display_name': project.name,
        'project_name': project.name,
        'updated_at': project.updatedAt.toIso8601String(),
        ...?additionalMetadata,
      },
    );
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

typedef _EvalInputs = ({
  List<Task> tasks,
  List<Project> projects,
  DateTime now,
});

class _EvaluatorSpec {
  const _EvaluatorSpec({
    required this.entityTypes,
    required this.evaluate,
  });

  final Set<AttentionEntityType> entityTypes;
  final Future<List<_EvaluatedItem>> Function(AttentionRule, _EvalInputs)
  evaluate;
}

class _EvaluatedItem {
  const _EvaluatedItem({
    required this.item,
    required this.stateHash,
  });

  final AttentionItem item;
  final String? stateHash;
}
