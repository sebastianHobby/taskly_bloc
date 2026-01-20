# `taskly_ui` — Intent, Not Config (Normative)

> Audience: developers
>
> Purpose: keep entity tile rendering consistent across screens by expressing
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

Entity tiles expose three kinds of inputs:

- **Intent** (`*TileIntent`):
  - describes *why* the tile is shown (screen/flow)
  - chooses the canonical layout/structure

- **Actions** (`*TileActions`):
  - describes what the user can do
  - callback presence opts into affordances

- **Markers** (`*TileMarkers`, or model fields where appropriate):
  - small semantic facts that affect minor affordances
  - examples: pinned, selected

## 3) Normative rules

- Do not add new “knobs” like `badges`, `trailing`, or generic `variant` flags to
  satisfy one-off screen needs.

- Prefer making the intent explicit:
  - add a new intent case only when multiple consumers truly need a distinct
    rendering intent.

- Prefer deriving UI affordances from callback presence:
  - overflow button shown only when `onOverflowMenuRequestedAt` exists
  - completion toggle enabled only when `onToggleCompletion` exists

- Avoid widget injection parameters on entity tiles.
  - if an extension point is unavoidable, keep it narrow and semantically named
    (e.g. `titlePrefix`) rather than exposing full custom builders.

## 4) Package boundary rules

- App code must not deep-import `package:taskly_ui/src/...`.
- App code should prefer tiered entrypoints:
  - `package:taskly_ui/taskly_ui_entities.dart`
  - `package:taskly_ui/taskly_ui_sections.dart`

## 5) How to review changes

When modifying entity tiles or sections:

- Check whether the change can be expressed as intent/actions/markers.
- Reject new parameters that are visual configuration unless there is a strong,
  cross-screen justification.
- Document any new intent cases in the PR description and ensure at least two
  real consumers exist (or one consumer with a near-term planned second).
