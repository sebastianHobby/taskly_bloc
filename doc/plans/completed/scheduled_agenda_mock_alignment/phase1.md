# Scheduled agenda mock alignment — Phase 1

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-13T00:00:00Z

## Goal
Align Scheduled screen (agenda renderer) with the reference mock by:
- Using entity-level visual variants (Task/Project) for Scheduled card styling.
- Anchoring the timeline dot to the first item in each date group.
- Refining the condensed in-progress (“ongoing”) item to match mock composition.

## Scope
- Presentation-only changes.
- No changes to domain models, unified screen specs, or interpreters.

## Plan
1. Add `agendaCard` visual variants to `TaskView` and `ProjectView`.
2. Update `AgendaSectionRenderer` to render agenda items using these variants.
3. Refactor timeline rendering to position the group dot based on the first item’s measured offset.
4. Refine the in-progress card layout (badge placement + end-day hint).

## AI instructions
- Run `flutter analyze` for this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
