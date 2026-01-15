# My Day / Someday — Unify UI with snapshot allocation enrichment (V2)

Implementation date (UTC): 2026-01-14T00:30:00Z

## What shipped
- My Day and Someday share the same Value → Project → Task primary section renderer path (`hierarchyValueProjectTaskV2`).
- Allocation semantics for My Day are preserved via snapshot-backed V2 enrichment (`allocationMembership`) that exposes:
  - `isAllocatedByTaskId`
  - `allocationRankByTaskId`
  - `qualifyingValueIdByTaskId`
- V2 enrichment is the only enrichment mechanism; enrichment computation is centralized in `SectionDataService._computeEnrichmentV2`.
- My Day gate criteria is unified: the gate is active when no focus mode is configured OR no values exist, and the Focus Setup wizard dynamically includes only missing steps.
- Legacy allocation primary section module wiring is removed (hard cutover).

## Verification
- `flutter analyze`: clean (as of implementation time).
- Tests: assumed passing per implementation note.

## Known issues / follow-ups
- Consider adding a focused unit test around allocation membership enrichment computation in `SectionDataService` if/when a test harness is added for enrichment paths.
