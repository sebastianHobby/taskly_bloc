# Architecture Exceptions

> Audience: developers + reviewers
>
> Scope: the only acceptable way to temporarily violate an architecture invariant
> or repo guardrail.

Taskly’s invariants are intended to keep the codebase clean long-term. When an
invariant blocks progress, we allow a *narrow*, *temporary* exception — but only
when it is explicitly documented and has an owner and an expiry.

## Rules (strict)

- Any `ignore-*-guardrail` usage must reference an exception document in this
  folder.
- Exceptions must have:
  - an owner
  - a clear scope (which files/areas are affected)
  - a concrete removal plan
  - an expiry date
- Expired exceptions should be treated as bugs and removed or renewed.

## Naming

Use a short, grep-friendly filename:

- `EXC-YYYYMMDD-short-title.md`

Example:

- `EXC-20260118-legacy-domain-import.md`

## Template

Start from [EXCEPTION_TEMPLATE.md](EXCEPTION_TEMPLATE.md).
