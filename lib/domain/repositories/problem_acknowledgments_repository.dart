import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';

/// Repository interface for managing soft gate acknowledgments.
abstract class ProblemAcknowledgmentsRepository {
  /// Watch acknowledgments for a given entity.
  Stream<List<ProblemAcknowledgment>> watchAcknowledgmentsForEntity({
    required EntityType entityType,
    required String entityId,
  });

  /// Create a new acknowledgment.
  Future<String> acknowledge({
    required ProblemType problemType,
    required EntityType entityType,
    required String entityId,
    ResolutionAction? resolutionAction,
    DateTime? snoozeUntil,
    DateTime? acknowledgedAt,
  });
}
