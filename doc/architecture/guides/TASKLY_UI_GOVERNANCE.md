# `taskly_ui` governance

> Audience: developers
>
> Purpose: keep shared UI evolution deliberate while allowing safe iteration.

## 1) Summary

Taskly follows a UI ownership rule:

- The app owns only **Screens/Templates**.
- All **Primitives / Entities / Sections** live in `packages/taskly_ui`.

This guide is descriptive. The canonical rules live in:

- [../INVARIANTS.md](../INVARIANTS.md#22-ui-composition-model-4-tier-strict)
- [../INVARIANTS.md](../INVARIANTS.md#221-taskly_ui-shared-surface-governance-strict)

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

## 3) Changes that typically need explicit approval

Any of the following typically require explicit user approval before implementation:

- Adding a new shared entity/section/template.
- Adding a new tile preset or changing an existing preset's visuals/behavior.
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

## 5) Configuration hygiene

When changing `taskly_ui` entities/sections:

- Remove unused options and unused callback wiring.
- Avoid option creep: do not add new flags for one-off screen needs.

### 5.1 Presets, not config

For entity rows (Task/Project/Value), the default pattern is:

- **Preset** describes *which supported tile layout* to render.
- **Actions** describe what the user can do (callbacks opt into affordances).
- **Markers** describe small semantic facts that affect minor affordances.

See: [../INVARIANTS.md](../INVARIANTS.md#25-entity-tile-presets-and-catalog-strict).

### 5.2 Narrow extension points only

To keep shared UI consistent across screens:

- Avoid “widget injection” parameters for entity rows.
- Prefer strings and UI-only models (data-in) and callbacks (events-out).
- If an extension point is unavoidable, keep it narrow and semantically named
  (for example a `titlePrefix` widget) rather than exposing a full `trailing`
  builder API.

### 5.3 Tile catalog requirement

All task/project/value tile presets must be represented in the shared catalog
widget (`TasklyTileCatalog`) so the complete surface is visible in one place.
