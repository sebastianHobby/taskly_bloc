# Phase 7A: Workflow Model Update

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Update `WorkflowStep` to use `Section` for content definition.

**Decisions Implemented**: DR-008 (WorkflowStep uses Section)

---

## Prerequisites

- Phase 2A complete (Section model exists)
- Existing WorkflowStep model exists

---

## Task 1: Locate Existing WorkflowStep

Search for the existing implementation:

```bash
# Find the file (for reference)
grep -r "WorkflowStep" lib/
```

Expected location: `lib/domain/models/workflow/workflow_step.dart` or similar.

---

## Task 2: Update WorkflowStep Model

**File**: `lib/domain/models/workflow/workflow_step.dart`

Update to use Section:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

part 'workflow_step.freezed.dart';
part 'workflow_step.g.dart';

/// A step in a workflow (DR-008: uses Section for content)
@freezed
class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    required String id,
    required String name,
    /// Position in workflow sequence
    required int order,
    /// Content sections for this step (DR-008)
    required List<Section> sections,
    /// Support blocks specific to this step
    @Default([]) List<SupportBlock> supportBlocks,
    /// Step description
    String? description,
    /// Step icon
    String? icon,
    /// Triggers for step transitions
    @Default([]) List<TriggerConfig> triggers,
    /// Whether step is required before moving to next
    @Default(true) bool isRequired,
    /// Estimated duration in minutes
    int? estimatedMinutes,
  }) = _WorkflowStep;

  const WorkflowStep._();

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);
}
```

---

## Task 3: Update WorkflowDefinition (if exists)

**File**: `lib/domain/models/workflow/workflow_definition.dart`

Ensure WorkflowDefinition uses updated WorkflowStep:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

part 'workflow_definition.freezed.dart';
part 'workflow_definition.g.dart';

/// A workflow definition (template)
@freezed
class WorkflowDefinition with _$WorkflowDefinition {
  const factory WorkflowDefinition({
    required String id,
    required String name,
    required List<WorkflowStep> steps,
    /// Support blocks shown throughout workflow (e.g., progress)
    @Default([]) List<SupportBlock> globalSupportBlocks,
    String? description,
    String? icon,
    @Default(false) bool isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WorkflowDefinition;

  const WorkflowDefinition._();

  /// Get step by index
  WorkflowStep? getStep(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }

  /// Get step by ID
  WorkflowStep? getStepById(String stepId) {
    return steps.where((s) => s.id == stepId).firstOrNull;
  }

  /// Total number of steps
  int get totalSteps => steps.length;

  factory WorkflowDefinition.fromJson(Map<String, dynamic> json) =>
      _$WorkflowDefinitionFromJson(json);
}
```

---

## Task 4: Update WorkflowRun (if exists)

**File**: `lib/domain/models/workflow/workflow_run.dart`

Update the run model to work with new step structure:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';

part 'workflow_run.freezed.dart';
part 'workflow_run.g.dart';

/// An active instance of a workflow
@freezed
class WorkflowRun with _$WorkflowRun {
  const factory WorkflowRun({
    required String id,
    required String workflowDefinitionId,
    required int currentStepIndex,
    /// Completed step IDs
    @Default([]) List<String> completedStepIds,
    /// Step-specific data storage
    @Default({}) Map<String, Map<String, dynamic>> stepData,
    /// Run status
    @Default(WorkflowRunStatus.inProgress) WorkflowRunStatus status,
    /// Associated entity (if workflow is attached to a project, etc.)
    String? entityId,
    String? entityType,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _WorkflowRun;

  const WorkflowRun._();

  /// Check if a step is completed
  bool isStepCompleted(String stepId) => completedStepIds.contains(stepId);

  /// Progress percentage (0.0 to 1.0)
  double progressPercent(WorkflowDefinition definition) {
    if (definition.totalSteps == 0) return 0.0;
    return completedStepIds.length / definition.totalSteps;
  }

  factory WorkflowRun.fromJson(Map<String, dynamic> json) =>
      _$WorkflowRunFromJson(json);
}

enum WorkflowRunStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('paused')
  paused,
  @JsonValue('cancelled')
  cancelled,
}
```

---

## Task 5: Create Example Workflow Definition

For reference, here's how a workflow with sections looks:

```dart
// Example: Weekly Review Workflow
final weeklyReviewWorkflow = WorkflowDefinition(
  id: 'weekly-review',
  name: 'Weekly Review',
  description: 'Review your week and plan ahead',
  isSystem: true,
  globalSupportBlocks: [
    const SupportBlock.workflowProgress(),
  ],
  steps: [
    WorkflowStep(
      id: 'review-inbox',
      name: 'Process Inbox',
      order: 0,
      description: 'Clear your inbox to zero',
      sections: [
        Section.data(
          config: DataConfig.task(
            query: TaskQuery.inbox(),
          ),
          title: 'Inbox Items',
        ),
      ],
      supportBlocks: [
        const SupportBlock.stats(stats: [
          StatConfig(label: 'Items', metricId: 'inbox_count'),
        ]),
      ],
    ),
    WorkflowStep(
      id: 'review-projects',
      name: 'Review Projects',
      order: 1,
      description: 'Check each active project',
      sections: [
        Section.data(
          config: DataConfig.project(
            query: ProjectQuery.active(),
          ),
          relatedData: [
            const RelatedDataConfig.tasks(),
          ],
          title: 'Active Projects',
        ),
      ],
    ),
    WorkflowStep(
      id: 'plan-week',
      name: 'Plan Next Week',
      order: 2,
      description: 'Set your focus for next week',
      sections: [
        const Section.allocation(
          maxTasks: 7,
          title: "Next Week's Focus",
        ),
      ],
    ),
  ],
);
```

---

## Task 6: Update Workflow Barrel Export

**File**: `lib/domain/models/workflow/workflow.dart`

Ensure all exports are correct:

```dart
export 'workflow_definition.dart';
export 'workflow_step.dart';
export 'workflow_run.dart';
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `workflow_step.freezed.dart` regenerated
- [ ] `workflow_step.g.dart` regenerated
- [ ] `WorkflowStep` uses `List<Section>` for content
- [ ] `WorkflowDefinition` compiles correctly
- [ ] `WorkflowRun` compiles correctly

---

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/workflow/workflow_step.dart` | Use Section for content |
| `lib/domain/models/workflow/workflow_definition.dart` | Update if needed |
| `lib/domain/models/workflow/workflow_run.dart` | Update if needed |
| `lib/domain/models/workflow/workflow.dart` | Update exports |

---

## Next Phase

Proceed to **Phase 7B: Workflow Bloc Integration** after validation passes.
