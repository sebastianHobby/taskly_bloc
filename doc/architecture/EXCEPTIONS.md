# Architecture Exceptions

> Audience: developers + reviewers + AI agents
>
> Scope: the only acceptable way to temporarily violate a rule in
> [INVARIANTS.md](INVARIANTS.md) or a repo guardrail.

## 1) Policy

Taskly’s invariants exist to keep the codebase maintainable long-term.
If an invariant blocks progress, we allow a **narrow, temporary exception** —
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
