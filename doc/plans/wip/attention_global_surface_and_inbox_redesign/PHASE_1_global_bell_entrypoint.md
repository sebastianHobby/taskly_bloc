# Plan Phase 1: Global bell entrypoint (everywhere)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal

Implement the **global bell entrypoint** across the app chrome:
- Bell is present on navigation screens.
- Tap bell navigates directly to the Attention inbox (`review_inbox`).
- Bell is not shown on the inbox screen itself.

Aligned decisions:
- [doc/plans/ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md](../../ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md)
- [doc/plans/ui_decisions/2026-01-16_attention-placement-matrix.md](../../ui_decisions/2026-01-16_attention-placement-matrix.md)

## Scope

- Add an AppBar action (bell) consistently to:
  - `my_day`, `scheduled`, `someday`, `journal`, `values`, `statistics`, `settings`
- Ensure it is hidden on `review_inbox`.
- Wire navigation to the existing system screen `review_inbox`.

## Non-goals

- Do not implement the in-content summary strip in this phase.
- Do not redesign the Attention inbox UI in this phase.

## Likely touch points

- Presentation routing / screen template app bar actions:
  - `lib/presentation/screens/templates/screen_template_widget.dart`
  - routing helpers that navigate to system screens
- System screen specs (only if needed to expose a canonical route key):
  - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

## Acceptance criteria

- Bell appears on all navigation screens except `review_inbox`.
- Bell tap always navigates to `review_inbox`.
- No new analyzer issues introduced.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes.
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: 2026-01-16T00:00:00Z

Summary:
- Added a global AppBar bell action that navigates to `review_inbox`.
- Suppressed the bell on the inbox screen itself.
- Added the bell to non-USM placeholder templates/pages used in navigation
  (`statisticsDashboard`, Settings, Journal hub).
