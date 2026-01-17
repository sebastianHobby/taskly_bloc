import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';
import 'package:taskly_domain/src/time/date_only.dart';

/// Evaluates tasks against dynamic query filters.
class TaskFilterEvaluator {
  const TaskFilterEvaluator();

  bool evaluate(
    QueryFilter<TaskPredicate> filter,
    Task task, {
    required DateTime todayDayKeyUtc,
  }) {
    // 1. Check shared predicates (AND)
    for (final predicate in filter.shared) {
      if (!_evaluatePredicate(predicate, task, todayDayKeyUtc: todayDayKeyUtc)) {
        return false;
      }
    }

    // 2. Check OR groups
    if (filter.orGroups.isEmpty) {
      return true;
    }

    for (final group in filter.orGroups) {
      // Each group is an AND list. If any group passes, the OR check passes.
      bool groupMatches = true;
      for (final predicate in group) {
        if (!_evaluatePredicate(
          predicate,
          task,
          todayDayKeyUtc: todayDayKeyUtc,
        )) {
          groupMatches = false;
          break;
        }
      }
      if (groupMatches) {
        return true;
      }
    }

    return false;
  }

  bool _evaluatePredicate(
    TaskPredicate predicate,
    Task task, {
    required DateTime todayDayKeyUtc,
  }) {
    return switch (predicate) {
      final TaskBoolPredicate p => _evaluateBool(p, task),
      final TaskDatePredicate p => _evaluateDate(
        p,
        task,
        todayDayKeyUtc: todayDayKeyUtc,
      ),
      final TaskProjectPredicate p => _evaluateProject(p, task),
      final TaskValuePredicate p => _evaluateValue(p, task),
    };
  }

  bool _evaluateBool(TaskBoolPredicate p, Task task) {
    final value = switch (p.field) {
      TaskBoolField.completed => task.completed,
    };

    return switch (p.operator) {
      BoolOperator.isTrue => value,
      BoolOperator.isFalse => !value,
    };
  }

  bool _evaluateDate(
    TaskDatePredicate p,
    Task task, {
    required DateTime todayDayKeyUtc,
  }) {
    final date = switch (p.field) {
      TaskDateField.startDate => task.startDate,
      TaskDateField.deadlineDate => task.deadlineDate,
      TaskDateField.createdAt => task.createdAt,
      TaskDateField.updatedAt => task.updatedAt,
      TaskDateField.completedAt => null, // Not available in Task model yet
    };

    // Handle null checks first
    if (p.operator == DateOperator.isNull) return date == null;
    if (p.operator == DateOperator.isNotNull) return date != null;

    if (date == null) return false; // Cannot compare null date

    switch (p.operator) {
      case DateOperator.onOrAfter:
        return p.date != null &&
            (date.isAfter(p.date!) || date.isAtSameMomentAs(p.date!));
      case DateOperator.onOrBefore:
        return p.date != null &&
            (date.isBefore(p.date!) || date.isAtSameMomentAs(p.date!));
      case DateOperator.before:
        return p.date != null && date.isBefore(p.date!);
      case DateOperator.after:
        return p.date != null && date.isAfter(p.date!);
      case DateOperator.on:
        return p.date != null &&
            date.year == p.date!.year &&
            date.month == p.date!.month &&
            date.day == p.date!.day;
      case DateOperator.between:
        if (p.startDate == null || p.endDate == null) return false;
        return (date.isAfter(p.startDate!) ||
                date.isAtSameMomentAs(p.startDate!)) &&
            (date.isBefore(p.endDate!) || date.isAtSameMomentAs(p.endDate!));
      case DateOperator.relative:
        if (p.relativeDays == null || p.relativeComparison == null) {
          return false;
        }
        final targetDate = todayDayKeyUtc.add(Duration(days: p.relativeDays!));
        final dateOnlyValue = dateOnly(date.toUtc());

        return switch (p.relativeComparison!) {
          RelativeComparison.on => dateOnlyValue.isAtSameMomentAs(targetDate),
          RelativeComparison.before => dateOnlyValue.isBefore(targetDate),
          RelativeComparison.after => dateOnlyValue.isAfter(targetDate),
          RelativeComparison.onOrAfter =>
            dateOnlyValue.isAfter(targetDate) ||
                dateOnlyValue.isAtSameMomentAs(targetDate),
          RelativeComparison.onOrBefore =>
            dateOnlyValue.isBefore(targetDate) ||
                dateOnlyValue.isAtSameMomentAs(targetDate),
        };
      case DateOperator.isNull:
      case DateOperator.isNotNull:
        return false; // Handled before switch
    }
  }

  bool _evaluateProject(TaskProjectPredicate p, Task task) {
    final projectId = task.projectId;

    switch (p.operator) {
      case ProjectOperator.isNull:
        return projectId == null;
      case ProjectOperator.isNotNull:
        return projectId != null;
      case ProjectOperator.matches:
        return projectId == p.projectId;
      case ProjectOperator.matchesAny:
        return projectId != null && p.projectIds.contains(projectId);
    }
  }

  bool _evaluateValue(TaskValuePredicate p, Task task) {
    final taskValueIds = task.values.map((v) => v.id).toSet();

    // If a task has explicit values, it is treated as overriding project values.
    // In that case, inherited values should not be considered.
    if (p.includeInherited && taskValueIds.isEmpty && task.project != null) {
      for (final v in task.project!.values) {
        taskValueIds.add(v.id);
      }
    }

    switch (p.operator) {
      case ValueOperator.isNull:
        return taskValueIds.isEmpty;
      case ValueOperator.isNotNull:
        return taskValueIds.isNotEmpty;
      case ValueOperator.hasAny:
        return p.valueIds.any(taskValueIds.contains);
      case ValueOperator.hasAll:
        return p.valueIds.every(taskValueIds.contains);
    }
  }
}
