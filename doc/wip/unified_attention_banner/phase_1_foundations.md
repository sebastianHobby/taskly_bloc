# Plan: Unified Attention Banner + Action/Review Cutover (Phase 1 — Data Model + Contracts)

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T14:00:00Z

## Goal
Make **Action vs Review** a first-class concept in the attention system while
also performing the **Tier 2 cutover** to explicit evaluator selection.

Phase 1 delivers schema + domain model + repository contract changes so Phase 2
can refactor the engine without ambiguity and Phase 3 can ship UI + cleanup.

## Confirmed decisions (from chat)
- Top-level taxonomy is **only**: `Action` + `Review`.
- `category` removal is confirmed.
- Do not persist computed `AttentionItem`s.
- Keep `ruleKey` (or a renamed equivalent) as the stable “rule family” key.
- Overflow routes to `review_inbox` (screen key can stay even if UI title changes).
- UI must not depend on `AttentionItem.metadata`.

## Non-goals (for this phase)
- Refactoring the attention engine implementation (Phase 2).
- Shipping the unified banner UI and overflow inbox UI (Phase 3).

## Existing plan decisions that remain true
- Overflow destination screen key remains `review_inbox`.
- Old `check_in` screen remains removed.
- My Day must still surface both:
  - allocation alerts (now bucket=action)
  - review-session due items (bucket=review)

## Proposed schema changes (attention_rules)
Replace the current rule definition fields with explicit evaluator selection.

### Add / keep
- Keep: `id`, `rule_key`, display fields, resolution actions, severity, `active`,
  `source`, `created_at`, `updated_at`.
- Add: `bucket` (`action|review`).
- Add: `evaluator` (stable key).
- Add: `evaluator_params` (JSON).

### Remove
- Remove: `category`.
- Remove: `rule_type`, `trigger_type`, `trigger_config`, `entity_selector`.

## Evaluator taxonomy (minimum viable set)
Evaluator keys should be minimal and stable:
- `task_predicate_v1`
- `project_predicate_v1`
- `review_session_due_v1`
- `allocation_snapshot_task_v1`

Each evaluator uses a typed params union (Freezed + JSON) internally.

## Migration approach (assume user data migrated)
Hard cutover is allowed. Supabase migration is already complete.

1) Add new columns.
2) Backfill `bucket`, `evaluator`, `evaluator_params` from legacy fields.
3) Drop legacy columns (`category`, `rule_type`, `trigger_type`,
   `trigger_config`, `entity_selector`).

This implies coordinated changes in:
- Drift schema (local app DB)
- PowerSync client schema (`lib/data/infrastructure/powersync/schema.dart`)
- Any client upload mapping/normalization that enumerates columns

## Contract + domain model changes
- Update `AttentionRule` domain model to match the new schema.
- Update repository mappings and queries.
- Update `AttentionSeeder` + `SystemAttentionRules` templates to emit:
  `bucket + evaluator + evaluatorParams`.

## Local DB alignment (Drift) (required)
Now that the Supabase migration is complete, Phase 1 must also update the local
Drift schema/mappings so the Flutter app compiles and reads/writes the new
columns:

- Update the Drift `attention_rules` table model to:
  - add `bucket`, `evaluator`, `evaluator_params`
  - remove legacy columns: `category`, `rule_type`, `trigger_type`,
    `trigger_config`, `entity_selector`
- Update any DAOs/queries/selects/inserts that reference removed columns.
- Run `build_runner` to regenerate Drift outputs.

## Concrete file targets (Phase 1)
These are the primary implementation touchpoints for schema + model alignment:

- Drift table definitions:
  - `lib/data/infrastructure/drift/features/attention_tables.drift.dart`
  - If enums changed, also check: `lib/data/infrastructure/drift/features/shared_enums.dart`
  - DB wiring (if table lists/migrations need updating):
    - `lib/data/infrastructure/drift/drift_database.dart`

- Domain models:
  - `lib/domain/attention/model/attention_rule.dart`
  - (May require adjusting related models if they reference rule fields)

- Repository + mapping:
  - `lib/domain/attention/contracts/attention_repository_contract.dart`
  - `lib/data/attention/repositories/attention_repository_v2.dart`

- System rule templates + seeding:
  - `lib/domain/attention/system_attention_rules.dart`
  - `lib/data/attention/maintenance/attention_seeder.dart`
  - `lib/data/id/id_generator.dart` (only if rule ids/keys strategy changes)

- PowerSync client schema + upload mapping (must match Supabase columns):
  - `lib/data/infrastructure/powersync/schema.dart`
  - `lib/data/infrastructure/powersync/upload_data_normalizer.dart`

- Remove legacy runtime migrations that write dropped columns:
  - `lib/data/infrastructure/powersync/api_connector.dart`
    - Search for SQL updating `attention_rules.rule_type` / legacy fields.
    - Delete or rewrite to operate on `bucket/evaluator` only.

## Phase 1 checklist (make it hard to miss things)
- Compile-time goal: no Dart references remain to dropped columns.
- Runtime goal: seeder produces valid rows with non-null:
  - `bucket`, `evaluator`, `evaluator_params`.
- Replication goal: PowerSync schema/table mapping does not mention dropped
  columns, otherwise replication will fail at runtime.

## Acceptance criteria
- Domain model and repository compile with the new schema.
- Migration/backfill plan is concrete enough to implement.
- `flutter analyze` is clean at end of phase.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
