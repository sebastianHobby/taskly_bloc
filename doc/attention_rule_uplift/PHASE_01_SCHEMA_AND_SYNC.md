# Phase 01 — Schema + PowerSync alignment

## Outcome

- Supabase schema supports Option 3 (clean rebuild) attention tables, including `attention_rule_runtime_state`.
- PowerSync sync rules and client schema include all attention tables.
- Codebase still compiles; no app behavior change required yet.

## Scope

- Supabase migrations: add a timestamped migration implementing the new attention schema.
- PowerSync:
  - Ensure `supabase/powersync-sync-rules.yaml` includes the new table.
  - Ensure `lib/data/infrastructure/powersync/schema.dart` matches the table columns.

## Non-goals

- No Dart-side refactor of the attention engine yet.
- No tests updated or run.

## Steps

1) Create a migration file in `supabase/migrations/` for the new attention schema

- Add a new timestamped migration (e.g. `YYYYMMDDHHMMSS_attention_rebuild.sql`) that:
  - Drops existing attention tables (rules/resolutions/condition_states/runtime_state) and recreates them.
  - Enforces `id uuid primary key default gen_random_uuid()` on every attention table.
  - Enforces `user_id uuid not null default auth.uid()` on every attention table.
  - Keeps `domain` and `category` columns on `attention_rules`.
  - Adds RLS policies for select/insert/update/delete (self-owned) for each table.
  - Adds `updated_at` triggers where applicable.

Notes:
- This repo already has a PowerSync publication migration; do not change publication strategy unless required.

2) PowerSync sync rules

- Ensure `supabase/powersync-sync-rules.yaml` includes:
  - `attention_rules`
  - `attention_resolutions`
  - `attention_condition_states`
  - `attention_rule_runtime_state`

Each must be filtered by `user_id = bucket.user_id` (server-owned user scoping).

3) PowerSync client schema

- Ensure `lib/data/infrastructure/powersync/schema.dart` includes matching tables and columns.
- Ensure any columns that exist in the DB but not in the PowerSync schema are either:
  - intentionally excluded (rare; must be justified), or
  - added so replication doesn’t fail.

4) Compile + analyze checkpoint

- Run: `flutter analyze`

Optional (if build_runner is used anywhere you touched):
- Run: `dart run build_runner build --delete-conflicting-outputs`

## Delete list (big-bang rule)

- None yet (this phase is additive at runtime; it creates schema primitives).

## Exit criteria

- Migrations apply cleanly locally.
- PowerSync rules + schema include the new runtime table.
- `flutter analyze` passes.
