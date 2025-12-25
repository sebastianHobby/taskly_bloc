import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart'
    as domain_filtering;
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_service.dart';

/// Result of a filtered stream query.
///
/// Contains both the stream of tasks and metadata about how the filtering
/// was applied. If not fully filtered, the stream may require post-processing
/// via [finalize].
class FilteredStreamResult {
  /// Creates a filtered stream result.
  const FilteredStreamResult({
    required this.stream,
    required this.metadata,
  });

  /// The stream of tasks from the database query.
  final Stream<List<Task>> stream;

  /// Metadata about which filters were applied and which are pending.
  final FilterResultMetadata metadata;

  /// Whether all filtering has been fully applied at the database level.
  bool get isFullyFiltered => metadata.isFullyApplied;

  /// Finalizes the stream by applying any pending rules and sort criteria.
  ///
  /// If the stream is already fully filtered, returns the stream unchanged.
  /// Otherwise, applies the pending operations using the provided [service]
  /// and [context].
  Stream<List<Task>> finalize(
    TaskFilterService service,
    domain_filtering.EvaluationContext context,
  ) {
    if (isFullyFiltered) {
      return stream;
    }

    return service.finalize(stream, metadata, context);
  }
}
