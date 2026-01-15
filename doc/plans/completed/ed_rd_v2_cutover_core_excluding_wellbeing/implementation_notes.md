# ED/RD + V2 Cutover (Core, excluding wellbeing) — Implementation Notes (AI-oriented)

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

This file is a concrete, step-by-step execution guide for implementing the plan phases efficiently.

## Locked decisions

- Remove `/label/:id` route entirely.
- Delete legacy ScreenDefinition stack files from the repo (delete-if-exists).
- Task is editor-only: `/task/:id` always opens the editor sheet.
- Project and Value detail UX must be identical.
- Done means: 0 legacy ScreenDefinition stack files remain in the repo.

## Suggested execution order (minimal risk)

1) Run `flutter analyze` first and keep it clean while working.
2) Apply routing cleanup (`/label/:id`) and update any callers.
3) Delete legacy ScreenDefinition stack + delete/adjust legacy-only tests.
4) Update stale documentation/comments referencing the removed legacy system-screen definitions.
5) Run `flutter analyze` (must be clean), then run recorded tests.

## Concrete file targets

### Remove label route

- Edit: `lib/presentation/routing/router.dart`
  - Remove the `GoRoute(path: '/label/:id', ...)` block.
- Verify no callers:
  - Search for `/label/` and `label/:id` and remove/update any navigation.

### Delete legacy ScreenDefinition stack (delete-if-exists)

- Expected deletion candidates:
  - `lib/presentation/screens/view/unified_screen_page.dart`
  - `lib/presentation/screens/bloc/screen_definition_bloc.dart`
  - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

Status (2026-01-14): these legacy files are already absent in the repo. Keep
the guidance as delete-if-exists so the plan stays resilient across branches.

- Tests to remove/adjust:
  - Search for the removed legacy screen-definition BLoC and remove tests that only cover legacy behavior.
  - Expected: `test/presentation/features/screens/bloc/screen_definition_bloc_test.dart`.

### Update stale docs/comments

- Ensure docs/comments reference `SystemScreenSpecs` as the system-screen source:
  - `lib/domain/interfaces/screen_catalog_repository_contract.dart`

## High-signal verification searches

After implementation, these should return 0 results:

- `\/label\/:id`
- `lib/presentation/screens/view/unified_screen_page.dart`
- `lib/presentation/screens/bloc/screen_definition_bloc.dart`
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

## Validation commands (repo workflow)

- Analysis: `flutter analyze`
- Tests (recorded): use the `flutter_test_record` task or CLI:
  - `dart run tool/test_run_recorder.dart --`
