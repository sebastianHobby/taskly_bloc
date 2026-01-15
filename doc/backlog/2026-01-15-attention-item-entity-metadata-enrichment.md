# Backlog — Enrich AttentionItem entity context (Value + others)

Created at: 2026-01-15 (UTC)

## Context
The Attention inbox UI now surfaces an entity context line (e.g. `Task • Pay rent`) when the `AttentionItem.metadata` provides a display name.

We already set `entity_display_name` for task and project items at creation time in the attention engine.

## Problem
Some attention items are not actionable because they primarily communicate rule output (e.g. “urgent but not allocated 4 times”) without clearly identifying *which entity* the user should act on.

This is most noticeable when:
- A rule produces “summary-like” titles/descriptions.
- The entity type is not task/project, or the engine does not populate a name field.
- The UI cannot (and should not) query repositories directly due to the presentation boundary rule.

## Goal
Make every attention item identify its actionable target entity (when one exists) using domain-first metadata enrichment.

## Proposal
### 1) Standardize a small metadata contract
Populate these keys consistently at `AttentionItem` creation time (domain):
- `entity_display_name`: string (primary human label shown in inbox/support tiles)
- Optional `entity_secondary_label`: string (context like project/value name, or a short qualifier)
- Optional `entity_kind_label`: string (e.g. `Task`, `Project`, `Value`) if needed outside of `entityType`

Keep existing per-entity keys for backward compatibility:
- `task_name`, `project_name`, and add `value_name` where applicable.

### 2) Extend enrichment for Value + other entity types
- Value items: ensure `value_name` and `entity_display_name` are populated.
- Journal / tracker / review session:
  - If these are actionable entities in the product, populate a stable human label.
  - If they are not actionable, consider omitting the entity context line and ensure the title/description is self-explanatory.

### 3) Improve rule outputs that still feel “non-actionable”
For rules where the title is inherently summary-like, consider including a concise “what to do” hint in `detail_lines` (already supported) or adding a new `action_hint` metadata key.

## Implementation sketch (domain-first)
- Prefer enriching in the attention engine at the exact place the item is created (it already has the entity object in hand).
- If an evaluator only has `entityId` and needs joins to build `entity_display_name`, add a small domain service (e.g. `AttentionItemEntityLabelService`) used by the engine (still not UI).

## Acceptance criteria
- In the inbox, items reliably show `Task/Project/Value • <name>` when the item has a meaningful target entity.
- For Value and any other supported entity types, `entity_display_name` is present when feasible.
- No repository calls are introduced in widgets/pages; any lookups happen in domain or via a domain enrichment service.

## Notes / risks
- Performance: avoid N+1 lookups in the engine; batch where possible.
- Consistency: keep metadata keys stable so the UI can render without per-rule special cases.
