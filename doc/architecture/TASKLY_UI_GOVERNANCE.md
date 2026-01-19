# `taskly_ui` governance (normative)

> Audience: developers
>
> Purpose: keep shared UI evolution deliberate while allowing safe iteration.

## 1) Summary

Taskly follows a strict UI ownership rule:

- The app owns only **Screens/Templates**.
- All **Primitives / Entities / Sections** live in `packages/taskly_ui`.

This is a strict placement rule, not a preference:

- App code must not introduce new primitives/entities/sections (even if used
  only once within a single screen).
- If a screen needs a new UI building block, it must be created in
  `packages/taskly_ui` and then composed from the screen.

Because `taskly_ui` is consumed across many screens, changes to its public
surface are governed.

## 2) Definitions

- **Public surface**: anything a consumer can import and depend on, including:
  - exported widgets and models
  - constructor parameters and defaults
  - enums and variants
  - entrypoints (barrel exports)
  - accessibility semantics and user-visible strings

- **Shared-surface change**: any change that modifies the public surface or
  changes default visuals/interaction behavior.

- **Internal-only change**: a change that does not alter the public surface and
  does not change default visuals/behavior.

## 3) Requires explicit user approval

Any of the following require explicit user approval before implementation:

- Adding a new shared entity/section/template.
- Adding new public configuration options (constructor params, new exported
  models, new enums/variants, new entrypoints).
- Any breaking change or downstream migration requirement.
- Any change to default visuals or interaction behavior.
- Any change to accessibility semantics (labels/roles/reading order).

Expected approval packet (minimum):

- **Impact analysis**: list affected call sites and migration steps.
- **Contract statement**: what changes, what stays the same.
- **Decision record**: if this introduces a new shared pattern, record it in
  the PR description or under `doc/architecture/`.

## 4) Fast path allowed

These may proceed without explicit user approval:

- Internal refactors that do not change the public surface.
- Bugfixes that restore intended behavior without changing defaults.
- Performance improvements with no user-visible changes.

## 5) Configuration hygiene (required)

When changing `taskly_ui` entities/sections:

- Remove unused options and unused callback wiring.
- Avoid option creep: do not add new flags for one-off screen needs.
- Prefer well-named variants (models/enums) when configuration is legitimately
  needed across multiple consumers.
