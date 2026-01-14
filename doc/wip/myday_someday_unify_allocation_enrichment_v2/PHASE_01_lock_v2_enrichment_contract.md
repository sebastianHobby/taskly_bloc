# Phase 01 — Lock V2 enrichment contract

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal
Make V2 enrichment the only supported enrichment mechanism end-to-end, and ensure the repo is in a stable baseline state for adding new enrichment items.

## Scope
- Confirm V1 enrichment is removed (already expected/decided).
- Ensure all list-style V2 sections use a single, consistent enrichment request/response shape.
- Ensure there is a single computation entrypoint for V2 enrichment.

## Non-goals
- Implement allocation membership enrichment (Phase 02).
- Change screen compositions (My Day/Someday) (Phase 03).

## Work items
1. Identify all current V2 enrichment request sites:
   - `EnrichmentPlanV2` usage in section params and system screen specs.
2. Identify where V2 enrichment is computed and attached:
   - `SectionDataService._computeEnrichmentV2(plan, items)`
   - Ensure all relevant section watch paths call it (no forks).
3. Verify `SectionDataResult.dataV2(items, enrichment: EnrichmentResultV2?)` is the only list-style V2 result shape used for enrichment.
4. If any duplicate/ad-hoc enrichment exists, consolidate into the single `_computeEnrichmentV2` path.
5. Ensure Freezed/JSON generated code is up to date when models change.

## Acceptance criteria
- No references to V1 enrichment types remain (`EnrichmentConfig` / `EnrichmentResult` non-V2).
- V2 list-style sections consistently use `SectionDataResult.dataV2(..., enrichment: EnrichmentResultV2?)`.
- Only one V2 enrichment compute entrypoint exists and is used.
- `flutter analyze` is clean for this phase.

## Risks / notes
- Keep this phase “mechanical”: avoid behavior changes beyond standardizing the enrichment contract.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase; update docs if this phase changes architecture.
- Run `flutter analyze` during this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of this phase.
