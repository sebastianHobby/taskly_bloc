# Architecture Exceptions

> Audience: developers + reviewers + AI agents
>
> Scope: the only acceptable way to temporarily violate a rule in
> [INVARIANTS.md](INVARIANTS.md) or a repo guardrail.

## 1) Policy

Taskly's invariants exist to keep the codebase maintainable long-term.
If an invariant blocks progress, we allow a **narrow, temporary exception** --
but only when it is explicitly documented and has an owner + expiry.

## 2) Rules

Canonical policy lives in: [INVARIANTS.md](INVARIANTS.md).

In practice:

- Any `ignore-*-guardrail` usage references an exception document under
  [exceptions/](exceptions/).
- Exception documents include:
  - an owner
  - a clear scope (which files/areas are affected)
  - a concrete removal plan
  - an expiry date
- Expired exceptions should be treated as bugs and removed or renewed.

## 3) Naming + template

- Naming: `EXC-YYYYMMDD-short-title.md`
- Template: [exceptions/EXCEPTION_TEMPLATE.md](exceptions/EXCEPTION_TEMPLATE.md)

## 4) Registry

See: [exceptions/README.md](exceptions/README.md)

## 5) Examples (format only)

Example A: temporary deep import while extracting a public API

- File: `exceptions/EXC-20260125-promote-domain-api.md`
- Scope: `lib/presentation/features/foo/...`
- Expiry: 2026-02-15
- Reason: needed for one release while `taskly_domain` public API is promoted
- Removal plan: expose the symbol via `taskly_domain.dart`, update call sites

Example B: legacy DI usage during refactor

- File: `exceptions/EXC-20260125-di-bridge.md`
- Scope: `lib/presentation/screens/legacy_bar_screen.dart`
- Expiry: 2026-02-01
- Reason: screen still uses a service locator pending BLoC migration
- Removal plan: add BLoC boundary and remove locator usage


