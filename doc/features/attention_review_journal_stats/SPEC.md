# Attention, Review, Journal, And Statistics Spec

## Scope

Defines support signals, weekly review cards, journal integration, and stats contracts.

## Core rules

- Support prompts are meaningful, limited, and suppressible.
- Weekly review surfaces only high-signal items.
- Journal/statistics derive from stable event/snapshot contracts.

## Journal UX contract (current)

- Journal entry create and edit use a single route-backed editor surface.
- Journal home quick capture uses a modal bottom-sheet editor optimized for
  rapid logging; full-screen route edit/create remains available for detailed
  edits.
- Journal home is summary-first for **today**:
  - "Your Day" card first (today summary with full day factors),
  - moments list second (today only, newest first),
  - one top insight card third when thresholds are met.
- Journal supports multiple entries per day; entry identity is `journal_entries.id`
  and edits are ID-targeted (never day-level upsert/merge by `entry_date`).
- Journal history is a **separate screen**:
  - journal home focuses on today only,
  - history owns search + filters + date range selection,
  - history results are a day list (newest first).
- Journal has a dedicated Insights screen (`/journal/insights`) for expanded
  evidence cards; journal home still shows the top insight card (or nudge) as
  the summary-first entry point.
- Journal history supports infinite scroll by expanding the date window
  as the user reaches the end of the list.
- Journal uses moment-first semantics:
  - all tracker values are recorded on moment entries,
  - daily summary aggregates are derived from per-entry tracker events.
- Default daily summary includes mood and energy averages plus sleep duration
  and sleep quality (recorded once per day).
- Tracker writes for a selected day must be anchored to that selected day (not
  the device's current day) for entry writes.
- The editor renders one grouped tracker accordion list.
- Tracker inputs are grouped by user-defined groups (including "Ungrouped").
- Grouped factor input uses a strict single-open accordion policy across the
  full tracker list to keep entry flow focused on one group at a time.
- Group ordering and tracker ordering are user-controlled and available from
  in-editor manage actions.
- Timeline factor summaries should be deduplicated per tracker so repeated
  edits do not produce duplicate chips for the same tracker.
- Trackers and groups are managed from one tabbed management surface
  (Trackers / Groups).
- Mood is required before a moment log can be saved.
- Journal history filters support:
  - date presets/range,
  - factor filters,
  - optional factor-group filter,
  - search text (matches moment text for a day).
- Journal does not support minimum mood threshold filtering.
- History day cards:
  - show date + mood average (numeric) when available.
  - show a summary of **day factors with values**.
  - hide empty/unset factors behind inline expand ("View more").
  - show the latest moment text preview (if any).
  - tap card opens day detail.
- Day detail:
  - shows full day factors list (including unset values),
  - shows all moments for the day,
  - tapping a moment opens the existing editor route for that moment.
- Insight contract:
  - show top insight only when thresholds are met (sample >= 10 and medium
    effect size),
  - if not met, show a single onboarding nudge card,
  - copy must use association language (not causation claims),
  - evidence metadata must include confidence, sample size, and time window.

## Testing minimums

- Threshold gating and suppression windows.
- Correct rendering conditions for review cards.
- Stats derivation from canonical inputs.

## PMD debug stats surface contract

- A debug-only developer stats surface may expose PMD behavior metrics (keep,
  defer, remove, snooze, completed) derived from canonical event facts.
- This surface is non-production and must be gated behind debug mode.
- PMD behavior metrics consume append-only behavior telemetry and existing
  outcome facts; no replacement of canonical execution tables.

Detailed implementation spec:

- `doc/features/my_day_plan_my_day/PMD_DECISION_EVENTS_DEBUG_STATS_SPEC.md`
