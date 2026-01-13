# Someday V2 Full Migration — Phase 4: Screen Cutover

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Switch the system Someday screen definition to V2.

## Work items
- Update system screen definition for Someday:
  - Use `SectionTemplateId.interleavedListV2`
  - Provide sources:
    - Tasks: incomplete + startDate null + deadlineDate null (no projectId filter)
    - Projects: incomplete + startDate null + deadlineDate null
    - Values: include if needed for stable value ordering and presence
  - Use layout `hierarchy_value_project_task` with `singleInboxGroupForNoProjectTasks: true`
- Ensure the Inbox group appears and contains only no-project + no-date tasks.

## Acceptance criteria
- Someday runs on V2 path with the intended grouping.
- `flutter analyze` clean.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
