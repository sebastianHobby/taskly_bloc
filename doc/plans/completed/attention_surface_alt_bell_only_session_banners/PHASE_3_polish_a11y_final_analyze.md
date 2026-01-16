# Plan Phase 3: Polish, a11y, final analyzer pass (last phase)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T02:24:35Z

## Goal

Polish banner visuals, ensure accessibility, and finish analyzer clean.

## Scope

- A11y:
  - semantics labels for bell, badge count, halo severity
  - banner semantics and button labels
  - tap target sizes
- Visual calmness:
  - stable height and spacing
  - non-alarmist tint choices
- Consistency:
  - use `Review` label consistently to navigate to inbox

## Acceptance criteria

- `flutter analyze` is clean.
- No layout shift for bell or banners.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- As this is the **last phase**, fix **any** `flutter analyze` error or warning (even if unrelated).
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: 2026-01-16T02:24:35Z

Summary:
- Added accessibility semantics for the attention bell and ensured analyzer remains clean.
