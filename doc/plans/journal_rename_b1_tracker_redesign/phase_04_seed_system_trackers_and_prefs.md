# Phase 04 — Seed system trackers + default preferences

Created at: 2026-01-13T12:16:40Z
Last updated at: 2026-01-13T12:19:51Z

## Goal

Provide a stable initial set of system trackers (with `system_key`) and default user preferences so Journal is immediately useful after install/login.

## Scope

- Seeder in the data layer to upsert system tracker definitions.
- Default preferences creation (visibility/order/pinned/quick-add).
- Choice seeding for choice-based trackers.

## Concrete touchpoints / file targets

- Seeder location (suggested): `lib/data/features/journal/maintenance/journal_tracker_seeder.dart`
- Call site (existing pattern): on-authenticated maintenance in DI/startup (follow attention seeder style).

Related references for seeding patterns:

- [lib/data/attention/maintenance/attention_seeder.dart](../../../lib/data/attention/maintenance/attention_seeder.dart)
- [lib/core/di/dependency_injection.dart](../../../lib/core/di/dependency_injection.dart)

## Starter system tracker set (placeholder)

This plan intentionally does not lock the full list here, but the seeder should support at least:

- `mood` (required for log)
- `note` (optional; either stored as a journal entry note field or as a tracker event with text value)
- a small set of common quick-add trackers (sleep, exercise, meds, etc.) using the new constrained tracker type system.

## Constraints

- Respect DQ decisions (system patching semantics-only).
- Never overwrite user layout/preferences unless explicitly intended.

## Acceptance criteria

- Fresh user sees a sensible default tracker set.
- System updates can patch definitions safely.
- `flutter analyze` clean.

## AI instructions

- Review doc/architecture/ before implementing.
- Run `flutter analyze` for this phase.
- Fix any errors or warnings introduced (or discovered) by the end of the phase.

## Verification

- `flutter analyze`
