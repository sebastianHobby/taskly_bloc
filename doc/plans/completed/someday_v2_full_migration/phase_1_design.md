# Someday V2 Full Migration — Phase 1: Design

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Define the exact V2 behavior for the Someday screen and the reusable filter spec.

## Decisions (locked for this plan)
- Someday migrates to V2 using `interleaved_list_v2` + `hierarchy_value_project_task`.
- Inbox stays inside the hierarchy (single global inbox group).
- Inbox group contains only tasks with `projectId == null` AND no dates (`startDate == null` AND `deadlineDate == null`).
- Value group ordering must be preserved: value priority then name.
- Per-screen filters are ephemeral (no persistence).
- Legacy Someday renderer/interpreter are deleted after cutover.

## Design deliverables
- `SectionFilterSpecV2` JSON shape (what toggles exist; what they apply to).
- Where filter state lives (presentation-only; per section instance).
- How value ordering is preserved in V2 hierarchy (renderer-level sorting vs upstream ordering contract).

## Open questions
- None.

## UX defaults (Someday)
- `pinnedValueHeaders: true`
- `pinnedProjectHeaders: false`
- Inbox header uses the same pinning behavior as value headers.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
