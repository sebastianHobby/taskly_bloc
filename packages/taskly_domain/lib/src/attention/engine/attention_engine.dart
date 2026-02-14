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
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_completion.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/time/date_only.dart';
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
    required RoutineRepositoryContract routineRepository,
    required Stream<void> invalidations,
    Clock clock = systemClock,
  }) : _attentionRepository = attentionRepository,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _routineRepository = routineRepository,
       _clock = clock,
       _invalidations = invalidations;

  final v2.AttentionRepositoryContract _attentionRepository;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final RoutineRepositoryContract _routineRepository;
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
    'routine_support_v1': _EvaluatorSpec(
      entityTypes: {AttentionEntityType.routine},
      evaluate: _evaluateRoutineSupportV1,
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

    final routineCompletions$ = _routineRepository.watchCompletions();
    final routines$ = _routineRepository.watchAll(includeInactive: true);

    return Rx.combineLatest6<
          List<AttentionRule>,
          List<Task>,
          List<Project>,
          List<Routine>,
          List<RoutineCompletion>,
          int,
          ({
            List<AttentionRule> rules,
            List<Task> tasks,
            List<Project> projects,
            List<Routine> routines,
            List<RoutineCompletion> routineCompletions,
          })
        >(
          rules$,
          _taskRepository.watchAll(),
          _projectRepository.watchAll(),
          routines$,
          routineCompletions$,
          pulse$,
          (rules, tasks, projects, routines, routineCompletions, _) => (
            rules: rules,
            tasks: tasks,
            projects: projects,
            routines: routines,
            routineCompletions: routineCompletions,
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
      List<Routine> routines,
      List<RoutineCompletion> routineCompletions,
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
          routines: inputs.routines,
          routineCompletions: inputs.routineCompletions,
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

  Future<List<_EvaluatedItem>> _evaluateRoutineSupportV1(
    AttentionRule rule,
    _EvalInputs inputs,
  ) async {
    final now = dateOnly(inputs.now);
    final params = rule.evaluatorParams;
    final buildingMinAgeDays = _readInt(params, 'buildingMinAgeDays') ?? 7;
    final buildingMaxAgeDays = _readInt(params, 'buildingMaxAgeDays') ?? 28;
    final needsHelpDropPp = _readInt(params, 'needsHelpDropPp') ?? 15;
    final needsHelpRecentAdherenceMax =
        _readInt(params, 'needsHelpRecentAdherenceMax') ?? 60;
    final maxCards = _readInt(params, 'maxCards') ?? 2;

    final completionsByRoutine = <String, List<RoutineCompletion>>{};
    for (final completion in inputs.routineCompletions) {
      (completionsByRoutine[completion.routineId] ??= <RoutineCompletion>[])
          .add(completion);
    }

    final candidates = <_RoutineSupportCandidate>[];
    for (final routine in inputs.routines) {
      if (!routine.isActive) continue;
      if (routine.isPausedOn(now)) continue;

      final ageDays = now.difference(dateOnly(routine.createdAt)).inDays;
      if (ageDays < buildingMinAgeDays) continue;

      final completions = completionsByRoutine[routine.id] ?? const [];
      final weeklyAdherence = _weeklyAdherence(
        routine: routine,
        completions: completions,
        nowDay: now,
        weeks: 8,
      );
      if (weeklyAdherence.length < 2) continue;

      final last14Adherence = _windowAdherence(
        routine: routine,
        completions: completions,
        endDay: now,
        days: 14,
      );
      final baseline = weeklyAdherence.isEmpty
          ? 0
          : weeklyAdherence.reduce((a, b) => a + b) / weeklyAdherence.length;
      final dropPp = baseline - last14Adherence;

      final trendDownTwoWeeks = _isTrendDownTwoWeeks(weeklyAdherence);
      final hasEnoughHistory = weeklyAdherence.length >= 4;

      final needsHelp =
          hasEnoughHistory &&
          trendDownTwoWeeks &&
          dropPp >= needsHelpDropPp &&
          last14Adherence < needsHelpRecentAdherenceMax;

      final recentCompletions = _completionCountInWindow(
        completions: completions,
        endDay: now,
        days: 14,
      );
      final building =
          !needsHelp &&
          ageDays <= buildingMaxAgeDays &&
          recentCompletions >= 1 &&
          last14Adherence >= 20 &&
          last14Adherence <= 70;

      if (!needsHelp && !building) continue;

      final suggestion = _bestWeekdaySuggestion(
        routine: routine,
        completions: completions,
        nowDay: now,
      );
      final state = needsHelp ? 'needs_help' : 'building';
      final severity = needsHelp && dropPp >= 15
          ? AttentionSeverity.warning
          : AttentionSeverity.info;
      final stateHash = _stableFingerprint([
        'routine=${routine.id}',
        'state=$state',
        'a14=${last14Adherence.toStringAsFixed(1)}',
        'drop=${dropPp.toStringAsFixed(1)}',
        'trend=${weeklyAdherence.take(3).join(",")}',
      ]);

      final sortWeight = needsHelp ? 0 : 1;
      final item = AttentionItem(
        id: _uuid.v4(),
        ruleId: rule.id,
        ruleKey: rule.ruleKey,
        bucket: rule.bucket,
        entityId: routine.id,
        entityType: AttentionEntityType.routine,
        severity: severity,
        title: routine.name,
        description:
            'Small changes restore momentum. Tune this routine for this week.',
        availableActions: _parseResolutionActions(rule.resolutionActions),
        detectedAt: inputs.now,
        sortKey:
            '${sortWeight.toString().padLeft(2, '0')}|${(100 - last14Adherence).toStringAsFixed(1)}|${routine.id}',
        metadata: <String, dynamic>{
          'entity_display_name': routine.name,
          'routine_name': routine.name,
          'support_state': state,
          'adherence_last_14': last14Adherence,
          'baseline_8w': baseline,
          'drop_pp': dropPp,
          'weekly_adherence': weeklyAdherence,
          if (suggestion != null) ...suggestion,
        },
      );

      candidates.add(
        _RoutineSupportCandidate(
          item: item,
          score: needsHelp ? (100 + dropPp) : (50 - last14Adherence),
          stateHash: stateHash,
        ),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates
        .take(maxCards < 1 ? 1 : maxCards)
        .map(
          (candidate) => _EvaluatedItem(
            item: candidate.item,
            stateHash: candidate.stateHash,
          ),
        )
        .toList(growable: false);
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

  bool _isTrendDownTwoWeeks(List<double> series) {
    if (series.length < 3) return false;
    final a = series[series.length - 3];
    final b = series[series.length - 2];
    final c = series[series.length - 1];
    return c < b && b < a;
  }

  int _completionCountInWindow({
    required List<RoutineCompletion> completions,
    required DateTime endDay,
    required int days,
  }) {
    final start = endDay.subtract(Duration(days: days - 1));
    return completions.where((completion) {
      final day = dateOnly(
        completion.completedDayLocal ?? completion.completedAtUtc,
      );
      return !(day.isBefore(start) || day.isAfter(endDay));
    }).length;
  }

  double _windowAdherence({
    required Routine routine,
    required List<RoutineCompletion> completions,
    required DateTime endDay,
    required int days,
  }) {
    final expected = _expectedForDays(routine: routine, days: days);
    if (expected <= 0) return 0;
    final actual = _completionCountInWindow(
      completions: completions,
      endDay: endDay,
      days: days,
    );
    return (actual / expected * 100).clamp(0, 200).toDouble();
  }

  int _expectedForDays({required Routine routine, required int days}) {
    if (days <= 0) return 0;
    return switch (routine.periodType) {
      RoutinePeriodType.day => routine.targetCount * days,
      RoutinePeriodType.week => ((routine.targetCount / 7) * days).round(),
      RoutinePeriodType.month => ((routine.targetCount / 30) * days).round(),
    };
  }

  List<double> _weeklyAdherence({
    required Routine routine,
    required List<RoutineCompletion> completions,
    required DateTime nowDay,
    required int weeks,
  }) {
    final safeWeeks = weeks < 1 ? 1 : weeks;
    final series = <double>[];
    final weekStart = _weekStart(nowDay);
    for (var i = safeWeeks - 1; i >= 0; i--) {
      final start = weekStart.subtract(Duration(days: i * 7));
      final end = start.add(const Duration(days: 6));
      final actual = completions.where((completion) {
        final day = dateOnly(
          completion.completedDayLocal ?? completion.completedAtUtc,
        );
        return !(day.isBefore(start) || day.isAfter(end));
      }).length;
      final expected = _expectedForDays(routine: routine, days: 7);
      if (expected <= 0) {
        series.add(0);
      } else {
        series.add((actual / expected * 100).clamp(0, 200).toDouble());
      }
    }
    return series;
  }

  Map<String, dynamic>? _bestWeekdaySuggestion({
    required Routine routine,
    required List<RoutineCompletion> completions,
    required DateTime nowDay,
  }) {
    if (routine.scheduleDays.isEmpty) return null;
    final start = nowDay.subtract(const Duration(days: 41));
    final completionByWeekday = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    final missedByWeekday = <int, int>{for (var i = 1; i <= 7; i++) i: 0};

    final completionDays = <DateTime>{};
    for (final completion in completions) {
      final day = dateOnly(
        completion.completedDayLocal ?? completion.completedAtUtc,
      );
      if (day.isBefore(start) || day.isAfter(nowDay)) continue;
      completionDays.add(day);
      completionByWeekday[day.weekday] =
          (completionByWeekday[day.weekday] ?? 0) + 1;
    }

    for (
      var cursor = start;
      !cursor.isAfter(nowDay);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (!routine.scheduleDays.contains(cursor.weekday)) continue;
      if (!completionDays.contains(cursor)) {
        missedByWeekday[cursor.weekday] =
            (missedByWeekday[cursor.weekday] ?? 0) + 1;
      }
    }

    final missEntry = missedByWeekday.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    final successEntry = completionByWeekday.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    if (missEntry.value <= 0 || successEntry.value <= 0) return null;
    if (missEntry.key == successEntry.key) return null;

    return <String, dynamic>{
      'suggestion_type': 'reschedule_day',
      'most_missed_weekday': missEntry.key,
      'most_success_weekday': successEntry.key,
    };
  }

  DateTime _weekStart(DateTime day) {
    final normalized = dateOnly(day);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
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
  List<Routine> routines,
  List<RoutineCompletion> routineCompletions,
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

class _RoutineSupportCandidate {
  const _RoutineSupportCandidate({
    required this.item,
    required this.score,
    required this.stateHash,
  });

  final AttentionItem item;
  final double score;
  final String stateHash;
}
