# Phase 03 — Row Content: Tag Pills, Metadata, Ordering

Created at: 2026-01-15T05:07:20Z
Last updated at: 2026-01-15T11:40:16.5322380Z

## Objective
Implement the detailed row requirements for tasks/projects under each Day Card.

## Target files (expected)
- `lib/presentation/entity_views/task_view.dart`
  - Ensure `TaskViewVariant.agendaCard` supports full-text tag pills.
  - Ensure title prefix / icons (recurring, in-focus/allocated) follow prior decisions.
- `lib/presentation/entity_views/project_view.dart` (or equivalent)
  - Ensure project rows can show a progress bar (instead of “open tasks count”).
- `lib/presentation/screens/templates/renderers/agenda_section_renderer.dart`
  - Apply ordering rules within each day.
  - Apply in-progress collapse behavior.

## Mutations funnel (SCH-002A)
If the day card rows expose any interactive mutations (complete, pin/unpin, delete, etc.):

- The row widgets must dispatch those intents via `ScreenActionsBloc`.
- Row widgets must not call repositories/services directly.
- Errors must be surfaced via the standard page/root `BlocListener<ScreenActionsBloc, ScreenActionsState>` -> `SnackBar` pattern.

## Row policy (from decisions)
Tasks:
- Show “value” prominently; show secondary values as count or pills depending on density.
- Show Inbox label when project is null.
- Icons:
  - recurring
  - focus/allocated indicator
- Ordering within a day card:
  - Due today/overdue first
  - Then start-today
  - In-progress: condensed/collapsed section (summary + expand)

Projects:
- Show progress bar based on `completedTaskCount / taskCount`.
- Prefer attention rules to surface “risk” rather than raw counts.

Tag pills (UX-102T(A)):
- Full text: “Due Jan 15”, “Start Jan 20”, etc.
- Only show pills that add information (avoid duplicates vs header).

## Tag pill rules (exact)

### Formatting
- Use `intl` short formats consistent with the screen header:
  - Date: `MMM d` (e.g., “Jan 15”)

### Which pills to show per rendered `AgendaItem`
Inputs available:
- `AgendaItem.tag` for the *current* day card.
- Underlying entity dates:
  - For tasks: `task.startDate`, `task.deadlineDate`
  - For projects: `project.startDate`, `project.deadlineDate`

Rules:
1) Always show a pill for the current day’s tag:
- If tag == due => show “Due <MMM d>”
- If tag == starts => show “Start <MMM d>”
- If tag == inProgress => show “In progress”

2) Show the “other” date pill when present and not redundant:
- If current tag is `due` and entity has `startDate` on a different day => show “Start <MMM d>”
- If current tag is `starts` and entity has `deadlineDate` on a different day => show “Due <MMM d>”
- If both dates fall on the same day => show only one pill (the current tag).

3) Hide pills that repeat the day-card header date:
- If pill date is the same calendar day as the day card’s date:
  - keep it only if it conveys the tag (Due vs Start), otherwise omit duplicates.

## Task row metadata rules (exact)
- Title: task name.
- Project label:
  - If `task.project == null && task.projectId == null` => show “Inbox”.
  - Else show project name (if available in hydrated model).
- Value display:
  - Primary value chip/label if `primaryValueId != null` and value exists.
  - Secondary values:
    - If 1–2: show as pills
    - If >2: show “+N values”

## Project row metadata rules (exact)
- Title: project name.
- Progress:
  - If `taskCount > 0`: show `LinearProgressIndicator(value: completedTaskCount / taskCount)`
  - If `taskCount == 0`: show a subtle “No tasks yet” caption (no progress bar).

## Ordering rules within a day card (exact)
Within each tag section (Due/Starts/In progress):
1) Tasks before projects.
2) Then pinned entities first (`isPinned == true`).
3) Then alphabetic by name.

In-progress section is collapsed by default and only expands within the day card.

## Acceptance criteria
- Tasks/projects match the metadata + ordering rules.
- In-progress collapse works and does not break scrolling performance.
- No analyzer errors introduced.

## AI instructions (strict)
- Review USM boundary rule: widgets do not fetch domain/data.
- Run `flutter analyze` for this phase.
- Fix analyzer issues caused by this phase’s changes by end of phase.

## Completed
Completed at: 2026-01-15T11:40:16.5322380Z

Summary:
- Implemented tag pill display rules and row ordering, and updated task/project agenda-card variants to match the approved metadata behavior.
