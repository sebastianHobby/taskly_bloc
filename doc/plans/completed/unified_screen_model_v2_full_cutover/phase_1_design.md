# Unified Screen Model V2 — Full Cutover Plan (Phase 1: Design)

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T06:10:00Z (UTC)

## Goal
Deliver a full cutover from the current “mixed params + ad-hoc flags” configuration surface to a single, consistent extension surface for section-driven screens:

- **Tile variants**: 2–3 supported looks per entity type (task/project/value) with discoverable, explicit selection.
- **Layout spec**: grouping, headers, separators, collapsing, and list/agenda structure expressed as a first-class model.
- **Enrichment plan**: explicit declaration of derived/related data required to render the chosen tiles/layout.

The end-state removes superseded legacy config models and codepaths, updates all system + generated detail screens, and keeps Agenda/Scheduled scroll semantics correct.

This plan assumes a **full cutover** with **new template IDs** for V2 list-like templates (no runtime compatibility layer).

Plan references:
- Decisions: `decisions.md`
- Open issues: `open_issues.md`
- Implementation reference: `implementation_reference.md`

## Implementation guide (Phase 1)

This phase produces the *final spec* that Phase 2 will implement. No Dart code changes are required in this phase.

### 1) Lock template IDs + migration contract

- Add the V2 IDs to the plan (done) and treat them as the only supported entry points after cutover:
  - `task_list_v2`, `project_list_v2`, `value_list_v2`, `interleaved_list_v2`, `agenda_v2`
- Confirm (and document) that we do **not** support reading legacy custom screen params (user will wipe data).

### 2) Lock the 3 V2 layout modes (no generic enums)

Document the intended behavior in terms of observable UI, not internal enums:

- `flat_list`
  - Optional section title (already exists in current renderers)
  - Item separators are per-list style (divider vs spacing)
- `timeline_month_sections`
  - Must match Scheduled’s current UX: Overdue / This Week / Next Week / Later buckets
  - **Pinned (sticky) headers** for each bucket
  - Per-day groups inside buckets
- `hierarchy_value_project_task`
  - Value groups
  - Nested project groups
  - Tasks rendered inside (project within value)
  - **Pinned (sticky) group headers** at least for Value; optionally for Project

### 3) Lock enrichment responsibilities + “agenda tags anywhere” semantics

- Typed enrichment is computed in domain/runtime (not UI): counts + valueStats + agenda tag mapping.
- Because `TaskTileVariant.agenda` can render outside `agenda_v2`, document the exact meaning of “agenda tag pills”:
  - Inputs required to compute tags: `dateField` + “now”
  - Output: a typed `AgendaTag` per task (or `null` / absent if not applicable)
  - UI contract: `TaskView` (or tile registry) receives a `titlePrefix` widget derived from the tag mapping.

### 4) Deprecation list (explicit removals)

Document all removals that must be completed by Phase 5:

- `AgendaSectionParams.showTitlePrefixTags`
- Legacy list templates: `task_list`, `project_list`, `value_list`, `interleaved_list`
- Legacy agenda template: `agenda`
- Related-data sidecar (OI-001):
  - `RelatedDataConfig`
  - `DataListSectionParams.relatedData`
  - `SectionDataResult.data.relatedEntities`
  - Any related-data fetch plumbing in runtime services

### 5) Verification checklist (design-only)

- The plan docs describe:
  - exactly which template IDs exist post-cutover
  - exactly which layout modes exist (3)
  - exactly which enrichments exist (counts/valueStats/agendaTag mapping)
  - which legacy types must be deleted

## Non-goals
- Re-architecting unrelated subsystems (sync, persistence, attention engine internals).
- Rewriting large feature-specific renderers (statistics, wellbeing, journal) unless needed for the new config surface.
- Building new UI features; this is a configuration/model cutover.

## Scope (what changes)
1) **List-like templates** (highest priority)
- V2 template IDs (new):
  - `task_list_v2`, `project_list_v2`, `value_list_v2`, `interleaved_list_v2`, `agenda_v2`
- Legacy templates remain temporarily during migration, then removed:
  - `task_list`, `project_list`, `value_list`, `interleaved_list`, `agenda`

2) **Screens impacted**
- All system screens in `SystemScreenDefinitions`
- Generated detail screens: `forProject()`, `forValue()`

3) **Removal targets (superseded code)**
- Any legacy flag/config that is replaced by V2 specs (e.g. `AgendaSectionParams.showTitlePrefixTags`).
- Legacy models that become redundant after cutover (e.g. current `DisplayConfig`/`EnrichmentConfig` patterns), but only once no callsites remain.
- Remove the related-data sidecar concept entirely (replacing it with typed enrichment outputs):
  - `RelatedDataConfig`, `DataListSectionParams.relatedData`, `SectionDataResult.data.relatedEntities`, and all supporting services.
- Domain entities may not always include all relationships; V2 may request missing derived data via typed enrichment.

See: `open_issues.md` (OI-001) for the current-state mismatch on `main`.

