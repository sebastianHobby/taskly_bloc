import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_type.dart';

part 'problem_definition.freezed.dart';
part 'problem_definition.g.dart';

/// Severity level of a problem
enum ProblemSeverity {
  /// Low severity - informational, can be ignored
  @JsonValue('low')
  low,

  /// Medium severity - should be addressed soon
  @JsonValue('medium')
  medium,

  /// High severity - needs immediate attention
  @JsonValue('high')
  high,
}

/// Definition of what a problem type means and how it can be resolved.
///
/// This is a static configuration model that describes problem types.
/// It's used to render problem cards with appropriate actions.
@freezed
abstract class ProblemDefinition with _$ProblemDefinition {
  const factory ProblemDefinition({
    /// The problem type this definition describes
    required ProblemType type,

    /// Human-readable title for the problem
    required String title,

    /// Longer description explaining the problem
    required String description,

    /// Severity level for visual indication
    required ProblemSeverity severity,

    /// Entity types this problem applies to
    required List<EntityType> applicableEntityTypes,

    /// Available quick-fix actions for this problem
    required List<ProblemAction> availableActions,

    /// Icon name (Material Icons) for the problem card
    String? iconName,
  }) = _ProblemDefinition;

  const ProblemDefinition._();

  factory ProblemDefinition.fromJson(Map<String, dynamic> json) =>
      _$ProblemDefinitionFromJson(json);

  /// Get the predefined definition for a problem type
  static ProblemDefinition forType(ProblemType type) {
    return _definitions[type]!;
  }

  /// All predefined problem definitions
  static final Map<ProblemType, ProblemDefinition> _definitions = {
    ProblemType.taskOverdue: const ProblemDefinition(
      type: ProblemType.taskOverdue,
      title: 'Overdue Task',
      description: 'This task is past its deadline and needs attention.',
      severity: ProblemSeverity.high,
      applicableEntityTypes: [EntityType.task],
      availableActions: [
        ProblemAction.rescheduleToday(),
        ProblemAction.rescheduleTomorrow(),
        ProblemAction.rescheduleInDays(days: 7),
        ProblemAction.pickDate(),
        ProblemAction.clearDeadline(),
        ProblemAction.lowerPriority(),
        ProblemAction.removePriority(),
      ],
      iconName: 'schedule',
    ),
    ProblemType.taskStale: const ProblemDefinition(
      type: ProblemType.taskStale,
      title: 'Stale Item',
      description:
          "This item hasn't been updated in a while and may need review.",
      severity: ProblemSeverity.low,
      applicableEntityTypes: [EntityType.task, EntityType.project],
      availableActions: [
        ProblemAction.rescheduleToday(),
        ProblemAction.pickDate(),
        ProblemAction.clearDeadline(),
      ],
      iconName: 'history',
    ),
    ProblemType.taskOrphan: const ProblemDefinition(
      type: ProblemType.taskOrphan,
      title: 'Unassigned Task',
      description:
          'This task has no value assigned and is excluded from Focus allocation.',
      severity: ProblemSeverity.medium,
      applicableEntityTypes: [EntityType.task],
      availableActions: [
        ProblemAction.pickValue(),
      ],
      iconName: 'label_off',
    ),
    ProblemType.projectIdle: const ProblemDefinition(
      type: ProblemType.projectIdle,
      title: 'Idle Project',
      description: 'This project has no actionable tasks assigned to it.',
      severity: ProblemSeverity.medium,
      applicableEntityTypes: [EntityType.project, EntityType.value],
      availableActions: [
        // Action to add task would be handled at UI level
      ],
      iconName: 'playlist_remove',
    ),
    ProblemType.allocationUnbalanced: const ProblemDefinition(
      type: ProblemType.allocationUnbalanced,
      title: 'Unbalanced Allocation',
      description:
          'Your task allocation is weighted heavily toward some values.',
      severity: ProblemSeverity.low,
      applicableEntityTypes: [EntityType.value],
      availableActions: [
        ProblemAction.pickValue(),
      ],
      iconName: 'balance',
    ),
    ProblemType.journalOverdue: const ProblemDefinition(
      type: ProblemType.journalOverdue,
      title: 'Journal Overdue',
      description:
          "You haven't journaled recently. Regular journaling helps track your wellbeing.",
      severity: ProblemSeverity.medium,
      applicableEntityTypes: [EntityType.journal],
      availableActions: [
        // Action to create journal entry would be handled at UI level
      ],
      iconName: 'edit_note',
    ),
    ProblemType.trackerMissing: const ProblemDefinition(
      type: ProblemType.trackerMissing,
      title: 'Tracker Not Filled',
      description:
          "Today's tracker hasn't been filled. Consistent tracking improves insights.",
      severity: ProblemSeverity.low,
      applicableEntityTypes: [EntityType.tracker],
      availableActions: [
        // Action to fill tracker would be handled at UI level
      ],
      iconName: 'checklist',
    ),
  };

  /// Get all problem definitions
  static List<ProblemDefinition> get all => _definitions.values.toList();
}
