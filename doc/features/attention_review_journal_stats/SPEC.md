# Attention, Review, Journal, And Statistics Spec

## Scope

Defines support signals, weekly review cards, journal integration, and stats contracts.

## Core rules

- Support prompts are meaningful, limited, and suppressible.
- Weekly review surfaces only high-signal items.
- Journal/statistics derive from stable event/snapshot contracts.

## Journal UX contract (current)

- Journal entry create and edit use a single route-backed editor surface.
- The editor supports selected-day creation from Journal home/day picker.
- Tracker writes for a selected day must be anchored to that selected day (not
  the device's current day) for both entry writes and day-scoped factor writes.
- The editor renders factor inputs as two explicit sections:
  - day-scoped factors ("All day")
  - entry-scoped factors ("Right now")
- Timeline factor summaries should be deduplicated per tracker so repeated
  edits do not produce duplicate chips for the same tracker.

## Testing minimums

- Threshold gating and suppression windows.
- Correct rendering conditions for review cards.
- Stats derivation from canonical inputs.
