import 'package:taskly_domain/core.dart';

/// Shared flat list row UI models for feed screens (Anytime).
///
/// The hierarchy is expressed via [depth] and by deterministic ordering of
/// header rows before their children (DEC-072A).
sealed class ListRowUiModel {
  const ListRowUiModel({required this.rowKey, required this.depth});

  final String rowKey;
  final int depth;
}

final class ValueHeaderRowUiModel extends ListRowUiModel {
  const ValueHeaderRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.title,
    required this.valueId,
    required this.priority,
    this.isTappableToScope = false,
  });

  final String title;
  final String? valueId;
  final ValuePriority? priority;

  /// Whether the UI should treat this header as tappable to scope navigation.
  final bool isTappableToScope;
}

final class ProjectHeaderRowUiModel extends ListRowUiModel {
  const ProjectHeaderRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.title,
    required this.projectRef,
    this.trailingLabel,
    this.isCollapsed,
  });

  final String title;
  final ProjectGroupingRef projectRef;

  /// Optional right-aligned label for the header (e.g. item count).
  final String? trailingLabel;

  /// Optional collapse state when the header controls hiding/showing children.
  final bool? isCollapsed;
}

final class TaskRowUiModel extends ListRowUiModel {
  const TaskRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.task,
    this.showProjectLabel = true,
  });

  final Task task;
  final bool showProjectLabel;
}

/// Scheduled-only: high-level bucket header (This Week/Next Week/Later).
// Scheduled feed row types were removed with the feed schema migration.
