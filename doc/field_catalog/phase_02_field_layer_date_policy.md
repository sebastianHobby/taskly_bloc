# Phase 02 — Field layer (date policy) + adapters

## Goal
Introduce a centralized date formatting policy and field-level building blocks, without changing entity composition yet.

## UX policy
- Dates should be **relative within 7 days** (past or future), otherwise use a **short date**.

## Steps
1. Implement `DateLabelFormatter` (or equivalent) in `lib/presentation/field_catalog/`.
2. Update existing field widgets to use the centralized formatter:
   - `DateChip` should use the policy rather than duplicating relative-date logic in multiple places.
3. Keep existing entity widgets intact (tiles/cards). If needed, add adapter functions so legacy widgets can consume the formatter.
4. Run `flutter analyze` and fix any issues.

## Exit criteria
- Date policy is implemented in one place.
- `DateChip` uses the central formatter.
- `flutter analyze` passes with 0 issues.
