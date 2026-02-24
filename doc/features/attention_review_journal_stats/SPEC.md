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
- Journal home is a single chronological timeline feed (newest first) grouped
  by day headers with compact metadata (entry count + mood average).
- Journal supports multiple entries per day; entry identity is `journal_entries.id`
  and edits are ID-targeted (never day-level upsert/merge by `entry_date`).
- Journal history is not a separate screen; search and filters live on the main
  Journal feed.
- Journal home timeline supports infinite scroll by expanding the date window
  as the user reaches the end of the list.
- Journal home does not render a daily summary section.
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
- Daily check-ins are a distinct user concept from trackers:
  - Daily check-ins are managed on a dedicated management surface.
  - Trackers are managed on a separate management surface.
  - Both daily check-ins and trackers appear in the entry editor.
- The entry editor renders daily check-ins in a pinned first card with
  "applies to today" semantics, and renders trackers in separate "for this
  log" sections.
- Timeline boolean chips do not use "Done"; they render only the tracker label
  when logged/true.
- Timeline quantity chips render day totals (aggregated across the day) rather
  than per-entry deltas.

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
