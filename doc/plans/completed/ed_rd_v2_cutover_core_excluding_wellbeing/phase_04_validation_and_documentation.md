# ED/RD + V2 Cutover (Core) — Phase 04: Validation & Documentation

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal

- Validate the cutover work end-to-end and ensure documentation reflects the final state.

## Scope

- In scope:
  - Run analysis + recorded tests.
  - Update architecture docs if any implementation changed contracts or boundaries.
  - Ensure navigation/screen catalog reflects the final supported set.
- Out of scope:
  - Journals/trackers.

## Acceptance Criteria

- `flutter analyze` is clean.
- Recorded test run passes (prefer `flutter_test_record`).
- Any changed architecture is reflected in `doc/architecture/`.
- The migration backlog docs remain accurate for the core entities/screens.
- **Completion definition**: no legacy pre-`ScreenSpec` screen-pipeline files remain in the repo.

Note (2026-01-14): this completion definition is now met on `main`.

## Implementation Notes

- If Phase 03 removed legacy files, also ensure:
  - No lingering imports in test files.
  - Any “legacy” references in docs are updated or removed.

### Final verification checklist

- Repo content checks:
  - `lib/presentation/routing/router.dart` contains no `/label/:id` route.
  - Legacy pipeline files are absent.
    - `lib/presentation/screens/bloc/screen_definition_bloc.dart`
    - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

  Note: references to these paths may still appear in historical plan files
  under `doc/plans/**`; those are archival and do not indicate runtime usage.
  - Task remains editor-only (route `/task/:id` opens editor sheet).

## AI instructions

- Before implementing this phase:
  - Review `doc/architecture/` for relevant context and constraints.
  - Run `flutter analyze`.
- While implementing:
  - Keep changes aligned with the architecture docs.
  - If this phase changes architecture (boundaries, responsibilities, data flow, storage/sync behavior, cross-feature patterns), update the relevant files in `doc/architecture/` as part of the same change.
- Before finishing the phase:
  - Run `flutter analyze` and fix *all* errors and warnings.
  - Only then run tests (prefer the `flutter_test_record` task).

## Verification

- `flutter analyze`
- Tests: `dart run tool/test_run_recorder.dart -- <args>`
