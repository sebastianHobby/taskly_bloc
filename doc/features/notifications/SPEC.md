# Notifications Spec

## Scope

Defines local reminder and notification planning behavior, including Plan My Day reminder policies.

## Core rules

- Notification planning logic lives in domain services.
- Notification delivery setup remains infrastructure concern.
- Notification behavior must be safe under offline and delayed sync conditions.

## Current implemented area

- Plan My Day reminder planning service contracts and time calculations.

## Testing minimums

- Reminder scheduling windows.
- Time-zone/local-day boundary behavior.
- Idempotent planning behavior.
