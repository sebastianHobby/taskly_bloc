# Unified Screen Model V2 — Full Cutover Plan (Phase 2: Domain Models + Codecs)

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T06:10:00Z (UTC)

## Objective
Introduce the V2 configuration models (tile variants + layout spec + enrichment plan) as typed domain models with strict JSON decoding, and integrate them into the params codec for the affected templates.

Plan references:
- Decisions: `decisions.md`
- Open issues: `open_issues.md`
- Implementation reference: `implementation_reference.md`

## Implementation guide (Phase 2)

Goal: introduce V2 params/models + strict decoding for new template IDs, without migrating runtime/renderers yet.

### 1) Add new template IDs

- Update: `lib/domain/screens/language/models/section_template_id.dart`
  - Add `task_list_v2`, `project_list_v2`, `value_list_v2`, `interleaved_list_v2`, `agenda_v2`.
- Keep legacy IDs for now; Phase 5 deletes them.

### 2) Add V2 params types (Freezed + JSON)

Create new param classes under `lib/domain/screens/templates/params/` (recommended: keep close to existing params and follow current Freezed conventions):

- `list_section_params_v2.dart` (or similar) defining:
  - `ListSectionSpecV2` (source/config + tiles + layout + enrichmentPlan)
  - `TilePolicyV2`
  - `SectionLayoutSpecV2`
  - `EnrichmentPlanV2`
- `interleaved_list_section_params_v2.dart`
  - `InterleavedListSpecV2` (list of sources + shared tiles/layout/enrichmentPlan)
- `agenda_section_params_v2.dart`
  - `AgendaSpecV2` (timeline-specific inputs + embeds a `ListSectionSpecV2` or reuses its fields)

Notes:
- Reuse `DataConfig` as-is.
- Avoid `Map<String, dynamic>` payloads; keep all enrichment/layout typed.

### 3) Encode the 3 layout modes explicitly

Implement `SectionLayoutSpecV2` as a discriminated union (recommended):

- `flatList(...)`
- `timelineMonthSections(...)`
- `hierarchyValueProjectTask(...)`

Each variant should include only the minimum needed to reproduce current UX. Avoid generic “groupBy field” enums.

### 4) Define typed enrichment plan + results

Add a typed enrichment plan + typed result payloads:

- Plan (`EnrichmentPlanV2`) should be declarative and composable:
  - `valueStats`
  - `openTaskCounts`
  - `agendaTags` (mapping used by `TaskTileVariant.agenda` anywhere)

- Result (`EnrichmentResultV2`) should contain exactly the computed payloads, each typed.

### 5) Wire params decoding for V2 template IDs

- Update: `lib/domain/screens/templates/interpreters/section_template_params_codec.dart`
  - Add decode branches for each new V2 template ID returning the V2 params type.
  - Add encode branches (`toJson`) if the codec supports round-trip.

### 6) Fix Value query honored end-to-end (model/codecs side)

Before touching runtime, ensure the V2 params surface can actually represent a `ValueDataConfig(query: ...)` and that JSON decoding preserves it.

If any existing converter/codec drops the query:
- fix it here (Phase 2) so Phase 3 runtime can rely on it.

### 7) Verify (analysis)

- Run `flutter analyze` and fix all issues introduced in this phase.
- Do not run tests yet (per repo workflow); tests run once at the end in Phase 5.

## Deliverables
- New domain model files for:
  - `ListSectionSpecV2`
  - `InterleavedListSpecV2`
  - `AgendaSpecV2`
  - `SectionLayoutSpecV2` (explicit layout modes only: `flat_list`, `timeline_month_sections`, `hierarchy_value_project_task`)
  - `EnrichmentPlanV2`
  - `EnrichmentResultV2` (typed payloads; no untyped related-entities map)
    - Must support:
      - `ValueStats` (existing behavior)
      - counts (open task counts per project/value)
      - agenda tag pills mapping for `TaskTileVariant.agenda` usage outside `agenda_v2`
  - `TilePolicyV2` (variant selections per entity)
- Add new V2 template IDs and params types:
  - `task_list_v2`, `project_list_v2`, `value_list_v2`, `interleaved_list_v2`, `agenda_v2`
- Updated params decoding in `SectionTemplateParamsCodec` to decode V2 params for the new V2 template IDs.
- Update system screen definitions to compile against the new model surface (conversion may happen in Phase 5, but types + codecs should exist now).

Explicit exclusions:
- Do not reintroduce a `RelatedDataConfig`-style concept in V2.
- Do not add generic `Map<String, List<Object>>` enrichment payloads.
- Do not add new “group by enum” surfaces (e.g. `GroupByField`, `AgendaGrouping`) to V2.

## Implementation notes
- Prefer `freezed` for unions and JSON if already used in the repo.
- Keep params strict (fail fast on missing/unknown required fields), consistent with current design.
- Avoid duplicating existing query models: reuse `TaskQuery`/`ProjectQuery`/`ValueQuery` and/or `DataConfig` where possible.
- Ensure `ValueDataConfig(query: ...)` is honored end-to-end by the section pipeline (this is currently a footgun and must be fixed as part of the cutover).

V2 strictness note:
- We are doing a full cutover with new template IDs and the user will delete persisted custom screen data.
- Therefore, we do not need dual decode or compatibility shims.

## Acceptance criteria
- All new models are wired into decoding and can round-trip through `toJson()`.
- `flutter analyze` is clean.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
