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
- Journal home is summary-first:
  - "Your Day" card first (selected day summary),
  - chronological timeline feed second (newest first),
  - one top insight card third when thresholds are met.
- Journal supports multiple entries per day; entry identity is `journal_entries.id`
  and edits are ID-targeted (never day-level upsert/merge by `entry_date`).
- Journal history is not a separate screen; search and filters live on the main
  Journal feed.
- Journal home timeline supports infinite scroll by expanding the date window
  as the user reaches the end of the list.
- Journal uses strict hybrid semantics:
  - day-scoped factors (daily card) are one-per-day state,
  - moment logs remain multi-entry-per-day.
- Tracker writes for a selected day must be anchored to that selected day (not
  the device's current day) for both entry writes and day-scoped factor writes.
- The editor renders one grouped tracker accordion list.
- Day-scoped factors are shown in a special first category:
  "Daily check-ins".
- Entry-scoped factors are shown in the regular user groups (including
  "Ungrouped").
- Grouped factor input uses a strict single-open accordion policy across the
  full tracker list to keep entry flow focused on one group at a time.
- Group ordering and tracker ordering are user-controlled and available from
  in-editor manage actions.
- Timeline factor summaries should be deduplicated per tracker so repeated
  edits do not produce duplicate chips for the same tracker.
- Daily check-ins and trackers are managed from one tabbed management surface
  (Factors / Groups).
- The entry editor renders daily check-ins in a pinned first card with
  "applies to today" semantics, and renders trackers in separate "for this
  log" sections.
- Mood is required before a moment log can be saved.
- Journal home filters support:
  - date presets/range,
  - factor filters,
  - optional factor-group filter.
- Journal home does not support minimum mood threshold filtering.
- Timeline density supports compact and rich modes; compact is the default.
- Timeline boolean chips do not use "Done"; they render only the tracker label
  when logged/true.
- Timeline quantity chips render day totals (aggregated across the day) rather
  than per-entry deltas.
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
