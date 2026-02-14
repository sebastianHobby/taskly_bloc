# Spec: Checklists for Tasks + Routines V1

Created at: 2026-02-14
Status: Proposed
Owner: TBD

## Summary

Introduce checklist support for both Tasks and Routines using a checklist-only
model (not subtasks). Keep feed surfaces (My Day, Scheduled, Projects, etc.)
parent-only, with checklist interaction via a dedicated bottom sheet.

Server-side Supabase and PowerSync updates are already completed. This spec
defines the remaining required app/documentation changes and locks UX + data
contracts for implementation.

## Goals

- Add lightweight execution support for tasks/routines without subtask
  complexity.
- Preserve list readability by avoiding child row expansion in feed screens.
- Support strict default behavior: parent complete/log tap opens checklist sheet
  first when checklist is incomplete.
- Support occurrence/window-scoped checklist state for recurring behavior.
- Enable routine analytics and partial completion insights.

## Non-goals

- No subtask hierarchy in this phase.
- No checklist row rendering directly inside My Day/Scheduled feed rows.
- No silent auto-complete of parent on last item check (default remains prompt).

## Product decisions (locked from design review)

- Checklist-only model for Tasks + Routines.
- Parent-only rows in My Day/Scheduled/Projects.
- If checklist exists and is incomplete, parent primary action opens checklist
  sheet first by default.
- Checklist sheet actions:
  - `Complete parent now` (task) / `Log routine now` (routine).
  - `Check all & complete`.
- When last checklist item is checked, show prompt:
  - `All steps done. Complete now?` (`Complete` / `Not now`).
- Do not silently auto-complete by default.
- If no checklist exists, primary action remains immediate complete/log.

## UX interaction contract

## Row-level affordances (all parent feeds)

- Parent row keeps existing primary action target and iconography.
- Show checklist progress indicator only when checklist exists (example: `2/5`).
- Progress affordance opens checklist bottom sheet.
- Child checklist items are not rendered inline as feed rows.

## Primary action behavior

- No checklist: complete/log immediately.
- Checklist exists + incomplete:
  - default behavior: open checklist sheet first.
- Checklist exists + all checked:
  - complete/log immediately.

## Checklist bottom sheet

- Header:
  - parent title
  - checklist progress
- Body:
  - checklist items with large tap targets
  - reorder/edit (if enabled for current surface)
- Footer actions:
  - task: `Complete parent now`
  - routine: `Log routine now`
  - `Check all & complete`
- On last item checked: show completion prompt, never silent auto-complete by
  default.

## Settings

Add settings fields in `user_profiles.settings_overrides`:

- `checklistTapOpensSheetFirst` (default `true`)
- `autoCompleteParentWhenChecklistDone` (default `false`, reserved for later)

## Data model (canonical)

## Supabase tables

Already created server-side:

- `task_checklist_items`
  - checklist definitions for tasks
  - includes `task_id`, `title`, `sort_index`
- `task_checklist_item_state`
  - occurrence-aware task checklist state
  - includes `occurrence_date` (`NULL` for non-recurring baseline)
- `routine_checklist_items`
  - checklist definitions for routines
  - includes `routine_id`, `title`, `sort_index`
- `routine_checklist_item_state`
  - window-aware routine checklist state
  - includes `period_type` (`day|week|month`) and `window_key` (date)
- `checklist_events`
  - append-only checklist analytics/event history
  - includes parent type/id, scope, event type, metrics json

Constraints and policies:

- Ownership via `user_id` and RLS owner policies.
- Parent ownership validation on insert/update for task/routine-linked rows.
- Uniqueness for item state scoping:
  - task: `(task_id, checklist_item_id, occurrence_date)` with nulls-not-distinct
  - routine: `(routine_id, checklist_item_id, period_type, window_key)`
- `set_updated_at()` trigger on mutable checklist tables.

## PowerSync sync rules

Already added server-side, aligned with existing bucket strategy:

- `user_core`:
  - `task_checklist_items`
  - `routine_checklist_items`
  - `task_checklist_item_state`
  - `routine_checklist_item_state`
- `user_history`:
  - `checklist_events`

## Domain contract expectations

Checklist operations remain BLoC-driven and domain-mediated:

- Widgets emit intents only.
- BLoCs orchestrate writes through domain services/contracts.
- No widget->repo direct calls.

Required contract surfaces:

- task checklist:
  - watch items
  - add/rename/reorder/delete
  - watch occurrence-scoped state
  - set checked/unchecked
