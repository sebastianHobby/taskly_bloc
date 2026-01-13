# Someday — Consolidated Inbox alignment (mock + requirements)

Created at: 2026-01-13 (UTC)
Last updated at: 2026-01-13 (UTC)

## Context
We want the Someday system screen to match the “Someday – Consolidated Inbox” mock (screen_id: 4fa747223777467ea176fef236fe0289) and the associated requirements:
- Grouping hierarchy + standard cards
- Global filter/sort bar
- FAB create task
- Tap-to-detail

Someday is currently implemented via a **legacy** unified-screen section template (`someday_backlog`) with a bespoke renderer.

Update (2026-01-13): Someday has been migrated off the legacy `someday_backlog` template.
See the completed migration plan: `doc/plans/completed/someday_v2_full_migration/`.

Architecture reference:
- Unified screen model: ../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md

## Goal
Align Someday UI/behavior to the Consolidated Inbox mock while staying consistent with the unified-screen model and minimizing bespoke per-screen UI logic where practical.

## Status

- The legacy `someday_backlog` renderer/template references in this document are historical.
- Any further UI alignment work should target the current V2 unified-screen templates and renderers.

## Work remaining (to align fully to mock)
### A) Top chrome (AppBar)
- Add mock-aligned status chip behavior (multi-value / single-value / no-value states)
- Add inline AppBar search interaction (vs separate search screen)
- Confirm placement/behavior for search + overflow/menu icons

### B) Sticky global filter bar
- Implement pinned/sticky pill bar (likely SliverPersistentHeader or equivalent)
- Ensure it stays visible while scrolling the list
- Match spacing/shape/typography to the mock

### C) “Projects Only” mode semantics (updated requirement)
Current direction: **Projects Only literally shows only projects**.
- No tasks rendered in this mode
- Tapping a project navigates to project details (where tasks can be viewed)
- Remove project subheaders in Projects Only mode

### D) Card variants (Someday-specific look)
Introduce Someday-specific tile variants for:
- Task cards
- Project “header” cards
- (Possibly) value cards or value header treatment

Constraints:
- Keep `_MetaLine` in the Someday cards.
- Prefer expressing variants declaratively via template params (vs hardcoding per-screen widget trees).

### E) Sorting behavior
If the mock removes the explicit “Sort” pill:
- Define a stable default ordering (and document it)
- Ensure ordering is consistent across sessions and predictable

## Design decisions recorded so far
These represent the current direction captured during batching; revisit/confirm before implementation if anything changed.

### Batch 1 — Top chrome
- Direction chosen: align to mock with chip-like status indicator + inline search.
- Open: final chip text rules and icon placement.

### Batch 2 — Filter bar semantics
- Sticky pill bar: YES (pinned)
- Sort pill: REMOVE (use stable default ordering instead)
- Projects Only semantics: change to literal projects-only (navigate to see tasks)

### Batch 3 — Cards/variants
- Direction: introduce explicit Someday tile variants; keep `_MetaLine`.
- Open: exact visual spec per entity type and where variants live (legacy renderer vs V2 params).

## Open questions (need explicit answers)
1) Value dropdown population
- Option A: show all values in the system
- Option B: show only values present in the current (effective) dataset
- Option C: show all values, but visually separate “present” vs “not present”

2) Default ordering (if no “Sort” pill)
- What is the primary order?
  - value priority then value name?
  - project name then task name?
  - task priority then name?
- Tie-breakers must be specified.

3) Status chip text rules
- What should it display for:
  - multi-value selection
  - single value
  - no values / inbox
  - “projects only” mode

4) Where to define Someday variants
- Historical note: a legacy `someday_backlog_renderer.dart` used to exist but Someday has now been migrated off that path.
- Define variants using the standard typed style keys (tile variants) in V2 template params.

## Open question: migrate Someday to V2?

Resolved: Someday has been migrated to V2 (see `doc/plans/completed/someday_v2_full_migration/`).

Why this matters:
- V2 allows tile variants to be expressed declaratively and reused across screens.
- Legacy renderer work may become throwaway if we later migrate.
- Sticky headers / grouping headers may need a V2-capable layout spec or an explicit V2 header variant.

## Next steps

- Re-review the remaining UI alignment items against the current V2 implementation.

### Re-review requirement after V2 migration
Now that V2 migration is complete, re-review:
- All UI decisions listed above
- Any legacy-only implementation shortcuts
- Whether the group header styling and sticky filter bar should be reimplemented via V2 layout/variants

## Acceptance criteria (definition of done)
- Someday matches the Consolidated Inbox mock for:
  - grouping hierarchy
  - sticky global filter bar
  - card visuals (task/project) and group headers
  - tap-to-detail flows
  - FAB create task
- “Projects Only” shows only projects and navigates to project details
- Sorting is stable and documented
- Analyzer clean (`flutter analyze`)
- Tests recorded via `flutter_test_record` at the end of implementation
