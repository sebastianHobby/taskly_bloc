# Plan Phase 4: Polish, a11y, and final analyzer pass (final phase)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal

Finish the feature with UI polish and accessibility checks, and ensure the repo
is analyzer-clean.

## Scope

- Visual consistency across:
  - Anytime summary strip (global, not filter-scoped)
  - My Day critical banner (obvious but not alarming)
- A11y:
  - semantics labels for bell/badge/halo
  - button labels and tap targets
  - dynamic text scaling sanity check
- Final pass on wording consistency (`Review`, `Snooze`, inbox screen title).

## Acceptance criteria

- No layout shift from bell halo/badge.
- Banner/summary collapse animations are calm and do not jitter.
- `flutter analyze` clean.

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

Completed at: TBD

Summary:
- TBD
