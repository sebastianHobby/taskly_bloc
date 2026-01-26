import 'package:taskly_domain/src/models/models.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class ProjectAnchorStateRepositoryContract {
  /// Watch anchor state for all projects.
  Stream<List<ProjectAnchorState>> watchAll();

  Future<List<ProjectAnchorState>> getAll();

  /// Record an anchor timestamp for multiple projects.
  Future<void> recordAnchors({
    required Iterable<String> projectIds,
    required DateTime anchoredAtUtc,
    OperationContext? context,
  });
}
