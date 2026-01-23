# `taskly_ui` — Intent, Not Config

> Audience: developers
>
> Purpose: keep entity row rendering consistent across screens by expressing
> semantics via intent/actions rather than per-call-site visual configuration.

## 1) Why this exists

Taskly has many screens that render the same entities (tasks/projects/values)
with slightly different policies:

- what tapping does (open editor vs toggle selection)
- whether completion is allowed
- whether an overflow menu is available
- whether a pinned indicator is shown

Historically, these differences were expressed with “knobs” (badges, trailing
specs, variants). That approach scales poorly: each screen becomes a mini
renderer and shared UI drifts.

The intent pattern keeps a single canonical renderer in `taskly_ui`.

## 2) The pattern

Entity rows expose three kinds of inputs:

- **Intent** (`*RowIntent`):
  - describes *why* the row is shown (screen/flow)
  - chooses the canonical layout/structure

- **Actions** (`*RowActions`):
  - describes what the user can do
  - callback presence opts into affordances

- **Markers** (`*RowMarkers`, or model fields where appropriate):
  - small semantic facts that affect minor affordances
  - examples: pinned, selected

## 3) Guidance

This is a descriptive guide. The canonical rules live in:

- [../INVARIANTS.md](../INVARIANTS.md#212-entity-rows-are-intent-driven-strict)
- [../INVARIANTS.md](../INVARIANTS.md#13-package-public-api-boundary-strict)

Practical guidance when extending entity rows:

- Avoid adding new visual configuration “knobs” (for example `badges`,
  `trailing`, generic `variant` flags) to satisfy one-off screen needs.
- Prefer making the intent explicit:
  - add a new intent case when multiple consumers truly need a distinct
    rendering intent.
- Prefer deriving UI affordances from callback presence:
  - show overflow only when `onOverflowMenuRequestedAt` exists
  - enable completion only when `onToggleCompletion` exists
- Avoid widget injection parameters on entity rows.
  - if an extension point is unavoidable, keep it narrow and semantically named
    (e.g. `titlePrefix`) rather than exposing full custom builders.

## 4) Package boundaries

Prefer consuming shared UI via the feed entrypoint:

- `package:taskly_ui/taskly_ui_feed.dart`

## 5) How to review changes

When modifying entity rows or sections:

- Check whether the change can be expressed as intent/actions/markers.
- Reject new parameters that are visual configuration unless there is a strong,
  cross-screen justification.
- Document any new intent cases in the PR description and ensure at least two
  real consumers exist (or one consumer with a near-term planned second).
