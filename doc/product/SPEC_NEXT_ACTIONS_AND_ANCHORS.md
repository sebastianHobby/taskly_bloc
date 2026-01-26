# Spec: Project Next Actions and Project-First Anchors

Created at: 2026-01-26
Status: Draft
Owner: TBD

## Summary

Implement project-first anchors for Suggested picks while keeping value
priorities as the top signal. Add project-scoped next actions (ranked up to 3)
and use them as the first-choice tasks within anchor projects. Next actions are
shown at the top of the project task list and are configurable per project.

## Goals

- Values remain the top signal for allocation.
- Select anchor projects first, then select tasks inside each anchor.
- Allow up to 3 ranked next actions per project.
- Keep start date as a soft "do date" tie-break only (not readiness).
- Preserve safety net behavior for due and start date items.

## Non-goals

- No urgency-first global optimizer.
- No prompts or alerts for missing next actions (handled via review UX).

## Data Model

### Project Next Actions (NA3)

Table: project_next_actions
- project_id (FK -> projects)
- task_id (FK -> tasks)
- rank (1-3)
- created_at
- updated_at

Constraints:
- Enforce uniqueness in app logic:
  - No duplicate task in a project.
  - Ranks are 1..3 with no duplicates.
  - Max 3 next actions per project.

Behavior:
- If a task moves projects, remove any rows where project_id does not match the
  task's current project_id.
- On task delete, cascade remove.

### Optional performance fields

- projects.last_progress_at (UTC) for fast project recency scoring.
- project_anchor_state table (project_id, last_anchored_at) for rotation
  stability (store and update on each anchor selection).

## Allocation Flow (Project-First)

1) Compute value quotas for anchor count.
2) Filter projects:
   - If readiness filter is on, include only projects with actionable tasks
     (incomplete tasks; do not use start date as readiness).
3) Score projects per value:
   - Base weight from value priority.
   - Project deadline proximity (soft boost).
   - Project priority (soft boost).
   - Days since last progress (boost for idle projects).
   - Rotation pressure (if enabled).
4) Select anchors per value quota (cap by anchor count).
5) For each anchor project, select tasks:
   - If next action policy is "require" or "prefer", pick ranked next actions
     first (rank 1-3).
   - If not enough next actions, fill using deterministic rules:
     deadline -> priority -> recency -> name
     start date is a soft tie-break only.
6) Fill free slots (if any) from best remaining tasks across values.

## Next Action UX

### Where users set next actions

- Project detail: "Next actions" list at the top of the task list with drag
  reorder (ranks 1-3).
- Task row action: "Mark as next in this project" with rank chooser.
- Weekly review: "Projects missing next actions" prompt to set 1-3.

### Adding and ranking rules

- Max 3 next actions per project.
- When the list is full, adding a new next action requires replacing an
  existing rank (user chooses which rank to replace).
- When a next action is removed or completed, remaining items are re-ranked
  from 1..n in existing order.

### Recurring tasks

- Next action applies to the next occurrence only.
- On completion, auto-advance to next ranked action or clear if none.

## Settings and Knobs

Recommended knobs and values:
- anchor_count: 1-4
- tasks_per_anchor_min: 1-2
- tasks_per_anchor_max: 2-4
- next_action_policy: off | prefer | require
- rotation_pressure_days: 3 | 7 | 14
- readiness_filter: off | on
- free_slots: 0-3

Settings storage:
- Global allocation settings only (no per-value or per-project overrides).
- Persist in user_profiles.settings_overrides.

## Suggestion Engine Integration Notes

- This replaces the current task-first allocation for Suggested picks.
- Routine selections can optionally reduce value quotas (see routines spec).

## Analytics and Telemetry

Track:
- Anchor selection coverage (value -> project counts).
- Next action usage rate (set, used, completed).
- Project progress recency distribution.

## Edge Cases

- No eligible projects for a value: reassign anchor slot to another value.
- Project has no next actions and policy is "require": fall back to deterministic
  task selection and flag as missing next actions in review UI.
- Task moved to new project: remove old next action entry.
- Projects with zero actionable tasks are never eligible as anchors.

## Open Questions

- None.

## Decisions (Locked)

- Project recency uses projects.last_progress_at (cache updated on task
  completion).

## Implementation Status (2026-01-26)

Completed:
- Attention rule template added: `problem_project_missing_next_actions`.
- Attention engine evaluates missing next actions and is wired via DI.

Remaining:
- Project detail UI: “Next actions” list at top with drag reorder (ranks 1..3).
- BLoC wiring: load next actions stream, reorder event, and `setForProject` updates with `OperationContext`.
- Task UI affordance: “Mark as next action” with rank chooser (where appropriate).
- Weekly review: add attention toggle + section for missing next actions.
- L10n additions for new UI strings and regenerate localizations.

## Prompt for Next AI

You are continuing implementation in `c:\Users\User\FlutterProjects\taskly_bloc`.

Goal: finish SPEC_NEXT_ACTIONS_AND_ANCHORS per latest decisions in chat.

Must-do:
1) Project detail: add a “Next actions” list at top of the task list with drag reorder (ranks 1..3).
2) BLoC: extend `ProjectOverviewBloc` (or equivalent) to include next actions stream and a reorder event using `ProjectNextActionsRepositoryContract.setForProject(...)` with `OperationContext`.
3) Task affordance: add “Mark as next action” with rank chooser; when list is full, replace a chosen rank.
4) Weekly review: add toggle setting (default on) and show missing next actions in maintenance section.
5) L10n: add new strings to `lib/l10n/arb/app_en.arb` + `app_es.arb`; run `flutter gen-l10n`.
6) Run `dart format` and `dart analyze` after changes.

Notes:
- BLoC boundary is strict: widgets must not call repositories directly.
- Shared UI changes in `taskly_ui` require explicit approval.
