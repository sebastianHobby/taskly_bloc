# Someday V2 Full Migration — Phase 5: Legacy Deletion + Verification

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Delete legacy Someday implementation and verify the migration end-to-end.

## Work items
- Remove legacy:
  - `SomedayBacklogRenderer`
  - `SomedayBacklogSectionInterpreter`
  - legacy template ID wiring for Someday
  - any unused params/models after deletion
- Ensure no remaining references in section registry/switches.

## Verification
- Run `flutter analyze` and fix all issues.
- Run tests exactly once at the end via `flutter_test_record`.

## Completion
- Move this plan folder to `doc/plans/completed/someday_v2_full_migration/`.
- Add a completion summary doc with implementation date (UTC), what shipped, and follow-ups.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
