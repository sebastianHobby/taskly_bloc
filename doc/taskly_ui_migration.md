# Taskly UI Migration Plan (`taskly_ui` first)

> Audience: developers
>
> Scope: a practical, phased plan to migrate shared UI into
> `packages/taskly_ui` while keeping strict layering and the 4-tier UI taxonomy.
>
> Normative rules (must follow):
> - `taskly_ui` is **pure UI** (no BLoCs/Cubits, no repositories/services,
>   no DI, no stream subscriptions, no navigation).
> - Shared UI must follow the **4-tier model**:
>   Primitives / Entities / Sections / Screens+Templates.
> - App code must import only `package:taskly_ui/taskly_ui.dart` and must not
>   deep-import `package:taskly_ui/src/...`.
> - **Architecture invariants are non-negotiable**. If an invariant blocks
>   progress, follow the documented exception process in
>   `doc/architecture/ARCHITECTURE_INVARIANTS.md`.
> - **USM is not allowed in `taskly_ui`**: do not import any USM/interpreted
>   screen system code into `packages/taskly_ui`.
>   The strategic direction is to migrate off USM and delete USM code.
>
> References:
> - `doc/architecture/ARCHITECTURE_INVARIANTS.md` (sections 2.1–2.2)
> - `doc/architecture/README.md`
>

## 1) Goals

- Establish `packages/taskly_ui` as the single home for shared UI
  (primitives/entities/sections) to reduce duplication and drift.
- Make shared UI reusable across features via **data in / events out** APIs.
- Keep the app presentation layer focused on screens/templates, routing,
  orchestration, and BLoC wiring.
- Reduce cross-feature coupling (especially app theme/l10n/util dependencies)
  by introducing small UI-friendly view models where needed.
- Migrate off the legacy USM (interpreted screens/templates/renderers) and
  delete USM code once callers have been moved.


## 2) Non-goals

- No re-architecture of BLoCs, routing, or screen interpreter systems.
- No large visual redesign.
- No introduction of new state management patterns.

Note:
- The long-term goal is **removal of USM**, but this plan avoids importing USM
  into `taskly_ui` as an intermediate step. USM retirement happens by moving
  consumers to explicit screens + shared UI, then deleting USM.


## 3) Constraints (strict)

### 3.1 `taskly_ui` purity

`packages/taskly_ui` may not import:
- app code (`package:taskly_bloc/...`)
- app routing/navigation (`go_router`, app `Routing`, route registries)
- BLoC (`flutter_bloc`, Cubit/BLoC types)
- domain/data packages (`taskly_domain`, `taskly_data`) unless explicitly
  approved and added as a dependency (default: avoid)

USM-specific constraint (strict):
- `taskly_ui` must not import any USM code.
  This includes (non-exhaustive) any code that is part of the interpreted
  screen/spec/template/renderer system.
- Do not “bridge” USM into `taskly_ui` to share widgets; instead:
  - extract pure UI into `taskly_ui`, and
  - keep USM-specific composition in the app until USM is removed.

`taskly_ui` may use:
- Flutter SDK only (current `pubspec.yaml` depends only on Flutter)
- Material theming via `Theme.of(context)`
- ephemeral widget-local state (controllers/focus/animations) when necessary

### 3.2 Package boundary

- Do not import/export `package:taskly_ui/src/...` from outside the package.
- Ensure `packages/taskly_ui/lib/taskly_ui.dart` exports the public surface.

### 3.3 4-tier taxonomy layout

Keep `taskly_ui` aligned to the invariant directory layout:
- `packages/taskly_ui/lib/src/primitives/`
- `packages/taskly_ui/lib/src/entities/`
- `packages/taskly_ui/lib/src/sections/`
- `packages/taskly_ui/lib/src/templates/` (layout-only; still routing/state-free)

Additional placement rule (strict):
- USM code must not be moved into `taskly_ui` under any folder.


## 4) Current State Snapshot (Jan 2026)

- `taskly_ui` now exports a broader shared UI surface via
  `packages/taskly_ui/lib/taskly_ui.dart`, including:
  - Sections: `EmptyStateWidget`, `ErrorStateWidget`, `LoadingStateWidget`,
    `FeedBody`, `SettingsSectionCard`, `IconPickerDialog`
  - Primitives: `ContentConstraint` + `SliverContentConstraint`,
    `SliverSeparatedList`, `SwipeToDelete`, `ModalChromeScope`
  - Templates: `FormShell`
