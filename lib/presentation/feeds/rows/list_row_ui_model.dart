import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart' show ScheduledOccurrence;

import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';

/// Shared flat list row UI models for feed screens (Anytime/Scheduled/My Day).
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
  });

  final String title;
  final ProjectGroupingRef projectRef;
}

final class TaskRowUiModel extends ListRowUiModel {
  const TaskRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.task,
  });

  final Task task;
}

/// Scheduled-only: high-level bucket header (This Week/Next Week/Later).
final class BucketHeaderRowUiModel extends ListRowUiModel {
  const BucketHeaderRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.bucketKey,
    required this.title,
    required this.isCollapsed,
  });

  final String bucketKey;
  final String title;

  /// Whether the bucket's child rows are currently hidden.
  final bool isCollapsed;
}

/// Scheduled-only: per-day header (e.g. "Mon, Jan 15").
final class DateHeaderRowUiModel extends ListRowUiModel {
  const DateHeaderRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.date,
    required this.title,
  });

  final DateTime date;
  final String title;
}

/// Scheduled-only: empty-day placeholder row.
final class EmptyDayRowUiModel extends ListRowUiModel {
  const EmptyDayRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.date,
  });

  final DateTime date;
}

/// Scheduled-only: a scheduled agenda item row (task or project).
final class AgendaEntityRowUiModel extends ListRowUiModel {
  const AgendaEntityRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.item,
  });

  final AgendaItem item;
}

/// Scheduled-only: a scheduled occurrence row (task or project).
final class ScheduledEntityRowUiModel extends ListRowUiModel {
  const ScheduledEntityRowUiModel({
    required super.rowKey,
    required super.depth,
    required this.occurrence,
  });

  final ScheduledOccurrence occurrence;
}
