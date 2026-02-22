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
- Journal history is not a separate screen; search and filters live on the main
  Journal feed.
- Journal home timeline supports infinite scroll by expanding the date window
  as the user reaches the end of the list.
- Journal home does not render a daily summary section.
- Tracker writes for a selected day must be anchored to that selected day (not
  the device's current day) for both entry writes and day-scoped factor writes.
- The editor renders factor inputs as two explicit sections with group
  accordions:
  - day-scoped factors ("All day")
  - entry-scoped factors ("Right now")
- Grouped factor input uses a strict single-open accordion policy per section
  to keep entry flow focused on one group at a time.
- Group ordering and tracker ordering are user-controlled and available from
  in-editor manage actions.
- Timeline factor summaries should be deduplicated per tracker so repeated
  edits do not produce duplicate chips for the same tracker.

## Testing minimums

- Threshold gating and suppression windows.
- Correct rendering conditions for review cards.
- Stats derivation from canonical inputs.
