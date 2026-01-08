# Phase 04 — Unify All Screens Under ScreenDefinitions; Remove Custom Builders

## Goal

- Remove the concept of “custom screen builders” registered in bootstrap.
- All screens (settings/journal/workflows/etc.) become ScreenDefinitions composed of section templates.

This phase also eliminates the persisted/parsed “custom render mode” switch that enables navigation-only/custom screens.

## Approach

## Amendments (2026-01-08)

### Workflow launch policy

- **Resolve** must be launched **only on click**.
- Any “auto-launch Resolve when attention exceeds threshold” logic is disallowed.
- Resolve eligibility/availability is computed from the current attention state
	(do not maintain separate trigger configuration).

### 1) Replace custom routing builders

Files:
- `lib/bootstrap.dart`
- `lib/core/routing/routing.dart`

Actions:
- Delete `Routing.registerScreenBuilders` usage.
- `Routing.buildScreen(screenKey)` must always load a ScreenDefinition and render `UnifiedScreenPage`.

Concrete repo-verified symbols to delete:

- `Routing.registerScreenBuilders(...)`
- `Routing._screenBuilders`
- Any `isCustomRender` logic around `renderMode == custom`

### 2) Convert navigation-only system screens into templated screens

Files:
- `lib/domain/models/screens/system_screen_definitions.dart`
- `lib/domain/models/screens/screen_definition.dart`
- `lib/presentation/features/screens/view/screen_management_page.dart` (contains UI for `NavigationOnlyScreenDefinition`)

Actions:
- Ensure there is only a **single concrete** `ScreenDefinition` model.
- All system screens are defined declaratively with `sections: List<SectionRef>`.
- Group screen metadata under `ScreenChrome` (icon/badge/fab/appbar/etc.) so
	the model does not grow ad-hoc metadata fields over time.

Implementation note:
- If `ScreenDefinition` is persisted as JSON, introducing `ScreenChrome` changes the
	persisted shape. Update parsing/serialization and any drift JSON converters or
	repositories that read/write the screen JSON accordingly.

Also remove the render-mode mechanism:

- Delete `RenderMode` enum and any `renderMode` parsing/serialization in `screen_definition.dart`.
- Remove any remaining `NavigationOnlyScreenDefinition` references.

Examples:
- `settings` screen: `settings_menu` section.
- `workflows` screen: `workflow_list` section.
- `journal` screen: `journal_timeline` section.

### 3) Specialized templates can embed existing widgets

To reduce refactor risk, a specialized template renderer may simply return the existing page content widget.

Example:
- `settings_menu` renderer can reuse `SettingsScreen` internal widget tree.

But routing must always go through the unified screen host.

Implementation note (repo-specific):

- Screens currently registered via bootstrap builders must be converted into templates/sections, even if the section renderer just reuses the existing widget tree.

## Validation
- `flutter analyze`

## Completion criteria
- No `registerScreenBuilders` remains.
- No navigation-only ScreenDefinition variant remains.
- All screens are declarative via section templates.
- `ScreenDefinition` uses `ScreenChrome` for screen metadata.

Repo-verified grep checks for completion:

- `registerScreenBuilders|_screenBuilders`
- `NavigationOnlyScreenDefinition|RenderMode\.custom|renderMode\b`

Persistence/update points you will likely need to touch in this phase:

- `lib/data/drift/features/screen_tables.drift.dart` (currently defines `RenderMode { unified, custom }`)
- `lib/data/features/screens/repositories/screen_definitions_repository_impl.dart` (currently branches on DB `renderMode`)
- `lib/data/services/screen_seeder.dart` (currently persists `renderMode`)

If `renderMode` is stored as its own DB column, you will need a drift schema migration/regen strategy consistent with the repo’s existing drift workflow.
