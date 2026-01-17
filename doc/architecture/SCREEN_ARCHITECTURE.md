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

## 4) Cross-Feature Reuse

Reuse should come from **shared widgets/components** and **shared domain/data
services**, not from a runtime screen interpreter.

Recommended reuse mechanisms:

- Shared presentation components under `lib/presentation/...` (widgets,
  theming/extensions)
- Shared domain services/use-cases under `lib/domain/...` (or extracted packages)
- Shared repositories/contracts and implementations

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
