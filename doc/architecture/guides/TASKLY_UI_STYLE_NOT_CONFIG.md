# 	askly_ui — Style, Not Config

> Audience: developers
>
> Purpose: keep entity row rendering consistent across screens by expressing
> layout via documented styles and letting the row data carry semantic facts
> instead of per-call-site visual configuration.

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

Styles keep a single canonical renderer in 	askly_ui.

## 2) The pattern

Entity rows expose three kinds of inputs:

- **Style** (*RowStyle):
  - describes which supported tile layout to render
  - each style is a named, documented variant that maps to the shared
    renderer

- **Actions** (*RowActions):
  - describes what the user can do
  - callback presence opts into affordances

- **Row data semantics** (*RowData):
  - carries the small semantic facts that affect affordances (for example
    pinned, primaryValueIconOnly)
  - keeps these facts explicit rather than re-introducing ad-hoc knobs

## 3) Guidance

This is a descriptive guide. The canonical rules live in:

- [../INVARIANTS.md](../INVARIANTS.md#212-entity-rows-are-style-driven-strict)
- [../INVARIANTS.md](../INVARIANTS.md#25-entity-tile-styles-and-catalog-strict)

Practical guidance when extending entity rows:

- Avoid adding new visual configuration knobs (for example adges, 	railing,
  generic ariant flags) to satisfy one-off screen needs.
- Prefer adding a new style when multiple consumers need a distinct layout.
- Prefer deriving UI affordances from callback presence:
  - show picker actions only when onToggleSelected exists
  - enable completion only when onToggleCompletion exists
- Avoid widget injection parameters on entity rows.
  - if an extension point is unavoidable, keep it narrow and semantically named
    (e.g. 	itlePrefix) rather than exposing full custom builders.

## 4) Catalog requirement

Every style must appear in the shared tile catalog (TasklyTileCatalog) so
its visual surface is visible in one place.

## 5) Package boundaries

Prefer consuming shared UI via the feed entrypoint:

- package:taskly_ui/taskly_ui_feed.dart
