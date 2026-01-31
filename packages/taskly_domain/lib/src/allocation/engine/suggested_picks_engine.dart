import 'dart:math' as math;

import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/projects/model/project_anchor_state.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';
import 'package:taskly_domain/time.dart';

/// Values-first allocator that anchors on projects, then selects tasks.
final class SuggestedPicksEngine implements AllocationStrategy {
  @override
  String get strategyName => 'ProjectFirstAnchors';

  @override
  String get description =>
      'Allocates anchor projects by value priority, then selects tasks within '
      'each anchor using calm tie-break rules.';

  @override
  AllocationResult allocate(AllocationParameters parameters) {
    final tasks = parameters.tasks;
    final projects = parameters.projects;
    final categories = parameters.categories;
    final totalLimit = parameters.maxTasks;
    final todayDayKeyUtc = parameters.todayDayKeyUtc;

    if (totalLimit <= 0 || categories.isEmpty) {
      return AllocationResult(
        allocatedTasks: const [],
        excludedTasks: _excludeAll(
          tasks,
          reason: 'Allocation disabled',
          todayDayKeyUtc: todayDayKeyUtc,
          urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
        ),
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: categories,
          explanation: 'No allocation performed',
        ),
      );
    }

    final totalWeight = categories.values.fold<double>(
      0,
      (sum, w) => sum + w,
    );
    if (totalWeight <= 0) {
      return const AllocationResult(
        allocatedTasks: [],
        excludedTasks: [],
        reasoning: AllocationReasoning(
          strategyUsed: 'ProjectFirstAnchors',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'No categories with weights defined',
        ),
      );
    }

    final (:tasksByProject, :projectsByValue, :excludedPre) = _groupEligible(
      tasks,
      projects: projects,
      categories: categories,
      readinessFilter: parameters.readinessFilter,
    );
    final projectValueById = <String, String>{};
    for (final entry in projectsByValue.entries) {
      for (final project in entry.value) {
        projectValueById[project.id] = entry.key;
      }
    }