## Current pain points (why)
- Per-screen or per-template boolean flags encourage “flag creep” and hidden behavior.
- Layout is partially encoded across multiple places (template params + renderer conditionals), making “same data, different layout” hard.
- Enrichment is split between `EnrichmentConfig` and `relatedData`, and is not uniformly discoverable.

## Proposed V2 model (design target)

### A) V2 template family + params shape

We introduce new V2 template IDs and V2 params types.

For list-like templates, introduce a single params model used by multiple templates:

- `ListSectionSpecV2`
- `ListSectionSpecV2`
  - `source`: `DataConfig` (reused as-is, including query models)
  - `tiles`: tile presentation policy (variants per entity)
  - `layout`: list layout spec (grouping, headers, separators, collapsing)
  - `enrichment`: enrichment plan (typed derived data such as stats/counts)

Explicitly excluded from V2:
- No `relatedData` concept and no `relatedEntities: Map<String, List<Object>>`. If something is needed for UI, it must be requested as typed enrichment.

Template IDs still exist (we keep the interpreter/renderer registry model), but multiple templates may decode to the same `ListSectionSpecV2` and then apply only template-specific constraints.

### B) Tile variants (2–3 per entity)
Keep/extend the existing enums:
- `TaskTileVariant` (e.g. `listTile`, `compact`, `agenda`)
- `ProjectTileVariant`
- `ValueTileVariant`

Key change: move special-case chrome such as Scheduled’s date tag pills from boolean flags into the agenda tile variant.

- **Decision:** date tag pills are part of `TaskTileVariant.agenda`.
- **Scope:** date tag pills must be available wherever `TaskTileVariant.agenda` is used (not agenda-only).
- This removes `AgendaSectionParams.showTitlePrefixTags` entirely.

### C) Layout spec (real-world modes only)

Avoid generic enum surfaces that are not actually wired today (e.g. `GroupByField`, `AgendaGrouping`).

Instead, V2 layout is expressed as a small set of explicit modes that match current UX patterns:

- `flat_list`
  - Simple list with optional item separators and an optional section title.
- `timeline_month_sections`
  - Scheduled-style timeline broken into month buckets (Overdue / This Week / Next Week / Later) with per-day groups.
  - Requires **sticky section headers** (pinned).
- `hierarchy_value_project_task`
  - Value → Project → Task hierarchy (replaces current `valueHierarchy` related-data sidecar).
  - Requires **sticky group headers** for good UX on long lists.

### D) Enrichment plan

A typed plan that declares required derived/related data:
- value stats (existing)
- counts (e.g. open task count per project/value)
- agenda tag pills mapping (to support `TaskTileVariant.agenda` anywhere)

Enrichment is evaluated in the domain/runtime layer before rendering.

**Decision:** enrichment results are typed.

**Design note:** the current `SectionDataResult.data.relatedEntities` pattern is removed in V2.

## Template-by-template mapping (V2 semantics)

### `task_list_v2` / `project_list_v2` / `value_list_v2`
- Decode `ListSectionSpecV2`.
- Constraints: `source` must be of the matching entity type.

### `interleaved_list_v2`
- Decode an `InterleavedListSpecV2` that is a list of `ListSectionSpecV2` sources with a single shared `layout`/`tiles` policy.

### `agenda_v2`
- Decode `AgendaSpecV2` which is `ListSectionSpecV2` + timeline-specific fields.
- Replace `showTitlePrefixTags` with `TaskTileVariant.agenda` behavior.

## Acceptance criteria
- All screens render using V2 params/specs; no remaining callsites depend on removed legacy models.
- Scheduled/Agenda retains its scroll ownership behavior (single agenda section special-case stays valid).
- No per-screen UI forks introduced.
- `flutter analyze` reports **0 issues**.
- Tests run via the recorded runner and pass: task `flutter_test_record`.

## Migration strategy (full cutover, but staged)
- Implement V2 types/codecs alongside existing types.
- Convert templates + interpreters + renderers to V2.
- Convert all definitions to V2.
- Delete legacy params/models and any translation layers.

## Risks & mitigations
- **Risk: V2 spec becomes too generic** → keep layout spec small; add options only when multiple screens need them.
- **Risk: churn across many files** → phase the cutover by template family, land in vertical slices.
- **Risk: regression in Scheduled scroll sync** → preserve `_AgendaBody` special-case; add targeted regression tests around it.

## Open decisions (to finalize before coding)

Resolved decisions:
 - Reuse `DataConfig` as-is.
 - New template IDs for V2 (`*_v2`) with full cutover.
 - Date tag pills are driven by `TaskTileVariant.agenda` (no separate flag) and must work anywhere the variant is used.
 - Remove “related data” sidecar concept and replace required derived data via typed enrichment.
 - Fix `ValueDataConfig.query` handling so Value queries are honored end-to-end.
 - Layout spec is a small set of explicit modes matching current UX patterns.
 - Sticky headers are supported for timeline and grouped lists.

Remaining decisions:
 - None (plan-level). Phase 2 will define the concrete model shapes.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
