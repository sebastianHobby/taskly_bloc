# Phase 02 — Add snapshot allocation enrichment (global allocated state)

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal
Add a V2 enrichment item that exposes allocation membership (and optionally ordering/grouping hints) as global, snapshot-backed state keyed by `taskId`.

## Decision recap (current)
- `isAllocated` is treated as **global state**, derived from the **latest allocation snapshot for the current UTC day**.
- Not all screens need to render any UI for allocation state; it is opt-in via enrichment requests.
- Pinned is already global (`Task.isPinned`) and should remain presentation-opt-in.

## Proposed API shape
- Extend `EnrichmentPlanItemV2` (in `list_section_params_v2.dart`) with something like `allocationMembership()`.
- Extend `EnrichmentResultV2` with snapshot-backed maps keyed by taskId:
  - Minimum: `Map<String, bool> isAllocatedByTaskId`
  - Recommended: `Map<String, int> allocationRankByTaskId` and/or `Map<String, String> qualifyingValueIdByTaskId` for stable ordering + Value grouping.

## Work items
1. Locate the best access point for “latest snapshot for current UTC day”:
   - Prefer an existing service/contract (e.g. `AllocationSnapshotRepositoryContract` used by orchestrator).
2. Implement enrichment computation in `SectionDataService._computeEnrichmentV2(...)`:
   - Gather task IDs from `items.whereType<ScreenItemTask>()`.
   - Load latest snapshot.
   - Join to produce the requested maps.
   - Ensure no work happens unless the plan includes the new enrichment item.
3. Add unit tests if there is an existing test pattern for `SectionDataService` enrichment computation.

## Acceptance criteria
- New enrichment plan item and result fields are Freezed/JSON serializable.
- `SectionDataService._computeEnrichmentV2(...)` only loads snapshot when requested.
- Clean `flutter analyze`.

## Risks / notes
- Snapshot lookup must be UTC-day consistent with allocation subsystem.
- Be careful not to create N+1 DB reads; do a single snapshot read and map join.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase; update docs if this phase changes architecture.
- Run `flutter analyze` during this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of this phase.
