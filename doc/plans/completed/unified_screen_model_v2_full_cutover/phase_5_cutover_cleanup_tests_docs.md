# Unified Screen Model V2 — Full Cutover Plan (Phase 5: Cutover + Cleanup + Tests + Docs)

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T06:10:00Z (UTC)

## Objective
Finish the full cutover: update all screen definitions to V2 params, delete legacy models/codepaths that are superseded, and validate with analysis + tests. Update architecture docs if responsibilities or config surface changes.

Plan references:
- Decisions: `decisions.md`
- Open issues: `open_issues.md`
- Implementation reference: `implementation_reference.md`

## Implementation guide (Phase 5)

Goal: switch all shipped screens to `*_v2`, delete legacy codepaths, then validate once at the end.

### 1) Convert system screens + generated detail screens

- Update: `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`
  - Replace legacy template IDs with V2 IDs.
  - Replace legacy params JSON with V2 params JSON.

- Update generated detail screen builders (`forProject`, `forValue`) to use V2 IDs/params.
  - Ensure they request any required enrichment via `EnrichmentPlanV2`.

### 2) Delete legacy templates + params + interpreters

After all callsites are gone:

- Remove legacy list/agenda template ID constants.
- Remove legacy params models:
  - `DataListSectionParams`
  - `AgendaSectionParams`
  - `InterleavedListSectionParams`
  - Any legacy display/enrichment config types no longer used for screens

### 3) Remove related-data sidecar plumbing (OI-001)

Delete the following once legacy templates are removed:

- `lib/domain/screens/language/models/related_data_config.dart`
- `relatedData` fields and decoding
- `SectionDataService` related-data fetch plumbing
- `SectionDataResult.data.relatedEntities` and any helper getters that depend on it

### 4) Remove `showTitlePrefixTags` flag

- Delete the field from params + any usage in renderers.
- Ensure tags still appear where desired via `TaskTileVariant.agenda` + typed derived mapping.

### 5) Update architecture docs

- Update: `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`
  - add the new `*_v2` templates to the template catalog section
  - describe the new config surface: layout modes (3) + typed enrichment
  - explicitly state that related-data sidecar no longer exists

### 6) Validate (strict order)

1) Run `flutter analyze` and fix **all** issues.
2) Run tests **once** via recorded runner: VS Code task `flutter_test_record`.

### 7) Plan completion workflow

After implementation is complete and validated:
- Move plan folder to `doc/plans/completed/unified_screen_model_v2_full_cutover/`.
- Add a summary doc including implementation date (UTC), what shipped, and follow-ups.

## Work items
- Convert all system screens in `SystemScreenDefinitions` to V2 template IDs + V2 params.
- Convert generated detail screens (`forProject`, `forValue`) to V2 template IDs + V2 params.
- Delete superseded legacy code:
  - Old params models and codecs that are no longer referenced.
  - Legacy config types replaced by V2 (only after references are gone).
  - Remove related-data sidecar plumbing entirely (OI-001): `RelatedDataConfig`, `relatedEntities`, and any fetch paths.
  - Remove legacy grouping config surfaces that are no longer used after V2 cutover.
- Run validation:
  - `flutter analyze` and fix all issues.
  - Run tests using task `flutter_test_record`.
- Update documentation:
  - Update `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md` to describe the new config surface and migration implications.

Cutover constraints:
- No backwards-compat required for persisted custom screen params (user will delete user data). Therefore V2 can be strict and legacy templates can be deleted once system screens are cut over.

## Acceptance criteria
- No legacy model/codepath remains for list/agenda configuration once V2 fully adopted.
- `flutter analyze` clean.
- Tests pass via recorded runner.

## Plan completion workflow
When Phases 1–5 are implemented:
- Move this plan folder to `doc/plans/completed/unified_screen_model_v2_full_cutover/`.
- Add a summary document with implementation date (UTC), what shipped, and known follow-ups.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
