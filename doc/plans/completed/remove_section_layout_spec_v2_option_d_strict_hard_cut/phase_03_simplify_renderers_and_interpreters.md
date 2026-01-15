# Phase 03 — Simplify renderers/interpreters (remove layout branching)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Intent
With the layout union removed, simplify code paths so that:
- Interleaved list rendering is purely interleaved (no “hierarchy mode” toggles).
- Hierarchy rendering is owned by `hierarchyValueProjectTaskV2` module + its interpreter/renderer.

This reduces cognitive overhead and removes misleading abstractions.

## AI instructions (required)
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase are fixed by the end of the phase.

## Expected refactors
(Confirm actual file names/paths with search in this phase.)

### 1) Remove hierarchy adapter from hierarchy interpreter
- File: `lib/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart`

Current known pattern:
- An adapter method that converts hierarchy params into interleaved params and injects `SectionLayoutSpecV2.hierarchyValueProjectTask(...)`.

Target:
- Hierarchy interpreter emits hierarchy-specific section VM data directly.
- No conversion to interleaved params.

### 2) Interleaved renderer becomes single-purpose
- File: `lib/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart`

Target:
- Remove any branching that previously depended on layout union.
- Interleaved list renderer should not know about “hierarchy”.

### 3) Task/value list renderers become single-purpose
- Files (expected):
  - `lib/presentation/screens/templates/renderers/task_list_renderer_v2.dart`
  - `lib/presentation/screens/templates/renderers/value_list_renderer_v2.dart` (if exists)

Target:
- Remove any leftover branching that existed only to support the deleted layout union.

### 4) Verify `SectionWidget` routing still correct
- File (expected): `lib/presentation/widgets/section_widget.dart` or equivalent.

Target:
- Ensure that section/template IDs still map to the correct renderer.
- No references to removed layout/template concepts.

## Acceptance criteria
- No remaining layout-branching in renderers/interpreters.
- Hierarchy behavior still reachable via `hierarchyValueProjectTaskV2` screens.
- `flutter analyze` clean for this phase.

## Guardrails
- Do not change visual design unless necessary to preserve behavior.
- If behavior changes are unavoidable, document exactly what changes and why, and prefer minimizing the delta.
