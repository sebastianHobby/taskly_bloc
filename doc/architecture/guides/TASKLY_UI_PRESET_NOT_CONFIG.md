# `taskly_ui` — Preset, Not Config

> Audience: developers
>
> Purpose: keep entity row rendering consistent across screens by expressing
> layout via explicit presets rather than per-call-site visual configuration.

## 1) Why this exists

Taskly has many screens that render the same entities (tasks/projects/values)
with slightly different policies:

- what tapping does (open editor vs toggle selection)
- whether completion is allowed
- whether a picker pill is shown
- whether a bulk selection state is shown

Historically, these differences were expressed with knobs (badges, trailing
specs, variants). That approach scales poorly: each screen becomes a mini
renderer and shared UI drifts.

Presets keep a single canonical renderer in `taskly_ui`.

## 2) The pattern

Entity rows expose three kinds of inputs:

- **Preset** (`*RowPreset`):
  - describes which supported tile layout to render
  - each preset is a named, documented variant

- **Actions** (`*RowActions`):
  - describes what the user can do
  - callback presence opts into affordances

- **Markers** (`*RowMarkers`, or model fields where appropriate):
  - small semantic facts that affect minor affordances
  - examples: pinned, selected

## 3) Guidance

This is a descriptive guide. The canonical rules live in:

- [../INVARIANTS.md](../INVARIANTS.md#212-entity-rows-are-preset-driven-strict)
- [../INVARIANTS.md](../INVARIANTS.md#25-entity-tile-presets-and-catalog-strict)

Practical guidance when extending entity rows:

- Avoid adding new visual configuration knobs (for example `badges`, `trailing`,
  generic `variant` flags) to satisfy one-off screen needs.
- Prefer adding a new preset when multiple consumers need a distinct layout.
- Prefer deriving UI affordances from callback presence:
  - show picker actions only when `onToggleSelected` exists
  - enable completion only when `onToggleCompletion` exists
- Avoid widget injection parameters on entity rows.
  - if an extension point is unavoidable, keep it narrow and semantically named
    (e.g. `titlePrefix`) rather than exposing full custom builders.

## 4) Catalog requirement

Every preset must appear in the shared tile catalog (`TasklyTileCatalog`) so
the full surface is visible in one place.

## 5) Package boundaries

Prefer consuming shared UI via the feed entrypoint:

- `package:taskly_ui/taskly_ui_feed.dart`
