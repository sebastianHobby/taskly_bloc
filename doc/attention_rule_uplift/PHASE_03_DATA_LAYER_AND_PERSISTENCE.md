# Phase 03 — Data layer + persistence rewrite

## Outcome

- Data layer matches the new Supabase schema:
  - `attention_rules` includes domain/category.
  - `attention_rule_runtime_state` is persisted and synced.
- Drift/PowerSync mapping is coherent and supports the new contracts.
- No runtime cutover to the new engine yet.

## Scope

- Rework the attention repository implementation to support:
  - rule storage
  - resolution storage
  - runtime state storage
- Add any missing converters/mappers.

## Constraints

- Do not update or run tests.
- Keep compilation and run `flutter analyze` at the end.

## Steps

1) Update persistence models

- Ensure local tables (Drift) represent:
  - attention_rules
  - attention_resolutions
  - attention_condition_states (if still used)
  - attention_rule_runtime_state

Rules:
- `id` is the PK UUID.
- `user_id` exists and is synced, but is not used by the app for logic.

2) Implement repository contract against the new tables

- Implement the new `AttentionRepositoryContract` (from Phase 02) using:
  - Drift queries for local read/write
  - PowerSync replication for updates

Key behaviors to support:
- Watch active rules reactively.
- Record resolutions.
- Read/write runtime state (dismissed state hash, next evaluate time).

3) Update seeding

- Update the seeder so that system rules:
  - include domain/category.
  - still use deterministic IDs if that’s part of your existing approach.

4) Ensure the upload JSON normalization still works

- If any new columns use jsonb/text[]/etc, confirm:
  - local TEXT representation is correctly decoded/encoded during upload.

5) Build runner checkpoint (if Drift schema changed)

- Run the existing build task:
  - `dart run build_runner build --delete-conflicting-outputs`

6) Compile + analyze checkpoint

- Run: `flutter analyze`

## Delete list (big-bang rule)

Only delete code that is fully replaced in this phase.

Expected deletions (once replacements are wired):
- Legacy attention mappers/converters that only support the old rule model.

If deletions require runtime cutover, postpone deletions to Phase 05.

## Exit criteria

- Drift tables and repository compile.
- Seeder compiles.
- `flutter analyze` passes.
