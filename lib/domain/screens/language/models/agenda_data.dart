import 'package:flutter/foundation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

/// Types of date tags for agenda items.
enum AgendaDateTag {
  /// Item starts on this date.
  starts,

  /// Item is in progress (between start and deadline).
  inProgress,

  /// Item is due on this date.
  due,
}

/// Extension for AgendaDateTag display.
extension AgendaDateTagX on AgendaDateTag {
  /// Display label for the tag.
  String get label => switch (this) {
    AgendaDateTag.starts => 'Starts',
    AgendaDateTag.inProgress => 'Ongoing',
    AgendaDateTag.due => 'Due',
  };

  /// Icon name for the tag.
  String get iconName => switch (this) {
    AgendaDateTag.starts => 'play_arrow',
    AgendaDateTag.inProgress => 'pending',
    AgendaDateTag.due => 'flag',
  };
}

/// A single item in the agenda (task or project).
@immutable
class AgendaItem {
  const AgendaItem({
    required this.entityType,
    required this.entityId,
    required this.name,
    required this.tag,
    required this.tileCapabilities,
    this.task,
    this.project,
    this.isCondensed = false,
    this.isAfterCompletionRepeat = false,
  });

  /// Type of entity.
  final EntityType entityType;

  /// Entity ID.
  final String entityId;

  /// Display name.
  final String name;

  /// Date tag for this occurrence.
  final AgendaDateTag tag;

  /// Domain-sourced tile capability policy for this item.
  final EntityTileCapabilities tileCapabilities;

  /// The task entity (if entityType == 'task').
  final Task? task;

  /// The project entity (if entityType == 'project').
  final Project? project;

  /// Whether to display in condensed "Ongoing" format.
  ///
  /// When true, shows only name and mini indicator without full metadata.
  /// Used for intermediate days between start and deadline.
  final bool isCondensed;

  /// Whether this is an after-completion repeating item.
  ///
  /// When true, displays a repeat icon to indicate the item
  /// repeats after completion (vs fixed interval).
  final bool isAfterCompletionRepeat;

  /// Convenience getter to check if this is a task.
  bool get isTask => entityType == EntityType.task;

  /// Convenience getter to check if this is a project.
  bool get isProject => entityType == EntityType.project;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgendaItem &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.tag == tag &&
        other.isCondensed == isCondensed;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, tag, isCondensed);
}

/// A group of items for a specific date in the agenda.
@immutable
class AgendaDateGroup {
  const AgendaDateGroup({
    required this.date,
    required this.semanticLabel,
    required this.formattedHeader,
    required this.items,
    this.isEmpty = false,
  });

  /// The date this group represents.
  final DateTime date;

  /// Semantic label like "Today", "Tomorrow", "This Week", etc.
  final String semanticLabel;

  /// Formatted header like "Mon, Jan 15".
  final String formattedHeader;

  /// Items scheduled for this date.
  final List<AgendaItem> items;

  /// Whether this is an empty day placeholder.
  final bool isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgendaDateGroup &&
        other.date == date &&
        other.semanticLabel == semanticLabel &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(date, semanticLabel, Object.hashAll(items));
}

/// Complete agenda data for the Scheduled view.
@immutable
class AgendaData {
  const AgendaData({
    required this.groups,
    required this.focusDate,
    this.overdueItems = const [],
    this.loadedHorizonEnd,
  });

  /// Date groups in chronological order.
  final List<AgendaDateGroup> groups;

  /// The current focus date (usually today or selected date).
  final DateTime focusDate;

  /// Overdue items (deadline < today, not completed).
  final List<AgendaItem> overdueItems;

  /// The end date of the currently loaded data horizon.
  final DateTime? loadedHorizonEnd;

  /// Total count of all items across all groups.
  int get totalItemCount =>
      groups.fold(0, (sum, group) => sum + group.items.length) +
      overdueItems.length;

  /// Whether there are any overdue items.
  bool get hasOverdue => overdueItems.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgendaData &&
        other.focusDate == focusDate &&
        listEquals(other.groups, groups) &&
        listEquals(other.overdueItems, overdueItems);
  }

  @override
  int get hashCode => Object.hash(
    focusDate,
    Object.hashAll(groups),
    Object.hashAll(overdueItems),
  );
}
