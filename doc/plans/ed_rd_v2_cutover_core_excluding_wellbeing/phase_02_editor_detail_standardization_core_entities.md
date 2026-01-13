# ED/RD + V2 Cutover (Core) — Phase 02: ED/RD Standardization (Task/Project/Value)

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-13T00:00:00Z

## Goal

- Standardize entity editor/detail behavior for core entities (`task`, `project`, `value`) using the already-established contracts (FormBuilder-first) and routing conventions.

## Scope

- In scope:
  - Align task/project/value flows to the agreed ED/RD contracts and NAV convention.
  - Ensure editor launches are consistent (modal behavior, callbacks, dependency wiring).
  - Ensure project/value “detail pages” are unified-screen-model based and consistent in chrome/actions.
- Out of scope:
  - Journals/trackers.
  - New entity types unless explicitly required for core cutover.

## Delta Checklist (What to change vs current state)

- Ensure the *editor entry point* is centralized and consistently used:
  - `EditorLauncher` remains the canonical launcher.
  - **Lock** Task as “editor-only” semantics (route and launcher both open the editor sheet).
    - `/task/:id` must render the editor sheet UI (not a separate task detail page).
    - Any future “task detail” UX is out-of-scope for this plan.
  - Confirm Project/Value editors are FormBuilder-first and meet the editor contract (draft → command, field key stability, validation mapping).
- Make Project/Value detail pages conform to the same RD/ED surface policy:
  - Edit action launches editor (sheet/modal) and refreshes the detail view.
  - Delete flows follow consistent confirmation copy and cascade expectations.
- Consolidate duplicated UI patterns (Project vs Value must be identical):
  - Ensure entity header, list section usage, and empty/error/loading states are identical between Project and Value.
  - Ensure AppBar actions and overflow menu structure are identical.
  - If needed, extract shared widgets/helpers; keep it small and local to avoid introducing a new architecture.

## Acceptance Criteria

- Task, Project, and Value flows match the ED/RD contract and are consistent in:
  - How editors are launched.
  - How detail pages expose “Edit” and refresh behavior.
  - Error/loading handling.
- Task detail routing is editor-only: `/task/:id` always opens the editor sheet.
- Project and Value detail pages are UX-identical.
- No journaling/tracking code is changed.

## Implementation Notes

- Backlog decision source of truth:
  - `doc/architecture/backlog/editor_detail_template_contracts_formbuilder.md`
  - `doc/architecture/backlog/screen_template_migration.md`
- Code touchpoints (expected):
  - `lib/presentation/features/editors/editor_launcher.dart`
  - `lib/presentation/features/projects/view/project_detail_unified_page.dart`
  - `lib/presentation/features/values/view/value_detail_unified_page.dart`
  - `lib/presentation/routing/router.dart` (task route should remain editor-only)
  - `lib/presentation/routing/routing.dart` (typed entity navigation should remain consistent)
  - Task editor/detail UI + bloc files

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
