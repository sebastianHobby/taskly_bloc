# Documentation Lifecycle

## Statuses

- `Draft`: incomplete or under active design.
- `Proposed`: ready for implementation review.
- `Implemented`: reflects current shipped behavior.
- `Deprecated`: replaced, pending archive move.
- `Archived`: historical, non-normative.

## Rules

- Active feature docs live under `doc/features/`.
- Architecture invariants stay in `doc/architecture/INVARIANTS.md` only.
- Superseded docs must move to `doc/archive/` in the same PR that introduces the replacement.
- Archived docs must include a pointer to their replacement.
