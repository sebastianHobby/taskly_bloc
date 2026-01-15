# Phase 02 — Delete `SectionLayoutSpecV2` and layout fields

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Intent
Now that nothing should *need* `SectionLayoutSpecV2` at runtime, remove it entirely and remove the `layout` fields that carry it around.

This is the phase where “layout as a first-class union” is fully deleted.

## AI instructions (required)
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase are fixed by the end of the phase.

## Delete/modify list (expected)
(Validate with search before edits.)

### A) Delete the union
- File: `lib/domain/screens/templates/params/list_section_params_v2.dart`
  - Delete `SectionLayoutSpecV2` completely.

If `ListSectionParamsV2` carries `layout`, remove the field (or refactor to the minimal stable API needed by the remaining modules).

### B) Remove layout from interleaved params
- File: `lib/domain/screens/templates/params/interleaved_list_section_params_v2.dart`
  - Remove `layout` field.
  - Remove any Freezed union fields / constructors related to layout.

### C) Remove layout from value/task list params if present
- File: `lib/domain/screens/templates/params/*list*_params*.dart`
  - If any remaining list params carry `layout` solely to select “flat vs hierarchy”, delete it.

## Codegen
If any Freezed models are changed:
- Run build runner task: `build_runner` (VS Code task) or `dart run build_runner build --delete-conflicting-outputs`.

## Acceptance criteria
- Repo-wide search finds no references to:
  - `SectionLayoutSpecV2`
  - `layout:` where it previously referenced that type
- `build_runner` succeeds (if invoked).
- `flutter analyze` clean for this phase.

## Notes
- Keep these changes mechanical.
- Avoid “simplify everything” refactors here; do the minimum so that Phase 03 can simplify behavior safely.
