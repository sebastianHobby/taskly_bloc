# Phase 01 — Rename “Wellbeing” → “Journal” (repo-wide)

Created at: 2026-01-13T12:16:40Z
Last updated at: 2026-01-13T12:25:20Z

## Goal

Remove the *concept/name* of “wellbeing” from the codebase and replace it with “journal”, while keeping the app compiling and behaviorally equivalent (no product redesign yet).

This phase is a **pure rename + wiring update** phase to reduce churn/risk before the B1 redesign work.

## Current state (observed)

- The repo currently implements “wellbeing” as a feature package and a set of system/unified screen specs.
- The wellbeing feature code is tightly coupled to the legacy journal + tracker-response model.
- The unified screen system also still references a wellbeing dashboard spec/definition.

## Rename map (mechanical)

Canonical rename targets:

- Route segment: `wellbeing` → `journal`
- Screen key: `wellbeing_dashboard` → `journal_dashboard` (temporary; Phase 03 may replace dashboard with hub)
- Icon name: `wellbeing` → `journal`
- Feature folder: `lib/presentation/features/wellbeing` → `lib/presentation/features/journal`
- Repository contract: `WellbeingRepositoryContract` → `JournalRepositoryContract`
- Repository impl: `WellbeingRepositoryImpl` → `JournalRepositoryImpl`

Compatibility policy (this plan):

- Assume all data is deleted/wiped; keep **no backwards compatibility**.
- Do not add route aliases (`/wellbeing`) or screenKey aliases.

## Scope

### In scope

- Rename user-facing labels (screen names, titles, strings) from “Wellbeing” to “Journal”.
- Rename internal identifiers where they are *conceptual* not *data-schema*:
  - screen keys/route segments (e.g. `/wellbeing` → `/journal`)
  - screen IDs (e.g. `wellbeing_dashboard` → `journal_dashboard` if it is truly a dashboard route)
  - icon names (`wellbeing` → `journal`)
  - feature package folder `presentation/features/wellbeing` → `presentation/features/journal`
  - repository contracts and implementations `WellbeingRepository*` → `JournalRepository*`
  - tests and test tags: `wellbeing` tag → `journal` (keeping compatibility during transition if needed)
- Update unified screen system catalogs to refer to Journal.

### Out of scope

- Changing the underlying storage model (the legacy daily/per-entry tracker model remains untouched here).
- Removing legacy code paths (that’s Phase 02+).
- Implementing the new Daylio-first B1 UI (Phase 03+).

## Constraints / invariants

- Build must pass.
- `flutter analyze` must have zero errors/warnings introduced by this phase.
- No compatibility: old deep links and old screen keys are expected to break.

## Implementation notes

### 1) Routing and screen keys

- Update route parsing and any `GoRouter` routes so `journal` is the canonical segment.
- Do not implement redirects/aliases.
- Update unified screen catalog entries:
  - `SystemScreenSpecs.wellbeingDashboard` → `SystemScreenSpecs.journalDashboard`
  - any `ScreenTemplateSpec.wellbeingDashboard()` usage should be renamed to `journalDashboard()` (or removed if the “dashboard” is going away later).

### 2) Feature folders and symbols

- Move feature UI code:
  - `lib/presentation/features/wellbeing/**` → `lib/presentation/features/journal/**`
- Rename BLoCs and screen widgets:
  - `WellbeingDashboardBloc` → `JournalDashboardBloc` (even if later removed)
  - `WellbeingDashboardScreen` → `JournalDashboardScreen`
  - `TrackerManagement*` and `JournalEntry*` should be audited:
    - If they are still tied to the legacy model, they can be renamed for consistency now, but their removal is Phase 02.

### 3) Domain/data contracts

- Rename repository contract + implementation:
  - `WellbeingRepositoryContract` → `JournalRepositoryContract`
  - `WellbeingRepositoryImpl` → `JournalRepositoryImpl`
- Update DI wiring and any analytics/section interpreter dependencies.

### 4) Copy, settings, and attention rules

- Update attention rule labels/strings referencing wellbeing (e.g. “Wellbeing Check-in”).
- Update review settings model keys:
  - Journal insights/review prompts are currently removed from surfaced reviews (see `review_journal` removal).
  - Do not rename `ReviewType.wellbeingInsights` → `journalInsights`; prefer deleting/omitting the setting type instead.

Important note: `ReviewType` is annotated with `@JsonValue(...)`. If we rename the enum value, we should either:

