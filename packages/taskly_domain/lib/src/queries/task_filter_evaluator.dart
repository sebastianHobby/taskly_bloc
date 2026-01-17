import 'package:taskly_domain/src/filtering/evaluation_context.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/queries/operators/operators.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

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
      TaskValuePredicate() => _evalValue(task, predicate),
    };
  }

  bool _evalBool(Task task, TaskBoolPredicate p) {
    final value = switch (p.field) {
      TaskBoolField.completed => task.completed,
    };
    return BoolComparison.evaluate(fieldValue: value, operator: p.operator);
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

  bool _evalValue(Task task, TaskValuePredicate p) {
    final ids = <String>{...task.values.map((v) => v.id)};

    // If a task has explicit values, it is treated as overriding project values.
    // In that case, inherited values should not be considered.
    if (p.includeInherited && ids.isEmpty && task.project != null) {
      ids.addAll(task.project!.values.map((v) => v.id));
    }

    return ValueComparison.evaluate(
      entityValueIds: ids,
      predicateValueIds: p.valueIds,
      operator: p.operator,
    );
  }

  bool _evalDate(Task task, TaskDatePredicate p, EvaluationContext ctx) {
    final fieldValue = switch (p.field) {
      TaskDateField.startDate => task.startDate,
      TaskDateField.deadlineDate => task.deadlineDate,
      TaskDateField.createdAt => task.createdAt,
      TaskDateField.updatedAt => task.updatedAt,
      TaskDateField.completedAt => task.occurrence?.completedAt,
    };

    if (p.operator == DateOperator.relative) {
      final comp = p.relativeComparison;
      final days = p.relativeDays;
      if (comp == null || days == null) return false;

      return DateComparison.evaluateRelative(
        fieldValue: fieldValue,
        comparison: comp,
        pivot: ctx.today.add(Duration(days: days)),
      );
    }

    return DateComparison.evaluate(
      fieldValue: fieldValue,
      operator: p.operator,
      date: p.date,
      startDate: p.startDate,
      endDate: p.endDate,
    );
  }
}
