# Someday V2 Full Migration — Phase 3: Presentation (Filters + Ordering)

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Implement filter UI and apply it to V2 renderers, and preserve Someday value ordering.

## Work items
- Implement filter bar widget(s) driven by `SectionFilterSpecV2`.
- Keep filter state ephemeral:
  - stored in widget state (e.g., `StatefulWidget`) or a local controller
  - no settings persistence
- Apply filters before rendering:
  - sort modes (as allowed)
  - entity visibility (tasks/projects/values)
  - value selection filter (if enabled)
- Preserve value group ordering for `hierarchy_value_project_task`:
  - Ensure value headers are ordered by ValuePriority then name
  - Ensure this ordering is independent of `updatedAt` sorting from interleaved service

## Acceptance criteria
- Someday value groups match legacy ordering.
- `flutter analyze` clean.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