- The app has a large shared-widgets folder:
  - `lib/presentation/widgets/` (~56 files)
  - additional helpers under
    `lib/presentation/screens/widgets/` and templates widgets/renderers

Known duplication:
- App-local duplicates of the empty/error/loading widgets have been removed;
  app code uses the `taskly_ui` exports instead.

Known integration note:
- `IconPickerDialog` must remain l10n-agnostic: categories, titles, and labels
  are supplied by the app (avoid defining default categories/constants inside
  `taskly_ui`).

### 4.1 Priority 0 — `lib/presentation/widgets/` inventory (move/keep decisions)

Treat everything under `lib/presentation/widgets/` as **legacy shared UI**.

Goal: migrate only truly reusable **Primitives / Entities / Sections** into
`packages/taskly_ui` (pure UI). Anything that is screen/interpreter/BLoC/
navigation/dialog policy stays in the app presentation layer.

Legend:
- **Move → `taskly_ui`**: intended shared UI; must be pure UI, l10n-agnostic,
  and “data in / events out”.
- **Keep (app-only)**: not allowed in `taskly_ui` (navigation/dialog/BLoC) or
  intentionally app-owned policy.
- **Needs decision**: requires a product/architecture decision before moving
  (usually because of dependencies or policy ownership).

#### Keep (app-only): not allowed in `taskly_ui`

- Interpreter/BLoC wiring (must stay app-owned):
  - `lib/presentation/widgets/section_widget.dart`
- Navigation/dialog helpers (must stay app-owned):
  - `lib/presentation/widgets/delete_confirmation.dart`
  - `lib/presentation/widgets/sign_out_confirmation.dart`
  - `lib/presentation/widgets/recurrence_picker.dart`
  - `lib/presentation/widgets/values_alignment/values_alignment_sheet.dart`
  - `lib/presentation/widgets/wolt_modal_helpers.dart`
  - `lib/presentation/widgets/next_action_indicator.dart`

#### Keep (app-owned “form infrastructure”)

These are presentation-layer form widgets (FormBuilder-first) and may depend on
domain, app policy, and validation mapping. Keep them in the app unless we
explicitly choose to allow `flutter_form_builder` inside `taskly_ui`.

- FormBuilder fields (app-owned):
  - `lib/presentation/widgets/form_fields/*`
  - `lib/presentation/widgets/form_fields/form_fields.dart`
  - `lib/presentation/widgets/form_fields/form_section_header.dart`

#### Moved → `taskly_ui` (Primitives): done

- `packages/taskly_ui/lib/src/primitives/project_pill.dart`
  - Now l10n-agnostic via `semanticsLabel`/`tooltipMessage` inputs.
- `packages/taskly_ui/lib/src/primitives/taskly_badge.dart`
- `packages/taskly_ui/lib/src/primitives/taskly_header.dart`

#### Needs decision (Primitives): dependency/policy questions

- `lib/presentation/widgets/taskly/taskly_card.dart`
  - Long-term shared Primitive but currently depends on app ThemeExtension.
  - Direction: move the ThemeExtension type (“design tokens”) into `taskly_ui`
    and have the app provide values.
- `lib/presentation/widgets/priority_flag.dart`
  - Uses app color constants and hardcoded semantics strings.
  - Decide: keep app-only vs move with parameterized labels and token-based
    colors.
- `lib/presentation/widgets/color_picker/color_picker_field.dart`
  - Depends on `flex_color_picker`.
  - Decide: keep app-only vs allow this dependency in `taskly_ui`.

#### Move later → `taskly_ui` (Entities/Sections via VMs): domain-coupled today

These currently import domain types and/or app utilities. The target is a split:
render-only widgets in `taskly_ui` that accept UI view-models + callbacks, with
thin adapters in the app mapping domain + l10n into VMs.

- `lib/presentation/widgets/value_chip.dart` → Entity (`ValueChipVm`)
- `lib/presentation/widgets/value_dots_cluster.dart` → Entity
- `lib/presentation/widgets/values_footer.dart` → Section (composed chips)
- `lib/presentation/widgets/entity_header.dart` → Section (composed entity UI)

