# Plan Phase 2: My Day critical banner + Snooze A UI (UX-COPY-002)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal

On My Day (`my_day`):

- Remove the summary strip.
- Introduce a **critical-only** in-content banner that is **obvious but not alarming**.
- Banner is only hidden by:
  - `Review` (navigate to inbox), or
  - `Snooze` (time-based), or
  - `criticalCount == 0`

Copy must match UX-COPY-002.

## Copy (UX-COPY-002)

Banner:
- Title: “Something needs attention”
- Subtitle: “Critical items are waiting. Review or snooze for later.”
- Buttons: `Review`, `Snooze`

Snooze sheet:
- Title: “Snooze for later”
- Helper: “We’ll hide this banner until your chosen time.”
- Presets: `Later (2h)`, `Later today (4h)`, `Tomorrow morning`, `Pick time…`

## Scope

- Implement banner UI and states.
- Implement snooze picker UI and selection behavior.
- Wire `Review` to navigate to `review_inbox`.

## Non-goals

- Do not implement the persistence mechanism in this phase (Phase 3).
- Do not redesign the inbox.

## Acceptance criteria

- Banner appears when `criticalCount > 0` (subject to snooze suppression, Phase 3).
- Banner does not appear for warnings-only.
- Banner actions behave as specified.
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

Completed at: TBD

Summary:
- TBD
