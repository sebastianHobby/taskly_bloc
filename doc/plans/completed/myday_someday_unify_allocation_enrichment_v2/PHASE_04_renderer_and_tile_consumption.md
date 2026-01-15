# Phase 04 — Renderer/tile consumption rules for allocation enrichment

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal
Teach the shared hierarchy/list renderer (and/or tile policy) to optionally consume allocation enrichment maps to achieve stable ordering and Value grouping for My Day, while remaining a no-op for sections that do not request those enrichments.

## Work items
1. Identify the renderer entrypoints for hierarchy/list sections:
   - `HierarchyValueProjectTaskRendererV2` / `InterleavedListRendererV2`
2. Implement optional behavior driven by enrichment presence:
   - If `allocationRankByTaskId` exists, order tasks by rank.
   - If `qualifyingValueIdByTaskId` exists, use it to drive Value grouping even if task primary value differs.
   - If neither exists, preserve existing renderer behavior.
3. Keep pinned display opt-in:
   - Pinned is global (`Task.isPinned`), but screens decide whether to show pinned indicators.

## Acceptance criteria
- Renderer behavior remains unchanged for Someday (no allocation enrichment requested).
- My Day ordering/grouping matches allocation snapshot semantics.
- Clean `flutter analyze`.

## Risks / notes
- Avoid mixing semantics: enrichment should not silently override Someday logic unless explicitly present.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase; update docs if this phase changes architecture.
- Run `flutter analyze` during this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of this phase.
