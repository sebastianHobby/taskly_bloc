# Plan Phase 3: Snooze persistence via Attention System suppression

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal

Make the My Day critical banner snooze align with the Attention System’s existing
suppression model (resolutions + runtime state), not widget-local state.

## Recommended approach

Preferred: **synthetic system AttentionRule** representing the global surface prompt.

- Add a system rule (e.g., rule key: `surface_prompt_critical_attention`).
- When user snoozes:
  - record an `AttentionResolution` with action `snoozed` and `action_details` containing `snooze_until`.
  - and/or update rule runtime state with `nextEvaluateAfter = snoozeUntil`.
- Banner visibility uses:
  - `criticalCount > 0`, AND
  - `now >= snoozeUntil` (or no active snooze record)

## Deterministic snooze presets

- `Later (2h)` => `now + 2h`
- `Later today (4h)` => `now + 4h`
- `Tomorrow morning` => next local 08:00 (if now < 08:00, today 08:00; else tomorrow 08:00)
- `Pick time…` => user selected local time

## Scope

- Implement storage for snooze state using attention persistence.
- Ensure banner reappears when snooze expires and critical remains.
- Ensure bell (UX101B) continues to show severity/count regardless of snooze.

## Non-goals

- Do not introduce modal interrupts.
- Do not add “break snooze on new critical” unless explicitly requested.

## Acceptance criteria

- Snooze survives app restart.
- Snooze correctly hides banner until chosen time.
- Banner returns after snooze expiration if critical items remain.
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
