import 'package:taskly_domain/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';

sealed class TileIntent {
  const TileIntent();
}

final class TileIntentSetCompletion extends TileIntent {
  const TileIntentSetCompletion({
    required this.entityType,
    required this.entityId,
    required this.completed,
    required this.scope,
    this.occurrenceDate,
    this.originalOccurrenceDate,
  });

  final EntityType entityType;
  final String entityId;
  final bool completed;

  final CompletionScope scope;
  final DateTime? occurrenceDate;
  final DateTime? originalOccurrenceDate;
}

final class TileIntentSetPinned extends TileIntent {
  const TileIntentSetPinned({
    required this.entityType,
    required this.entityId,
    required this.isPinned,
  });

  final EntityType entityType;
  final String entityId;
  final bool isPinned;
}

final class TileIntentRequestDelete extends TileIntent {
  const TileIntentRequestDelete({
    required this.entityType,
    required this.entityId,
    required this.entityName,
  });

  final EntityType entityType;
  final String entityId;
  final String entityName;
}

final class TileIntentOpenEditor extends TileIntent {
  const TileIntentOpenEditor({
    required this.entityType,
    required this.entityId,
    this.openToValues = false,
    this.openToProjectPicker = false,
  });

  final EntityType entityType;
  final String entityId;

  /// When true, opens the editor and scrolls to/open the values alignment UX.
  final bool openToValues;

  /// When true, opens the editor and immediately opens the project picker.
  ///
  /// Intended for task move-to-project flows.
  final bool openToProjectPicker;
}

final class TileIntentOpenDetails extends TileIntent {
  const TileIntentOpenDetails({
    required this.entityType,
    required this.entityId,
  });

  final EntityType entityType;
  final String entityId;
}

final class TileIntentOpenMoveToProject extends TileIntent {
  const TileIntentOpenMoveToProject({
    required this.taskId,
    required this.taskName,
    required this.allowOpenEditor,
    required this.allowQuickMove,
  });

  final String taskId;
  final String taskName;

  /// Whether the UX may offer the "open editor" option.
  final bool allowOpenEditor;

  /// Whether the UX may offer the "quick move" option.
  final bool allowQuickMove;
}

final class TileIntentMoveTaskToProject extends TileIntent {
  const TileIntentMoveTaskToProject({
    required this.taskId,
    required this.targetProjectId,
  });

  final String taskId;

  /// Empty string means "no project".
  final String targetProjectId;
}
