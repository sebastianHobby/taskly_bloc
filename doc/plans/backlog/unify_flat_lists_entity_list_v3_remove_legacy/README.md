# Plan — Unify Flat Lists into `entity_list_v3` (Remove Legacy)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal
Replace the legacy flat list modules:
- `task_list_v2`
- `value_list_v2`

…with a single flat list module:
- `entity_list_v3` (final name may be adjusted during Phase 00)

Keep hierarchy separate:
- `hierarchy_value_project_task_v2` remains in place.

## End State (Definition of Done)
- No remaining code references to legacy list modules/IDs/VMs/renderers:
  - `taskListV2`, `valueListV2`
  - `task_list_v2`, `value_list_v2`
  - `TaskListRendererV2`, `ValueListRendererV2`
  - legacy interpreter/registry branches and `SectionVm` variants
- All catalog specs use `entity_list_v3` for flat lists.
- Entity tile styling continues to be resolved via `EntityStyleV1` keyed by `(ScreenTemplateSpec, SectionTemplateId)`.
- Unified Screen Model invariants remain intact (presentation boundary, section isolation, mutations funnel).

## Non-Goals
- No agenda refactors.
- No new filtering UX.
- No new mixed “interleaved” feed feature.

## Risks
- Freezed/union churn: removing sealed union cases requires updating all `when`/`map`/switch branches.
- Style key migration: the new `SectionTemplateId` must preserve list styling defaults.
- Renderer parity: list header/empty state behavior must remain consistent.

## Phases
- PHASE_00 — Inventory + safety rails
- PHASE_01 — Add `entity_list_v3` end-to-end (keep legacy temporarily)
- PHASE_02 — Migrate all specs to `entity_list_v3`
- PHASE_03 — Delete legacy list modules/IDs/renderers
- PHASE_04 — Cleanup + regression hardening
