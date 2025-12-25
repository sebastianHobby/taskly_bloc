import 'dart:async';

import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart'
    as domain_filtering;
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_transformer.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

/// Service for finalizing task filter streams.
///
/// Applies pending rules and sort criteria to task streams that were not
/// fully filtered at the database level.
class TaskFilterService {
  /// Creates a task filter service.
  const TaskFilterService();

  static final _logger = AppLogger('domain.filter_service');

  /// Finalizes a stream by applying pending rules and sort criteria.
  ///
  /// If [metadata] indicates no pending operations, returns [source] unchanged.
  /// Otherwise, applies pending rules and sort criteria using [context].
  Stream<List<Task>> finalize(
    Stream<List<Task>> source,
    FilterResultMetadata metadata,
    domain_filtering.EvaluationContext context,
  ) {
    try {
      if (!metadata.requiresPostProcessing) {
        _logger.debug('No post-processing required, returning source stream');
        return source;
      }

      _logger.debug(
        'Finalizing stream with ${metadata.pendingRules.length} pending rules '
        'and ${metadata.pendingSort.length} pending sort criteria',
      );

      return source.transform(
        transformer(
          rules: metadata.pendingRules,
          sortCriteria: metadata.pendingSort,
          context: context,
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error finalizing filter stream',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Creates a stream transformer for filtering and sorting tasks.
  ///
  /// The transformer applies [rules] followed by [sortCriteria] to each
  /// emitted task list, using [context] for rule evaluation.
  StreamTransformer<List<Task>, List<Task>> transformer({
    required List<TaskRule> rules,
    required List<SortCriterion> sortCriteria,
    required domain_filtering.EvaluationContext context,
  }) {
    return TaskFilterTransformer(
      rules: rules,
      sortCriteria: sortCriteria,
      context: context,
    );
  }
}