#### Needs refactor first (before any move)

- `lib/presentation/widgets/date_chip.dart`
  - Mixes UI with RRULE parsing/logging/l10n.
  - Target: move a generic icon+label chip primitive into `taskly_ui` and keep
    RRULE parsing + localized labels in the app.
- `lib/presentation/widgets/form_date_chip.dart`
  - Uses DI/time service and hardcoded English strings; not suitable for
    `taskly_ui` as-is.
- Filters (potentially reusable, but currently stringly-typed / app-dependent):
  - `lib/presentation/widgets/filters/entity_multi_select.dart` (has default
    English strings)
  - `lib/presentation/widgets/filters/selection_mode_choice.dart` (labels come
    from `filter_enums.dart` which hardcodes English)
  - `lib/presentation/widgets/filters/filter_enums.dart` (hardcoded labels)
  - `lib/presentation/widgets/filters/date_range_filter.dart` (depends on
    `FormDateChip` + uses `showDatePicker`)
  - `lib/presentation/widgets/filters/filters.dart` (barrel)

#### Already migrated / not in this inventory

The following shared primitives/sections/templates are already in `taskly_ui`
and exported via `packages/taskly_ui/lib/taskly_ui.dart`:
- `ContentConstraint` / `SliverContentConstraint`, `SliverSeparatedList`,
  `SwipeToDelete`, `ModalChromeScope`
- `EmptyStateWidget`, `ErrorStateWidget`, `LoadingStateWidget`, `FeedBody`,
  `SettingsSectionCard`, `IconPickerDialog`
- `FormShell`


## 5) Migration Strategy Overview

We migrate in increasing complexity:

1) **De-duplicate**: make the app use the `taskly_ui` versions for the
   already-extracted widgets.
2) **Move pure primitives**: widgets with no app/l10n/domain dependencies.
3) **Move sections**: reusable composed blocks; parameterize strings and avoid
   app-only imports.
4) **Move entities**: extract render-only entity UI into `taskly_ui` using
   UI-focused view models; keep domain adapters in the app.
5) **Stabilize**: tighten exports, remove remaining deep imports, and document
   the final public surface.

In parallel, we run a **USM retirement track**:
- Keep USM dependencies contained in the app while migrating shared UI out.
- Migrate screens off USM onto explicit routes/screens/templates.
- Delete USM code when no longer referenced.


## 6) API Design Rules (data in / events out)

### 6.1 Avoid app l10n in `taskly_ui`

- `taskly_ui` must not import `taskly_bloc/l10n`.
- All user-facing strings must be provided as parameters
  (e.g., `retryLabel`, `deleteLabel`, dialog body text).

### 6.2 Avoid domain types in `taskly_ui` (default)

- Prefer UI view models that are stable and presentation-agnostic.

Example approach:
- Create `ValueChipVm` in `taskly_ui` (name, `IconData`, `Color`, semantics
  labels).
- Keep a tiny adapter in the app that maps `taskly_domain.Value` to `ValueChipVm`.

### 6.3 Theming

Default: rely on Material 3 theming:
- `Theme.of(context).colorScheme`, `textTheme`, etc.

If we need custom tokens:
- Prefer a `ThemeExtension` defined inside `taskly_ui` and provided by the app.

### 6.4 Navigation

- No navigation in `taskly_ui`.
- Express intent via callbacks (e.g., `onTap`, `onRetry`, `onSelect`).

### 6.5 Forms (preference)

App screens should prefer `flutter_form_builder` for all forms/editors.

- Widgets own the `FormBuilder` state/key and compose field widgets.
- BLoCs own entity subscriptions/snapshots, validation policy, and save/delete
  intents.
- Do not pass `Map<String, dynamic>` or raw string field names into BLoCs;
  prefer typed draft/value objects at the widget → BLoC boundary.


## 7) Phased Work Plan (Backlog)

Each phase includes:
- scope
- code moves
- required app changes
- acceptance criteria

### Phase 0 — Baseline guardrails (prep)

Scope:
- Ensure the team consistently uses `package:taskly_ui/taskly_ui.dart`.

