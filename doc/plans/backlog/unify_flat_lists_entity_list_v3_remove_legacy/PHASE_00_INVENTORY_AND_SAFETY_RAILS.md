# Phase 00 — Inventory + Safety Rails

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Purpose
Establish the blast radius and ensure we can complete a “full legacy removal” safely.

## Work
1) Enumerate current usage sites (must be exhaustive):
   - `ScreenModuleSpec.taskListV2` / `ScreenModuleSpec.valueListV2`
   - `SectionTemplateId.task_list_v2` / `SectionTemplateId.value_list_v2`
   - `TaskListRendererV2` / `ValueListRendererV2`
   - Any tests/fixtures/snapshots that reference the legacy IDs or VMs.

2) Confirm “user-facing” screens affected:
   - System screens that use value lists.
   - Entity detail specs (project detail RD uses task list).

3) Decide canonical new identifiers:
   - New module case name: `entityListV3` (or alternative)
   - New `SectionTemplateId`: `entity_list_v3` (or alternative)
   - Confirm whether we keep `ListSectionParamsV2` as-is.

4) Identify style keys that will change:
   - Map from `(template, task_list_v2/value_list_v2)` to `(template, entity_list_v3)`.
   - Decide how to preserve existing defaults via `EntityStyleResolver`.

5) Confirm any dependencies on legacy VMs in presentation switchboards.

## Deliverables
- A checklist of every code location to be modified.
- A final naming decision (module + template id) recorded in this phase doc.

## Acceptance Criteria
- You can answer: “Which screens will change?” and “Which files must be updated?” with a concrete list.
- No code changes are required to complete this phase (analysis-only is acceptable).

## AI instructions
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by end of phase. (Expected: none.)
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if this phase changes architecture.
- When the phase is complete, update this file immediately with:
  - `Last updated at:` (UTC)
  - a short summary of what was done
  - `Completed at:` (UTC)
