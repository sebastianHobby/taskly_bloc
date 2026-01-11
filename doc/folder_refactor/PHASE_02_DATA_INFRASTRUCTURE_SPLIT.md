# Phase 02 — Data: Split infrastructure into `data/infrastructure/*`

## Goal

Make cross-cutting persistence/sync plumbing explicit by moving Drift/PowerSync/Supabase code into:

- `lib/data/infrastructure/drift/**`
- `lib/data/infrastructure/powersync/**`
- `lib/data/infrastructure/supabase/**`

This matches the architecture described in `doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md` (infrastructure is not a feature).

## Moves (mechanical)

- Move:
  - `lib/data/drift/**` → `lib/data/infrastructure/drift/**`
  - `lib/data/powersync/**` → `lib/data/infrastructure/powersync/**`
  - `lib/data/supabase/**` → `lib/data/infrastructure/supabase/**`

## Import updates

Update all imports across `lib/**` (and avoid touching tests until final phase).

Patterns:

- `package:taskly_bloc/data/drift/...`
  → `package:taskly_bloc/data/infrastructure/drift/...`

- `package:taskly_bloc/data/powersync/...`
  → `package:taskly_bloc/data/infrastructure/powersync/...`

- `package:taskly_bloc/data/supabase/...`
  → `package:taskly_bloc/data/infrastructure/supabase/...`

Pay special attention to DI wiring:

- `lib/core/dependency_injection/**`

## Analyze and fix (required at end of phase)

- Run `flutter analyze`.
- Fix all errors/warnings.

## Do NOT do in this phase

- Do not run tests.
- Do not restructure repositories yet (that’s Phase 03).
