# Recurrence And Sync Contract

## Purpose

Canonical contract for recurrence occurrence keys, routine window keys, and sync-safe write behavior.

## Task occurrence keys

- Non-recurring tasks may use baseline null occurrence scope where applicable.
- Recurring task actions must target a derived local date occurrence key.
- UI must not derive occurrence keys ad-hoc.
- Repeating tasks and projects require an explicit start-date anchor. Legacy
  rows without start-date anchors must be repaired before recurrence
  reads/writes.

## Routine window keys

- `day`: local date key.
- `week`: Monday date of local week window.
- `fortnight`: first Monday of local 14-day window.
- `month`: first day of local month.

## Write requirements

- Recurrence-targeted writes must carry explicit scope keys.
- Multi-table recurrence writes must be atomic.
- User-initiated writes require `OperationContext` propagation.

## Sync constraints

- Local writes must follow PowerSync-safe patterns (no local UPSERT against view-backed tables).
- Conflict handling follows logging-first anomaly policy.
