import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// Evaluates task filters (shared AND + one-level OR groups).
class TaskFilterEvaluator {
  const TaskFilterEvaluator();

  bool matches(
    Task task,
    QueryFilter<TaskPredicate> filter,
    EvaluationContext ctx,
  ) {
    if (filter.isMatchAll) return true;

    final sharedOk = filter.shared.every((p) => _evalPredicate(task, p, ctx));
    if (!sharedOk) return false;

    if (filter.orGroups.isEmpty) return true;

    for (final group in filter.orGroups) {
      final groupOk = group.every((p) => _evalPredicate(task, p, ctx));
      if (groupOk) return true;
    }

    return false;
  }

  bool _evalPredicate(
    Task task,
    TaskPredicate predicate,
    EvaluationContext ctx,
  ) {
    return switch (predicate) {
      TaskBoolPredicate() => _evalBool(task, predicate),
      TaskDatePredicate() => _evalDate(task, predicate, ctx),
      TaskProjectPredicate() => _evalProject(task, predicate),
      TaskLabelPredicate() => _evalLabel(task, predicate),
    };
  }

  bool _evalBool(Task task, TaskBoolPredicate p) {
    final value = switch (p.field) {
      TaskBoolField.completed => task.completed,
    };

    return switch (p.operator) {
      BoolOperator.isTrue => value,
      BoolOperator.isFalse => !value,
    };
  }

  bool _evalProject(Task task, TaskProjectPredicate p) {
    return switch (p.operator) {
      ProjectOperator.matches =>
        task.projectId != null && task.projectId == p.projectId,
      ProjectOperator.matchesAny =>
        task.projectId != null && p.projectIds.contains(task.projectId),
      ProjectOperator.isNull => task.projectId == null,
      ProjectOperator.isNotNull => task.projectId != null,
    };
  }

  bool _evalLabel(Task task, TaskLabelPredicate p) {
    final ids = task.labels
        .where((l) => l.type == p.labelType)
        .map((l) => l.id)
        .toSet();

    return switch (p.operator) {
      LabelOperator.hasAny => p.labelIds.any(ids.contains),
      LabelOperator.hasAll => p.labelIds.every(ids.contains),
      LabelOperator.isNull => ids.isEmpty,
      LabelOperator.isNotNull => ids.isNotEmpty,
    };
  }

  bool _evalDate(Task task, TaskDatePredicate p, EvaluationContext ctx) {
    final fieldValue = switch (p.field) {
      TaskDateField.startDate => task.startDate,
      TaskDateField.deadlineDate => task.deadlineDate,
      TaskDateField.createdAt => task.createdAt,
      TaskDateField.updatedAt => task.updatedAt,
      TaskDateField.completedAt => task.occurrence?.completedAt,
    };

    DateTime? absoluteDate;
    DateTime? absoluteEndDate;

    if (p.operator == DateOperator.relative) {
      final comp = p.relativeComparison;
      final days = p.relativeDays;
      if (comp == null || days == null) return false;

      final pivot = dateOnly(ctx.today.add(Duration(days: days)));
      final target = fieldValue == null ? null : dateOnly(fieldValue);
      if (target == null) return false;

      return switch (comp) {
        RelativeComparison.on => target.isAtSameMomentAs(pivot),
        RelativeComparison.before => target.isBefore(pivot),
        RelativeComparison.after => target.isAfter(pivot),
        RelativeComparison.onOrAfter => !target.isBefore(pivot),
        RelativeComparison.onOrBefore => !target.isAfter(pivot),
      };
    }

    absoluteDate = p.date;
    absoluteEndDate = p.endDate;

    return switch (p.operator) {
      DateOperator.onOrAfter =>
        fieldValue != null && !fieldValue.isBefore(absoluteDate!),
      DateOperator.onOrBefore =>
        fieldValue != null && !fieldValue.isAfter(absoluteDate!),
      DateOperator.before =>
        fieldValue != null && fieldValue.isBefore(absoluteDate!),
      DateOperator.after =>
        fieldValue != null && fieldValue.isAfter(absoluteDate!),
      DateOperator.on =>
        fieldValue != null && dateOnly(fieldValue) == dateOnly(absoluteDate!),
      DateOperator.between =>
        fieldValue != null &&
            !fieldValue.isBefore(p.startDate!) &&
            !fieldValue.isAfter(absoluteEndDate!),
      DateOperator.isNull => fieldValue == null,
      DateOperator.isNotNull => fieldValue != null,
      DateOperator.relative => false,
    };
  }
}
