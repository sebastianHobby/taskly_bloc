# Plan Phase 5: Severity-aware bell badge/halo (noticed, not overwhelming)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:58:47Z

## Goal

Implement severity-aware signaling for the global bell without layout shift:
- Fixed-size bell container.
- Badge + subtle halo varies by severity (warning vs critical).
- No animations that feel alarmist; prefer a stable ring or gentle emphasis.

Aligned decisions:
- [doc/plans/ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md](../../ui_decisions/2026-01-16_attention-surface-and-myday-calmness.md)
- [doc/plans/ui_decisions/2026-01-16_attention-placement-matrix.md](../../ui_decisions/2026-01-16_attention-placement-matrix.md)

## Scope

- Define thresholds and mapping using existing computed counts (e.g.
  `criticalCount`, `warningCount`) where available.
- Ensure the same mapping is used consistently across screens.

## Likely touch points

- AppBar bell widget implementation and any shared theme tokens.

## Acceptance criteria

- Bell shows:
  - no badge/halo at zero
  - warning style when warnings > 0 and critical == 0
  - critical style when critical > 0
- No layout shift when state changes.
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

## Completion

Completed at: 2026-01-16T00:58:47Z

Summary:
- Added `AttentionBellCubit` to compute `totalCount`/`warningCount`/`criticalCount` for the bell.
- Implemented `AttentionBellIconButton` with fixed sizing and severity-aware badge/halo with no layout shift.
- Wired the bell into shared app chrome (hidden on `review_inbox`) and registered the cubit in DI.
