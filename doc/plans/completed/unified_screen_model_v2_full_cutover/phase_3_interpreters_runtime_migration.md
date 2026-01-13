# Unified Screen Model V2 — Full Cutover Plan (Phase 3: Interpreters + Runtime)

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T06:10:00Z (UTC)

## Objective
Migrate domain interpreters and runtime wiring to consume the V2 specs and produce section data consistently, removing legacy config plumbing once unused.

Plan references:
- Decisions: `decisions.md`
- Open issues: `open_issues.md`
- Implementation reference: `implementation_reference.md`

## Implementation guide (Phase 3)

Goal: make the domain runtime able to interpret and execute the new `*_v2` templates.

### 1) Add V2 interpreters (no branching in legacy interpreters)

Create new interpreter classes under `lib/domain/screens/templates/interpreters/`:

- `data_list_section_interpreter_v2.dart`
- `interleaved_list_section_interpreter_v2.dart`
- `agenda_section_interpreter_v2.dart`

Each should:
- implement `SectionTemplateInterpreter<...V2Params>`
- return the new `SectionTemplateId.*_v2`
- call runtime services that implement V2 fetching/watching

### 2) Runtime service changes (V2 pipeline)

Implement V2 equivalents inside the runtime layer:

- Recommended pattern: extend `SectionDataService` with dedicated V2 entry points:
  - `fetchDataListV2(...)`, `watchDataListV2(...)`
  - `fetchInterleavedListV2(...)`, `watchInterleavedListV2(...)`
  - `fetchAgendaV2(...)`, `watchAgendaV2(...)`

These methods must:
- execute `DataConfig` primary queries
- apply `EnrichmentPlanV2` centrally
- return a result that does **not** rely on `relatedEntities`

### 3) Handling `SectionDataResult` during migration

Because legacy templates still exist until Phase 5:

- Preferred: add a new union branch for V2 data sections (e.g. `dataV2`) that carries:
  - `items: List<ScreenItem>`
  - `enrichment: EnrichmentResultV2?`

This avoids mixing legacy `relatedEntities` into V2.

### 4) Remove related-data concept for V2

V2 must not use any of:
- `RelatedDataConfig`
- `DataListSectionParams.relatedData`
- `SectionDataResult.data.relatedEntities`

Counts/stats previously derived via related-data must be produced via typed enrichment.

### 5) Agenda tags anywhere (`TaskTileVariant.agenda`)

Implement a domain-side derived output:
- Input: the section spec declares `dateField` + optional filter semantics.
- Output: `Map<TaskId, AgendaTag>` (typed) included in `EnrichmentResultV2`.

This output must be computed for any section that renders tasks with `TaskTileVariant.agenda` (not only `agenda_v2`).

### 6) Value query end-to-end (runtime)

Verify that:
- `ValueDataConfig(query: ...)` flows through V2 params → runtime watchers → repository calls.
- If the current repository/service ignores queries in any path, fix it here.

### 7) Verify (analysis)

- Run `flutter analyze` and fix all issues introduced in this phase.
- Do not run tests yet.

## Work items
- Update interpreters:
  - `data_list_section_interpreter.dart`
  - `interleaved_list_section_interpreter.dart`
  - `agenda_section_interpreter.dart`
- Add V2 interpreters and registry wiring for new template IDs:
  - `task_list_v2`, `project_list_v2`, `value_list_v2`, `interleaved_list_v2`, `agenda_v2`
  - Prefer new interpreter classes rather than branching existing ones (to keep legacy removal clean).
- Ensure enrichment plan is applied centrally:
  - If enrichment requires additional queries/streams, resolve them in the interpreter layer (or a shared enrichment coordinator) rather than in UI renderers.
- Keep existing `SectionDataResult`/`AgendaSectionResult` stable unless there is a compelling reason to change; prefer adapting internals first.

Given the V2 decision to remove related-data, we should expect `SectionDataResult` to change for data sections:
- Remove `SectionDataResult.data.relatedEntities`.
- Replace with typed `EnrichmentResultV2` outputs as needed.

Assumptions / constraints for V2:
- No related-entities sidecar concept exists in V2. Remove `RelatedDataConfig`/`relatedEntities` plumbing as part of this phase + cleanup.
- Primary domain entities may not include everything; V2 must request required derived data via typed enrichment outputs.
- `ValueDataConfig(query: ...)` must be honored end-to-end.

## Agenda/Scheduled invariants
- Preserve Scheduled’s page-level scroll ownership behavior (single agenda section rendered by the special body).
- “Date tag pills” behavior must be driven by tile variant + typed derived data, not a per-screen boolean.
- Tags must be available wherever `TaskTileVariant.agenda` is used (not only `agenda_v2`).

## Removal targets (as they become unused)
- Legacy display/enrichment config usage in interpreters where replaced by V2.
- Related-data sidecar removal (OI-001):
  - `RelatedDataConfig`
  - `DataListSectionParams.relatedData`
  - `SectionDataService` related fetch paths
  - `SectionDataResult.data.relatedEntities`

## Acceptance criteria
- Interpreters compile and run with V2 params.
- `flutter analyze` is clean.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
