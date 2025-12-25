import 'dart:async';

import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart'
    as domain_filtering;
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

/// Stream transformer that applies filtering rules and sorting to task lists.
///
/// Filters tasks according to provided rules, then sorts them according to
/// provided criteria. Handles errors gracefully by logging and propagating.
class TaskFilterTransformer
    extends StreamTransformerBase<List<Task>, List<Task>> {
  /// Creates a task filter transformer.
  TaskFilterTransformer({
    required this.rules,
    required this.sortCriteria,
    required this.context,
  });

  /// The filtering rules to apply.
  final List<TaskRule> rules;

  /// The sort criteria to apply after filtering.
  final List<SortCriterion> sortCriteria;

  /// The evaluation context for rule evaluation.
  final domain_filtering.EvaluationContext context;

  static final _logger = AppLogger('domain.filter_transformer');

  @override
  Stream<List<Task>> bind(Stream<List<Task>> stream) {
    return stream.map(_transform).handleError(
      (Object error, StackTrace stackTrace) {
        _logger.error(
          'Error in task filter transformer',
          error,
          stackTrace,
        );
        // Propagate the error to the stream
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  /// Transforms a list of tasks by applying filtering and sorting.
  List<Task> _transform(List<Task> tasks) {
    try {
      // Apply filtering rules
      List<Task> filtered = tasks;
      if (rules.isNotEmpty) {
        filtered = tasks.where(_evaluateRules).toList();
      }

      // Apply sorting
      if (sortCriteria.isNotEmpty) {
        filtered.sort((a, b) => _compareWithCriteria(a, b, sortCriteria));
      }

      return filtered;
    } on Exception catch (error, stackTrace) {
      _logger.error(
        'Error transforming tasks',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Evaluates all rules against a task (AND logic).
  bool _evaluateRules(Task task) {
    try {
      for (final rule in rules) {
        if (!rule.evaluate(task, context)) {
          return false;
        }
      }
      return true;
    } on Exception catch (error, stackTrace) {
      _logger.error(
        'Error evaluating rule for task ${task.id}',
        error,
        stackTrace,
      );
      // On error, exclude the task to be safe
      return false;
    }
  }

  /// Compares two tasks using the provided sort criteria.
  int _compareWithCriteria(Task a, Task b, List<SortCriterion> criteria) {
    for (final criterion in criteria) {
      final comparison = _compareByField(a, b, criterion);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  /// Compares two tasks by a specific field.
  int _compareByField(Task a, Task b, SortCriterion criterion) {
    final comparison = switch (criterion.field) {
      SortField.name => compareAsciiLowerCase(a.name, b.name),
      SortField.startDate => compareNullableDate(a.startDate, b.startDate),
      SortField.deadlineDate => compareNullableDate(
        a.deadlineDate,
        b.deadlineDate,
      ),
      SortField.createdDate => a.createdAt.compareTo(b.createdAt),
      SortField.updatedDate => a.updatedAt.compareTo(b.updatedAt),
    };

    return criterion.direction == SortDirection.ascending
        ? comparison
        : -comparison;
  }
}
