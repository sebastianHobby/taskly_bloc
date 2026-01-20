import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// High-level rendering intent for a Task tile.
///
/// Use intents to describe *why* a tile is being shown (screen/flow), not *how*
/// it should be configured.
sealed class TaskTileIntent {
  const TaskTileIntent();

  /// Default task list tile used across most lists.
  const factory TaskTileIntent.standardList() = TaskTileIntentStandardList;

  /// A task list tile optimized for "My Day" surfaces.
  const factory TaskTileIntent.myDayList() = TaskTileIntentMyDayList;

  /// A task row used for selection flows (e.g., "pick tasks").
  ///
  /// The selection state is part of the intent.
  const factory TaskTileIntent.selection({required bool selected}) =
      TaskTileIntentSelection;
}

final class TaskTileIntentStandardList extends TaskTileIntent {
  const TaskTileIntentStandardList();
}

final class TaskTileIntentMyDayList extends TaskTileIntent {
  const TaskTileIntentMyDayList();
}

final class TaskTileIntentSelection extends TaskTileIntent {
  const TaskTileIntentSelection({required this.selected});

  final bool selected;
}

/// Semantic markers about a task that affect small affordances.
@immutable
final class TaskTileMarkers {
  const TaskTileMarkers({this.pinned = false});

  final bool pinned;
}

/// Intent-based actions for a task tile.
///
/// Passing a callback opts into the corresponding affordance.
@immutable
final class TaskTileActions {
  const TaskTileActions({
    required this.onTap,
    this.onToggleCompletion,
    this.onOverflowMenuRequestedAt,
    this.onToggleSelected,
    this.onSnoozeRequested,
  });

  final VoidCallback onTap;

  /// When non-null, the completion checkbox is enabled.
  final ValueChanged<bool?>? onToggleCompletion;

  /// When non-null, an overflow button is shown.
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;

  /// Used only for [TaskTileIntent.selection].
  ///
  /// When provided, the tile can toggle selection via row tap and trailing pill.
  final VoidCallback? onToggleSelected;

  /// Optional secondary action for selection flows.
  ///
  /// When provided, a small action button is shown next to the Add/Added pill.
  ///
  /// This is intentionally generic and callback-driven so `taskly_ui` remains
  /// pure UI and does not perform any business logic.
  final VoidCallback? onSnoozeRequested;
}

/// High-level rendering intent for a Project tile.
sealed class ProjectTileIntent {
  const ProjectTileIntent();

  const factory ProjectTileIntent.standardList() =
      ProjectTileIntentStandardList;

  const factory ProjectTileIntent.agenda() = ProjectTileIntentAgenda;
}

final class ProjectTileIntentStandardList extends ProjectTileIntent {
  const ProjectTileIntentStandardList();
}

final class ProjectTileIntentAgenda extends ProjectTileIntent {
  const ProjectTileIntentAgenda();
}

/// Intent-based actions for a project tile.
@immutable
final class ProjectTileActions {
  const ProjectTileActions({this.onTap, this.onOverflowMenuRequestedAt});

  final VoidCallback? onTap;

  /// When non-null, an overflow button is shown.
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;
}

/// High-level rendering intent for a Value tile.
sealed class ValueTileIntent {
  const ValueTileIntent();

  const factory ValueTileIntent.standardList() = ValueTileIntentStandardList;

  const factory ValueTileIntent.myValuesCardV1() =
      ValueTileIntentMyValuesCardV1;
}

final class ValueTileIntentStandardList extends ValueTileIntent {
  const ValueTileIntentStandardList();
}

final class ValueTileIntentMyValuesCardV1 extends ValueTileIntent {
  const ValueTileIntentMyValuesCardV1();
}

/// Intent-based actions for a value tile.
@immutable
final class ValueTileActions {
  const ValueTileActions({this.onTap, this.onOverflowMenuRequestedAt});

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;
}
