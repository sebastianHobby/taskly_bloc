# WIP Plan — Phase 2: USM wiring + navigation entry points

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T06:45:00Z

## Purpose
Wire My Day’s new header/mix/list behavior into the USM pipeline with minimal blast radius.

## Scope constraints (locked)
- No new `ScreenTemplateSpec` for this work.
- Keep My Day on `ScreenTemplateSpec.standardScaffoldV1()`.
- Avoid My Day-only list shaping inside `_StandardScaffoldV1Template`; prefer a My Day-specific screen module + interpreter + dedicated `SectionVm` rendered through `SectionWidget`.
- Maintain the presentation boundary rule: UI triggers navigation via BLoCs; widgets do not access repositories.

## Planned changes
1) **My Day chrome simplification**
- In `SystemScreenSpecs.myDay` (in `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`):
  - Remove `AppBarAction.settingsLink` from `chrome.appBarActions`.
  - Remove `chrome.settingsRoute: 'focus_setup'` (My Day should not have settings/focus affordances in the app bar).
  - Keep `fabOperations: [FabOperation.createTask]`.
- In `_StandardScaffoldV1Template` (in `lib/presentation/screens/templates/screen_template_widget.dart`):
  - Remove the My Day focus-mode banner UI from the app bar (both the My Day-specific title subtitle and the `_MyDayFocusModeAction` action).
  - Keep (or relocate) `BlocProvider<MyDayHeaderBloc>` so the new in-body header can read focus mode and trigger navigation.

2) **Add a dedicated My Day primary module + interpreter (ARCH-001 B)**
- Add a new `ScreenModuleSpec` variant for the My Day ranked list section (name TBD but stable), e.g.:
  - `ScreenModuleSpec.myDayRankedTasksV1(...)`
- Update `SystemScreenSpecs.myDay` to select this module in the `primary` slot instead of relying on template-driven extraction of a generic `DataV2SectionResult`.
- Update the domain pipeline mapping so the new module routes to a typed interpreter that outputs a dedicated `SectionVm` variant, e.g.:
  - `SectionVm.myDayRankedTasksV1(...)`

Intent:
- The interpreter remains responsible for obtaining/producing the reactive section data needed to render the ranked list (tasks + stable IDs + rank/qualifying value IDs if available).
- Rendering stays inside the section rendering pipeline (`SectionWidget`), preserving section isolation and keeping templates lean.

## Locked naming decisions (stable contract)

These names are now locked so implementation stays consistent across domain → presentation.

### Module + interpreter
- `ScreenModuleSpec` variant: `myDayRankedTasksV1`
- Interpreter class: `MyDayRankedTasksV1ModuleInterpreter`
- Interpreter output `SectionVm` variant: `myDayRankedTasksV1`

### Presentation rendering
- Section widget/renderer: `MyDayRankedTasksV1Section`
  - Renders (top-to-bottom): Focus header card, Today’s mix, ranked task list.
  - Keeps only ephemeral UI-only state locally (row expansion, mix expand/collapse).

### Today’s mix computation (ARCH-002 B)
- Presentation BLoC: `MyDayRankedTasksV1Bloc`
  - Input: the `SectionVm.myDayRankedTasksV1` data.
  - Output: a widget-friendly `MyDayMixVm` (collapsed summary + expanded breakdown rows).
  - Must not read repositories/services.

Notes:
- The existing `MyDayHeaderBloc` remains the navigation source-of-truth for “Change focus mode”.
- The new `MyDayRankedTasksV1Bloc` is responsible only for derived presentation state (Today’s mix), not navigation.

3) **My Day header entry point (data + navigation only in this phase)**
- Reuse `MyDayHeaderBloc` (in `lib/presentation/screens/bloc/my_day_header_bloc.dart`) as the single source of truth for the current `FocusMode` and for the one-shot navigation request.
- The header widget itself will be implemented in later phases; for this phase the critical contract is:
  - My Day has an in-body place to host a header that can trigger `MyDayHeaderFocusModeBannerTapped`.
  - The template listens for `MyDayHeaderNav.openFocusSetupWizard` and performs navigation.

4) **Navigation contract: Change → focus mode step**
- Use query params on the existing focus setup system screen route.
- Contract:
  - Target screen: `focus_setup`
  - Query parameter: `step=select_focus_mode`
  - Example path: `/focus-setup?step=select_focus_mode`
- Implementation points:
  - My Day: update the listener in `_StandardScaffoldV1Template` to navigate via `Routing.toScreenKeyWithQuery(...)` with `{'step': 'select_focus_mode'}`.
  - Focus setup: teach the focus setup wizard to honor `step` when present.
    - Read the query parameter from `GoRouterState.of(context).uri.queryParameters['step']` inside `buildFocusSetupWizard()`.
    - Map strings to `FocusSetupWizardStep` (ignore unknown values).
    - Extend `FocusSetupEvent.started()` to accept an optional `initialStep`.
    - On start, set `state.stepIndex` to the index of `initialStep` within `state.steps` (fallback to `0` if missing/not present).

## Files likely involved
- `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
- `lib/presentation/screens/templates/screen_template_widget.dart`
- `lib/presentation/routing/routing.dart` (already supports query params via `toScreenKeyWithQuery`)
- `lib/domain/screens/language/models/screen_spec.dart` (if the module spec is defined here)
- `lib/domain/screens/runtime/screen_spec_data_interpreter.dart` (route new module -> interpreter)
- `lib/domain/screens/templates/interpreters/` (new My Day module interpreter)
- `lib/presentation/widgets/section_widget.dart` (render new `SectionVm` variant)
- `lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart` (add optional initial step handling)
- `lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart` (thread initial step into `FocusSetupEvent.started(...)`)
- `lib/presentation/screens/bloc/my_day_header_bloc.dart` (reuse existing event for the new header `Change` CTA)

## Acceptance criteria
- My Day app bar no longer includes settings/focus actions.
- My Day primary slot is backed by a My Day-specific module + interpreter outputting a dedicated `SectionVm` (no template-driven `DataV2SectionResult` extraction).
- My Day provides a My Day-only header entry point in the scroll body (implementation in later phases), backed by `MyDayHeaderBloc`.
- Tapping `Change` opens focus setup at the focus mode selection step via `focus_setup?step=select_focus_mode`.

## AI instructions
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- Maintain the presentation boundary rule: no repository access from widgets.
