# Editor boilerplate strategy gap (no codegen)

Created at: 2026-01-13 (UTC)
Last updated at: 2026-01-13 (UTC)

## Context

The editor/detail contracts expect consistent patterns across entities:

- `*Draft` state in the editor
- `Create*Command` / `Update*Command` on save
- typed/stable field keys (no ad-hoc string literals)
- structured validation errors mapped to UI field errors
- a reusable `*FormModule` per entity (fields-only; template owns actions)

A previously stated idea was to have the repo generate boilerplate for these
editors.

## Design gap

There is currently **no committed, implemented, or planned mechanism** that
explains how the required editor boilerplate is produced consistently across
entities.

We also explicitly do **not** want to introduce code generation for this.

## Why it matters

Without a clear approach, editor work risks:

- inconsistency in field key naming
- duplicated glue code (draft plumbing, error mapping)
- fragile validation mapping and tests
- divergence across task/project/value and future entities

## Non-codegen options (follow-up candidates)

Pick one approach (or a small combination) and document it as the standard.

### Option A — “Manual, but standardized” (docs + checklists)

- Add a per-entity checklist to the plan/docs: Draft, FieldKeys, Commands,
  ValidationError mapping, FormModule, Template actions, tests.
- Provide a canonical example implementation (task/project/value) that future
  entities copy.

### Option B — Shared helper library (reduce glue)

Introduce small, reusable utilities (not codegen) such as:

- a common field-key type/pattern (e.g., sealed keys + `.name`)
- a shared validation error model shape + mapper helpers
- helpers to apply domain errors to FormBuilder fields consistently

### Option C — IDE snippets / templates (developer tooling, not generation)

- Provide VS Code snippets for Draft/Command/FieldKeys/FormModule skeletons.
- Keep them as editor-only productivity tools (no build integration).

### Option D — Minimal base widgets/adapters

- Provide a base “editor template” widget that wires standard save/cancel/error
  presentation.
- Entities supply only: form module, save callback, and error mapping.

## Recommendation

Default to Option A + B:

- Make the standard explicit (docs/checklist + examples).
- Add small helper utilities where they reduce repetition without hiding
  behavior.

## Next steps

- Decide which option(s) are the official standard.
- Update the ED/RD plan Phase 02 to explicitly state the chosen strategy.
- Ensure task/project/value implementations conform and become the reference.
