# Phase 03 — Unify My Day + Someday primary section UI

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal
Make My Day “look like Someday” by reusing the same Value → Project → Task hierarchy/list primary section, while keeping My Day allocation semantics.

## Design constraints
- UI alignment: same renderer/layout path for both screens.
- Semantics preserved:
  - My Day membership + stable ordering comes from allocation snapshot.
  - My Day gating (focus-mode required) stays.
  - Allocation alerts/check-in summary headers stay.
- Someday semantics remain query-driven (e.g. “no dates” inbox logic).

## Work items
1. Update system screen specs to align primary section template usage:
   - Someday continues to use the hierarchy/list section params.
   - My Day switches primary section to the same hierarchy/list template.
2. Ensure My Day’s underlying data source is allocation-driven:
   - Produce `items` based on snapshot membership (tasks + required related entities for hierarchy rendering).
   - Request the new allocation enrichment item(s) to carry ordering/grouping hints.
3. Verify My Day-specific states still exist:
   - focus-mode gate page behavior
   - allocation alerts header
   - value setup gateway behavior (if still required; decide whether it becomes a gate vs a section empty state)

## Acceptance criteria
- Someday and My Day share the same primary section renderer/layout.
- My Day’s set and order of tasks matches allocation snapshot expectations.
- No allocation UI leaks into Someday (because Someday does not request allocation enrichment).
- Clean `flutter analyze`.

## Risks / notes
- Hydration: hierarchy renderer may expect values/projects present; ensure My Day pipeline provides enough entities without reintroducing heavy query coupling.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase; update docs if this phase changes architecture.
- Run `flutter analyze` during this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of this phase.
