# Phase 01 — Add `entity_list_v3` End-to-End (Keep Legacy Temporarily)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Purpose
Introduce the new flat list module end-to-end in the typed USM pipeline while preserving existing screens (legacy still works).

## Work
1) Add new typed “language” surface:
   - Add `ScreenModuleSpec.entityListV3(...)` to the sealed union.
   - Add `SectionTemplateId.entity_list_v3`.

2) Add runtime pipeline wiring:
   - `screen_module_interpreter_registry.dart`: map new module → interpreter.
   - Reuse existing list data interpreter path (same data shapes as current list modules).
   - Ensure section isolation: failures become section-level error VMs.

3) Add presentation rendering:
   - `section_renderer_registry.dart`: map new section VM/type to a renderer.
   - Implement `EntityListRendererV3` with strict typed validation:
     - Supports `DataConfig.task` and `DataConfig.value`.
     - Rejects any other `DataConfig` (clear error VM).
   - Preserve behavior parity by delegating to existing render logic (or porting minimal common behavior).

4) Add entity style defaults:
   - `EntityStyleResolver` must define defaults for `(template, entity_list_v3)`.
   - Ensure parity with existing list defaults.

5) Codegen:
   - Run `build_runner` to update Freezed/JSON serialization output.

## Deliverables
- New module compiles, is wired through interpreter + renderer + style defaults.
- At least one low-risk screen or dev-only spec can be switched to prove it works.

## Acceptance Criteria
- App compiles.
- `flutter analyze` is clean.
- No behavior changes to existing user-facing screens required in this phase.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by end of phase.
- If Freezed/JSON output is affected, run the workspace task `build_runner`.
- When complete, update this file with summary + `Completed at:` (UTC).
