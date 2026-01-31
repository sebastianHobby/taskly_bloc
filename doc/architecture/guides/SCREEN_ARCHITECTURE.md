# Screen Architecture 

> Audience: developers + architects
>
> Scope: the post-migration presentation architecture: explicit routes, explicit
> screens/pages, and BLoC-owned state/subscriptions.

## 1) Executive Summary

Future-state Taskly screens are built as **explicit Flutter pages** driven by
**presentation-owned BLoCs**.

Canonical boundary:

- [../INVARIANTS.md](../INVARIANTS.md#2-presentation-boundary-bloc-only)

## 2) Routing

Routing should be **explicit** and deep-link friendly.

- Define concrete routes for top-level screens (e.g. `/my-day`, `/anytime`,
  `/scheduled`) and feature routes (e.g. `/settings/...`).
- Use a single `MaterialApp.router`; splash/auth/main are routes gated via
  router redirects rather than swapping entire app shells.
- Avoid convention-based catch-all routes that map arbitrary segments to a
  dynamic screen composition system.
- See [NAVIGATION_AND_SCREEN_KEYS.md](NAVIGATION_AND_SCREEN_KEYS.md) for
  screen-key conventions and app shell behavior.

Naming note:
- The Anytime screen is implemented under the historical system screen key
  `someday`, but the canonical route path is `/anytime` (see
  `doc/product/SCREEN_PURPOSE_CONCEPTS.md`).

## 3) Screen Composition Pattern

A typical screen has:

- A **Page widget** (UI layout, theming, navigation triggers)
- One or more **BLoCs** that:
  - read from domain/services/repositories
  - subscribe to reactive sources (DB watchers, streams)
  - expose state for rendering and drive side-effects via events
- Optional **presentation query services** that:
  - combine multiple streams into a single derived stream for the screen
  - encode repeatable presentation policy (sectioning, debouncing, paging)
  - remain side-effect free (no writes, no routing)
- Optional **child widgets** that render subsets of the BLoC state.
  - Under the UI ownership rule, these should not become app-owned
    primitives/entities/sections. Prefer composing `taskly_ui` components
    directly in the screen.

This keeps data flow consistent and debuggable:

```text
UI events -> BLoC events -> domain/services/repositories
DB/reactive streams -> BLoC state -> widgets
```

Design intent:

- BLoCs are thin orchestrators: interpret user intent, start/stop subscriptions,
  map domain outputs into renderable state, and drive side-effects.
- Domain owns business semantics; presentation owns screen-shaped policy.

## 3.1 Forms (FormBuilder-first preference)

All editor/detail screens should prefer `flutter_form_builder` for forms.

- The **widget** owns the `FormBuilder` key/state and composes field widgets.
- The **BLoC** owns entity subscriptions/snapshots, validation policy, and
  save/delete intents.
- Keep the widget -> BLoC boundary strongly typed:
  - do not pass `Map<String, dynamic>` as the draft model
  - do not let raw string field names become a "protocol" into BLoCs
- Use domain validator helpers (`*Validators`) via presentation adapters for
  all field validation to keep UI behavior aligned with domain rules.

Rationale:
- Keeps validation + save flows consistent across entities.
- Keeps repositories/services out of widgets (BLoC boundary rule).

## 4) Cross-Feature Reuse

Reuse should come from **shared widgets/components** and **shared domain/data
services**, not from a runtime screen interpreter.

Recommended reuse mechanisms:

- Shared UI components in `packages/taskly_ui` (pure UI only)
- Prefer extracting non-trivial reusable UI blocks into `packages/taskly_ui`
  instead of creating app-owned primitives/entities/sections.
- Shared domain services/use-cases under `packages/taskly_domain/lib/src/...`
  (or app-specific domain in `lib/domain/...` when present)
- Presentation query services when reuse is screen-shaped (reactive composition,
  sectioning, pagination mechanics) but not business semantics.
- Shared repositories/contracts and implementations

## 4.2 UI composition model (4-tier)

All UI uses the same composition vocabulary:

- **Primitives**: tiny, style-driven building blocks with no domain meaning.
- **Entities**: render-only UI for a single domain concept, still "data in /
  events out".
- **Sections**: composed, reusable chunks that group primitives/entities.
  Sections stay presentation-agnostic (no routing/state).
- **Screens/Templates**: full pages and flows (routing, BLoC wiring, effects,
  feature orchestration).

Placement and boundaries (canonical):

- [../INVARIANTS.md](../INVARIANTS.md) (UI composition + `taskly_ui` boundary)

### 4.3 Shared UI package: `taskly_ui`

To reduce inconsistent look-and-feel and avoid ad-hoc cross-feature imports,
prefer extracting reusable UI building blocks into `packages/taskly_ui`.

Boundaries for `taskly_ui` are defined in:

- [../INVARIANTS.md](../INVARIANTS.md) (`taskly_ui` boundary)
- [TASKLY_UI_GOVERNANCE.md](TASKLY_UI_GOVERNANCE.md) (how to evolve shared UI)

For entity rows, the default approach is **preset, not config**:

- pass a `*TileIntent` to describe the screen/flow,
- pass a `*TileActions` object and let callback presence opt into affordances.

See: [TASKLY_UI_STYLE_NOT_CONFIG.md](TASKLY_UI_STYLE_NOT_CONFIG.md)

Package hygiene (recommended):

- App code should import one of the curated public entrypoints (and avoid
  `package:taskly_ui/src/...` deep imports):
  - `package:taskly_ui/taskly_ui_feed.dart` (feed schema + renderer)
  - `package:taskly_ui/taskly_ui_sections.dart` (dialogs/overlays)
  - `package:taskly_ui/taskly_ui_models.dart` (UI-only models)
  - `package:taskly_ui/taskly_ui_forms.dart` (template-like form chrome only)
- Keep `taskly_ui` implementation private under `packages/taskly_ui/lib/src/`.

Taxonomy layout (recommended):

- `packages/taskly_ui/lib/src/primitives/`
- `packages/taskly_ui/lib/src/entities/`
- `packages/taskly_ui/lib/src/sections/`
- (Reserved) `packages/taskly_ui/lib/src/templates/` for layout-only
  scaffolding that remains routing/state-free.

Governance:

- The app owns only Screens/Templates; primitives/entities/sections live in
  `packages/taskly_ui`.
- Shared-surface changes (new exports/options, default visual/interaction
  changes) require explicit user approval; internal-only refactors/bugfixes are
  allowed via fast path.

See: [../INVARIANTS.md](../INVARIANTS.md) (`taskly_ui` boundary)

## 5) Errors and Empty States

- Prefer screen-specific error handling and retries in the BLoC.
- Use typed error states to keep rendering deterministic.

## 5.1 Mutations and OperationContext (strict)

User-initiated mutations are correlated end-to-end using `OperationContext`.

- Create the `OperationContext` in the BLoC handler where the user intent is
  interpreted (tap/submit/confirm).
- Pass `context` down through domain write APIs and into repository mutations.
- Ensure failures surfaced back to the BLoC preserve the context correlation id
  so logs and UI failures can be joined.

See the canonical rule in:
- [../INVARIANTS.md](../INVARIANTS.md) (OperationContext write correlation)




