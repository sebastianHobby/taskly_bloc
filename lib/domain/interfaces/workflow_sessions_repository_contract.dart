import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart';

/// Repository contract for managing workflow sessions.
abstract class WorkflowSessionsRepositoryContract {
  /// Watch a workflow session by ID.
  Stream<WorkflowSession?> watchSession(String id);

  /// Watch sessions for a given screen definition ID.
  Stream<List<WorkflowSession>> watchSessionsForScreen(String screenId);

  /// Start a new workflow session for a screen.
  Future<String> startSession({
    required String screenId,
    required int totalItems,
    String? sessionNotes,
  });

  /// Mark a session as completed.
  Future<void> completeSession({
    required String sessionId,
    String? sessionNotes,
  });

  /// Mark a session as abandoned.
  Future<void> abandonSession({
    required String sessionId,
    String? sessionNotes,
  });
}
