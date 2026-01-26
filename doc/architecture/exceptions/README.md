# Architecture Exceptions

> Audience: developers + reviewers
>
> Scope: the only acceptable way to temporarily violate an architecture invariant
> or repo guardrail.

Taskly's invariants are intended to keep the codebase clean long-term. When an
invariant blocks progress, we allow a *narrow*, *temporary* exception -- but only
when it is explicitly documented and has an owner and an expiry.

## How exceptions work

This folder is the tracking mechanism for temporary exceptions.

Canonical policy:

- [../INVARIANTS.md](../INVARIANTS.md) (guardrail escape hatch policy)

Practical expectations for an exception document:

- Owner
- Clear scope (which files/areas)
- Concrete removal plan
- Expiry date

## Naming

Use a short, grep-friendly filename:

- `EXC-YYYYMMDD-short-title.md`

Example:

- `EXC-20260118-legacy-domain-import.md`

## Template

Start from [EXCEPTION_TEMPLATE.md](EXCEPTION_TEMPLATE.md).


