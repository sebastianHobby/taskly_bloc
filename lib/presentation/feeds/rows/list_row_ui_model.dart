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
  });

  final Task task;
}

final class ProjectRowUiModel extends ListRowUiModel {
  const ProjectRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.project,
    required this.taskCount,
    required this.completedTaskCount,
    required this.dueSoonCount,
  });

  final Project? project;
  final int taskCount;
  final int completedTaskCount;
  final int dueSoonCount;
}

/// Scheduled-only: high-level bucket header (This Week/Next Week/Later).
// Scheduled feed row types were removed with the feed schema migration.
