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

### 5.1 Intent, not config (required)

For entity tiles and list rows (Task/Project/Value), the default pattern is:

- **Intent** describes *why* the tile is being shown (screen/flow).
- **Actions** describe what the user can do (callbacks opt into affordances).
- **Markers** describe small semantic facts that affect minor affordances.

Normative rules:

- Do not add visual/structural configuration knobs (for example “badge lists”,
  “trailing spec”, “variant flags”) to satisfy one-off screen needs.
- Prefer adding a new intent case when multiple screens truly need a distinct
  rendering intent.
- Prefer deriving affordances from the presence/absence of callbacks in the
  `*Actions` object (for example, show overflow only when an
  `onOverflowMenuRequestedAt` callback is provided).

See: `doc/architecture/ARCHITECTURE_INVARIANTS.md` (UI + `taskly_ui` rules).

### 5.2 Narrow extension points only (required)

To keep shared UI consistent across screens:

- Avoid “widget injection” parameters for entity tiles.
- Prefer strings and UI-only models (data-in) and callbacks (events-out).
- If an extension point is unavoidable, keep it narrow and semantically named
  (for example a `titlePrefix` widget) rather than exposing a full `trailing`
  builder API.
