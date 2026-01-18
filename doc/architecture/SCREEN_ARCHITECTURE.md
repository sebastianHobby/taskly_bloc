# Screen Architecture (Future State)

> Audience: developers + architects
>
> Scope: the post-migration presentation architecture: explicit routes, explicit
> screens/pages, and BLoC-owned state/subscriptions.

## 1) Executive Summary

Future-state Taskly screens are built as **explicit Flutter pages** driven by
**presentation-owned BLoCs**.

Non-negotiable invariant:

- Widgets/pages must not talk to repositories directly and must not subscribe to
  domain/data streams directly. BLoCs own subscriptions and expose widget-ready
  state.

## 2) Routing

Routing should be **explicit** and deep-link friendly.

- Define concrete routes for top-level screens (e.g. `/my-day`, `/anytime`,
  `/scheduled`) and feature routes (e.g. `/settings/...`).
- Avoid convention-based catch-all routes that map arbitrary segments to a
  dynamic screen composition system.

## 3) Screen Composition Pattern

A typical screen has:

- A **Page widget** (UI layout, theming, navigation triggers)
- One or more **BLoCs** that:
  - read from domain/services/repositories
  - subscribe to reactive sources (DB watchers, streams)
  - expose state for rendering and drive side-effects via events
- Optional **child/section widgets** that render subsets of the BLoC state

This keeps data flow consistent and debuggable:

```text
UI events -> BLoC events -> domain/services/repositories
DB/reactive streams -> BLoC state -> widgets
```

## 3.1 Forms (FormBuilder-first preference)

All editor/detail screens should prefer `flutter_form_builder` for forms.

- The **widget** owns the `FormBuilder` key/state and composes field widgets.
- The **BLoC** owns entity subscriptions/snapshots, validation policy, and
  save/delete intents.
- Keep the widget → BLoC boundary strongly typed:
  - do not pass `Map<String, dynamic>` as the draft model
  - do not let raw string field names become a “protocol” into BLoCs

Rationale:
- Keeps validation + save flows consistent across entities.
- Keeps repositories/services out of widgets (BLoC boundary rule).

## 4) Cross-Feature Reuse

Reuse should come from **shared widgets/components** and **shared domain/data
services**, not from a runtime screen interpreter.

Recommended reuse mechanisms:

- Shared UI components in `packages/taskly_ui` (pure UI only; see below)
- Shared presentation components under `lib/presentation/...` when they are
  screen/feature-specific or still in the process of extraction
- Shared domain services/use-cases under `lib/domain/...` (or extracted packages)
- Shared repositories/contracts and implementations

## 4.2 UI composition model (4-tier) (strict)

All UI must use the same composition vocabulary:

- **Primitives**: tiny, style-driven building blocks with no domain meaning.
- **Entities**: render-only UI for a single domain concept, still “data in /
  events out”.
- **Sections**: composed, reusable chunks that group primitives/entities.
  Sections must remain presentation-agnostic (no routing/state).
- **Screens/Templates**: full pages and flows (routing, BLoC wiring, effects,
  feature orchestration).

Code placement is strict:

- Shared **Primitives / Entities / Sections** belong in `packages/taskly_ui`.
- **Screens/Templates** belong in the app presentation layer.

See the normative rule:
- [ARCHITECTURE_INVARIANTS.md](ARCHITECTURE_INVARIANTS.md) (section 2.2)

### 4.3 Shared UI package: `taskly_ui` (strict)

To reduce inconsistent look-and-feel and avoid ad-hoc cross-feature imports,
prefer extracting reusable UI building blocks into `packages/taskly_ui`.

Normative boundaries for `taskly_ui`:

- `taskly_ui` is **pure UI** (widgets + small UI helpers).
- `taskly_ui` must not contain BLoCs/Cubits, subscribe to domain/data streams,
  or call repositories/services/use-cases.
- `taskly_ui` must not perform navigation (no app routing, no `go_router`).
- Interactivity is expressed as **callbacks / UI events** that are handled by
  the app-owned screen/BLoC.

Package hygiene (recommended):

- App code should import only `package:taskly_ui/taskly_ui.dart`.
- Keep `taskly_ui` implementation private under `packages/taskly_ui/lib/src/`.

Taxonomy layout (strict):

- `packages/taskly_ui/lib/src/primitives/`
- `packages/taskly_ui/lib/src/entities/`
- `packages/taskly_ui/lib/src/sections/`
- (Reserved) `packages/taskly_ui/lib/src/templates/` for layout-only
  scaffolding that remains routing/state-free.

## 5) Errors and Empty States

- Prefer screen-specific error handling and retries in the BLoC.
- Use typed error states to keep rendering deterministic.

## 5.1 Mutations and OperationContext (strict)

User-initiated mutations must be correlated end-to-end using
`OperationContext`.

- Create the `OperationContext` in the BLoC handler where the user intent is
  interpreted (tap/submit/confirm).
- Pass `context` down through domain write APIs and into repository mutations.
- Ensure failures surfaced back to the BLoC preserve the context correlation id
  so logs and UI failures can be joined.

See the normative rule in:
- [ARCHITECTURE_INVARIANTS.md](ARCHITECTURE_INVARIANTS.md) (section: 8.1)

## 6) Legacy Note

Legacy USM concepts (spec-interpreted screens, template renderers, and
catch-all routing) are documented only in:

- [LEGACY_ARCHITECTURE_OVERVIEW.md](LEGACY_ARCHITECTURE_OVERVIEW.md)
