# Under Consideration (Not Ready for Build)

This document captures a potential future direction for the attention system.

**Status:** Under consideration / for future analysis.
**Do not implement yet** without an explicit decision and a dedicated implementation plan.

Created at: 2026-01-14T07:21:59.4334840Z (UTC)
Last updated at: 2026-01-14T07:21:59.4334840Z (UTC)

## Summary

Explore an alternative to the current `attention_rules.id`-based linking: move engine persistence (runtime state + resolutions) to link by `rule_key` instead of `rule_id`.

Motivation: make system rules safe and functional even if no DB rows exist (and avoid startup/post-auth seeding failures causing missing features).

## Context

Current schema links:
- `attention_rule_runtime_state.rule_id` references `attention_rules.id`.
- `attention_resolutions.rule_id` references `attention_rules.id`.

System rules are currently defined in code (`SystemAttentionRules`) and seeded into `attention_rules`.

Requirement direction:
- Some rules are system-defined (code-owned) with user-toggles and a curated set of editable params.
- Future: user-created rules with richer/flexible definition.
- Reduce risk of seeding/DB ordering issues breaking core attention features.

## Proposed Direction (Option 2)

Make `rule_key` the durable linkage key across the attention subsystem:

- System rules: exist only in code as templates with stable `rule_key` values.
- User-created rules: stored in DB with unique `rule_key` values (e.g. `usr_<uuid>`).
- Runtime state and resolutions link to rules by `rule_key`.

Tables still have an `id` primary key (PowerSync requirement), but the cross-table relationship is no longer based on `id`.

### High-level schema concept

- `attention_rules`
  - Purpose: user-created rule definitions (and optionally system overrides/config).
  - Keep `id` (text) PK.
  - Ensure `rule_key` is unique.

- `attention_rule_runtime_state`
  - Add `rule_key` (text, not null)
  - Deprecate / drop `rule_id` usage over time
  - Unique key becomes `(rule_key, entity_type, entity_id)`

- `attention_resolutions`
  - Add `rule_key` (text, not null)
  - Deprecate / drop `rule_id` usage over time

## Migration Plan (Two-phase)

### Phase A: Additive + backward compatible

1) Add nullable `rule_key` column to:
   - `attention_rule_runtime_state`
   - `attention_resolutions`

2) Backfill existing rows by joining through `attention_rules`:
   - `runtime.rule_key = attention_rules.rule_key WHERE runtime.rule_id = attention_rules.id`
   - `resolutions.rule_key = attention_rules.rule_key WHERE resolutions.rule_id = attention_rules.id`

3) Update app writes:
   - Always write `rule_key` for new runtime/resolution records.
   - Continue writing `rule_id` during transition (optional, for safety/joins).

4) Update app reads:
   - Prefer `rule_key`.
   - Fallback: if `rule_key` is null, join via `rule_id` to recover it.

### Phase B: Cutover

1) Make `rule_key` non-null.
2) Stop writing `rule_id` (or keep as denormalized cache).
3) Update unique keys/indexes to key by `rule_key`.
4) Update cleanup logic:
   - Orphan cleanup should consider whether `rule_key` is either:
     - a known system key, or
     - present in `attention_rules.rule_key` for user-created rules.

## Code Touchpoints (Expected)

- Repository contract and drift repository methods likely need `ruleKey` variants:
  - `watchRuntimeStateForRuleKey(ruleKey, ...)`
  - `getLatestResolution(ruleKey, entityId, ...)`

- Engine currently indexes runtime/resolution by rule `id`. Decide whether to:
  - change engine to use `ruleKey` for persistence lookups, or
  - keep `AttentionRule.id` for user rules but carry `ruleKey` as the stable identity.

- Post-auth maintenance cleanup routines must be updated to avoid deleting valid system-keyed records.

- PowerSync schema + server schema must be updated for new columns.

## Pros

- System rules can exist purely in code; no DB seeding required for rule *existence*.
- Runtime/resolution persistence no longer depends on `attention_rules` row availability.
- Supports a clean split between:
  - code-owned system rules
  - user-created DB rules

## Cons / Risks

- Larger migration affecting Drift schema, PowerSync schema, and server schema.
- Renaming a `rule_key` becomes a migration/aliasing problem (keys must be treated as immutable).
- Requires careful dual-read/dual-write during migration to avoid data loss.
- Existing analytics/queries that assume `rule_id` joins may need rewriting.

## Open Questions

- Should `rule_id` be retained permanently as a denormalized cache for debugging/joins?
- Should user-created rules use a structured key (`usr_<uuid>`) or plain UUID string?
- How should we handle “ruleKey renamed” for system rules (aliases mapping old->new)?
- What is the desired sync behavior for runtime/resolution entries for rules that no longer exist (system removed or user deleted)?

## Decision Criteria

Proceed with this option if:
- We want to eliminate seeding as a correctness requirement.
- We are willing to pay a one-time migration + compatibility complexity cost.
- We can commit to `rule_key` immutability and provide a migration strategy for template evolution.

Prefer the simpler "templates + DB overlay using attention_rules rows" approach if:
- We want minimal migration risk and to keep `rule_id` joins intact.

---

## AI instructions

- Review `doc/architecture/` before implementing any phase of this work.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by the phase’s changes are fixed by the end of the phase.
- Exception: in the last phase of the plan, fix any `flutter analyze` error or warning.
- This backlog item is analysis-only; do not ship code until explicitly approved.
