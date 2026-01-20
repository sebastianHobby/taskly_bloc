import 'dart:math' as math;

import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

/// Single, calm, values-led allocator used for "Suggested" picks.
///
/// Key properties:
/// - Proportional value distribution based on category weights.
/// - Optional bounded value balancing via "quota repair" (Q2).
/// - Calm tie-break ordering (no multiplicative urgency/priority weighting).
final class SuggestedPicksEngine implements AllocationStrategy {
  @override
  String get strategyName => 'SuggestedPicksEngine';

  @override
  String get description =>
      'Allocates tasks proportionally by value and optionally rebalances toward '
      'neglected values using bounded quota repair.';

  @override
  AllocationResult allocate(AllocationParameters parameters) {
    final tasks = parameters.tasks;
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
          strategyUsed: 'SuggestedPicksEngine',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'No categories with weights defined',
        ),
      );
    }

    final (
      tasksByCategory,
      tasksWithoutCategory,
      excludedPre,
    ) = _groupTasksByCategory(
      tasks,
      categories: categories,
    );

    final baseQuotas = _computeProportionalQuotas(
      categories: categories,
      totalWeight: totalWeight,
      totalLimit: totalLimit,
    );

    final baseSelection = _selectByQuotas(
      tasksByCategory: tasksByCategory,
      quotas: baseQuotas,
      parameters: parameters,
    );

    final bool keepValuesInBalance =
        parameters.keepValuesInBalance &&
        parameters.completionsByValue.isNotEmpty;

    final finalQuotas = keepValuesInBalance
        ? _applyBoundedQuotaRepairQ2(
            baseQuotas: baseQuotas,
            tasksByCategory: tasksByCategory,
            categories: categories,
            totalWeight: totalWeight,
            suggestedCount: totalLimit,
            completionsByValue: parameters.completionsByValue,
          )
        : baseQuotas;

    final selection = _selectByQuotas(
      tasksByCategory: tasksByCategory,
      quotas: finalQuotas,
      parameters: parameters,
    );

    final repairedSelectionIds = keepValuesInBalance
        ? selection.selectedTaskIds.difference(baseSelection.selectedTaskIds)
        : const <String>{};

    final allocatedTasks = <AllocatedTask>[];
    for (final allocated in selection.selected) {
      final reasonCodes = _buildReasonCodes(
        task: allocated.task,
        todayDayKeyUtc: todayDayKeyUtc,
        urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
        isBalancePick: repairedSelectionIds.contains(allocated.task.id),
      );

      allocatedTasks.add(
        AllocatedTask(
          task: allocated.task,
          qualifyingValueId: allocated.categoryId,
          allocationScore: categories[allocated.categoryId] ?? 0,
          reasonCodes: reasonCodes,
        ),
      );
    }

    final excludedTasks = <ExcludedTask>[
      ...excludedPre,
      ..._excludeUnselectedByCategory(
        tasksByCategory: tasksByCategory,
        selectedTaskIds: selection.selectedTaskIds,
        quotas: finalQuotas,
        parameters: parameters,
      ),
      ..._excludeWithoutCategory(
        tasksWithoutCategory,
        reason: 'Task has no matching priority category',
        todayDayKeyUtc: todayDayKeyUtc,
        urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
      ),
    ];

    return AllocationResult(
      allocatedTasks: allocatedTasks,
      excludedTasks: excludedTasks,
      reasoning: AllocationReasoning(
        strategyUsed: strategyName,
        categoryAllocations: finalQuotas,
        categoryWeights: categories,
        explanation: keepValuesInBalance
            ? 'Proportional allocation with bounded value balancing'
            : 'Proportional allocation',
      ),
    );
  }

  ({
    List<_SelectedTask> selected,
    Set<String> selectedTaskIds,
  })
  _selectByQuotas({
    required Map<String, List<Task>> tasksByCategory,
    required Map<String, int> quotas,
    required AllocationParameters parameters,
  }) {
    final todayDayKeyUtc = parameters.todayDayKeyUtc;

    final selected = <_SelectedTask>[];
    final selectedIds = <String>{};

    for (final entry in quotas.entries) {
      final categoryId = entry.key;
      final quota = entry.value;

      final available = List<Task>.from(
        tasksByCategory[categoryId] ?? const [],
      );
      if (available.isEmpty || quota <= 0) continue;

      available.sort(
        (a, b) => _compareTasksCalm(
          a,
          b,
          todayDayKeyUtc: todayDayKeyUtc,
          urgencyThresholdDays: parameters.taskUrgencyThresholdDays,
        ),
      );

      final takeCount = math.min(quota, available.length);
      for (var i = 0; i < takeCount; i++) {
        final task = available[i];
        selected.add(_SelectedTask(task: task, categoryId: categoryId));
        selectedIds.add(task.id);
      }
    }

    // Fill remaining slots (if some categories are empty) with best remaining.
    final remainingSlots = parameters.maxTasks - selected.length;
    if (remainingSlots > 0) {
      final remaining = <_SelectedTask>[];
      for (final entry in tasksByCategory.entries) {
        final categoryId = entry.key;
        for (final task in entry.value) {
          if (selectedIds.contains(task.id)) continue;
          remaining.add(_SelectedTask(task: task, categoryId: categoryId));
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

      for (final pick in remaining.take(remainingSlots)) {
        selected.add(pick);
        selectedIds.add(pick.task.id);
      }
    }

    return (selected: selected, selectedTaskIds: selectedIds);
  }

  (
    Map<String, List<Task>> tasksByCategory,
    List<Task> tasksWithoutCategory,
    List<ExcludedTask> excludedPre,
  )
  _groupTasksByCategory(
    List<Task> tasks, {
    required Map<String, double> categories,
  }) {
    final tasksByCategory = <String, List<Task>>{};
    final tasksWithoutCategory = <Task>[];
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

      // Use effective values (task values override project, else inherit).
      final effectiveValueIds = task.effectiveValues.map((v) => v.id).toSet();

      // Match categories from parameters.
      final matched = categories.keys
          .where(effectiveValueIds.contains)
          .toList();
      if (matched.isEmpty) {
        tasksWithoutCategory.add(task);
        continue;
      }

      // Assign to highest-weighted matching category.
      matched.sort((a, b) => categories[b]!.compareTo(categories[a]!));
      final categoryId = matched.first;
      tasksByCategory.putIfAbsent(categoryId, () => []).add(task);
    }

    return (tasksByCategory, tasksWithoutCategory, excludedPre);
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
  Map<String, int> _applyBoundedQuotaRepairQ2({
    required Map<String, int> baseQuotas,
    required Map<String, List<Task>> tasksByCategory,
    required Map<String, double> categories,
    required double totalWeight,
    required int suggestedCount,
    required Map<String, int> completionsByValue,
  }) {
    // Only consider categories that have at least one candidate task.
    final availableCountByCategory = <String, int>{
      for (final entry in categories.entries)
        entry.key: (tasksByCategory[entry.key]?.length ?? 0),
    };

    final relevantCategories = categories.keys
        .where((id) => (availableCountByCategory[id] ?? 0) > 0)
        .toList(growable: false);

    if (relevantCategories.length <= 1) return baseQuotas;

    final totalCompletions = relevantCategories.fold<int>(
      0,
      (sum, id) => sum + (completionsByValue[id] ?? 0),
    );

    // If we have no completion data, we can't honestly claim "neglect".
    if (totalCompletions <= 0) return baseQuotas;

    final deficits = <String, double>{};
    var topNeglect = 0.0;

    for (final id in relevantCategories) {
      final targetShare = (categories[id]! / totalWeight).clamp(0.0, 1.0);
      final actualShare = (completionsByValue[id] ?? 0) / totalCompletions;
      final deficit = (targetShare - actualShare).clamp(0.0, 1.0);
      deficits[id] = deficit;
      if (deficit > topNeglect) topNeglect = deficit;
    }

    final maxMoves = (suggestedCount * 0.25 * topNeglect).round().clamp(0, 3);
    if (maxMoves <= 0) return baseQuotas;

    final repairedQuotas = Map<String, int>.from(baseQuotas);

    String? pickReceiver() {
      final sorted = deficits.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sorted) {
        final categoryId = entry.key;
        final quota = repairedQuotas[categoryId] ?? 0;
        final available = availableCountByCategory[categoryId] ?? 0;
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
    }

    return repairedQuotas;
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

    return a.name.compareTo(b.name);
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

  List<ExcludedTask> _excludeUnselectedByCategory({
    required Map<String, List<Task>> tasksByCategory,
    required Set<String> selectedTaskIds,
    required Map<String, int> quotas,
    required AllocationParameters parameters,
  }) {
    final excluded = <ExcludedTask>[];

    for (final entry in quotas.entries) {
      final categoryId = entry.key;
      final allocation = entry.value;
      final available = tasksByCategory[categoryId] ?? const [];
      if (available.isEmpty) continue;

      // Exclude all tasks in category that weren't selected.
      for (final task in available) {
        if (selectedTaskIds.contains(task.id)) continue;
        excluded.add(
          ExcludedTask(
            task: task,
            reason: 'Category limit reached ($allocation tasks)',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: _isUrgent(
              task,
              parameters.taskUrgencyThresholdDays,
              todayDayKeyUtc: parameters.todayDayKeyUtc,
            ),
          ),
        );
      }
    }

    return excluded;
  }

  List<ExcludedTask> _excludeWithoutCategory(
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
            exclusionType: ExclusionType.noCategory,
            isUrgent: _isUrgent(
              t,
              urgencyThresholdDays,
              todayDayKeyUtc: todayDayKeyUtc,
            ),
          ),
        )
        .toList(growable: false);
  }
}

final class _SelectedTask {
  const _SelectedTask({required this.task, required this.categoryId});

  final Task task;
  final String categoryId;
}
