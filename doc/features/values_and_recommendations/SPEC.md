# Values And Recommendations Spec

## Scope

Defines value models, ratings semantics, and how values influence recommendations and allocation.

## Core rules

- Values are user-defined and drive recommendation weighting.
- Recommendation logic is deterministic and testable.
- Recommendation UI must separate rationale from action affordances.

## Testing minimums

- Value rating aggregation correctness.
- Allocation tie-break determinism.
- Empty-values fallback behavior.