- routine checklist:
  - same operations with window-scoped state
- completion/log write facade:
  - complete/log with checklist snapshot semantics
  - optional force-complete/log path when incomplete

Scope key derivation must stay outside UI:

- task recurrence scope: domain-derived occurrence date key.
- routine scope: domain-derived window key using period semantics.

## Completion semantics

## Tasks

- Non-recurring: checklist state uses baseline (`occurrence_date = NULL`).
- Recurring: checklist state is occurrence-scoped by date key.
- Parent completion allowed with partial checklist completion.

## Routines

- Checklist state is scoped to routine window:
  - day: specific date
  - week: canonical week start date
  - month: first day of month
- Routine checklist resets naturally across windows via scoped state.
- Parent log allowed with partial checklist completion.

## Analytics semantics

Support metrics (derived via `checklist_events` and/or snapshots):

- completed/logged with all checklist items
- completion ratio at parent completion (`checked/total`)
- most skipped checklist items
- routine adherence quality with step completion context

At parent complete/log, persist snapshot metrics to event payload:

- `checked_items`
- `total_items`
- `completion_ratio`
- `completed_with_all_items`

## Required app changes

## Data layer

- Add checklist tables to local PowerSync schema:
  - `packages/taskly_data/lib/src/infrastructure/powersync/schema.dart`
- Add Drift table mappings and queries:
  - `packages/taskly_data/lib/src/infrastructure/drift/drift_database.dart`
  - regenerate `drift_database.g.dart`
- Add mappers + repository implementations for checklist contracts.
- Ensure local writes follow PowerSync view-safe patterns (no local UPSERT to
  PowerSync-backed views).

## Domain layer

- Add checklist entities/contracts/services (task + routine).
- Add scope-key helpers for recurrence/window alignment.
- Add parent complete/log orchestration with checklist snapshot metrics.

## Presentation layer

- Add checklist state to scheduled/my day row models.
- Add progress affordance and strict default primary action routing.
- Implement checklist bottom sheet + prompt flow.
- Ensure routine verbs use `Log` language and task verbs use `Complete`.

## Settings integration

- Add settings read/write support for checklist flags.
- Default behavior uses `checklistTapOpensSheetFirst = true`.

## Testing requirements

## Domain tests

- occurrence/window key derivation correctness
- partial vs all-checked completion semantics
- completion/log with checklist snapshot metrics

## Data tests

- repository CRUD for checklist definitions/state
- uniqueness behavior by scope
- event writes for checked/unchecked and parent completion/log

## Presentation tests

- feed row behavior by checklist state
- strict default: tap opens sheet when incomplete
- no-checklist immediate complete/log
- all-checked immediate complete/log
- last-item checked prompt behavior

## Regression coverage

- Scheduled + My Day + Project list task/routine row interactions
- recurring task/routine behavior across date/window boundaries
- existing non-checklist tasks/routines unaffected

## Acceptance criteria

- Users can create/manage checklist items for tasks and routines.
- Feed screens remain parent-only (no checklist row expansion).
- Incomplete checklist blocks immediate parent complete/log by default and opens
  checklist sheet first.
- Parent can still be completed/logged with partial checklist by explicit
  action.
- Routine checklist state does not leak across windows.
- Recurring task checklist state does not leak across occurrences.
- Checklist progress is visible in parent rows where applicable.
- Checklist events are persisted for analytics.

## Rollout plan

- Phase 1:
  - data/domain contracts + repositories + settings plumbed
  - checklist bottom sheet available in Scheduled and My Day
- Phase 2:
  - expand checklist affordance consistently to remaining task/routine lists
  - add analytics dashboards/insights based on checklist events

## Documentation updates required

- Update `doc/product/SCREEN_PURPOSE_CONCEPTS.md` with checklist interaction
  meaning across parent feed screens.
- Update routine/task concept docs if checklist wording changes core definitions.
- Add architecture deep-dive follow-up if checklist introduces new cross-feature
  write orchestration patterns.

## Confirmed decisions

1. `checklistTapOpensSheetFirst` is hidden/internal at launch and defaults to
   `true`.
2. Checklist items are editable/reorderable directly in the checklist bottom
   sheet on feed screens.
3. Recurrence semantics apply to parent tasks, not checklist item definitions.
   Checklist items are static definitions under a parent; scoped checklist state
   follows the parent occurrence/window model.
4. `checklist_events` is append-only in production (no user update/delete
   policy).