Work:
- Confirm `packages/taskly_ui/lib/taskly_ui.dart` exports all public widgets.
- Ensure no app code imports `package:taskly_ui/src/...`.

Acceptance:
- `flutter analyze` stays clean.
- Guardrail `tool/no_local_package_src_deep_imports.dart` would pass.

Status (Jan 2026): complete (analyzer clean; no app deep-imports of
`package:taskly_ui/src/...`).


### Phase 1 — De-duplicate existing sections (highest ROI)

Scope:
- Replace app-local duplicates of: Empty/Error/Loading state widgets.

Work:
- Update app imports to use `package:taskly_ui/taskly_ui.dart`.
- Remove the duplicate app files:
  - `lib/presentation/widgets/empty_state_widget.dart`
  - `lib/presentation/widgets/error_state_widget.dart`
  - `lib/presentation/widgets/loading_state_widget.dart`
- Update `lib/presentation/widgets/widgets.dart` barrel exports accordingly.

Acceptance:
- No duplicate widget definitions remain in the app.
- All usages compile and render the same.

Status (Jan 2026): complete (duplicates removed; app uses `taskly_ui` exports).


### Phase 2 — Move “pure primitives” (minimal dependency risk)

Candidates:
- `SliverSeparatedList`
  - current: `lib/presentation/widgets/sliver_separated_list.dart`
  - target: `packages/taskly_ui/lib/src/primitives/sliver_separated_list.dart`

Work:
- Move file into `taskly_ui` and export from `taskly_ui.dart`.
- Update app imports to use the package export.

Acceptance:
- No app imports remain for these widgets.
- Public surface is only via `taskly_ui.dart`.

Status (Jan 2026): complete (`SliverSeparatedList` is exported via
`packages/taskly_ui/lib/taskly_ui.dart`).


### Phase 3 — Move primitives that need small API tweaks

Candidates:
- `SwipeToDelete`
  - current hardcodes label text ("Delete")
  - target: `packages/taskly_ui/lib/src/primitives/swipe_to_delete.dart`

Required API changes:
- Add parameters:
  - `String deleteLabel`
  - optionally `Widget? background` to allow custom background

Acceptance:
- No hardcoded English strings remain in the shared widget.

Status (Jan 2026): complete (`SwipeToDelete` is in `taskly_ui` and takes a
`deleteLabel` provided by the app).


### Phase 4 — Move layout primitives by removing app responsive deps

Candidate:
- `ContentConstraint` / `ResponsiveBody`
  - currently imports app responsive helpers.

Plan:
- Replace app dependency with explicit boolean/layout inputs:
  - e.g., `applyConstraints`, `isExpandedLayout`, `maxWidth`.
- App decides expanded/compact using its own responsive logic.

Acceptance:
- `taskly_ui` has no dependency on app responsive utilities.

Status (Jan 2026): complete (`ContentConstraint` + `SliverContentConstraint`
are exported from `taskly_ui`).


### Phase 5 — Move reusable sections (parameterize strings + callbacks)

Likely candidates:
- `SettingsSectionCard`
- `IconPickerDialog` (ensure search labels/title are parameters)
- Filters widgets (if reused across screens)
- `FormShell` (remove app modal scope and responsive deps)

Approach:
- Make all user-facing strings parameters.
- Keep any screen-specific policies out (no routing, no BLoC reads).

Acceptance:
- Widgets are usable from multiple screens without importing app utilities.


### Phase 6 — Entities via view models (split adapters vs renderers)

Candidates that are currently domain-coupled:
- `ValueChip`, `ValuesFooter`, `EntityHeader`

Plan:
1) Extract render-only entity widgets into `taskly_ui` using UI models:
   - `ValueChipVm` (label, icon, color)
   - `EntityHeaderVm` (title, description, status flags, metadata slots)
2) Keep thin adapters in the app:
   - map `taskly_domain.Value/Project/...` to `*Vm`
   - supply localized strings from app l10n

Acceptance:
- `taskly_ui` does not depend on domain.
- Entities remain render-only and callback-driven.


### Phase 7 — Clean-up and documentation

Work:
- Ensure `taskly_ui` exports are organized by tier
  (optionally group exports in `taskly_ui.dart`).
