# Agent Start Here

Use this sequence before non-trivial changes.

1. Read `doc/architecture/README.md`.
2. Open `doc/agents/PATH_TO_SPEC_MAP.md` and find the impacted feature spec.
3. Read only the relevant feature spec(s) under `doc/features/`.
4. Read `doc/architecture/INVARIANT_INDEX.md`, then read only the relevant sections in `doc/architecture/INVARIANTS.md`.
5. If changing architecture boundaries, update architecture docs in the same PR.
6. Run checks:
   - `dart run tool/guardrails.dart`
   - `dart analyze`
   - Relevant tests for changed areas

## Decision rules

- If a requirement conflicts with an invariant, do not implement directly.
- Add a documented exception under `doc/architecture/exceptions/` first.
- Treat archived docs as context only, not source of truth.
