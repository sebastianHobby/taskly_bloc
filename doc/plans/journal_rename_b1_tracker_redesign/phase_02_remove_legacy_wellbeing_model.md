# Phase 02 — Remove legacy journal/tracker model (wellbeing v1)

Created at: 2026-01-13T12:16:40Z
Last updated at: 2026-01-13T12:19:51Z

## Goal

Delete the legacy wellbeing v1 data model (daily tracker responses + per-entry tracker responses) and its UI/BLoC/repository/persistence wiring so the codebase no longer supports the old model.

This phase intentionally focuses on **deletion + isolation** and should leave the app compiling with placeholders where needed.

## Scope

### In scope (expected deletions)

- Domain models under `lib/domain/wellbeing/model/**` (after Phase 01 rename, these should become `domain/journal/model/**`, then removed).
- UI flows built around:
  - `DailyTrackerResponse`
  - `TrackerResponseValue`
  - `TrackerEntryScope` (all-day vs per-entry)
  - tracker management CRUD tied to the old schema
- Repository and persistence:
  - Drift tables `daily_tracker_responses`, `tracker_responses` (and any legacy journal entry table shape that embeds per-entry responses)
  - PowerSync client schema entries and upload normalizer entries for these tables
  - ID generator helpers for those tables

### In scope (required replacements)

- Introduce/finish the new event-log tracker model plumbing based on the already-migrated Supabase schema:
  - `tracker_definitions`
  - `tracker_preferences`
  - `tracker_definition_choices`
  - `tracker_events`
  - projections (`tracker_state_day`, `tracker_state_entry`) if present
- Replace repository contract with an interface aligned to the new model (read/write via events and projection reads).

### Out of scope

- Building the final B1 “Today/History/Trackers” UI (Phase 03).
- Insights calculations beyond placeholder surface (Phase 04/05).

## Implementation notes

## Decision: tracker model option

This plan assumes **OPT-A**:

- Use `tracker_events` as the append-only write model.
- Maintain projections for fast UI reads:
  - `tracker_state_day`
  - `tracker_state_entry`

Note: Supabase is assumed to already have the required tables. Repo Supabase
migrations can be ignored for this plan.

## Current state (observed)

- The legacy model exists end-to-end:
  - domain models: `DailyTrackerResponse`, `TrackerResponseValue`, `TrackerEntryScope`, `JournalEntry`, `Tracker`
  - UI: tracker fields in FormBuilder, daily tracker section, journal timeline/cards
  - repository: a wellbeing repository that reads/writes legacy Drift tables
  - persistence: PowerSync client schema includes `tracker_responses` and `daily_tracker_responses` and upload normalization supports them

The goal of this phase is to delete these surfaces, then replace with the event-log tracker model.

### 1) Persistence consistency (PowerSync + Drift)

Goal: make the **local** schema (PowerSync client + Drift) match the already-
updated Supabase schema for OPT-A.

- Update PowerSync client schema (required):
  - remove legacy tables: `trackers`, `tracker_responses`, `daily_tracker_responses`
  - add new tracker tables (and projections):
    - `tracker_definitions`
    - `tracker_preferences`
    - `tracker_definition_choices`
    - `tracker_events`
    - `tracker_state_day`
    - `tracker_state_entry`
- Update Drift DB tables (required):
  - remove legacy wellbeing-v1 tables
  - add new Drift tables matching the new tracker tables/projections
- Ensure upload normalizer does not reference deleted legacy tables.

Concrete touchpoints:

- PowerSync client schema + upload:
  - [lib/data/infrastructure/powersync/schema.dart](../../../lib/data/infrastructure/powersync/schema.dart) (remove `tracker_responses`, `daily_tracker_responses`; add new tracker tables)
  - [lib/data/infrastructure/powersync/upload_data_normalizer.dart](../../../lib/data/infrastructure/powersync/upload_data_normalizer.dart) (remove normalizers for legacy tables; add/verify new table normalization needs)
  - [lib/data/infrastructure/powersync/api_connector.dart](../../../lib/data/infrastructure/powersync/api_connector.dart) (remove special-casing/known table lists if present)

- Drift:
  - [lib/data/infrastructure/drift/features/wellbeing_tables.drift.dart](../../../lib/data/infrastructure/drift/features/wellbeing_tables.drift.dart) (delete legacy tables)
  - [lib/data/infrastructure/drift/drift_database.dart](../../../lib/data/infrastructure/drift/drift_database.dart) (remove wellbeing table registrations/imports; add new tracker tables)

- ID generation:
  - [lib/data/id/id_generator.dart](../../../lib/data/id/id_generator.dart) (remove legacy table names + `dailyTrackerResponseId` etc)

### 2) UI + feature removal

- Remove legacy screens/widgets (post-rename they live under `presentation/features/journal/**` but are still the legacy implementation).
- Replace with minimal placeholder screens/routes so navigation still works.

Concrete touchpoints (legacy UI to delete after Phase 01 rename):

- Feature folder: `lib/presentation/features/journal/**` (previously wellbeing)
- Shared form fields tied to legacy types:
  - [lib/presentation/widgets/form_fields/form_builder_mood_field.dart](../../../lib/presentation/widgets/form_fields/form_builder_mood_field.dart)
  - [lib/presentation/widgets/form_fields/form_builder_mood_rating_field.dart](../../../lib/presentation/widgets/form_fields/form_builder_mood_rating_field.dart)
  - [lib/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart](../../../lib/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart)

If any of these widgets remain useful for B1, they should be rewritten against the new tracker event value types rather than kept as compatibility wrappers.

### 3) Data migration strategy

- Data is not automatically migrated from legacy local tables to `tracker_events` in this phase.
- If a local migration is required for continuity, scope it explicitly as Phase 04.

## Delta checklist (what to delete vs keep)

Delete (legacy model):

- Domain models (all tied to daily/per-entry response split):
  - `DailyTrackerResponse`
  - `TrackerResponse`
  - `TrackerResponseValue`
  - `TrackerResponseConfig`
  - `TrackerEntryScope`
  - legacy `JournalEntry` shape if it embeds `perEntryTrackerResponses`

Delete (legacy persistence):

- Local tables and sync schema for:
  - `tracker_responses`
  - `daily_tracker_responses`

Keep (conceptually, but re-implement):

- Mood, notes, and timestamped entries remain, but data shape becomes “log event + tracker_events”.
- Tracker definitions remain, but stored as `tracker_definitions` + `tracker_definition_choices` + `tracker_preferences`.

## Verification

- `flutter analyze`

## Acceptance criteria

- No code remains that references:
  - `DailyTrackerResponse`
  - `TrackerResponseValue`
  - `TrackerEntryScope`
  - legacy drift/powersync tables (`daily_tracker_responses`, etc)
- App compiles.
- `flutter analyze` is clean.

## AI instructions

- Review doc/architecture/ before implementing.
- Run `flutter analyze` for this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If changes affect sync/persistence architecture, update doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md.
