# Phase 05 — Attention System Compatibility (workflowStep)

## Goal
Ensure removing workflows does not break the Attention System.

## Background
The Attention architecture explicitly notes `workflowStep` is a known gap and currently yields no items in the engine.

## Recommended default (safe)
Keep `workflowStep` in the Attention schema as a deprecated no-op.

## Files to keep as-is (unless you are purging schema)
- Domain enum includes `workflowStep`:
  - `lib/domain/attention/model/attention_rule.dart`
- Engine returns empty list for `workflowStep`:
  - `lib/domain/attention/engine/attention_engine.dart`
- Drift enum includes `workflowStep`:
  - `lib/data/infrastructure/drift/features/attention_tables.drift.dart`
- Legacy migration of enum string values:
  - `lib/data/attention/maintenance/attention_seeder.dart`
  - `lib/data/infrastructure/powersync/api_connector.dart`
- Repository mapping:
  - `lib/data/attention/repositories/attention_repository_v2.dart`

## If you DO want to purge workflowStep (not recommended in same PR)
1. Add a data migration that rewrites or deletes rows:
   - `UPDATE attention_rules SET rule_type='problem' WHERE rule_type='workflowStep';` (or `DELETE`)
2. Remove `workflowStep` from domain enum + drift enum.
3. Remove all mapping and legacy migration code that references `workflowStep`.
4. Verify server-side Supabase enum/type allows the new set of values.

## Verification
- Run `flutter analyze`.
- Fix compilation errors only.
