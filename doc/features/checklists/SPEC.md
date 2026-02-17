# Checklists Spec

## Scope

Checklist model for tasks and routines, including authoring, scoped completion state, and completion snapshot metrics.

## Core rules

- Checklist is checklist-only model (not subtasks).
- Parent rows stay parent-only on feed surfaces.
- Incomplete checklists route users into checklist flow before parent complete/log when enabled by settings.
- State scoping:
  - Task: occurrence date key.
  - Routine: period window key.

## Metrics contract

At parent completion/log with checklist:
- `checked_items`
- `total_items`
- `completion_ratio`
- `completed_with_all_items`

## Testing minimums

- Scoped key correctness.
- Parent completion behavior with partial and full checklist states.
- Event payload correctness for metrics snapshots.