    if (projectsByValue.isEmpty) {
      return AllocationResult(
        allocatedTasks: const [],
        excludedTasks: excludedPre,
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: categories,
          explanation: 'No eligible projects for allocation',
        ),
      );
    }

    final anchorCount = math.max(0, parameters.anchorCount);
    if (anchorCount == 0) {
      return AllocationResult(
        allocatedTasks: const [],
        excludedTasks: excludedPre,
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: categories,
          explanation: 'Anchor count is zero',
        ),
      );
    }

    final availableValues = {
      for (final entry in projectsByValue.entries)
        if (entry.value.isNotEmpty) entry.key: categories[entry.key] ?? 0,
    };
    final availableWeight = availableValues.values.fold<double>(
      0,
      (sum, w) => sum + w,
    );
    if (availableWeight <= 0) {
      return AllocationResult(
        allocatedTasks: const [],
        excludedTasks: excludedPre,
        reasoning: AllocationReasoning(
          strategyUsed: strategyName,
          categoryAllocations: const {},
          categoryWeights: categories,
          explanation: 'No eligible values for allocation',
        ),
      );
    }

    final baseQuotas = _computeProportionalQuotas(
      categories: availableValues,
      totalWeight: availableWeight,
      totalLimit: anchorCount,
    );

    final keepValuesInBalance =
        parameters.keepValuesInBalance &&
        parameters.completionsByValue.isNotEmpty;

    final repair = keepValuesInBalance
        ? _applyBoundedQuotaRepairQ2(
            baseQuotas: baseQuotas,
            availableCounts: {
              for (final entry in projectsByValue.entries)
                entry.key: entry.value.length,
            },
            categories: availableValues,
            totalWeight: availableWeight,
            suggestedCount: anchorCount,
            completionsByValue: parameters.completionsByValue,
          )
        : (
            quotas: baseQuotas,
            boostedCategories: const <String>{},
            deficits: const <String, double>{},
            topNeglectScore: 0.0,
            topNeglectValueId: null,
          );

    final repairedQuotas = repair.quotas;
    final repairedCategories = repair.boostedCategories;

    final adjustedQuotas = _applyRoutineSelectionAdjustment(
      quotas: repairedQuotas,
      routineSelectionsByValue: parameters.routineSelectionsByValue,
    );

    final anchorByProjectId = {
      for (final entry in parameters.projectAnchorStates)
        entry.projectId: entry,
    };
    final totalEligibleProjects = projectsByValue.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final targetAnchorCount = math.min(anchorCount, totalEligibleProjects);

    final anchorSelection = _selectAnchors(
      projectsByValue: projectsByValue,
      quotas: adjustedQuotas,
      todayDayKeyUtc: todayDayKeyUtc,
      rotationPressureDays: parameters.rotationPressureDays,
      anchorByProjectId: anchorByProjectId,
      targetAnchorCount: targetAnchorCount,
    );

    final anchorProjectIds = anchorSelection.map((a) => a.project.id).toList();
    final maxAnchorTasks = math.max(0, totalLimit - parameters.freeSlots);
    final selected = <_SelectedTask>[];
    final selectedTaskIds = <String>{};

    var remainingAnchorSlots = maxAnchorTasks;
    for (final anchor in anchorSelection) {
      if (remainingAnchorSlots <= 0) break;
      final tasksForProject = tasksByProject[anchor.project.id] ?? const [];
      if (tasksForProject.isEmpty) continue;

      final limit = math.min(
        parameters.tasksPerAnchorMax,
        remainingAnchorSlots,
      );
      final selectedForProject = _selectTasksForProject(
        tasksForProject,
        maxCount: limit,
        todayDayKeyUtc: todayDayKeyUtc,
        urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
      );

      for (final task in selectedForProject) {
        if (selectedTaskIds.contains(task.id)) continue;
        selected.add(
          _SelectedTask(task: task, categoryId: anchor.valueId),
        );
        selectedTaskIds.add(task.id);
        remainingAnchorSlots -= 1;
        if (remainingAnchorSlots <= 0) break;
      }
    }

    final remainingFreeSlots = math.min(
      parameters.freeSlots,
      totalLimit - selected.length,
    );
    if (remainingFreeSlots > 0) {
      final remaining = <_SelectedTask>[];
      for (final entry in tasksByProject.entries) {
        final projectId = entry.key;
        final valueId = projectValueById[projectId] ?? '';
        for (final task in entry.value) {
          if (selectedTaskIds.contains(task.id)) continue;
          remaining.add(_SelectedTask(task: task, categoryId: valueId));
        }
      }

      remaining.sort(
        (a, b) => _compareTasksCalm(
          a.task,
          b.task,
          todayDayKeyUtc: todayDayKeyUtc,
          urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
        ),
      );

      for (final pick in remaining.take(remainingFreeSlots)) {
        selected.add(pick);
        selectedTaskIds.add(pick.task.id);
      }
    }

    final allocatedTasks = <AllocatedTask>[];
    for (final allocated in selected) {
      final reasonCodes = _buildReasonCodes(
        task: allocated.task,
        todayDayKeyUtc: todayDayKeyUtc,
        urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
        isBalancePick: repairedCategories.contains(allocated.categoryId),
      );

      final qualifyingValueId = allocated.categoryId.isEmpty
          ? (allocated.task.effectivePrimaryValueId ?? '')
          : allocated.categoryId;

      allocatedTasks.add(
        AllocatedTask(
          task: allocated.task,
          qualifyingValueId: qualifyingValueId,
          allocationScore: categories[qualifyingValueId] ?? 0,
          reasonCodes: reasonCodes,
        ),
      );
    }

    final excludedTasks = <ExcludedTask>[
      ...excludedPre,
      ..._excludeUnselected(
        tasksByProject: tasksByProject,
        selectedTaskIds: selectedTaskIds,
        todayDayKeyUtc: todayDayKeyUtc,
        urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
      ),
    ];

    return AllocationResult(
      allocatedTasks: allocatedTasks,
      excludedTasks: excludedTasks,
      anchorProjectIds: anchorProjectIds,
      reasoning: AllocationReasoning(
        strategyUsed: strategyName,
        categoryAllocations: adjustedQuotas,
        categoryWeights: categories,
        neglectDeficits: repair.deficits,
        topNeglectScore: repair.topNeglectScore,
        topNeglectValueId: repair.topNeglectValueId,
        explanation: keepValuesInBalance
            ? 'Project-first anchors with bounded value balancing'
            : 'Project-first anchors',
      ),
    );
  }

  Map<String, int> _computeProportionalQuotas({
    required Map<String, double> categories,
    required double totalWeight,
    required int totalLimit,
  }) {
    final quotas = <String, int>{};

    var remainingSlots = totalLimit;

    final rawAllocations = <String, double>{
      for (final entry in categories.entries)
        entry.key: totalLimit * (entry.value / totalWeight),
    };

    final remainders = <String, double>{};
    for (final entry in rawAllocations.entries) {
      final allocated = entry.value.floor();
      quotas[entry.key] = allocated;
      remainingSlots -= allocated;
      remainders[entry.key] = entry.value - allocated;
    }

    if (remainingSlots > 0) {
      final sortedByRemainder = remainders.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var i = 0; i < remainingSlots && i < sortedByRemainder.length; i++) {
        final categoryId = sortedByRemainder[i].key;
        quotas[categoryId] = (quotas[categoryId] ?? 0) + 1;
      }
    }

    return quotas;
  }

  /// Q2 bounded quota repair:
  ///
  /// maxMoves = clamp(round(suggestedCount * 0.25 * topNeglect), 0, 3)
  ({
    Map<String, int> quotas,
    Set<String> boostedCategories,
    Map<String, double> deficits,
    double topNeglectScore,
    String? topNeglectValueId,
  })
  _applyBoundedQuotaRepairQ2({
    required Map<String, int> baseQuotas,
    required Map<String, int> availableCounts,
    required Map<String, double> categories,
    required double totalWeight,
    required int suggestedCount,
    required Map<String, double> completionsByValue,
  }) {
    final relevantCategories = categories.keys
        .where((id) => (availableCounts[id] ?? 0) > 0)
        .toList(growable: false);

    if (relevantCategories.length <= 1) {
      return (
        quotas: baseQuotas,
        boostedCategories: const <String>{},
        deficits: const <String, double>{},
        topNeglectScore: 0.0,
        topNeglectValueId: null,
      );
    }

    final totalCompletions = relevantCategories.fold<double>(
      0,
      (sum, id) => sum + (completionsByValue[id] ?? 0.0),
    );

    // If we have no completion data, we can't honestly claim "neglect".
    if (totalCompletions <= 0) {
      return (
        quotas: baseQuotas,
        boostedCategories: const <String>{},
        deficits: const <String, double>{},
        topNeglectScore: 0.0,
        topNeglectValueId: null,
      );
    }

    final deficits = <String, double>{};
    var topNeglect = 0.0;
    String? topNeglectValueId;

    for (final id in relevantCategories) {
      final targetShare = (categories[id]! / totalWeight).clamp(0.0, 1.0);
      final actualShare = (completionsByValue[id] ?? 0.0) / totalCompletions;
      final deficit = (targetShare - actualShare).clamp(0.0, 1.0);
      deficits[id] = deficit;
      if (deficit > topNeglect) {
        topNeglect = deficit;
        topNeglectValueId = id;
      }
    }

    final baseMoveBudget = (suggestedCount * 0.25 * topNeglect).round().clamp(
      0,
      suggestedCount,
    );
    final adaptiveCap = _adaptiveNeglectCap(relevantCategories.length);
    final maxMoves = math.min(baseMoveBudget, adaptiveCap);
    if (maxMoves <= 0) {
      return (
        quotas: baseQuotas,
        boostedCategories: const <String>{},
        deficits: deficits,
        topNeglectScore: topNeglect,
        topNeglectValueId: topNeglectValueId,
      );
    }

    final repairedQuotas = Map<String, int>.from(baseQuotas);
    final boosted = <String>{};

    String? pickReceiver() {
      final sorted = deficits.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sorted) {
        final categoryId = entry.key;
        final quota = repairedQuotas[categoryId] ?? 0;
        final available = availableCounts[categoryId] ?? 0;
        if (quota < available) return categoryId;
      }
      return null;
    }

    String? pickDonor() {
      final sorted = deficits.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (final entry in sorted) {
        final categoryId = entry.key;
        final quota = repairedQuotas[categoryId] ?? 0;
        if (quota > 0) return categoryId;
      }
      return null;
    }

    for (var i = 0; i < maxMoves; i++) {
      final receiver = pickReceiver();
      final donor = pickDonor();

      if (receiver == null || donor == null) break;
      if (receiver == donor) break;

      repairedQuotas[receiver] = (repairedQuotas[receiver] ?? 0) + 1;
      repairedQuotas[donor] = (repairedQuotas[donor] ?? 0) - 1;
      boosted.add(receiver);
    }

    return (
      quotas: repairedQuotas,
      boostedCategories: boosted,
      deficits: deficits,
      topNeglectScore: topNeglect,
      topNeglectValueId: topNeglectValueId,
    );
  }

  int _adaptiveNeglectCap(int valueCount) {
    if (valueCount <= 1) return 0;
    return math.max(1, (valueCount / 2).round());
  }

  Map<String, int> _applyRoutineSelectionAdjustment({
    required Map<String, int> quotas,
    required Map<String, int> routineSelectionsByValue,
  }) {
    if (routineSelectionsByValue.isEmpty) return quotas;

    final adjusted = Map<String, int>.from(quotas);

    for (final entry in routineSelectionsByValue.entries) {
      final valueId = entry.key;
      final count = entry.value;
      if (!adjusted.containsKey(valueId) || count <= 0) continue;
      adjusted[valueId] = math.max(0, (adjusted[valueId] ?? 0) - count);
    }

    return adjusted;
  }

  ({
    Map<String, List<Task>> tasksByProject,
    Map<String, List<Project>> projectsByValue,
    List<ExcludedTask> excludedPre,
  })
  _groupEligible(
    List<Task> tasks, {
    required List<Project> projects,
    required Map<String, double> categories,
    required bool readinessFilter,
  }) {
    final projectsById = {for (final project in projects) project.id: project};
    final tasksByProject = <String, List<Task>>{};
    final excludedPre = <ExcludedTask>[];

    for (final task in tasks) {
      if (task.completed) {
        excludedPre.add(
          ExcludedTask(
            task: task,
            reason: 'Task is completed',
            exclusionType: ExclusionType.completed,
          ),
        );
        continue;
      }

      final projectId = task.projectId;
      if (projectId == null) {
        excludedPre.add(
          ExcludedTask(
            task: task,
            reason: 'Task has no project',
            exclusionType: ExclusionType.noCategory,
          ),
        );
        continue;
      }

      final project = projectsById[projectId];
      if (project == null || project.completed) {
        excludedPre.add(
          ExcludedTask(
            task: task,
            reason: 'Project is unavailable',
            exclusionType: ExclusionType.completed,
          ),
        );
        continue;
      }

      if (project.primaryValueId == null ||
          !categories.containsKey(project.primaryValueId)) {
        excludedPre.add(
          ExcludedTask(
            task: task,
            reason: 'Project has no value priority',
            exclusionType: ExclusionType.noCategory,
          ),
        );
        continue;
      }

      tasksByProject.putIfAbsent(projectId, () => []).add(task);
    }

    final projectsByValue = <String, List<Project>>{};
    for (final project in projects) {
      if (project.completed) continue;
      final valueId = project.primaryValueId;
      if (valueId == null || !categories.containsKey(valueId)) continue;

      final tasksForProject = tasksByProject[project.id] ?? const [];
      if (readinessFilter && tasksForProject.isEmpty) continue;

      projectsByValue.putIfAbsent(valueId, () => []).add(project);
    }

    return (
      tasksByProject: tasksByProject,
      projectsByValue: projectsByValue,
      excludedPre: excludedPre,
    );
  }

  List<_AnchorProject> _selectAnchors({
    required Map<String, List<Project>> projectsByValue,
    required Map<String, int> quotas,
    required DateTime todayDayKeyUtc,
    required int rotationPressureDays,
    required Map<String, ProjectAnchorState> anchorByProjectId,
    required int targetAnchorCount,
  }) {
    final anchors = <_AnchorProject>[];
    final selectedProjectIds = <String>{};

    final valueOrder = quotas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in valueOrder) {
      final valueId = entry.key;
      final quota = entry.value;
      if (quota <= 0) continue;

      final available = List<Project>.from(
        projectsByValue[valueId] ?? const [],
      );
      available.sort(
        (a, b) => _compareProjects(
          a,
          b,
          todayDayKeyUtc: todayDayKeyUtc,
          rotationPressureDays: rotationPressureDays,
          anchorByProjectId: anchorByProjectId,
        ),
      );

      for (final project in available) {
        if (anchors.length >= quotas.values.fold<int>(0, (s, v) => s + v)) {
          break;
        }
        if (selectedProjectIds.contains(project.id)) continue;
        anchors.add(_AnchorProject(project: project, valueId: valueId));
        selectedProjectIds.add(project.id);
        if (anchors.where((a) => a.valueId == valueId).length >= quota) {
          break;
        }
      }
    }

    if (anchors.length < targetAnchorCount) {
      final remaining = <_AnchorProject>[];
      for (final entry in projectsByValue.entries) {
        for (final project in entry.value) {
          if (selectedProjectIds.contains(project.id)) continue;
          remaining.add(
            _AnchorProject(project: project, valueId: entry.key),
          );
        }
      }

      remaining.sort(
        (a, b) => _compareProjects(
          a.project,
          b.project,
          todayDayKeyUtc: todayDayKeyUtc,
          rotationPressureDays: rotationPressureDays,
          anchorByProjectId: anchorByProjectId,
        ),
      );

      for (final candidate in remaining) {
        if (anchors.length >= targetAnchorCount) break;
        if (selectedProjectIds.contains(candidate.project.id)) continue;
        anchors.add(candidate);
        selectedProjectIds.add(candidate.project.id);
      }
    }

    return anchors;
  }

  List<Task> _selectTasksForProject(
    List<Task> tasks, {
    required int maxCount,
    required DateTime todayDayKeyUtc,
    required int urgencyThresholdDays,
  }) {
    if (maxCount <= 0 || tasks.isEmpty) return const [];

    final sorted = tasks.toList(growable: false)
      ..sort(
        (a, b) => _compareTasksCalm(
          a,
          b,
          todayDayKeyUtc: todayDayKeyUtc,
          urgencyThresholdDays: urgencyThresholdDays,
        ),
      );

    return sorted.take(maxCount).toList(growable: false);
  }

  int _compareProjects(
    Project a,
    Project b, {
    required DateTime todayDayKeyUtc,
    required int rotationPressureDays,
    required Map<String, ProjectAnchorState> anchorByProjectId,
  }) {
    final aDeadline = a.deadlineDate;
    final bDeadline = b.deadlineDate;
    if (aDeadline != null || bDeadline != null) {
      if (aDeadline == null) return 1;
      if (bDeadline == null) return -1;
      final c = aDeadline.compareTo(bDeadline);
      if (c != 0) return c;
    }

    final aPriority = a.priority;
    final bPriority = b.priority;
    if (aPriority != null || bPriority != null) {
      if (aPriority == null) return 1;
      if (bPriority == null) return -1;
      final c = aPriority.compareTo(bPriority);
      if (c != 0) return c;
    }

    final aIdleDays = _daysSince(a.lastProgressAt, todayDayKeyUtc);
    final bIdleDays = _daysSince(b.lastProgressAt, todayDayKeyUtc);
    if (aIdleDays != bIdleDays) {
      return bIdleDays.compareTo(aIdleDays);
    }

    if (rotationPressureDays > 0) {
      final aAnchorDays = _daysSince(
        anchorByProjectId[a.id]?.lastAnchoredAtUtc,
        todayDayKeyUtc,
      );
      final bAnchorDays = _daysSince(
        anchorByProjectId[b.id]?.lastAnchoredAtUtc,
        todayDayKeyUtc,
      );
      final aPressure = aAnchorDays >= rotationPressureDays;
      final bPressure = bAnchorDays >= rotationPressureDays;
      if (aPressure != bPressure) return aPressure ? -1 : 1;
      if (aAnchorDays != bAnchorDays) {
        return bAnchorDays.compareTo(aAnchorDays);
      }
    }

    return a.name.compareTo(b.name);
  }

  int _compareTasksCalm(
    Task a,
    Task b, {
    required DateTime todayDayKeyUtc,
    required int urgencyThresholdDays,
  }) {
    final aUrgent = _isUrgent(
      a,
      urgencyThresholdDays,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    final bUrgent = _isUrgent(
      b,
      urgencyThresholdDays,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    if (aUrgent != bUrgent) return aUrgent ? -1 : 1;

    final aDeadline = a.deadlineDate;
    final bDeadline = b.deadlineDate;
    if (aDeadline != null || bDeadline != null) {
      if (aDeadline == null) return 1;
      if (bDeadline == null) return -1;
      final c = aDeadline.compareTo(bDeadline);
      if (c != 0) return c;
    }

    final aPriority = a.priority;
    final bPriority = b.priority;
    if (aPriority != null || bPriority != null) {
      if (aPriority == null) return 1;
      if (bPriority == null) return -1;
      final c = aPriority.compareTo(bPriority);
      if (c != 0) return c;
    }

    final updatedC = a.updatedAt.compareTo(b.updatedAt);
    if (updatedC != 0) return updatedC;

    final createdC = a.createdAt.compareTo(b.createdAt);
    if (createdC != 0) return createdC;

    final aStart = a.startDate;
    final bStart = b.startDate;
    if (aStart != null || bStart != null) {
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      final c = aStart.compareTo(bStart);
      if (c != 0) return c;
    }

    return a.name.compareTo(b.name);
  }

  int _daysSince(DateTime? date, DateTime todayDayKeyUtc) {
    if (date == null) return 9999;
    return todayDayKeyUtc.difference(dateOnly(date)).inDays;
  }

  bool _isUrgent(
    Task task,
    int thresholdDays, {
    required DateTime todayDayKeyUtc,
  }) {
    final deadline = task.deadlineDate;
    if (deadline == null) return false;
    final daysUntil = deadline.difference(todayDayKeyUtc).inDays;
    return daysUntil <= thresholdDays;
  }

  List<AllocationReasonCode> _buildReasonCodes({
    required Task task,
    required DateTime todayDayKeyUtc,
    required int urgencyThresholdDays,
    required bool isBalancePick,
  }) {
    return <AllocationReasonCode>[
      AllocationReasonCode.valueAlignment,
      if (task.effectiveValues.length >= 2) AllocationReasonCode.crossValue,
      if (_isUrgent(
        task,
        urgencyThresholdDays,
        todayDayKeyUtc: todayDayKeyUtc,
      ))
        AllocationReasonCode.urgency
      else if (task.priority != null)
        AllocationReasonCode.priority,
      if (isBalancePick) AllocationReasonCode.neglectBalance,
    ];
  }

  List<ExcludedTask> _excludeAll(
    List<Task> tasks, {
    required String reason,
    required DateTime todayDayKeyUtc,
    required int urgencyThresholdDays,
  }) {
    return tasks
        .map(
          (t) => ExcludedTask(
            task: t,
            reason: reason,
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: _isUrgent(
              t,
              urgencyThresholdDays,
              todayDayKeyUtc: todayDayKeyUtc,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<ExcludedTask> _excludeUnselected({
    required Map<String, List<Task>> tasksByProject,
    required Set<String> selectedTaskIds,
    required DateTime todayDayKeyUtc,
    required int urgencyThresholdDays,
  }) {
    final excluded = <ExcludedTask>[];

    for (final entry in tasksByProject.entries) {
      for (final task in entry.value) {
        if (selectedTaskIds.contains(task.id)) continue;
        excluded.add(
          ExcludedTask(
            task: task,
            reason: 'Anchor quota reached',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: _isUrgent(
              task,
              urgencyThresholdDays,
              todayDayKeyUtc: todayDayKeyUtc,
            ),
          ),
        );
      }
    }

    return excluded;
  }
}

final class _AnchorProject {
  const _AnchorProject({required this.project, required this.valueId});

  final Project project;
  final String valueId;
}

final class _SelectedTask {
  const _SelectedTask({required this.task, required this.categoryId});

  final Task task;
  final String categoryId;
}