- Remove any remaining app shared widgets that are now in `taskly_ui`.
- Add short guidelines to `doc/architecture` or to this doc if needed.

Acceptance:
- Clear ownership: shared UI lives in `taskly_ui`, screens/templates in app.


### Phase 8 — USM retirement and deletion (strategic track)

Scope:
- Migrate off the interpreted screen system (USM) and delete USM code.

Rules:
- Do not import USM code into `taskly_ui` to “help” this migration.
- Prefer explicit screens/pages and shared UI extracted into `taskly_ui`.

Work (suggested order):
1) Identify USM entrypoints and callers (routes/pages that instantiate USM).
2) Replace USM-driven flows with explicit pages and BLoC wiring.
3) Extract any reused UI discovered during conversion into `taskly_ui`.
4) Remove USM renderers/templates/spec language code once unused.

Acceptance:
- No code path in the app depends on USM for rendering screens.
- USM files are deleted (or reduced to empty stubs if an intermediate step is
  required), and `flutter analyze` remains clean.


## 8) File Move Mapping (initial targets)

> This is the initial candidate set; treat it as a backlog, not a mandate.

### 8.1 Phase 1: remove duplicates
- App → remove:
  - `lib/presentation/widgets/empty_state_widget.dart`
  - `lib/presentation/widgets/error_state_widget.dart`
  - `lib/presentation/widgets/loading_state_widget.dart`
- Use instead:
  - `packages/taskly_ui/lib/src/sections/*_state_widget.dart`

Status: complete (duplicates removed; app uses `taskly_ui` exports).

### 8.2 Phase 2–4: primitives
- Previously in app:
  - `lib/presentation/widgets/sliver_separated_list.dart`
  - `lib/presentation/widgets/swipe_to_delete.dart`
  - `lib/presentation/widgets/content_constraint.dart`
- Now in `taskly_ui` (exported via `packages/taskly_ui/lib/taskly_ui.dart`):
  - `packages/taskly_ui/lib/src/primitives/sliver_separated_list.dart`
  - `packages/taskly_ui/lib/src/primitives/swipe_to_delete.dart`
  - `packages/taskly_ui/lib/src/primitives/content_constraint.dart`

Status: complete.

### 8.3 Phase 5: sections
- `lib/presentation/widgets/settings_section_card.dart`
- `lib/presentation/widgets/icon_picker/icon_picker_dialog.dart`
- `lib/presentation/widgets/form_shell.dart`

Note: `SettingsSectionCard`, `IconPickerDialog`, and `FormShell` exist in
`taskly_ui` already; verify/clean up any remaining app-local versions and
imports as part of Phase 7.


## 9) Validation Checklist (per phase)

- Run `flutter analyze` and ensure no new warnings/errors.
- Ensure app imports use `package:taskly_ui/taskly_ui.dart` only.
- Ensure `taskly_ui` does not import app code, BLoC, domain/data.
- Ensure `taskly_ui` does not import any USM code.
- Spot-check UI behavior on one representative screen that uses the migrated
  widget(s).

Notes:
- Prefer small PR-sized phases (Phase 1 is an ideal first PR).


## 10) Risks and Mitigations

- Risk: Accidental dependency leaks into `taskly_ui`.
  - Mitigation: keep `taskly_ui` `pubspec.yaml` minimal; run analyze frequently.
- Risk: L10n regressions from parameterization.
  - Mitigation: provide required labels as parameters; add asserts/defaults.
- Risk: Duplicated “defaults” cause ambiguous imports or l10n leakage.
  - Mitigation: keep app-owned defaults (e.g., icon categories) in the app;
    `taskly_ui` consumes them via parameters.
- Risk: Theme divergence.
  - Mitigation: rely on Material 3 defaults first; add theme tokens only when
    necessary.


## 11) Proposed Execution Order (recommended)

1) Phase 5: promote/standardize 1–2 reusable sections (`SettingsSectionCard`,
  `IconPickerDialog`, `FormShell`) and remove any remaining app-local copies
2) Phase 7: clean up exports + remove remaining app shared widgets now in
  `taskly_ui`
3) Phase 6: start entity VM extraction for `ValueChip`

