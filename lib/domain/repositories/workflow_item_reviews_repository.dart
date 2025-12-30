import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart';

/// Repository interface for managing per-item workflow actions.
abstract class WorkflowItemReviewsRepository {
  /// Watch all recorded item actions for a workflow session.
  Stream<List<WorkflowItemReview>> watchSessionItemReviews(String sessionId);

  /// Record an action for a single entity in a workflow session.
  ///
  /// Implementations should update workflow session counters and update the
  /// underlying entity's review fields (where applicable).
  Future<String> addItemReview({
    required String sessionId,
    required EntityType entityType,
    required String entityId,
    required WorkflowAction action,
    String? reviewNotes,
    DateTime? reviewedAt,
  });
}