- keep `@JsonValue('wellbeingInsights')` for backward compatibility, or
- add an explicit decoding alias (if a custom converter exists) before changing the serialized value.

### 5) Tests

- Update tests that mention “wellbeing” in routing/navigation.
- Update test tag naming:
  - Add `journal` tag.
  - Keep `wellbeing` tag as an alias (optional) to avoid CI/tooling breakage until Phase 05 cleanup.

## Delta checklist (what to change vs current repo)

Routing + screen catalog:

- Update [lib/presentation/routing/router.dart](../../../lib/presentation/routing/router.dart) and [lib/presentation/routing/routing.dart](../../../lib/presentation/routing/routing.dart) so `/journal` is canonical (no redirects).
- Update system screens via specs only:
  - [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)
  - [lib/domain/screens/language/models/section_template_id.dart](../../../lib/domain/screens/language/models/section_template_id.dart)

Remove legacy screen-definition catalog wiring (required):

- Remove (or delete) `SystemScreenDefinitions` usage paths; do not depend on it.
- Ensure any remaining references are removed from routing/template wiring.

Feature folder + template wiring:

- Move and rename everything under `lib/presentation/features/wellbeing/**`.
- Update unified template wiring that directly imports wellbeing BLoCs/screens:
  - [lib/presentation/screens/templates/screen_template_widget.dart](../../../lib/presentation/screens/templates/screen_template_widget.dart)

Domain/data wiring:

- Update contract and implementations:
  - [lib/domain/interfaces/wellbeing_repository_contract.dart](../../../lib/domain/interfaces/wellbeing_repository_contract.dart)
  - [lib/data/features/wellbeing/repositories/wellbeing_repository_impl.dart](../../../lib/data/features/wellbeing/repositories/wellbeing_repository_impl.dart)
  - [lib/core/di/dependency_injection.dart](../../../lib/core/di/dependency_injection.dart)
  - [lib/domain/screens/runtime/section_data_service.dart](../../../lib/domain/screens/runtime/section_data_service.dart)
  - [lib/data/features/analytics/services/analytics_service_impl.dart](../../../lib/data/features/analytics/services/analytics_service_impl.dart)

Icons + copy + attention:

- Update icon resolver and icon picker catalog:
  - [lib/presentation/features/navigation/services/navigation_icon_resolver.dart](../../../lib/presentation/features/navigation/services/navigation_icon_resolver.dart)
  - [lib/presentation/widgets/icon_picker/icon_picker_dialog.dart](../../../lib/presentation/widgets/icon_picker/icon_picker_dialog.dart)
- Update attention rules copy if it names “wellbeing”:
  - [lib/domain/attention/system_attention_rules.dart](../../../lib/domain/attention/system_attention_rules.dart)
- Update review settings naming:
  - [lib/domain/settings/model/review_settings.dart](../../../lib/domain/settings/model/review_settings.dart)

Tests:

- Update routing/nav tests and integration helpers:
  - [test/presentation/features/navigation/bloc/navigation_bloc_test.dart](../../../test/presentation/features/navigation/bloc/navigation_bloc_test.dart)
  - [test/integration_test/e2e_test_helpers.dart](../../../test/integration_test/e2e_test_helpers.dart)
  - [test/mocks/feature_mocks.dart](../../../test/mocks/feature_mocks.dart)
  - [test/helpers/bloc_test_helpers.dart](../../../test/helpers/bloc_test_helpers.dart)
  - [test/fixtures/test_data.dart](../../../test/fixtures/test_data.dart)
  - [test/README.md](../../../test/README.md) (tag docs)

## Verification

- `flutter analyze`
- (Optional for this phase) run a targeted test subset for routing/nav if available.

## Acceptance criteria

- App compiles and launches.
- `flutter analyze` is clean.
- All references to “wellbeing” are eliminated from:
  - screen keys/routes
  - feature folders and primary symbols
  - user-facing nav labels
- Any remaining “wellbeing” occurrences are explicitly justified as:
  - historical migration aliases, or
  - legacy DB/table names to be removed in Phase 02.

## AI instructions

- Review doc/architecture/ before implementing.
- Run `flutter analyze` for this phase.
- Fix any errors or warnings introduced (or discovered) by the end of the phase.
- If renaming changes any architecture boundaries (routing keys, screen catalog behavior), update doc/architecture/ accordingly.
