# Phase 01 — Inventory & Entry Point Removal Plan

## Goal
Create a complete list of workflow entrypoints and remove user-visible navigation into workflows.

## Remove/Update (expected files)
- Settings entry that navigates to workflows:
  - `lib/presentation/features/settings/view/settings_screen.dart`
- Router route `/workflow-run`:
  - `lib/presentation/routing/router.dart`
- System screen definition and mapping for `workflows`:
  - `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`
- Section template id for workflow list:
  - `lib/domain/screens/language/models/section_template_id.dart` (remove `workflowList`)
- Section template widget mapping:
  - `lib/presentation/widgets/section_widget.dart` (remove mapping to `WorkflowListPage`)
- DI registrations for workflow section interpreters (if any):
  - `lib/core/di/dependency_injection.dart`
- Navigation icon mapping for workflows:
  - `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

## Step-by-step
1. Remove the workflows tile/row from Settings.
2. Remove the `/workflow-run` route from `GoRouter`.
3. Remove the system screen `workflows` definition and any `screenKey` mappings.
4. Remove the `SectionTemplateId.workflowList` constant and any places it is referenced.
5. Remove workflow-specific navigation icon resolver entries.

## Verification
- Run `flutter analyze`.
- Fix compilation errors only (do not address tests yet).

## Notes
- This phase should not touch workflow domain/data code yet; it should only eliminate app entrypoints so the feature is no longer reachable.
