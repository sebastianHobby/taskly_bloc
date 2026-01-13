# Unified Screen Model V2 — Open Issues

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T00:00:00Z (UTC)

## OI-001 — Related-data sidecar still exists on `main`

The Phase 1 plan currently assumes `RelatedDataConfig` and `relatedEntities` plumbing has already been removed elsewhere. This is **not true** on the current `main` branch.

Current state:

Implication for V2 cutover:
  - `RelatedDataConfig`
  - `DataListSectionParams.relatedData`
  - `_fetchRelatedData` and related plumbing in `SectionDataService`
  - `SectionDataResult.data.relatedEntities` and any downstream consumers

Recommended resolution:


## OI-002 — Widget tests failing due to missing DI registration (PerformanceLogger)

### Summary
Some existing widget tests are failing because `GetIt` is missing a registration for `PerformanceLogger`.

### Why it matters to this plan
Phase 5 requires a final recorded test run. If the baseline test suite is already red, the V2 cutover work cannot be confidently validated.

### Recommended approach
- Treat this as prerequisite work to the Phase 5 “run recorded tests” step.
- Fix should be minimal and test-focused (register a fake or a lightweight implementation in test setup).
- Do not weaken production DI; keep production registration explicit.

### Notes
- This issue is not necessarily caused by the V2 cutover, but it will block the final verification step if left unresolved.
