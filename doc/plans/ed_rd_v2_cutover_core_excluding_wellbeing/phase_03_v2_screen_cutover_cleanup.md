# ED/RD + V2 Cutover (Core) — Phase 03: V2 Screen Cutover Cleanup

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-13T00:00:00Z

## Goal

- Complete the core V2 cutover by deleting dead legacy screen pipelines and fixing remaining routing inconsistencies.

## Scope

- In scope:
  - Delete the unused ScreenDefinition-based rendering stack (explicit decision; delete-if-exists).
  - Fix routing inconsistencies that violate the “two patterns only” rule.
  - Align contract docs/comments with the actual V2 implementation.
- Out of scope:
  - Journals/trackers.
  - Any re-architecture of the V2 unified screen model (it is already the active path).

## Delta Checklist (What to change vs current state)

- Routing cleanup
  - **Remove** the `/label/:id` route (explicit decision: Option A).
    - Update file: `lib/presentation/routing/router.dart`
    - Verify after change: no code navigates to `/label/:id`.
  - Ensure `Routing.entityTypes` matches the actual registered entity routes.
    - Expected: `task`, `project`, `value`.
- Legacy screen pipeline cleanup (only if zero runtime references)
  - **Delete legacy ScreenDefinition artifacts from the repo** (explicit decision).
    - Implementation should be delete-if-exists (these files may already be gone when the plan is executed).
    - Expected deletion candidates (confirm references are zero before deleting):
      - `lib/presentation/screens/view/unified_screen_page.dart`
      - `lib/presentation/screens/bloc/screen_definition_bloc.dart`
      - `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`
  - Delete/adjust tests that only exercise the legacy stack.
    - Search for tests referencing `ScreenDefinitionBloc`, `UnifiedScreenPage`, `SystemScreenDefinitions`.
    - Expected: remove `test/presentation/features/screens/bloc/screen_definition_bloc_test.dart` if it only covers the deleted bloc.
  - Remove or update any stale comments that still reference the legacy system.
- Documentation and naming consistency
  - Update the repository contract docs to reference `SystemScreenSpecs` (current source of system screens).
    - Update file: `lib/domain/interfaces/screen_definitions_repository_contract.dart`

## Acceptance Criteria

- There is a single, obvious, supported system-screen rendering path:
  - `GoRouter '/:segment'` → `Routing.buildScreen` → `SystemScreenSpecs` → `UnifiedScreenPageFromSpec`.
- No remaining routes point to missing/unregistered entity builders.
- `/label/:id` is not present in routing.
- No legacy ScreenDefinition stack files remain in the repo.
- `flutter analyze` is clean.

## Implementation Notes

- Expected touchpoints:
  - `lib/presentation/routing/router.dart`
  - `lib/presentation/routing/routing.dart`
  - `lib/domain/interfaces/screen_definitions_repository_contract.dart`
  - Delete legacy presentation/domain screen-definition files and their tests.

### Verification (high-signal grep checks)

- After implementation, these searches should return 0 results:
  - `\/label\/:id`
  - `UnifiedScreenPage` (type/name)
  - `ScreenDefinitionBloc`
  - `SystemScreenDefinitions`

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
