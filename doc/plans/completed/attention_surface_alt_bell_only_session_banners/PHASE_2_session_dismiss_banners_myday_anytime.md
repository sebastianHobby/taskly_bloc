# Plan Phase 2: Session-dismiss banners (My Day critical, Anytime warning+critical)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T02:23:35Z

## Goal

Implement on-enter banners with **session-scoped dismiss**:

- My Day (`my_day`): banner when `criticalCount > 0`.
- Anytime (`someday`): banner when `criticalCount > 0` OR `warningCount > 0`.
- Scheduled (`scheduled`): no banner.

## Behavior

- Banner includes `Review` (navigate to inbox) and `Dismiss`.
- `Dismiss` hides the banner until the app session ends.
- Bell remains the global indicator; dismiss does not affect counts/halo.

## Escalation styling (ALT-003A)

- Severity changes **icon + tint only**.
- No height/layout changes between warning and critical.

## Implementation notes

- BLoC owns streams and computes `maxSeverity` + counts.
- UX-ALT-101A: Session dismiss lives in an **app-session scoped** presentation store (not per-screen BLoC), so it survives navigating away/back and typical widget disposal.
- UX-ALT-102A: Banner renders at the **screen template level**, driven by `ScreenSpecBloc` state (avoid screen-specific widget forks).
- Avoid persisting dismiss to DB; do not write `AttentionResolution` for banner dismiss.

## Acceptance criteria

- My Day banner appears only for critical.
- Anytime banner appears for warning or critical.
- Dismiss hides banner until app restart (including if the user navigates away and returns in the same session).
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

Completed at: 2026-01-16T02:23:35Z

Summary:
- Added app-session scoped dismissal store and template-level on-enter banners for My Day (critical only) and Anytime (warning+critical), driven by `ScreenSpecBloc` state.
